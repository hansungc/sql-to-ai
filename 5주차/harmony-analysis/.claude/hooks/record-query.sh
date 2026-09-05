#!/usr/bin/env bash
# .claude/hooks/record-query.sh
# (교재 474쪽) 실행된 쿼리를 query_history에 한 줄 INSERT하는 PostToolUse 훅
# 사전 준비: harmony-analysis/.env의 RECORDER_PASSWORD를 현재 셸에 적용
# 계정 생성은 환경셋업/recorder_account.sql.example을 로컬 파일로 복사해 진행합니다.

# 전제 확인: 기록만 건너뛰며 원래 분석 명령의 성공/실패는 바꾸지 않습니다.
command -v jq >/dev/null 2>&1 || {
  echo "[record-query] jq가 없어 기록을 건너뜁니다." >&2; exit 0; }
[ -n "${RECORDER_PASSWORD:-}" ] || {
  echo "[record-query] RECORDER_PASSWORD가 없어 기록을 건너뜁니다." >&2; exit 0; }

payload=$(cat)
tool_name=$(printf '%s' "$payload" | jq -r '.tool_name // "unknown"')
event_name=$(printf '%s' "$payload" | jq -r '.hook_event_name // "PostToolUse"')

case "$tool_name" in
  mcp__harmony_db__execute_sql)
    sql=$(printf '%s' "$payload" | jq -r '.tool_input.sql // ""')
    category='mcp'
    ;;
  Bash)
    command=$(printf '%s' "$payload" | jq -r '.tool_input.command // ""')
    one_line=$(printf '%s\n' "$command" | tr '\n' ' ')
    printf '%s\n' "$one_line" | grep -qE '(^|[[:space:]])mysql([[:space:]]|$)' || exit 0
    sql=$(printf '%s\n' "$one_line" \
      | sed -nE 's/^.*[[:space:]]-e[[:space:]]+"([^"]*)"[[:space:]]*$/\1/p')
    category='bash'
    ;;
  *)
    exit 0
    ;;
esac

[ -n "$sql" ] || {
  echo '[record-query] SQL을 확인할 수 없어 기록을 건너뜁니다.' >&2
  exit 0
}

session_id=$(printf '%s' "$payload" | jq -r '.session_id // "unknown"')
tool_use_id=$(printf '%s' "$payload" | jq -r '.tool_use_id // "unknown"')
agent_name=$(printf '%s' "$payload" | jq -r '.agent_type // "main"')
executor=${USER:-unknown}
description="$agent_name via $tool_name"

if [ "$event_name" = 'PostToolUseFailure' ]; then
  execution_status='failure'
  error_message=$(printf '%s' "$payload" | jq -r '.error // "unknown error"')
else
  execution_status='success'
  error_message=''
fi

mysql_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e "s/'/''/g"
}

esc_sql=$(mysql_escape "$sql")
esc_session=$(mysql_escape "$session_id")
esc_tool_use=$(mysql_escape "$tool_use_id")
esc_executor=$(mysql_escape "$executor")
esc_agent=$(mysql_escape "$agent_name")
esc_tool=$(mysql_escape "$tool_name")
esc_category=$(mysql_escape "$category")
esc_description=$(mysql_escape "$description")
esc_status=$(mysql_escape "$execution_status")
esc_error=$(mysql_escape "$error_message")

insert_sql="INSERT INTO query_history
  (session_id, tool_use_id, executor, agent_name, tool_name, category,
   description, sql_query, execution_status, error_message, verified)
VALUES
  ('$esc_session', '$esc_tool_use', '$esc_executor', '$esc_agent', '$esc_tool',
   '$esc_category', '$esc_description', '$esc_sql', '$esc_status',
   NULLIF('$esc_error', ''), FALSE);"

if [ "${RECORD_QUERY_DRY_RUN:-0}" = '1' ]; then
  printf '%s\n' "$insert_sql"
  exit 0
fi

# 로컬 mysql 클라이언트를 우선 사용하고, 없으면 이 저장소의 Docker Compose로 접속합니다.
if command -v mysql >/dev/null 2>&1; then
  MYSQL_PWD="$RECORDER_PASSWORD" mysql \
    -h 127.0.0.1 -P "${HARMONY_DB_PORT:-3306}" -u recorder harmony_db \
    -e "$insert_sql" 2>/dev/null \
    || echo "[record-query] 기록 실패(계정·비밀번호·포트를 확인하세요)." >&2
elif command -v docker >/dev/null 2>&1; then
  compose_file="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}/../환경셋업/docker-compose.yml"
  compose_env="$(dirname "$compose_file")/.env"
  compose_args=(-f "$compose_file")
  [ -f "$compose_env" ] \
    && compose_args=(--env-file "$compose_env" -f "$compose_file")
  MYSQL_PWD="$RECORDER_PASSWORD" docker compose "${compose_args[@]}" exec -T \
    -e MYSQL_PWD harmony-mysql \
    mysql -u recorder harmony_db -e "$insert_sql" 2>/dev/null \
    || echo "[record-query] Docker 기록 실패(컨테이너와 계정을 확인하세요)." >&2
else
  echo "[record-query] mysql 또는 docker 명령이 없어 기록을 건너뜁니다." >&2
fi
exit 0
