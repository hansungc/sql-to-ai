#!/usr/bin/env bash
# .claude/hooks/sql-guard.sh
# (교재 470~472쪽) 위험한 쿼리를 실행 직전에 검사해 차단·경고하는 PreToolUse 훅

# 전제: jq가 설치되어 있어야 합니다(macOS: brew install jq / Windows: winget install jqlang.jq).
# jq가 없으면 검사값이 비어 위험한 쿼리가 그대로 통과하므로, 먼저 확인하고 차단합니다.
if ! command -v jq >/dev/null 2>&1; then
  echo "jq가 없어 SQL 안전 검사를 수행할 수 없습니다. jq를 설치한 뒤 다시 실행하세요." >&2
  exit 2
fi

payload=$(cat)
tool_name=$(printf '%s' "$payload" | jq -r '.tool_name // ""')

case "$tool_name" in
  mcp__harmony_db__execute_sql)
    sql=$(printf '%s' "$payload" | jq -r '.tool_input.sql // ""')
    ;;
  Bash)
    command=$(printf '%s' "$payload" | jq -r '.tool_input.command // ""')
    printf '%s\n' "$command" | grep -qE '(^|[[:space:]])mysql([[:space:]]|$)' || exit 0
    sql="$command"
    ;;
  *)
    exit 0
    ;;
esac

[ -n "$sql" ] || {
  echo "검사할 SQL을 찾지 못해 실행을 막았습니다." >&2
  exit 2
}

# WHERE 없는 DELETE는 차단
if printf '%s\n' "$sql" | grep -qiE '(^|[^[:alnum:]_])DELETE([^[:alnum:]_]|$)' \
  && ! printf '%s\n' "$sql" | grep -qiE '(^|[^[:alnum:]_])WHERE([^[:alnum:]_]|$)'; then
  echo "WHERE 절 없는 DELETE는 위험해 막았습니다." >&2
  exit 2                                              # 2로 끝내면 클로드 코드가 실행을 차단한다.
fi

# DROP 명령 추가 차단 - 테이블, DB 삭제 방지
if printf '%s\n' "$sql" | grep -qiE '(^|[^[:alnum:]_])DROP[[:space:]]+(TABLE|DATABASE)([^[:alnum:]_]|$)'; then
  echo "DROP 명령은 차단됩니다. 관리자만 실행하세요." >&2
  exit 2
fi

# 분석 계정은 조회만 합니다 - 나머지 DML/DDL은 실행 직전에 차단
if printf '%s\n' "$sql" | grep -qiE '(^|[^[:alnum:]_])(INSERT|UPDATE|DELETE|REPLACE|TRUNCATE|CREATE|ALTER|DROP|RENAME|GRANT|REVOKE|CALL)([^[:alnum:]_]|$)' \
  || printf '%s\n' "$sql" | grep -qiE 'INTO[[:space:]]+(OUTFILE|DUMPFILE)'; then
  echo "분석 계정에서는 조회 SQL만 허용합니다." >&2
  exit 2
fi

# 선행 와일드카드 LIKE - 차단 말고 'EXPLAIN 확인' 알림만
if printf '%s\n' "$sql" | grep -qiE "LIKE[[:space:]]+'%"; then
  echo "⚠ [참고] 앞에 %가 붙은 LIKE가 보입니다. 인덱스를 못 탈 수 있으니 EXPLAIN으로 실행 계획을 확인하세요." >&2
  echo "(풀스캔 여부는 SQL 텍스트가 아니라 EXPLAIN의 type·rows로 판단합니다)." >&2
fi
# 이 검사는 '의심 알림'일 뿐, 실제 풀스캔 판정은 EXPLAIN으로. exit 2가 없으니 통과

# ※ 이 훅이 검사하는 범위(교재 예제 기준)
#    차단: WHERE 없는 DELETE, DROP TABLE/DATABASE, 조회 이외의 주요 변경문
#    경고: 선행 와일드카드 LIKE
#    한계: 정규식 검사라서 주석·문자열 속 키워드에 오탐할 수 있습니다.
#    Bash와 mcp__harmony_db__execute_sql을 모두 검사하지만 SQL 파서는 아닙니다.
#    실제 안전장치는 Day 22의 읽기 전용 계정 권한입니다.

exit 0                                                # 0이면 통과
