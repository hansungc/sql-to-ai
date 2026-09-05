#!/usr/bin/env bash

set -u

day=${1:-21}
phase=${2:-preflight}

case "$day" in
  21|22|23|24|25) ;;
  *) echo "사용법: ./check-environment.sh [21|22|23|24|25] [preflight|ready]" >&2; exit 2 ;;
esac
case "$phase" in
  preflight|ready) ;;
  *) echo "단계는 preflight 또는 ready여야 합니다." >&2; exit 2 ;;
esac

failed=0
script_dir=$(cd "$(dirname "$0")" && pwd)
project_dir=$(cd "$script_dir/../harmony-analysis" && pwd)
compose_file="$script_dir/docker-compose.yml"

run_compose() {
  if [ -f "$script_dir/.env" ]; then
    docker compose --env-file "$script_dir/.env" -f "$compose_file" "$@"
  else
    docker compose -f "$compose_file" "$@"
  fi
}

pass() { printf 'OK   %s\n' "$1"; }
warn() { printf 'WARN %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; failed=1; }

check_completed_file() {
  local file_path=$1
  local file_label=$2
  local required_term
  shift 2

  if [ ! -f "$file_path" ]; then
    fail "$file_label 파일이 없습니다: $file_path"
    return
  fi
  if grep -qi 'TODO' "$file_path"; then
    fail "$file_label 에 시작 파일의 TODO 주석이 그대로 있습니다. 해당 Day의 프롬프트로 본문을 채우세요."
    return
  fi

  for required_term in "$@"; do
    if ! grep -Fqi "$required_term" "$file_path"; then
      fail "$file_label 파일에 필수 항목 '$required_term'이 없습니다."
      return
    fi
  done
  pass "$file_label 완성본 확인"
}

has_command() { command -v "$1" >/dev/null 2>&1; }
need_command() {
  if has_command "$1"; then
    pass "$1: $(command -v "$1")"
  else
    fail "$1 명령을 찾지 못했습니다."
  fi
}

need_command claude

# git은 필수가 아닙니다. 각 Day 첫머리의 'git rev-parse'와 'git check-ignore'에만 쓰입니다.
if has_command git; then
  pass "git: $(command -v git)"
else
  warn "git이 없습니다. 각 Day 첫머리의 'git rev-parse --show-toplevel' 두 줄 대신"
  warn "     압축을 푼 저장소 루트로 직접 이동하세요. 'git check-ignore' 확인은 건너뜁니다."
fi

backend=none
if [ "$day" -ge 22 ]; then
  need_command node
  need_command npm

  if has_command node; then
    if node -e 'const [a,b]=process.versions.node.split(".").map(Number); process.exit(a>22 || (a===22 && b>=5) ? 0 : 1)'; then
      pass "Node.js $(node --version): DBHub 요구 버전 충족"
    else
      fail "Node.js 22.5.0 이상이 필요합니다. 현재: $(node --version)"
    fi
  fi

  docker_available=0
  local_mysql_available=0
  if has_command docker && docker info >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    docker_available=1
  fi
  has_command mysql && local_mysql_available=1

  requested_backend=${HARMONY_DB_BACKEND:-auto}
  case "$requested_backend" in
    docker)
      [ "$docker_available" -eq 1 ] && backend=docker \
        || fail "HARMONY_DB_BACKEND=docker이지만 Docker 엔진과 Compose를 사용할 수 없습니다."
      ;;
    local)
      [ "$local_mysql_available" -eq 1 ] && backend=local \
        || fail "HARMONY_DB_BACKEND=local이지만 mysql 클라이언트를 찾지 못했습니다."
      ;;
    auto)
      if [ "$phase" = ready ] && [ "$docker_available" -eq 1 ] \
        && run_compose ps --status running --services 2>/dev/null \
          | grep -qx 'harmony-mysql'; then
        backend=docker
      elif [ "$local_mysql_available" -eq 1 ]; then
        backend=local
      elif [ "$docker_available" -eq 1 ]; then
        backend=docker
      else
        fail "Docker 또는 로컬 mysql 중 하나가 필요합니다."
      fi
      ;;
    *) fail "HARMONY_DB_BACKEND는 auto, docker, local 중 하나여야 합니다." ;;
  esac

  [ "$backend" != none ] && pass "데이터베이스 실행 방식: $backend"

  if [ "$phase" = preflight ]; then
    [ -n "${DB_PASSWORD:-}" ] \
      && pass "DB_PASSWORD 설정됨(값은 표시하지 않음)" \
      || warn "DB_PASSWORD는 계정을 만든 뒤 harmony-analysis/.env에 설정합니다."
  fi
fi

db_query() {
  query=$1
  if [ "$backend" = docker ]; then
    MYSQL_PWD="$DB_PASSWORD" run_compose exec -T \
      -e MYSQL_PWD harmony-mysql \
      mysql -h 127.0.0.1 -uclaude_readonly -N -B harmony_db -e "$query"
  else
    MYSQL_PWD="$DB_PASSWORD" mysql \
      -h "${HARMONY_DB_HOST:-127.0.0.1}" -P "${HARMONY_DB_PORT:-3306}" \
      -uclaude_readonly -N -B harmony_db -e "$query"
  fi
}

recorder_query() {
  query=$1
  if [ "$backend" = docker ]; then
    MYSQL_PWD="$RECORDER_PASSWORD" run_compose exec -T \
      -e MYSQL_PWD harmony-mysql \
      mysql -h 127.0.0.1 -urecorder -N -B harmony_db -e "$query"
  else
    MYSQL_PWD="$RECORDER_PASSWORD" mysql \
      -h "${HARMONY_DB_HOST:-127.0.0.1}" -P "${HARMONY_DB_PORT:-3306}" \
      -urecorder -N -B harmony_db -e "$query"
  fi
}

if [ "$phase" = ready ] && [ "$day" -ge 22 ]; then
  [ -n "${DB_PASSWORD:-}" ] \
    && pass "DB_PASSWORD 설정됨(값은 표시하지 않음)" \
    || fail "DB_PASSWORD가 비어 있습니다. harmony-analysis/.env를 적용한 뒤 다시 실행하세요."

  if [ -f "$project_dir/.mcp.json" ]; then
    if node -e 'JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"))' "$project_dir/.mcp.json"; then
      pass ".mcp.json JSON 정상"
      if node -e '
        const c = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
        const s = c.mcpServers && c.mcpServers.harmony_db;
        const ok = s && s.command === "npx" && Array.isArray(s.args)
          && s.args.includes("@bytebase/dbhub@1.2.3")
          && s.env && s.env.DB_TYPE === "mysql"
          && s.env.DB_USER === "claude_readonly"
          && s.env.DB_PASSWORD === "${DB_PASSWORD}"
          && s.env.DB_NAME === "harmony_db";
        process.exit(ok ? 0 : 1);
      ' "$project_dir/.mcp.json"; then
        pass "현재 Bash 환경용 DBHub·읽기 전용 계정 설정 확인"
      else
        fail ".mcp.json이 Bash용 견본과 다릅니다. Windows cmd 설정이나 평문 비밀번호가 없는지 확인하세요."
      fi
    else
      fail ".mcp.json JSON 문법 오류"
    fi
  else
    fail "$project_dir/.mcp.json이 없습니다. Day 22 예제대로 복사하세요."
  fi

  if [ "$backend" = docker ]; then
    if run_compose ps --status running --services 2>/dev/null \
      | grep -qx 'harmony-mysql'; then
      pass "harmony-mysql 실행 중"
    else
      fail "harmony-mysql이 실행 중이 아닙니다. docker compose up -d 후 확인하세요."
    fi

    published_endpoint=$(run_compose port harmony-mysql 3306 2>/dev/null | tail -n 1)
    published_port=${published_endpoint##*:}
    expected_port=${HARMONY_DB_PORT:-3306}
    if [ -n "$published_endpoint" ] && [ "$published_port" = "$expected_port" ]; then
      pass "MCP 환경 변수와 Docker 공개 포트 일치: $expected_port"
    else
      fail "Docker 공개 포트($published_port)와 HARMONY_DB_PORT($expected_port)가 다릅니다. 두 .env를 맞추세요."
    fi
  fi

  if [ -n "${DB_PASSWORD:-}" ]; then
    counts_sql="SELECT CONCAT_WS(',',
      (SELECT COUNT(*) FROM artists),
      (SELECT COUNT(*) FROM fans),
      (SELECT COUNT(*) FROM tracks),
      (SELECT COUNT(*) FROM streaming),
      (SELECT COUNT(*) FROM orders),
      (SELECT COUNT(*) FROM subscription_history),
      (SELECT COUNT(*) FROM fan_activities));"
    if counts=$(db_query "$counts_sql" 2>/dev/null); then
      if [ "$counts" = '15,111,104,375,234,100,140' ]; then
        pass "HARMONY 핵심 테이블 행 수 일치: $counts"
      else
        fail "HARMONY 핵심 행 수 불일치: $counts"
      fi
    else
      fail "claude_readonly로 harmony_db에 접속하지 못했습니다."
    fi

    if grants=$(db_query 'SHOW GRANTS;' 2>/dev/null); then
      if printf '%s\n' "$grants" | grep -q 'SELECT' \
        && ! printf '%s\n' "$grants" | grep -qE 'ALL PRIVILEGES|INSERT|UPDATE|DELETE|DROP'; then
        pass "claude_readonly: SELECT 전용 권한 확인"
      else
        fail "claude_readonly에 SELECT 이외 권한이 있습니다. SHOW GRANTS를 확인하세요."
      fi
    else
      fail "claude_readonly 권한을 확인하지 못했습니다."
    fi

    if db_query 'SELECT email FROM fans LIMIT 1;' >/dev/null 2>&1; then
      fail "claude_readonly가 fans.email을 읽을 수 있습니다. 계정 SQL을 다시 적용하세요."
    else
      pass "fans.email 데이터베이스 권한 차단 확인"
    fi
  fi
fi

if [ "$phase" = ready ] && [ "$day" -ge 23 ]; then
  check_completed_file "$project_dir/CLAUDE.md" "CLAUDE.md" \
    '2026-09-03' 'churned' 'VIP' 'email' '팩트'
  check_completed_file \
    "$project_dir/.claude/skills/fan-churn-analysis/SKILL.md" \
    "fan-churn-analysis Skill" 'churned' 'email'

  if claude plugin validate --strict "$project_dir/.claude/skills" >/dev/null 2>&1; then
    pass "Skill 문법 검사 통과"
  else
    fail "Skill 문법 오류입니다: claude plugin validate --strict '$project_dir/.claude/skills'"
  fi
fi

if [ "$day" -ge 24 ]; then
  need_command jq
  for hook in sql-guard.sh mask-pii.sh record-query.sh; do
    hook_path="$project_dir/.claude/hooks/$hook"
    [ -x "$hook_path" ] && pass "$hook 실행 권한 있음" \
      || fail "$hook 실행 권한이 없습니다: chmod +x '$hook_path'"
  done

  if [ "$phase" = ready ]; then
    [ -n "${RECORDER_PASSWORD:-}" ] \
      && pass "RECORDER_PASSWORD 설정됨(값은 표시하지 않음)" \
      || fail "RECORDER_PASSWORD가 비어 있습니다. harmony-analysis/.env를 적용하세요."

    settings="$project_dir/.claude/settings.json"
    if jq -e '
      def has_hook($event; $command):
        any(.hooks[$event][]?;
          .matcher == "Bash|mcp__harmony_db__execute_sql"
          and any(.hooks[]?; .type == "command" and .command == $command)
        );
      has_hook("PreToolUse"; "$CLAUDE_PROJECT_DIR/.claude/hooks/sql-guard.sh")
      and has_hook("PostToolUse"; "$CLAUDE_PROJECT_DIR/.claude/hooks/mask-pii.sh")
      and has_hook("PostToolUse"; "$CLAUDE_PROJECT_DIR/.claude/hooks/record-query.sh")
      and has_hook("PostToolUseFailure"; "$CLAUDE_PROJECT_DIR/.claude/hooks/record-query.sh")
    ' "$settings" >/dev/null 2>&1; then
      pass "Bash·MCP용 차단·마스킹·성공/실패 기록 훅 확인"
    else
      fail ".claude/settings.json의 matcher 또는 훅 명령이 Day 24 완성본과 다릅니다."
    fi

    if [ -n "${RECORDER_PASSWORD:-}" ] && grants=$(recorder_query 'SHOW GRANTS;' 2>/dev/null); then
      if printf '%s\n' "$grants" | grep -q 'INSERT' \
        && ! printf '%s\n' "$grants" | grep -qE 'ALL PRIVILEGES|UPDATE|DELETE|DROP'; then
        pass "recorder: query_history INSERT 전용 권한 확인"
      else
        fail "recorder 권한이 INSERT 전용이 아닙니다."
      fi
    elif [ -n "${RECORDER_PASSWORD:-}" ]; then
      fail "recorder 계정으로 접속하지 못했습니다."
    fi

    for agent_name in sql-writer validator business-translator; do
      check_completed_file "$project_dir/.claude/agents/$agent_name.md" \
        "$agent_name 서브에이전트"
    done
    if claude plugin validate --strict "$project_dir/.claude/agents" >/dev/null 2>&1; then
      pass "서브에이전트 문법 검사 통과"
    else
      fail "서브에이전트 문법 오류입니다: claude plugin validate --strict '$project_dir/.claude/agents'"
    fi
  fi
fi

if [ "$phase" = ready ] && [ "$day" -ge 25 ] && [ -n "${DB_PASSWORD:-}" ]; then
  eval_sql="SELECT EXISTS(SELECT 1 FROM eval_cases
    WHERE case_name IN ('universe-daily-streams', 'universe-daily-streams-sha256')
      AND canonical_sql IS NOT NULL
      AND expected_result IS NOT NULL
      AND (
        (hash_algorithm = 'MD5'
          AND expected_hash = 'c85f4f00095b42365b007fc38f8b8e36')
        OR
        (hash_algorithm = 'SHA256'
          AND expected_hash = 'ed7d8fc8ab7d18d437434f136528651b342232880fa09e049d690b9e681b8c43')
      )
      AND expected_row_count = 4
      AND dataset_version = 'harmony_v1'
      AND serialization_version = 'date-colon-integer-comma-v1');"
  if eval_count=$(db_query "$eval_sql" 2>/dev/null) && [ "$eval_count" = '1' ]; then
    pass "eval_cases 기준 SQL·정답 행·해시 메타데이터 확인"
  else
    fail "eval_cases가 미완성이거나 claude_readonly SELECT 권한이 없습니다."
  fi

  actual_hash_sql="SELECT SHA2(GROUP_CONCAT(
    CONCAT(DATE_FORMAT(stream_date, '%Y-%m-%d'), ':', CAST(daily_streams AS CHAR))
    ORDER BY stream_date SEPARATOR ','
  ), 256)
  FROM (
    SELECT s.stream_date, SUM(s.play_count) AS daily_streams
    FROM streaming s
    JOIN tracks t ON s.track_id = t.track_id
    WHERE t.track_name = 'Universe'
      AND s.stream_date >= '2026-07-01'
      AND s.stream_date < '2026-08-01'
    GROUP BY s.stream_date
  ) result;"
  if actual_hash=$(db_query "$actual_hash_sql" 2>/dev/null) \
    && [ "$actual_hash" = 'ed7d8fc8ab7d18d437434f136528651b342232880fa09e049d690b9e681b8c43' ]; then
    pass "현재 Universe 결과 SHA-256 일치"
  else
    fail "현재 Universe 결과가 저장 기준과 다릅니다: ${actual_hash:-조회 실패}"
  fi

  check_completed_file \
    "$project_dir/.claude/skills/regression-test/SKILL.md" \
    "regression-test Skill" 'canonical_sql' 'expected_result' 'hash_algorithm' 'PASS'

  wrapper="$project_dir/scripts/run-churn-check.sh"
  if [ -x "$wrapper" ] && bash -n "$wrapper"; then
    pass "cron 래퍼 실행 권한·Bash 문법 확인"
  else
    fail "scripts/run-churn-check.sh가 없거나 실행 권한·Bash 문법에 문제가 있습니다."
  fi

  cron_path="${NODE_BIN_DIR:-/opt/homebrew/bin}:/usr/local/bin:/usr/bin:/bin"
  if { [ -n "${CLAUDE_BIN:-}" ] && [ -x "$CLAUDE_BIN" ]; } \
    || PATH="$cron_path" command -v claude >/dev/null 2>&1; then
    pass "cron 환경에서 claude 실행 파일 확인"
  else
    fail ".env의 CLAUDE_BIN이 실행 파일이 아니며 cron PATH에서도 claude를 찾지 못합니다."
  fi
  if PATH="$cron_path" command -v npx >/dev/null 2>&1; then
    pass "cron 환경에서 npx 확인"
  else
    fail ".env의 NODE_BIN_DIR을 실제 npx가 있는 폴더로 바꾸세요."
  fi
fi

if [ "$failed" -ne 0 ]; then
  echo "$phase 점검 실패 항목을 고친 뒤 다시 실행하세요." >&2
  exit 1
fi

if [ "$phase" = preflight ]; then
  echo "Day $day 사전 도구 점검을 통과했습니다. 아직 DB·계정·MCP 준비 완료를 뜻하지 않습니다."
else
  echo "Day $day 실습 준비 검증을 통과했습니다."
fi
