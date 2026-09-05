# Day 25 “이 결과, 진짜 믿어도 될까요?”–평가셋과 자동 실행

> 교재 481~489쪽과 함께 사용합니다. 정답 대조→점수→회귀 검사→자동 실행→기록 순서입니다. 개념은 교재에서 읽고, 여기서는 그대로 실행할 코드·SQL·프롬프트와 환경 보완만 제공합니다.

## 시작 전 확인–Day 24까지의 환경 이어받기

> ZIP으로 내려받아 git이 없다면 `git rev-parse` 줄 대신 압축을 푼 저장소 루트의
> `5주차/harmony-analysis`로 직접 이동하세요. `git check-ignore` 확인도 건너뛰면 됩니다.

```bash
# macOS·Linux·WSL
REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT/5주차/harmony-analysis"
set -a
. ./.env
set +a
../환경셋업/check-environment.sh 24 ready
```

Day 24 훅은 Bash로 작성되어 있으므로 Windows는 Day 24에서 사용한 WSL 터미널에서 같은 명령을 실행합니다. 위 검사가 실패하면 Day 25를 진행하지 말고 표시된 Day 24 미완료 항목부터 고칩니다. 아래 관리자 SQL과 Claude Code의 읽기 전용 분석은 실행 주체가 다릅니다.

- `CREATE`, `INSERT`, `GRANT`, `UPDATE`: 관리자 MySQL 세션
- 분석용 `SELECT`와 회귀 확인: `claude_readonly` MCP

## 평가셋–AI 쿼리 결과를 점수로 검증하기

### 예제 1 · [481~482쪽] 관리자 세션 열기

`claude_readonly`에는 의도적으로 테이블 생성 권한이 없습니다. 임시 테이블은 접속을 끊으면 사라지므로 예제 1~4를 같은 관리자 세션에서 순서대로 실행합니다. 아래 세션을 **터미널 A**라고 부르며, 안내가 나오기 전까지 `exit`하지 않습니다.

Docker 환경

```bash
cd ../환경셋업
docker compose exec harmony-mysql \
  sh -c 'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" exec mysql -uroot --default-character-set=utf8mb4 harmony_db'
```

로컬 MySQL 환경

```bash
mysql -u root -p --default-character-set=utf8mb4 harmony_db
```

### 예제 2 · [482~483쪽] 정답과 생성 결과 양방향 대조

관리자 MySQL 세션에서 정답을 만듭니다.

```sql
CREATE TEMPORARY TABLE gold_result AS
SELECT s.stream_date, SUM(s.play_count) AS daily_streams
FROM streaming s
JOIN tracks t ON s.track_id = t.track_id
WHERE t.track_name = 'Universe'
  AND s.stream_date >= '2026-07-01'
  AND s.stream_date < '2026-08-01'
GROUP BY s.stream_date;
```

터미널 A의 관리자 MySQL 세션은 그대로 둡니다. 새 **터미널 B**를 열어 Claude Code를 시작합니다.

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT/5주차/harmony-analysis"
set -a
. ./.env
set +a
claude
```

터미널 B의 Claude Code 프롬프트

```text
Celestial 신곡 Universe의 2026년 7월 일별 스트리밍을 다시 계산해 줘.
사용한 SELECT SQL과 날짜별 결과를 보여 주고, 데이터는 바꾸지 마.
날짜 범위는 2026-07-01 이상, 2026-08-01 미만으로 작성해.
```

Claude가 제시한 SELECT를 먼저 읽어 본 뒤, 터미널 A의 같은 관리자 세션으로 돌아와 생성 결과를 만듭니다. 아래 SQL은 정답과 일치하는 기준 예시입니다.

```sql
CREATE TEMPORARY TABLE generated_result AS
SELECT s.stream_date, SUM(s.play_count) AS daily_streams
FROM streaming s
JOIN tracks t ON s.track_id = t.track_id
WHERE t.track_name = 'Universe'
  AND s.stream_date >= '2026-07-01'
  AND s.stream_date < '2026-08-01'
GROUP BY s.stream_date;
```

정답에만 있는 행

```sql
SELECT g.stream_date, g.daily_streams
FROM gold_result g
LEFT JOIN generated_result gr
  ON g.stream_date = gr.stream_date
  AND g.daily_streams = gr.daily_streams
WHERE gr.stream_date IS NULL;
```

생성 결과에만 있는 행

```sql
SELECT gr.stream_date, gr.daily_streams
FROM generated_result gr
LEFT JOIN gold_result g
  ON g.stream_date = gr.stream_date
  AND g.daily_streams = gr.daily_streams
WHERE g.stream_date IS NULL;
```

두 쿼리 모두 0행이어야 합니다. 정답 네 행은 `07-22 212`, `07-23 233`, `07-24 256`, `07-25 232`입니다.

임시 테이블 권한 없이 MCP에서 같은 원리를 확인할 때는 CTE를 사용합니다.

```sql
WITH gold_result AS (
  SELECT DATE('2026-07-22') AS stream_date, 212 AS daily_streams
  UNION ALL SELECT DATE('2026-07-23'), 233
  UNION ALL SELECT DATE('2026-07-24'), 256
  UNION ALL SELECT DATE('2026-07-25'), 232
),
generated_result AS (
  SELECT s.stream_date, SUM(s.play_count) AS daily_streams
  FROM streaming s
  JOIN tracks t ON s.track_id = t.track_id
  WHERE t.track_name = 'Universe'
    AND s.stream_date >= '2026-07-01'
    AND s.stream_date < '2026-08-01'
  GROUP BY s.stream_date
),
differences AS (
  SELECT 'missing' AS diff_type, g.stream_date, g.daily_streams
  FROM gold_result g
  LEFT JOIN generated_result gr
    ON g.stream_date = gr.stream_date AND g.daily_streams = gr.daily_streams
  WHERE gr.stream_date IS NULL
  UNION ALL
  SELECT 'extra', gr.stream_date, gr.daily_streams
  FROM generated_result gr
  LEFT JOIN gold_result g
    ON g.stream_date = gr.stream_date AND g.daily_streams = gr.daily_streams
  WHERE g.stream_date IS NULL
)
SELECT * FROM differences ORDER BY diff_type, stream_date;
```

### 예제 3 · [483~484쪽] 정확도 점수

앞의 관리자 세션에서 실행합니다.

```sql
SELECT
  COUNT(*) AS gold_rows,
  SUM(gr.stream_date IS NOT NULL) AS matched_rows,
  ROUND(SUM(gr.stream_date IS NOT NULL) / COUNT(*) * 100, 2) AS accuracy
FROM gold_result g
LEFT JOIN generated_result gr
  ON g.stream_date = gr.stream_date
  AND g.daily_streams = gr.daily_streams;
```

`gold_rows=4`, `matched_rows=4`, `accuracy=100.00`이어야 합니다. 점수만 보지 말고 예제 2의 양방향 차이도 함께 확인합니다.

## 회귀 테스트–정답과 직렬화 규칙으로 변화 감지

### 예제 4 · [484~485쪽] 재현 가능한 평가 케이스 저장

관리자 세션에서 테이블을 만듭니다.

```sql
CREATE TABLE IF NOT EXISTS eval_cases (
  case_name VARCHAR(100) PRIMARY KEY,
  request TEXT NOT NULL,
  canonical_sql TEXT NOT NULL,
  expected_result JSON NOT NULL,
  hash_algorithm VARCHAR(10) NOT NULL,
  expected_hash VARCHAR(64) NOT NULL,
  expected_row_count INT UNSIGNED NOT NULL,
  dataset_version VARCHAR(50) NOT NULL,
  serialization_version VARCHAR(50) NOT NULL
);
```

> **교재보다 칼럼이 많습니다.** 교재 484쪽은 `case_name`·`request`·`expected_hash`
> 3칼럼입니다. 해시가 달라졌을 때 원인을 짚을 수 있도록 실행 SQL·기대 행·해시 방식·
> 행 수·데이터 버전·직렬화 규칙을 더했습니다. 3칼럼으로도 회귀 테스트는 동작하며,
> 그 경우 PASS/FAIL만 나오고 어긋난 행은 직접 대조해야 합니다.
>
> 더한 칼럼이 모두 `NOT NULL`이라, **교재 484쪽의 3칼럼 `INSERT`를 이 테이블에 그대로
> 실행하면** `Field 'canonical_sql' doesn't have a default value`(ERROR 1364)가 납니다.
> 아래 예제 4의 `INSERT`를 쓰세요. 교재 지면 그대로 실습하고 싶다면 `eval_cases`를 만들 때
> 위 `CREATE TABLE`도 교재의 3칼럼으로 바꾸면 됩니다.

이미 있던 테이블이라면 칼럼을 확인합니다.

```sql
SHOW COLUMNS FROM eval_cases;
```

`request`, `expected_hash`를 포함한 3칼럼 형태라면 다음 INSERT로 넘어가지 말고, 데이터를 삭제하지 않는 보완 스크립트를 새 **터미널 C**에서 먼저 실행합니다. 임시 테이블이 있는 터미널 A는 닫지 않습니다.

Docker

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT/5주차/환경셋업"
docker compose exec -T harmony-mysql \
  sh -c 'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" exec mysql -uroot harmony_db' \
  < eval_cases_upgrade_v2.sql
```

로컬 MySQL

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT/5주차/환경셋업"
mysql -u root -p harmony_db < eval_cases_upgrade_v2.sql
```

스크립트가 끝나면 터미널 A에서 `SHOW COLUMNS FROM eval_cases;`를 다시 실행합니다. 기존 `universe-daily-streams` 행은 스크립트가 채워 주므로 아래 INSERT는 건너뛰면 됩니다. 그 행이 없을 때만 터미널 A의 관리자 MySQL 세션에서 저장하세요.

```sql
SET SESSION group_concat_max_len = 1048576;

INSERT INTO eval_cases (
  case_name, request, canonical_sql, expected_result, hash_algorithm,
  expected_hash, expected_row_count, dataset_version, serialization_version
)
SELECT
  'universe-daily-streams',
  'Celestial 신곡 Universe의 2026년 7월 일별 스트리밍',
  'SELECT s.stream_date, SUM(s.play_count) AS daily_streams FROM streaming s JOIN tracks t ON s.track_id = t.track_id WHERE t.track_name = ''Universe'' AND s.stream_date >= ''2026-07-01'' AND s.stream_date < ''2026-08-01'' GROUP BY s.stream_date ORDER BY s.stream_date',
  JSON_ARRAY(
    JSON_OBJECT('stream_date', '2026-07-22', 'daily_streams', 212),
    JSON_OBJECT('stream_date', '2026-07-23', 'daily_streams', 233),
    JSON_OBJECT('stream_date', '2026-07-24', 'daily_streams', 256),
    JSON_OBJECT('stream_date', '2026-07-25', 'daily_streams', 232)
  ),
  'MD5',
  MD5(GROUP_CONCAT(
    CONCAT(DATE_FORMAT(stream_date, '%Y-%m-%d'), ':', CAST(daily_streams AS CHAR))
    ORDER BY stream_date SEPARATOR ','
  )),
  COUNT(*),
  'harmony_v1',
  'date-colon-integer-comma-v1'
FROM gold_result;
```

신규 INSERT와 기존 테이블 업그레이드 중 어느 경로를 택했든, 다음 권한은 터미널 A의 관리자 세션에서 한 번 실행합니다. 이 공통 단계를 건너뛰면 회귀 Skill이 `eval_cases`를 읽지 못합니다.

```sql
GRANT SELECT ON harmony_db.eval_cases TO 'claude_readonly'@'%';
```

직렬화 문자열은 다음 형태로 고정됩니다.

```text
2026-07-22:212,2026-07-23:233,2026-07-24:256,2026-07-25:232
```

저장됐는지 터미널 A에서 확인합니다.

```sql
SELECT
  case_name, hash_algorithm, expected_hash, expected_row_count,
  dataset_version, serialization_version
FROM eval_cases;
```

기대 해시는 `c85f4f00095b42365b007fc38f8b8e36`, 행 수는 `4`입니다. 같은 `case_name`이 있다는 오류가 나면 자동으로 덮어쓰지 말고 먼저 확인합니다.

```sql
SELECT case_name, canonical_sql, expected_result, expected_hash
FROM eval_cases
WHERE case_name = 'universe-daily-streams';
```

MD5가 보안 정책으로 비활성화된 환경에서는 MD5 case 대신 다음 SHA-256 case를 관리자 세션에서 저장합니다. 직렬화 규칙은 바꾸지 않습니다.

```sql
INSERT INTO eval_cases (
  case_name, request, canonical_sql, expected_result, hash_algorithm,
  expected_hash, expected_row_count, dataset_version, serialization_version
) VALUES (
  'universe-daily-streams-sha256',
  'Celestial 신곡 Universe의 2026년 7월 일별 스트리밍',
  'SELECT s.stream_date, SUM(s.play_count) AS daily_streams FROM streaming s JOIN tracks t ON s.track_id = t.track_id WHERE t.track_name = ''Universe'' AND s.stream_date >= ''2026-07-01'' AND s.stream_date < ''2026-08-01'' GROUP BY s.stream_date ORDER BY s.stream_date',
  JSON_ARRAY(
    JSON_OBJECT('stream_date', '2026-07-22', 'daily_streams', 212),
    JSON_OBJECT('stream_date', '2026-07-23', 'daily_streams', 233),
    JSON_OBJECT('stream_date', '2026-07-24', 'daily_streams', 256),
    JSON_OBJECT('stream_date', '2026-07-25', 'daily_streams', 232)
  ),
  'SHA256',
  'ed7d8fc8ab7d18d437434f136528651b342232880fa09e049d690b9e681b8c43',
  4,
  'harmony_v1',
  'date-colon-integer-comma-v1'
);
```

현재 결과도 같은 알고리즘으로 계산합니다.

```sql
SET SESSION group_concat_max_len = 1048576;

SELECT SHA2(GROUP_CONCAT(
  CONCAT(DATE_FORMAT(stream_date, '%Y-%m-%d'), ':', CAST(daily_streams AS CHAR))
  ORDER BY stream_date SEPARATOR ','
), 256) AS actual_hash
FROM gold_result;
```

기대값은 `ed7d8fc8ab7d18d437434f136528651b342232880fa09e049d690b9e681b8c43`입니다. 기존 MD5 case의 알고리즘과 해시만 몰래 바꾸지 않습니다.

### 예제 5 · [485~486쪽] 회귀 테스트 Skill 만들기

선택한 해시 저장까지 끝났다면 터미널 A의 관리자 MySQL 세션에서 `exit`합니다. 터미널 B도 Claude Code에서 `/exit`해 셸로 돌아옵니다. 견본은 자동 실행되지 않도록 `.example`로 제공됩니다. 셸에서 프로젝트 폴더로 이동해 실제 Skill 파일로 복사한 뒤 `claude`를 다시 열어 완성합니다.

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT/5주차/harmony-analysis"
cp -n .claude/skills/regression-test/SKILL.md.example \
  .claude/skills/regression-test/SKILL.md
git check-ignore .claude/skills/regression-test/SKILL.md
claude
```

완성했을 때의 머리말은 다음과 같습니다(교재 485쪽).

```markdown
---
name: regression-test
description: eval_cases에 저장한 정답을 모두 다시 돌려 깨진 분석을 찾는다. 회귀 점검, 정답 검증 요청 시 사용
---
```

다음 프롬프트로 본문을 완성합니다.

```text
eval_cases를 이용하는 회귀 테스트 Skill을 완성해 줘.
파일은 .claude/skills/regression-test/SKILL.md야.

각 case마다 canonical_sql을 읽은 뒤 원문을 임의로 고치지 말고 SELECT인지 확인해서 실행해.
expected_row_count와 실제 행 수를 먼저 비교해.
serialization_version이 date-colon-integer-comma-v1이면 날짜 오름차순으로
YYYY-MM-DD:정수 값을 쉼표로 이어 붙여. 모르는 버전은 추측하지 말고 설정 오류로 보고해.
hash_algorithm 값에 따라 MD5 또는 SHA2(..., 256)를 사용해 expected_hash와 비교해.
expected_result와 실제 결과를 양방향 비교해 누락·추가·변경 행을 보여 줘.
case별 PASS/FAIL, 기대 해시, 실제 해시, 행 수, 차이 행을 표로 보고해.
원본 데이터와 eval_cases는 수정하지 마. 파일 수정 전 diff를 먼저 보여 줘.
```

명시적 호출

```text
/regression-test
```

Skill 결과를 직접 대조하려면 `harmony_db` MCP에서 현재 결과의 MD5를 다시 계산합니다.

```sql
SET SESSION group_concat_max_len = 1048576;

SELECT MD5(GROUP_CONCAT(
  CONCAT(DATE_FORMAT(stream_date, '%Y-%m-%d'), ':', CAST(daily_streams AS CHAR))
  ORDER BY stream_date SEPARATOR ','
)) AS actual_hash
FROM (
  SELECT s.stream_date, SUM(s.play_count) AS daily_streams
  FROM streaming s
  JOIN tracks t ON s.track_id = t.track_id
  WHERE t.track_name = 'Universe'
    AND s.stream_date >= '2026-07-01'
    AND s.stream_date < '2026-08-01'
  GROUP BY s.stream_date
) result;
```

저장된 해시와 실제 해시가 같아야 합니다. 정답은 사람이 데이터·SQL 변경 사유를 확인한 뒤에만 갱신합니다.

### 예제 6 · [486쪽] 해시 대신 불변 조건으로도 검사

교재 486쪽이 든 세 가지 불변 조건을 한 번에 확인하는 SQL입니다.

```sql
SELECT
  (SELECT COUNT(DISTINCT fan_id) FROM subscription_history
    WHERE status = 'active')                       AS active_fans,
  (SELECT SUM(cnt) FROM (
     SELECT COUNT(DISTINCT fan_id) AS cnt
     FROM subscription_history GROUP BY status) s) AS sum_by_status,
  (SELECT COUNT(DISTINCT fan_id) FROM subscription_history) AS total_fans,
  (SELECT COUNT(*) FROM subscription_history)      AS total_rows;
```

확인: HARMONY v1에서는 `85 / 100 / 100 / 100`이 나옵니다. 값이 아니라 아래 세 관계가
성립하는지를 봅니다.

- `active_fans` ≥ 0
- `sum_by_status` = `total_fans`
- `total_fans` ≤ `total_rows`

여기에 더해, 구독 이력의 값 자체가 유효한지도 검사합니다.

```sql
SELECT
  SUM(fan_id IS NULL) AS missing_fan_rows,
  SUM(start_date IS NULL) AS missing_start_rows,
  SUM(status NOT IN ('active', 'churned', 'reactivated') OR status IS NULL)
    AS invalid_status_rows,
  SUM(end_date < start_date) AS reversed_date_rows,
  SUM(status IN ('active', 'reactivated') AND end_date IS NOT NULL)
    AS open_status_with_end_rows,
  SUM(status = 'churned' AND end_date IS NULL)
    AS churned_without_end_rows
FROM subscription_history;
```

HARMONY v1에서는 여섯 값이 모두 `0`이어야 합니다. 현재 데이터셋이 팬당 한 행이라는 전제도 별도로 검사합니다.

```sql
SELECT fan_id, COUNT(*) AS row_count
FROM subscription_history
GROUP BY fan_id
HAVING COUNT(*) > 1;
```

HARMONY v1에서는 0행이어야 합니다. 향후 이력 데이터가 팬당 여러 행으로 바뀐다면 이 검사는 실패가 아니라 “평가 규칙 갱신 필요” 신호입니다.

## 자동 실행–비밀값을 코드와 분리해 정시에 실행

> cron은 등록해 두면 정해진 시각에 알아서 실행됩니다. `crontab`에 올리기 전에 `.env`의
> 접속 대상이 실습용 `harmony_db`가 맞는지, 계정이 읽기 전용인지 확인하세요.

### 예제 7 · [487쪽] cron용 래퍼

회귀 Skill 확인이 끝나면 Claude Code에서 `/exit`합니다. 긴 Claude 명령과 비밀번호를 crontab에 직접 쓰지 않습니다. 프로젝트 폴더에서 추적되지 않는 실행 파일과 환경 파일을 준비합니다.

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT/5주차/harmony-analysis"
cp -n scripts/run-churn-check.sh.example scripts/run-churn-check.sh
chmod 700 scripts/run-churn-check.sh

# Day 22에서 만들지 않았다면 생성합니다.
cp -n .env.example .env
chmod 600 .env
git check-ignore .env scripts/run-churn-check.sh .claude/logs/
```

`.env`에서 `DB_PASSWORD`, `RECORDER_PASSWORD`, `CLAUDE_BIN`, `NODE_BIN_DIR`를 실제 로컬 값으로 바꿉니다. 먼저 대화형 터미널에서 실행합니다.

제공 래퍼는 한 번의 자동 실행이 끝없이 이어지지 않도록 `--max-turns 12`를 사용하고, 결과는 Git에서 제외된 `.claude/logs/churn-check.log`에 남깁니다.

파일: `scripts/run-churn-check.sh.example`

```bash
#!/usr/bin/env bash

set -euo pipefail
umask 077

project_dir=$(cd "$(dirname "$0")/.." && pwd)
env_file="$project_dir/.env"

[ -f "$env_file" ] || {
  echo "필수 파일이 없습니다: $env_file" >&2
  exit 1
}

set -a
# shellcheck disable=SC1090
. "$env_file"
set +a

export PATH="${NODE_BIN_DIR:-/opt/homebrew/bin}:/usr/local/bin:/usr/bin:/bin"
claude_bin=${CLAUDE_BIN:-}
if [ -z "$claude_bin" ] || [ ! -x "$claude_bin" ]; then
  claude_bin=$(command -v claude || true)
fi
[ -n "$claude_bin" ] || {
  echo "claude 실행 파일을 찾지 못했습니다. .env의 CLAUDE_BIN을 확인하세요." >&2
  exit 1
}
command -v npx >/dev/null 2>&1 || {
  echo "npx를 찾지 못했습니다. .env의 NODE_BIN_DIR을 확인하세요." >&2
  exit 1
}
[ -n "${DB_PASSWORD:-}" ] || { echo "DB_PASSWORD가 비어 있습니다." >&2; exit 1; }
[ -n "${RECORDER_PASSWORD:-}" ] || { echo "RECORDER_PASSWORD가 비어 있습니다." >&2; exit 1; }

log_dir="$project_dir/.claude/logs"
mkdir -p "$log_dir"

cd "$project_dir"
"$claude_bin" -p \
  --max-turns 12 \
  --permission-mode dontAsk \
  --allowedTools "mcp__harmony_db__search_objects,mcp__harmony_db__execute_sql,Read" \
  "실습 기준일 2026-09-03을 기준으로 이탈 팬을 점검해 줘. 원본 데이터는 바꾸지 말고 실행 SQL과 검증 결과를 출력해." \
  >> "$log_dir/churn-check.log" 2>&1
```

```bash
./scripts/run-churn-check.sh
tail -n 50 .claude/logs/churn-check.log
```

성공한 뒤 `crontab -e`에는 절대 경로 한 줄만 등록합니다.

교재 487쪽은 `cd ~/harmony-analysis && claude -p "..." --allowedTools "..."`처럼 한 줄에
모두 적습니다. 여기서는 Day 21에서 설명한 대로 실습 폴더가 저장소 안에 있고, cron이
환경 변수를 물려받지 않아 `.env`를 먼저 읽어야 하므로 **래퍼 스크립트를 한 겹 두고**
그 절대 경로만 등록합니다. 프롬프트와 `--allowedTools`는 래퍼 안에 그대로 들어 있습니다.

```cron
0 9 * * * "/절대/경로/sql-to-ai/5주차/harmony-analysis/scripts/run-churn-check.sh"
```

cron은 터미널의 PATH와 환경 변수를 상속하지 않습니다. 로그가 없으면 절대 경로, `.env` 권한, Docker 실행 상태를 확인합니다. macOS에서 `Operation not permitted`가 나오면 사용 중인 터미널 또는 cron 실행 주체의 개인정보 보호 접근 권한을 확인합니다.

Windows는 Day 24와 같은 WSL 배포판에 프로젝트를 두고 작업 스케줄러에서 다음 형식으로 래퍼를 호출합니다.

```text
wsl.exe -e bash -lc '/절대/WSL/경로/sql-to-ai/5주차/harmony-analysis/scripts/run-churn-check.sh'
```

### 예제 8 · [487~488쪽] Routines

Routines는 계정과 실행 환경에 따라 보이지 않을 수 있습니다. 화면에 실제로 표시될 때만 프로젝트 폴더에서 `claude`를 열어 사용하세요.

```bash
claude
```

```text
/schedule 매일 아침 9시, 어제 이탈한 팬을 점검해 리포트로 정리
```

클라우드 실행 환경에서는 로컬 PC의 `127.0.0.1` MySQL에 접근할 수 없습니다. 이 실습 구성은 로컬 cron 또는 WSL 작업 스케줄러를 사용합니다.

## 기록–query_history로 실행 SQL 재현하기

### 예제 9 · [488~489쪽] Bash와 MCP 기록 확인

Day 24의 `record-query.sh`와 설정을 적용했다면 Bash의 `mysql -e`와 `mcp__harmony_db__execute_sql` 호출이 모두 기록됩니다. 실패한 도구 호출도 `execution_status='failure'`로 구분됩니다.

```sql
SELECT
  query_id, session_id, agent_name, tool_name, category,
  execution_status, created_datetime, verified
FROM query_history
WHERE DATE(created_datetime) = CURDATE()
ORDER BY created_datetime DESC, query_id DESC;
```

실패 원인과 원문 SQL 확인

```sql
SELECT query_id, sql_query, error_message
FROM query_history
WHERE query_id = 1;
```

사람이 실제 `query_id`와 결과를 확인한 뒤, UPDATE 권한이 있는 관리자 세션에서만 검증 표시를 바꿉니다.

```sql
UPDATE query_history
SET verified = TRUE
WHERE query_id = 1;
```

예시의 `query_id=1`을 그대로 실행하지 말고 조회 결과의 대상 ID로 바꿉니다. 기록 실패가 본래 분석까지 실패시키지는 않으므로, 자동 실행 뒤에는 로그와 `query_history`를 함께 확인합니다.

## 완료 검증

Claude Code가 열려 있으면 `/exit`합니다. 프로젝트의 `.env`를 현재 셸에 적용한 뒤 실행합니다.

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT/5주차/harmony-analysis"
set -a
. ./.env
set +a
../환경셋업/check-environment.sh 25 ready
```

체크리스트

- [ ] 관리자 SQL과 읽기 전용 분석을 분리했다.
- [ ] 양방향 차이가 0행이고 정확도가 100.00이다.
- [ ] 정답 해시와 현재 결과 해시가 같은 직렬화 버전으로 일치한다.
- [ ] 회귀 Skill을 직접 완성하고 PASS/FAIL 및 차이 행을 확인했다.
- [ ] 자동 실행 래퍼를 대화형으로 먼저 검증했다.
- [ ] 기록된 SQL을 사람이 확인한 뒤에만 `verified`를 바꿨다.

## 막힐 때

| 증상 | 바로 확인할 것 |
|---|---|
| 임시 테이블 권한 오류 | 읽기 전용 제한이 정상 작동한 것입니다. 관리자 세션 또는 CTE 대안을 사용합니다. |
| 임시 테이블을 찾지 못함 | `gold_result`와 `generated_result`를 같은 MySQL 접속 세션에서 만듭니다. |
| `eval_cases` 칼럼이 부족함 | 데이터를 DROP하지 말고 `eval_cases_upgrade_v2.sql`을 관리자 계정으로 실행합니다. |
| `Field 'canonical_sql' doesn't have a default value` | 교재 484쪽의 3칼럼 `INSERT`를 9칼럼 테이블에 실행한 경우입니다. 예제 4의 `INSERT`를 쓰거나, `eval_cases`를 교재의 3칼럼으로 다시 만듭니다. |
| 해시가 환경마다 다름 | `group_concat_max_len`, 날짜 형식, 정수 변환, 행 순서, 구분자, 알고리즘을 모두 확인합니다. |
| cron에서 MCP 연결 실패 | 절대 경로, `.env`, PATH, 작업 폴더, Docker 상태를 확인합니다. |
| `query_history`가 비어 있음 | Day 24 settings의 MCP matcher, recorder 계정, `RECORDER_PASSWORD`, 훅 로그를 확인합니다. |
| `permissions.allow ... workspace has not been trusted` | `claude -p`는 신뢰하지 않은 폴더에서 `settings.json`의 `permissions`를 무시합니다. cron에 걸기 전에 그 폴더에서 대화형 `claude`를 한 번 열어 신뢰 대화상자를 수락하세요. 훅은 그대로 동작하므로 데이터 안전에는 영향이 없습니다. |

교재 490~491쪽의 에필로그는 책에서 이어서 읽습니다.
