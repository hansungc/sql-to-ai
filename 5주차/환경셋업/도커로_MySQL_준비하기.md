# 도커로 MySQL 준비하기

이 문서는 교재 436~437쪽의 로컬 MySQL 준비를 보완합니다. 개념 설명은 교재에서 읽고, 설치·경로·포트 문제로 실습이 멈출 때 이 문서를 사용하세요. 검증 기준은 2026-09-03입니다.

## 1. 준비 확인

macOS와 Windows는 Docker Desktop을 설치해 실행하면 됩니다. Linux는 Docker Engine과 Compose 플러그인을 설치한 뒤, 지금 쓰는 계정이 Docker를 실행할 수 있도록 설정하세요.

Day 22 문서에서 `preflight`를 이미 통과했다면 이 단계는 건너뛰고 2단계로 갑니다.

macOS·Linux·WSL:

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT/5주차/환경셋업"
chmod +x check-environment.sh
./check-environment.sh 22 preflight
```

Windows PowerShell:

```powershell
$RepoRoot = git rev-parse --show-toplevel
Set-Location (Join-Path $RepoRoot '5주차/환경셋업')
powershell -ExecutionPolicy Bypass -File ./check-environment.ps1 -Day 22 -Phase preflight
```

`preflight`는 필요한 명령이 깔려 있는지만 봅니다. 계정을 만들기 전이라면 `DB_PASSWORD` 경고가 뜨는 것이 정상이고, 이 단계를 통과했다고 해서 데이터베이스 연결까지 끝난 것은 아닙니다.

## 2. MySQL 시작

추적되지 않는 Compose 환경 파일을 먼저 만들고 `MYSQL_ROOT_PASSWORD`를 실제 로컬 비밀번호로 바꿉니다.

macOS·Linux·WSL:

```bash
cp -n .env.example .env
chmod 600 .env
git check-ignore .env
```

이미 `.env`가 있으면 `cp -n`이 기존 비밀번호를 덮어쓰지 않습니다.

Windows PowerShell:

```powershell
if (-not (Test-Path .env)) {
  Copy-Item .env.example .env
}
git check-ignore .env
```

```bash
docker compose up -d
docker compose ps
```

`harmony-mysql`의 상태가 `healthy`가 될 때까지 기다립니다. 최초 실행은 이미지 다운로드와 데이터 적재 때문에 시간이 더 걸릴 수 있습니다.

```bash
docker compose logs harmony-mysql
```

포트 3306을 이미 사용 중이면 `환경셋업/.env`의 `HARMONY_DB_PORT=3306`을 `HARMONY_DB_PORT=13306`으로 바꾸고 `docker compose up -d`를 다시 실행합니다. Day 22에서 만드는 `harmony-analysis/.env`와 Windows PowerShell의 `HARMONY_DB_PORT`도 반드시 같은 값으로 맞춥니다. 데이터베이스 포트는 보안을 위해 `127.0.0.1`에만 공개됩니다.

## 3. 데이터 확인

root 비밀번호는 `환경셋업/.env`의 `MYSQL_ROOT_PASSWORD`이며 명령줄에 직접 적지 않습니다.

```bash
docker compose exec -T harmony-mysql \
  sh -c 'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" exec mysql -uroot --default-character-set=utf8mb4 harmony_db' <<'SQL'
SELECT 'artists' AS table_name, COUNT(*) AS row_count FROM artists
UNION ALL SELECT 'fans', COUNT(*) FROM fans
UNION ALL SELECT 'tracks', COUNT(*) FROM tracks
UNION ALL SELECT 'streaming', COUNT(*) FROM streaming
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'subscription_history', COUNT(*) FROM subscription_history
UNION ALL SELECT 'fan_activities', COUNT(*) FROM fan_activities
UNION ALL SELECT 'query_history', COUNT(*) FROM query_history;
SQL
```

기대 행 수: `artists 15`, `fans 111`, `tracks 104`, `streaming 375`, `orders 234`, `subscription_history 100`, `fan_activities 140`, `query_history 0`.

## 4. Day 22로 돌아가기

컨테이너가 `healthy`이고 위 행 수가 맞으면 데이터베이스 준비는 끝났습니다. [Day 22](../day22/day22.md)의 예제 1로 돌아가 읽기 전용 계정을 만듭니다. 기록용 `recorder` 계정은 Day 24에서 만듭니다.

## 5. 환경별 보완

| 증상 | 해결 |
|---|---|
| `docker: command not found` | Docker를 설치한 뒤 새 터미널을 엽니다. |
| Docker daemon 연결 오류 | Docker Desktop 또는 Linux Docker 서비스를 시작합니다. |
| `port is already allocated` | 환경셋업과 harmony-analysis의 두 `.env`에서 `HARMONY_DB_PORT=13306`으로 맞춥니다. |
| `no matching manifest` | 오래된 Docker를 업데이트합니다. Apple Silicon에서는 Rosetta를 강제로 쓸 필요가 없습니다. |
| 데이터 테이블이 없음 | `docker compose ps`와 로그를 확인합니다. 초기화 SQL은 빈 볼륨에서 한 번만 실행됩니다. |
| 한글이 깨짐 | `--default-character-set=utf8mb4`를 붙이고 `mysql-utf8mb4.cnf` 마운트를 확인합니다. |
| `mysql: command not found` | Docker 명령은 위처럼 `docker compose exec ... mysql`을 사용합니다. macOS에서 로컬 클라이언트를 설치했다면 `brew install mysql-client` 뒤 안내된 PATH도 반영합니다. |
| Windows에서 Bash 훅 실패 | Day 24의 제공 훅은 Bash 코드입니다. WSL에서 Claude Code를 실행하면 같은 파일을 그대로 사용할 수 있습니다. |

## 6. 중지와 초기화

```bash
docker compose stop
docker compose start
docker compose down
```

`docker compose down`은 데이터 볼륨을 남깁니다. 아래 명령은 이 실습의 데이터와 계정, 평가셋을 모두 지우므로, 처음부터 다시 시작하기로 결정한 경우에만 실행합니다.

```bash
docker compose down -v
```

이미 로컬 MySQL을 사용한다면 `harmony_db`를 먼저 백업하고, 교재의 데이터 적재 절차를 따르세요. 기존 DB를 자동으로 삭제하는 명령은 이 보조자료에서 제공하지 않습니다.
