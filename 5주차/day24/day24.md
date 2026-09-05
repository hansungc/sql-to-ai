# Day 24 “위험한 쿼리를 실행 전에 막을 수 있을까요?”–Hooks와 서브에이전트

> 교재 469~480쪽과 함께 사용합니다. 지면의 훅 네 가지(차단·경고·마스킹·기록)를 하나도 빠뜨리지 않고 담되, 코드는 **지면 그대로가 아니라 보완본**입니다. 무엇을 왜 바꿨는지는 각 예제 아래에 적어 두었습니다. 실제 등록은 코드 자체를 먼저 시험한 뒤 진행하도록 순서도 바꿨습니다.

제공된 훅은 Bash용입니다. macOS·Linux 또는 Day 22부터 WSL을 사용한 환경에서는 프로젝트 폴더로 이동해 확인합니다.

> ZIP으로 내려받아 git이 없다면 `git rev-parse` 줄 대신 압축을 푼 저장소 루트의
> `5주차/harmony-analysis`로 직접 이동하세요. `git check-ignore` 확인도 건너뛰면 됩니다.

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT/5주차/harmony-analysis"
set -a
. ./.env
set +a
../환경셋업/check-environment.sh 23 ready
chmod +x .claude/hooks/*.sh ../환경셋업/check-environment.sh
../환경셋업/check-environment.sh 24 preflight
```

Day 22를 Windows PowerShell에서 진행했다면 이 Day를 시작하기 전에 WSL 터미널로 전환하고 WSL 안에 Claude Code, Node.js, Docker CLI, `jq`를 준비합니다. `cmd /c npx` 설정도 WSL용 설정과 환경 파일로 바꾼 뒤, 앞 Day가 제대로 끝났는지 검사합니다.

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT/5주차/harmony-analysis"
if [ -f .mcp.json ]; then
  cp -n .mcp.json .mcp.windows.local.json
fi
cp .mcp.json.example .mcp.json
cp -n .env.example .env
chmod 600 .env
git check-ignore .mcp.json .mcp.windows.local.json .env
```

`.env`의 `DB_PASSWORD`와 포트를 Day 22에서 사용한 값으로 바꾸고 같은 WSL 터미널에 적용합니다.

```bash
set -a
. ./.env
set +a
../환경셋업/check-environment.sh 23 ready
chmod +x .claude/hooks/*.sh ../환경셋업/check-environment.sh
../환경셋업/check-environment.sh 24 preflight
claude mcp list
```

`harmony_db` 연결을 확인한 뒤 이후 명령을 macOS·Linux와 같이 실행합니다. Docker Desktop을 쓴다면 해당 WSL 배포판의 Docker 통합도 켭니다.

## Hooks–위험한 쿼리를 실행 전에 차단한다

### 예제 1 · [470~472쪽] WHERE 없는 DELETE와 DROP 차단

파일: `.claude/hooks/sql-guard.sh`

```bash
#!/usr/bin/env bash

if ! command -v jq >/dev/null 2>&1; then
  echo "jq가 없어 SQL 안전 검사를 수행할 수 없습니다." >&2
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
  *) exit 0 ;;
esac

[ -n "$sql" ] || { echo "검사할 SQL을 찾지 못해 실행을 막았습니다." >&2; exit 2; }

if printf '%s\n' "$sql" | grep -qiE '(^|[^[:alnum:]_])DELETE([^[:alnum:]_]|$)' \
  && ! printf '%s\n' "$sql" | grep -qiE '(^|[^[:alnum:]_])WHERE([^[:alnum:]_]|$)'; then
  echo "WHERE 절 없는 DELETE는 위험해 막았습니다." >&2
  exit 2
fi

if printf '%s\n' "$sql" \
  | grep -qiE '(^|[^[:alnum:]_])DROP[[:space:]]+(TABLE|DATABASE)([^[:alnum:]_]|$)'; then
  echo "DROP 명령은 차단됩니다. 관리자만 실행하세요." >&2
  exit 2
fi

if printf '%s\n' "$sql" \
  | grep -qiE '(^|[^[:alnum:]_])(INSERT|UPDATE|DELETE|REPLACE|TRUNCATE|CREATE|ALTER|DROP|RENAME|GRANT|REVOKE|CALL)([^[:alnum:]_]|$)' \
  || printf '%s\n' "$sql" | grep -qiE 'INTO[[:space:]]+(OUTFILE|DUMPFILE)'; then
  echo "분석 계정에서는 조회 SQL만 허용합니다." >&2
  exit 2
fi

if printf '%s\n' "$sql" | grep -qiE "LIKE[[:space:]]+'%"; then
  echo "⚠ [참고] 앞에 %가 붙은 LIKE가 보입니다. 인덱스를 못 탈 수 있으니 EXPLAIN으로 실행 계획을 확인하세요." >&2
  echo "(풀스캔 여부는 SQL 텍스트가 아니라 EXPLAIN의 type·rows로 판단합니다)." >&2
fi

exit 0
```

`grep`의 `\b`, `\s`는 macOS 기본 도구에서 기대대로 동작하지 않을 수 있어 POSIX 문자 클래스로 보완했습니다. Bash 명령의 `mysql`과 `mcp__harmony_db__execute_sql`을 모두 검사하지만 정규식은 SQL 파서가 아니므로, 최종 차단은 Day 22의 데이터베이스 권한이 담당합니다.

## Hooks의 네 가지–실행 전 차단과 경고, 실행 후 마스킹과 기록

### 예제 2 · [472쪽] 선행 와일드카드 LIKE 경고

위 `sql-guard.sh`의 세 번째 조건입니다. 이 조건은 경고만 출력하고 `exit 0`으로 원래 명령을 통과시킵니다. 실제 풀스캔인지는 다음처럼 `EXPLAIN` 결과로 확인합니다.

```sql
EXPLAIN
SELECT fan_id, fan_name
FROM fans
WHERE fan_name LIKE '%민지';
```

### 예제 3 · [472~473쪽] 개인정보 마스킹

파일: `.claude/hooks/mask-pii.sh`

```bash
#!/usr/bin/env bash

command -v jq >/dev/null 2>&1 || {
  echo "[mask-pii] jq가 없어 마스킹을 건너뜁니다." >&2
  exit 0
}

payload=$(cat)
masked=$(printf '%s' "$payload" | jq -c '
  def redact:
    gsub("[A-Za-z0-9._%+\\-]+@[A-Za-z0-9.\\-]+\\.[A-Za-z]{2,}"; "***@***")
    | gsub("01[0-9]-[0-9]{4}-[0-9]{4}"; "***-****-****");
  .tool_response | walk(if type == "string" then redact else . end)
')

LOG_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}/.claude/logs"
mkdir -p "$LOG_DIR"
printf '%s\n' "$masked" >> "$LOG_DIR/masked-results.log"

jq -cn --argjson updated "$masked" '{
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    updatedToolOutput: $updated
  }
}'
exit 0
```

교재의 `|` 구분 이메일 패턴은 `mysql -e`의 탭 구분 결과에서 한 행을 넓게 가릴 수 있어 이메일 형식 자체를 찾게 보완했습니다. 응답 객체 모양을 유지한 `updatedToolOutput`을 반환하므로 Claude가 보는 결과도 가려집니다. 단, 훅 실행 전 원본을 DB가 이미 반환한 뒤이므로 Day 22에서 `fans.email` 조회 권한도 차단합니다.

### 예제 4 · [473~474쪽] 실행 쿼리 기록

먼저 추적되지 않는 로컬 계정 파일을 만듭니다.

```bash
cp -n ../환경셋업/recorder_account.sql.example \
   ../환경셋업/recorder_account.sql.local
chmod 600 ../환경셋업/recorder_account.sql.local
git check-ignore ../환경셋업/recorder_account.sql.local
```

`recorder_account.sql.local`에서 `비밀번호`만 실제 값으로 바꾸고 관리자 계정으로 한 번 실행합니다. Day 22와 마찬가지로 이 입문 실습의 비밀번호에는 작은따옴표(`'`)와 역슬래시(`\`)를 쓰지 않습니다. 기존 `query_history`가 있다면 삭제하지 말고 `query_history_upgrade_v2.sql`도 먼저 실행합니다.

```sql
CREATE USER IF NOT EXISTS 'recorder'@'%' IDENTIFIED BY '비밀번호';
ALTER USER 'recorder'@'%' IDENTIFIED BY '비밀번호';
REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'recorder'@'%';
GRANT INSERT ON harmony_db.query_history TO 'recorder'@'%';
FLUSH PRIVILEGES;
```

Docker에서는 v2 보완과 계정 SQL을 순서대로 적용합니다.

```bash
cd ../환경셋업
docker compose exec -T harmony-mysql \
  sh -c 'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" exec mysql -uroot harmony_db' \
  < query_history_upgrade_v2.sql
docker compose exec -T harmony-mysql \
  sh -c 'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" exec mysql -uroot harmony_db' \
  < recorder_account.sql.local
cd ../harmony-analysis
```

로컬 MySQL에서는 다음 두 명령을 실행합니다.

```bash
mysql -u root -p harmony_db < ../환경셋업/query_history_upgrade_v2.sql
mysql -u root -p harmony_db < ../환경셋업/recorder_account.sql.local
```

`harmony-analysis/.env`의 `RECORDER_PASSWORD`를 같은 값으로 바꾼 뒤 현재 셸에 적용합니다. 비밀번호를 `export ...` 명령으로 직접 입력해 셸 기록에 남기지 않습니다.

```bash
chmod 600 .env
set -a
. ./.env
set +a
case "$RECORDER_PASSWORD" in
  ''|*'에_적은_비밀번호') echo '.env의 RECORDER_PASSWORD를 실제 값으로 바꾸세요' ;;
  *) echo 'RECORDER_PASSWORD 설정 완료' ;;
esac
```

파일: `.claude/hooks/record-query.sh`

```bash
#!/usr/bin/env bash

command -v jq >/dev/null 2>&1 || {
  echo "[record-query] jq가 없어 기록을 건너뜁니다." >&2
  exit 0
}
[ -n "${RECORDER_PASSWORD:-}" ] || {
  echo "[record-query] RECORDER_PASSWORD가 없어 기록을 건너뜁니다." >&2
  exit 0
}

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
  *) exit 0 ;;
esac

[ -n "$sql" ] || { echo '[record-query] SQL을 확인할 수 없어 건너뜁니다.' >&2; exit 0; }

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
```

이 보완본은 Bash의 `mysql ... -e "SQL"`과 MCP의 `tool_input.sql`을 모두 기록합니다. 세션, 실행자, 에이전트, 도구, 성공·실패도 함께 남기고 비밀번호는 명령 인수가 아닌 환경 변수로 전달합니다.

### 예제 5 · [474쪽] 훅을 등록하기 전 직접 검사

아직 `.claude/settings.json`에 훅을 등록하지 않은 상태에서 실행합니다.

```bash
bash -n .claude/hooks/*.sh

jq -n --arg command 'mysql -e "DELETE FROM fans"' \
  '{tool_name:"Bash",tool_input:{command:$command}}' \
  | .claude/hooks/sql-guard.sh

echo $?
```

첫 검사는 문법 오류 없이 끝나고, 두 번째 검사는 차단 문구와 종료 코드 `2`를 반환해야 합니다.

MCP 입력도 같은 방식으로 막히는지 확인합니다.

```bash
jq -n --arg sql 'UPDATE fans SET fan_name="x" WHERE fan_id=1' \
  '{tool_name:"mcp__harmony_db__execute_sql",tool_input:{sql:$sql}}' \
  | .claude/hooks/sql-guard.sh

echo $?
```

확인: `분석 계정에서는 조회 SQL만 허용합니다.`와 종료 코드 `2`.

마스킹 검사

```bash
jq -n --arg stdout $'1\t김민지\tminji@example.com\t010-1234-5678' \
  '{tool_name:"Bash",tool_response:{stdout:$stdout,stderr:"",interrupted:false,isImage:false}}' \
  | .claude/hooks/mask-pii.sh \
  | jq -r '.hookSpecificOutput.updatedToolOutput.stdout'

tail -n 1 .claude/logs/masked-results.log
```

확인: 화면과 로그에서 이메일은 `***@***`, 전화번호는 `***-****-****`로 나옵니다.

DB에 쓰지 않고 MCP 기록 SQL을 미리 확인합니다.

```bash
jq -n '{
  session_id:"session-test",
  tool_use_id:"tool-test",
  hook_event_name:"PostToolUse",
  tool_name:"mcp__harmony_db__execute_sql",
  tool_input:{sql:"SELECT COUNT(*) FROM fans"}
}' | RECORD_QUERY_DRY_RUN=1 RECORDER_PASSWORD=test \
  .claude/hooks/record-query.sh
```

확인: 출력된 `INSERT INTO query_history`에 세션, 도구, SQL, `success`가 들어 있어야 합니다.

### 예제 6 · [471~474쪽] `.claude/settings.json` 등록

직접 검사가 끝난 뒤 기존 `permissions` 아래에 `hooks`를 추가합니다. 전체 파일은 다음과 같습니다.

```json
{
  "permissions": {
    "allow": ["Read"],
    "ask": ["Edit", "Write"],
    "deny": [
      "Bash(rm *)",
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(**/.env)",
      "Read(**/.env.*)",
      "Read(**/*.sql.local)"
    ]
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash|mcp__harmony_db__execute_sql",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/sql-guard.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Bash|mcp__harmony_db__execute_sql",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/mask-pii.sh"
          },
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/record-query.sh"
          }
        ]
      }
    ],
    "PostToolUseFailure": [
      {
        "matcher": "Bash|mcp__harmony_db__execute_sql",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/record-query.sh"
          }
        ]
      }
    ]
  }
}
```

프로젝트 폴더에서 `claude`를 실행한 뒤 입력할 프롬프트

```bash
claude
```

```text
.claude/hooks의 sql-guard.sh, mask-pii.sh, record-query.sh를 먼저 읽고
.claude/settings.json에 Bash와 mcp__harmony_db__execute_sql용
PreToolUse, PostToolUse, PostToolUseFailure 훅으로 등록해 줘.
기존 permissions는 유지하고 JSON 전체를 수정 전에 보여 줘.
```

저장 후 `/exit`로 터미널에 돌아와 검증하고 Claude Code를 재시작합니다.

```bash
jq empty .claude/settings.json
claude
```

등록 후 Bash와 `mcp__harmony_db__execute_sql`이 모두 matcher에 들어 있는지 확인합니다. 훅은 보조 장치이므로 Day 22의 읽기 전용 계정도 반드시 유지합니다.

## 서브에이전트–여러 전문가로 교차 검증하기

### 예제 7 · [475~478쪽] 세 역할 파일 만들기

Claude Code 세션은 그대로 두고 새 터미널 탭을 엽니다. 자동 선택되지 않는 `.md.example` 세 파일을 실제 에이전트 파일로 복사한 뒤 Claude Code 탭으로 돌아옵니다.

```bash
for name in sql-writer validator business-translator; do
  cp -n ".claude/agents/$name.md.example" ".claude/agents/$name.md"
done
git check-ignore .claude/agents/*.md
```

Windows도 Day 24는 WSL에서 위 명령을 실행합니다. 복사한 뒤 아래 프롬프트로 역할 본문을 완성합니다.

```text
.claude/agents 아래의 시작 파일 세 개를 완성해 줘.
1. sql-writer: harmony_db 스키마를 확인하고 SELECT SQL, 가정, 결과를 제시
2. validator: 조인, 중복, NULL, 날짜 경계와 정의를 반박하고 독립 SQL로 재계산
3. business-translator: 검증된 결과만 팩트→의미→제안으로 설명
sql-writer와 validator는 harmony_db의 search_objects와 execute_sql만 사용하고,
business-translator는 Read만 사용하게 해. email 조회와 데이터 변경은 모두 금지해.
세 파일의 diff를 먼저 보여 주고 승인 후 수정해 줘.
```

`sql-writer.md` 머리말

```yaml
---
name: sql-writer
description: harmony_db 스키마 기반으로 정확한 SQL을 작성한다. 비즈니스 로직을 쿼리로 옮길 때.
tools: Read, mcp__harmony_db__search_objects, mcp__harmony_db__execute_sql
model: sonnet
---
```

`validator.md` 머리말

```yaml
---
name: validator
description: 작성된 SQL의 정확성을 검증한다. 조인·NULL·예외 상황을 의심하고, 반박해 문제를 찾는다.
tools: Read, mcp__harmony_db__search_objects, mcp__harmony_db__execute_sql
---
```

`business-translator.md` 머리말

```yaml
---
name: business-translator
description: 분석 결과를 비즈니스 의미로 해석한다. 숫자가 무엇을 뜻하고 어떤 결정을 유도하는지.
tools: Read
---
```

현재 DBHub가 내보내는 도구 이름은 `search_objects`, `execute_sql`입니다. `/mcp`에서 다르게 보이면 머리말의 `mcp__harmony_db__...` 이름을 실제 표시 이름과 맞춥니다. `sonnet`을 사용할 수 없는 계정이면 `model` 줄을 지워 현재 모델을 상속합니다.

세 파일을 완성한 뒤 Claude Code에서 `/exit`하고 파일 문법을 검사합니다. 다시 `claude`를 열어 `/agents`에서 세 이름이 보이는지 확인합니다. 이미 파일을 만들었으므로 `/agents`에서 다시 생성할 필요는 없습니다.

```bash
claude plugin validate --strict .claude/agents
claude
```

### 예제 8 · [475~477쪽] 작성가와 검증가의 SQL

작성가 요청

```text
sql-writer에게 최애 아티스트가 Celestial인 팬들의 2026년 7월 주문 총액을 구하게 해.
정의, 실행 SQL, 결과를 함께 보여 줘.
```

작성가가 내놓는 SQL은 다음과 같습니다. 팬의 최애 아티스트를 기준으로 셉니다.

```sql
SELECT SUM(o.total_amount) AS celestial_fan_revenue
FROM orders o
JOIN fans f ON o.fan_id = f.fan_id
JOIN artists a ON f.favorite_artist_id = a.artist_id
WHERE a.artist_name = 'Celestial'
  AND o.order_date >= '2026-07-01'
  AND o.order_date < '2026-08-01';
```

확인: `552000`.

검증가 요청

```text
validator에게 방금 SQL이 질문의 대상을 정확히 세는지 반박 검증하게 해.
팬의 최애 기준과 실제 주문 상품의 아티스트 기준을 구분하고 독립 SQL로 재계산해 줘.
```

검증가가 다시 계산한 SQL은 다음과 같습니다. 실제로 팔린 상품의 아티스트를 기준으로 셉니다.

```sql
SELECT SUM(o.total_amount) AS celestial_goods_revenue
FROM orders o
JOIN products p ON o.product_id = p.product_id
JOIN artists a ON p.artist_id = a.artist_id
WHERE a.artist_name = 'Celestial'
  AND o.order_date >= '2026-07-01'
  AND o.order_date < '2026-08-01';
```

확인: `2732000`. 두 숫자의 의미 해석은 교재 477쪽에서 확인합니다.

> **교재와 SQL 표기가 다릅니다.** 교재 476~477쪽은 `artist_id = 10`과 `YEAR()`·`MONTH()`를
> 쓰고, 위 두 SQL은 `artists`를 조인해 이름으로 찾고 날짜는 범위로 비교합니다. 결과는
> `552000`·`2732000`으로 같습니다. 아티스트 번호를 외우지 않아도 되고, 날짜 범위 비교가
> 인덱스를 쓸 수 있어서입니다. 교재 표기 그대로 실행해도 같은 값이 나옵니다.

### 예제 9 · [477~480쪽] 세 전문가 교차 검증

```text
sql-writer에게 “최애 아티스트가 Celestial인 팬들의 2026년 7월 주문 총액”을 계산하게 해.
그 SQL과 결과를 validator가 독립적으로 반박 검증하게 하고,
정의나 조인 기준이 다르면 두 값을 모두 제시해.
마지막으로 business-translator가 검증된 결과만 팩트→의미→제안 순서로 설명하게 해.
각 단계의 담당자, SQL, 가정, 결과를 남겨 줘.
```

확인: 세 역할이 순서대로 호출되고, 결과에는 `552000`과 `2732000`이 서로 다른 정의로 표시되어야 합니다. 호출이 안 되면 파일 문법 검사 결과와 이름·description을 먼저 확인합니다.

이름을 직접 지정해 부를 때(교재 479쪽)

```text
검증가에게 이 쿼리를 검토시켜 줘.
```

확인: 지정한 에이전트가 실행됩니다.

## 막힐 때

| 증상 | 바로 확인할 것 |
|---|---|
| 훅이 실행되지 않음 | 실행 권한, `jq`, 설정 JSON, Claude Code 재시작, matcher에 Bash와 MCP 도구가 모두 있는지 확인합니다. |
| 위험 SQL이 MCP에서 실행됨 | `mcp__harmony_db__execute_sql` matcher와 `claude_readonly`의 `SHOW GRANTS`를 확인합니다. |
| 기록이 남지 않음 | `RECORDER_PASSWORD`, recorder 권한, `query_history` v2 칼럼, Docker 상태를 확인합니다. |
| 모든 Bash 명령이 기록됨 | 최신 `record-query.sh`인지 확인합니다. 이 버전은 mysql의 `-e` SQL만 기록합니다. |
| CRLF 관련 `/usr/bin/env: bash\r` 오류 | Git에서 다시 체크아웃하거나 `sed -i.bak $'s/\\r$//' .claude/hooks/*.sh`로 LF로 바꿉니다. 저장소의 `.gitattributes`는 이후 LF를 유지합니다. |
| 서브에이전트가 DB 도구를 못 씀 | `/mcp`의 실제 서버·도구 이름과 에이전트 머리말의 이름을 맞춥니다. |

## 완료 확인

설정과 계정까지 끝난 뒤 준비 상태를 다시 검사합니다.

```bash
../환경셋업/check-environment.sh 24 ready
```

- [ ] 훅 세 파일이 `bash -n`을 통과했다.
- [ ] 직접 검사 후 훅을 등록했다.
- [ ] 차단, 경고, 마스킹, SQL 기록을 각각 확인했다.
- [ ] Bash와 MCP에서 훅이 모두 작동하고 DB 권한도 유지되는지 확인했다.
- [ ] 서브에이전트 세 파일을 직접 완성했다.
- [ ] 두 SQL의 `552000`과 `2732000`을 교차 검증했다.

다음: [Day 25–평가셋과 자동 실행](../day25/day25.md)
