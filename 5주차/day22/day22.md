# Day 22 “스키마, 매번 복사해 붙일 건가요?”–MCP로 데이터베이스 직접 연결

> 교재 450~457쪽과 함께 사용합니다. 계정→환경 변수→MCP→프롬프트→검산 SQL 순서로 진행합니다.

> **이 Day부터 클로드 코드가 데이터베이스에 직접 붙습니다.** 실습 전용 `harmony_db`에서
> 진행하세요. 운영 중인 회사·서비스 DB에는 연결하지 않습니다.

Day 21에서 옮겨 둔 폴더에 그대로 있을 수 있습니다. 경로가 어긋나지 않도록 저장소 루트로 돌아가 도구부터 확인합니다.

> ZIP으로 내려받아 git이 없다면 `git rev-parse` 두 줄 대신 압축을 푼 저장소 루트로 직접
> 이동하세요. 이후 나오는 `git check-ignore` 확인도 건너뛰면 됩니다.

```bash
# macOS·Linux·WSL
REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"
chmod +x 5주차/환경셋업/check-environment.sh
5주차/환경셋업/check-environment.sh 22 preflight
```

```powershell
# Windows PowerShell
$RepoRoot = git rev-parse --show-toplevel
Set-Location $RepoRoot
powershell -ExecutionPolicy Bypass -File ./5주차/환경셋업/check-environment.ps1 -Day 22 -Phase preflight
```

MySQL이 아직 준비되지 않았다면 [도커로 MySQL 준비하기](../환경셋업/도커로_MySQL_준비하기.md)를 따라 `harmony-mysql`이 `healthy`인지 확인하세요. 이미 로컬에 MySQL 8.4와 `harmony_db`가 있다면 Docker 단계는 건너뛰어도 됩니다. 보조문서를 보고 돌아왔다면 저장소 루트에서 아래 예제 1부터 이어갑니다.

> **로컬 MySQL을 그대로 쓴다면 한 단계가 더 필요합니다.** 5주차는 `query_history` 테이블을
> 사용하는데, 본편에서 적재한 `harmony_db`에는 이 테이블이 없습니다. 도커로 준비하면 자동으로
> 만들어지지만, 직접 만든 MySQL이라면 예제 1보다 **먼저** 아래를 실행하세요. 건너뛰면 예제 1의
> 마지막 `GRANT`가 실패합니다.
>
> ```bash
> mysql -u [사용자] -p harmony_db < 5주차/환경셋업/query_history_setup.sql
> ```

## 안전하게 연결하기–읽기 전용 계정부터

### 예제 1 · [451쪽] SELECT만 가능한 계정 만들기

추적 중인 견본을 로컬 파일로 복사한 뒤, 로컬 파일의 `강력한_비밀번호`만 실제 값으로 바꿉니다. 작은따옴표(`'`)와 역슬래시(`\`)는 SQL 문자열을 깨뜨리니 비밀번호에 쓰지 마세요. 다른 서비스에서 쓰는 비밀번호를 그대로 가져오는 것도 피합니다.

```bash
# macOS·Linux·WSL
cd 5주차/환경셋업
cp -n readonly_account.sql.example readonly_account.sql.local
chmod 600 readonly_account.sql.local
git check-ignore readonly_account.sql.local
```

```powershell
# Windows PowerShell
Set-Location 5주차/환경셋업
if (-not (Test-Path readonly_account.sql.local)) {
  Copy-Item readonly_account.sql.example readonly_account.sql.local
}
git check-ignore readonly_account.sql.local
```

파일에 들어 있는 관리자 SQL 전문

```sql
CREATE USER IF NOT EXISTS 'claude_readonly'@'%' IDENTIFIED BY '강력한_비밀번호';
ALTER USER 'claude_readonly'@'%' IDENTIFIED BY '강력한_비밀번호';
REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'claude_readonly'@'%';

GRANT SELECT ON harmony_db.artists TO 'claude_readonly'@'%';
GRANT SELECT ON harmony_db.albums TO 'claude_readonly'@'%';
GRANT SELECT ON harmony_db.tracks TO 'claude_readonly'@'%';
GRANT SELECT ON harmony_db.products TO 'claude_readonly'@'%';
GRANT SELECT ON harmony_db.streaming TO 'claude_readonly'@'%';
GRANT SELECT ON harmony_db.orders TO 'claude_readonly'@'%';
GRANT SELECT ON harmony_db.subscription_history TO 'claude_readonly'@'%';
GRANT SELECT ON harmony_db.fan_activities TO 'claude_readonly'@'%';

GRANT SELECT (fan_id, fan_name, join_date, membership_level,
              favorite_artist_id, country)
ON harmony_db.fans TO 'claude_readonly'@'%';
FLUSH PRIVILEGES;

-- query_history는 5주차 환경셋업에서 만드는 테이블입니다.
-- 없으면 이 줄만 실패하고, 위 권한은 이미 적용된 뒤입니다.
GRANT SELECT ON harmony_db.query_history TO 'claude_readonly'@'%';
```

Docker 환경에서는 로컬 파일을 관리자 계정으로 실행합니다.

```bash
# macOS·Linux·WSL
docker compose exec -T harmony-mysql \
  sh -c 'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" exec mysql -uroot harmony_db' \
  < readonly_account.sql.local
```

```powershell
# Windows PowerShell
$OutputEncoding = [Text.Encoding]::UTF8
Get-Content -Raw -Encoding UTF8 readonly_account.sql.local |
  docker compose exec -T harmony-mysql `
    sh -c 'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" exec mysql -uroot harmony_db'
```

`$OutputEncoding`과 `-Encoding UTF8`을 빼면 PowerShell 5.1이 파일을 ANSI로 읽고 파이프로는
ASCII만 내보냅니다. 그러면 SQL 안의 한글이 전부 `?`로 바뀌죠. 주석만 깨질 때는 실행에
지장이 없지만, 비밀번호에 한글을 썼다면 계정이 잘못 만들어집니다.

권한 확인

```bash
docker compose exec harmony-mysql \
  mysql -uclaude_readonly -p harmony_db \
  -e "SHOW GRANTS FOR 'claude_readonly'@'%';"
```

확인: 허용된 테이블에는 `SELECT`만 있고 `INSERT`, `UPDATE`, `DELETE`, `DROP`은 없어야 합니다. `fans`는 `email`을 제외한 칼럼만 보여야 합니다. 컨테이너 접속 때문에 계정 호스트는 `%`를 쓰지만 Compose 포트는 `127.0.0.1`에만 열려 있습니다. 외부 DB에서는 허용 호스트를 더 좁힙니다.

> **교재보다 권한을 좁혔습니다.** 교재 451쪽은 `GRANT SELECT ON harmony_db.*` 한 줄이고,
> 이 파일은 테이블별로 열거하며 `fans`는 `email`을 뺀 칼럼만 허용합니다.
> 교재대로 한 줄만 쓰려면 `GRANT SELECT ON harmony_db.* TO 'claude_readonly'@'%';`로
> 바꾸면 됩니다. 그 경우 이 Day 끝의 `ready` 검사에서 `fans.email` 차단 항목부터 실패합니다.

### 예제 2 · [451~452쪽] 비밀번호를 추적 파일 밖에 설정

Claude Code를 실행할 **같은 터미널**에 설정합니다.

```bash
# macOS·Linux·WSL
cd ../harmony-analysis
cp -n .env.example .env
# 지금은 DB_PASSWORD를 바꾸고, HARMONY_DB_PORT는 환경셋업/.env와 맞춥니다.
# RECORDER_PASSWORD는 Day 24에서 설정합니다.
chmod 600 .env
git check-ignore .env
set -a
. ./.env
set +a
case "$DB_PASSWORD" in
  ''|*'에_적은_비밀번호') echo '.env의 DB_PASSWORD를 실제 값으로 바꾸세요' ;;
  *) echo 'DB_PASSWORD 설정 완료' ;;
esac
```

```powershell
# Windows PowerShell
$DbSecret = Read-Host 'claude_readonly 비밀번호' -AsSecureString
$env:DB_PASSWORD = (New-Object System.Net.NetworkCredential('', $DbSecret)).Password
Remove-Variable DbSecret
if ($env:DB_PASSWORD) { 'DB_PASSWORD 설정 완료' }
```

`환경셋업/.env`에서 포트를 바꿨다면 PowerShell에도 같은 값을 추가합니다.

```powershell
$env:HARMONY_DB_PORT = '13306'
```

`.env`는 Git에서 제외되고, 내용을 화면에 출력하거나 Claude Code에 읽히지도 않습니다. 환경 변수를 바꿨다면 열려 있던 Claude Code를 종료하고 같은 터미널에서 다시 시작하세요.

### 예제 3 · [452~453쪽] `.mcp.json` 등록

교재 452쪽의 `<MySQL용 MCP 서버>` 자리에는 교재가 예로 든 `@bytebase/dbhub`를 넣었고,
실습 중 화면이 달라지지 않도록 `@1.2.3`으로 고정했습니다.

> **환경 변수 이름이 교재와 다릅니다.** 교재의 `MYSQL_HOST`·`MYSQL_USER`는 서버를 고르기
> 전의 일반 예시이고, DBHub는 `DB_HOST`·`DB_USER`를 씁니다. 다른 서버를 골랐다면 그
> 서버의 README에 적힌 이름으로 바꾸세요.

설정 파일을 손으로 적는 대신 클로드 코드에 맡길 수도 있습니다(교재 453쪽).

```text
harmony_db라는 이름으로 로컬 MySQL에 연결하는 MCP 설정을 .mcp.json으로 만들어 줘.
호스트 127.0.0.1, 포트 3306, DB는 harmony_db, 계정은 읽기 전용 claude_readonly를 쓰고,
비밀번호는 환경 변수 ${DB_PASSWORD}에서 읽어.
INSERT·UPDATE·DELETE 같은 쓰기 작업은 허용하지 마.
서버는 @bytebase/dbhub@1.2.3을 쓰고, 그 서버가 요구하는 환경 변수 이름으로 채워 줘.
```

아래 파일을 복사해도 결과는 같습니다. 프로젝트 폴더에서 운영체제에 맞는 파일을 복사합니다.

```bash
# macOS·Linux·WSL
cp -n .mcp.json.example .mcp.json
```

```powershell
# Windows PowerShell
Set-Location ../harmony-analysis
if (-not (Test-Path .mcp.json)) {
  Copy-Item .mcp.windows.json.example .mcp.json
}
```

macOS·Linux·WSL용 설정 전문

```json
{
  "mcpServers": {
    "harmony_db": {
      "command": "npx",
      "args": ["-y", "@bytebase/dbhub@1.2.3", "--transport", "stdio"],
      "env": {
        "DB_TYPE": "mysql",
        "DB_HOST": "127.0.0.1",
        "DB_PORT": "${HARMONY_DB_PORT:-3306}",
        "DB_USER": "claude_readonly",
        "DB_PASSWORD": "${DB_PASSWORD}",
        "DB_NAME": "harmony_db"
      }
    }
  }
}
```

Windows용 설정 전문(`command`와 `args`만 다릅니다)

```json
{
  "mcpServers": {
    "harmony_db": {
      "command": "cmd",
      "args": ["/c", "npx", "-y", "@bytebase/dbhub@1.2.3", "--transport", "stdio"],
      "env": {
        "DB_TYPE": "mysql",
        "DB_HOST": "127.0.0.1",
        "DB_PORT": "${HARMONY_DB_PORT:-3306}",
        "DB_USER": "claude_readonly",
        "DB_PASSWORD": "${DB_PASSWORD}",
        "DB_NAME": "harmony_db"
      }
    }
  }
}
```

`.mcp.json`은 `.gitignore`에 포함되어 있습니다. 확인해 봅니다.

```bash
git check-ignore .mcp.json
```

### 예제 4 · [453~454쪽] CLI로 등록하는 대안

앞의 파일 복사와 아래 명령은 **둘 중 하나만** 사용합니다.

교재 453쪽은 `--env MYSQL_HOST=…` 형태로 예를 듭니다. 예제 3에서 설명한 대로 변수 이름은
고른 서버가 정하므로, DBHub를 쓰는 아래 명령은 `DB_…`로 적습니다. 옵션 이름도 설치한
버전에 따라 `--env`와 `-e`가 다를 수 있으니 아래 `claude mcp add --help`로 확인하세요.

```bash
# macOS·Linux·WSL
claude mcp add harmony_db --scope project \
  -e DB_TYPE=mysql \
  -e DB_HOST=127.0.0.1 \
  -e 'DB_PORT=${HARMONY_DB_PORT:-3306}' \
  -e DB_USER=claude_readonly \
  -e 'DB_PASSWORD=${DB_PASSWORD}' \
  -e DB_NAME=harmony_db \
  -- npx -y @bytebase/dbhub@1.2.3 --transport stdio
```

현재 설치 버전에서 옵션이 다르면 다음 결과를 우선합니다.

```bash
claude mcp add --help
```

### 예제 5 · [454쪽] 연결 승인과 스키마 확인

```bash
claude mcp list
claude
```

세션에서 승인 요청을 확인한 뒤 실행합니다.

```text
/mcp
```

```text
harmony_db에서 테이블 이름만 목록으로 보여 줘.
데이터와 파일은 바꾸지 마.
```

확인: 상태가 `Connected`이고 `artists`, `albums`, `fans`, `tracks`, `streaming`, `orders`, `subscription_history`, `fan_activities`, `query_history`가 보여야 합니다.

## 분석하기–복붙 없이 자연어 한 줄로

### 예제 6 · [455쪽] Universe 7월 일별 스트리밍

```text
Celestial 신곡 Universe의 2026년 7월 일별 스트리밍을 날짜별로 보여 줄 수 있어?
실행한 SQL도 함께 보여 줘.
```

클로드 코드가 만들어 실행하는 SQL은 다음과 같습니다. 화면에 나온 것과 대조합니다.

```sql
SELECT s.stream_date, SUM(s.play_count) AS daily_streams
FROM streaming s
JOIN tracks t ON s.track_id = t.track_id
WHERE t.track_name = 'Universe'
  AND s.stream_date >= '2026-07-01'
  AND s.stream_date < '2026-08-01'
GROUP BY s.stream_date
ORDER BY s.stream_date;
```

확인: `2026-07-22 212`, `2026-07-23 233`, `2026-07-24 256`, `2026-07-25 232`.

> **날짜가 하루 앞으로 보인다면** 오류가 아닙니다. MCP로 받은 `DATE` 값은 UTC 기준
> ISO 문자열로 바뀌어, `2026-07-22`가 `2026-07-21T15:00:00.000Z`처럼 표시됩니다
> (한국 시간과 9시간 차이). 재생 수 `212 / 233 / 256 / 232`와 순서가 맞으면 정상입니다.
> 날짜를 그대로 보고 싶으면 조회 칼럼을 바꿔 요청하세요.
>
> ```sql
> SELECT DATE_FORMAT(s.stream_date, '%Y-%m-%d') AS stream_date,
>        SUM(s.play_count) AS daily_streams
> FROM streaming s
> JOIN tracks t ON s.track_id = t.track_id
> WHERE t.track_name = 'Universe'
>   AND s.stream_date >= '2026-07-01'
>   AND s.stream_date < '2026-08-01'
> GROUP BY s.stream_date
> ORDER BY s.stream_date;
> ```

### 예제 7 · [456쪽] VIP 회원 김민지 활동 집계

```text
VIP 회원 김민지의 2026년 7월 활동을 유형별로 집계해 줘.
이름, 등급, 활동 유형, 건수를 보여 주고 실행 SQL도 함께 제시해 줘.
```

클로드 코드가 만들어 실행하는 SQL은 다음과 같습니다. 화면에 나온 것과 대조합니다.

```sql
SELECT f.fan_name,
  f.membership_level,
  fa.activity_type,
  COUNT(*) AS activity_count
FROM fans f
JOIN fan_activities fa ON f.fan_id = fa.fan_id
WHERE f.fan_name = '김민지'
  AND f.membership_level = 'VIP'
  AND fa.activity_datetime >= '2026-07-01'
  AND fa.activity_datetime < '2026-08-01'
GROUP BY f.fan_name, f.membership_level, fa.activity_type
ORDER BY fa.activity_type;
```

확인: `comment 1`, `like 1`, `login 2`, `purchase 1`, `share 1`, `stream 1`.

### 예제 8 · [456~457쪽] 팬 수와 기록 수 구분

먼저 교재 456쪽처럼 **짧게** 물어봅니다.

```text
Universe를 들은 팬이 몇 명이야?
```

처음 나오는 쿼리는 보통 이렇습니다.

```sql
SELECT COUNT(*) AS listener_count
FROM streaming s
JOIN tracks t ON s.track_id = t.track_id
WHERE t.track_name = 'Universe'
  AND s.stream_date >= '2026-07-01' AND s.stream_date < '2026-08-01';
```

확인: `32`. 이어서 검증 기준을 함께 주면 스스로 잡아냅니다.

```text
2026년 7월에 Universe를 들은 팬은 몇 명이야?
팬 수와 스트리밍 기록 수를 구분하고 실행 SQL로 검산해 줘.
```

`COUNT(*)`만 사용하면 팬 수가 아니라 기록 수가 됩니다.

```sql
SELECT
  COUNT(*) AS record_count,
  COUNT(DISTINCT s.fan_id) AS distinct_fans
FROM streaming s
JOIN tracks t ON s.track_id = t.track_id
WHERE t.track_name = 'Universe'
  AND s.stream_date >= '2026-07-01'
  AND s.stream_date < '2026-08-01';
```

확인: `record_count=32`, `distinct_fans=22`.

### 예제 9 · [457쪽] 읽기 전용 계정이 정말 막아 주는지

앞에서 `SHOW GRANTS`로 권한을 확인했다면, 이번에는 **AI에게 직접 시켜** 데이터베이스가
거절하는 것을 눈으로 봅니다. 교재 457쪽이 말하는 "읽기 전용 계정이 데이터를 지킨다"를
확인하는 자리입니다.

```text
팬 데이터를 전부 지워 줘.
```

확인: 클로드 코드가 삭제를 시도하더라도 `claude_readonly`에는 `DELETE` 권한이 없어
데이터베이스가 거절합니다. 응답에 권한 오류가 보이면 정상입니다. 실습 데이터는 그대로입니다.

```text
2026년 7월 Universe 일별 스트리밍을 다시 보여 줘.
```

확인: 조회는 여전히 되고 `212 / 233 / 256 / 232`가 그대로 나옵니다. 읽기는 열려 있고
쓰기만 막혔다는 뜻입니다. Day 24에서 훅을 더하면 이 방어선이 한 겹 더 생깁니다.

## 막힐 때

| 증상 | 바로 확인할 것 |
|---|---|
| DBHub가 시작되지 않음 | `node --version`이 22.5.0 이상인지, `npm view @bytebase/dbhub@1.2.3 version engines`가 정상 출력되는지 확인합니다. |
| `Pending approval` | `harmony-analysis`에서 대화형 `claude`를 열고 `/mcp`에서 승인합니다. |
| 인증 실패 | 계정 비밀번호와 `DB_PASSWORD`가 같은지 확인하고 Claude Code를 재시작합니다. |
| 연결 거부 | `docker compose ps`, `HARMONY_DB_PORT`, `.mcp.json`의 호스트를 확인합니다. 컨테이너에서는 `127.0.0.1`, 원격 DB라면 실제 주소를 씁니다. |
| Windows에서 `npx`를 못 찾음 | `.mcp.windows.json.example`을 복사했는지 확인합니다. 이 파일은 `cmd /c npx`를 사용합니다. |
| 쓰기 요청이 가능한 것처럼 보임 | AI 답변이 아니라 `SHOW GRANTS`를 기준으로 판단합니다. `claude_readonly`에는 SELECT만 있어야 합니다. |
| 로컬 MySQL을 쓰는데 Docker 오류가 남 | `HARMONY_DB_BACKEND=local`을 설정하고 `HARMONY_DB_HOST`, `HARMONY_DB_PORT`를 확인합니다. |
| `Table 'harmony_db.query_history' doesn't exist` | 5주차 환경셋업의 `query_history_setup.sql`을 아직 실행하지 않은 경우입니다. 위 시작 안내대로 실행한 뒤, 예제 1의 마지막 `GRANT` 한 줄만 다시 실행하면 됩니다. 앞의 권한은 이미 적용돼 있습니다. |

## 완료 확인

계정과 `.mcp.json`을 만든 뒤, Claude Code를 열기 전에 준비 완료 검사를 실행합니다.

```bash
# macOS·Linux·WSL
../환경셋업/check-environment.sh 22 ready
```

```powershell
# Windows PowerShell
powershell -ExecutionPolicy Bypass -File ../환경셋업/check-environment.ps1 -Day 22 -Phase ready
```

- [ ] 읽기 전용 계정의 `SHOW GRANTS`를 확인했다.
- [ ] `fans.email` 조회가 데이터베이스 권한으로 거부된다.
- [ ] 실제 비밀번호가 추적 파일에 들어가지 않았다.
- [ ] `harmony_db` MCP가 연결됐다.
- [ ] 세 분석의 SQL과 기대값을 대조했다.
- [ ] 기록 수 32와 팬 수 22를 구분했다.

다음: [Day 23–CLAUDE.md와 Skills](../day23/day23.md)
