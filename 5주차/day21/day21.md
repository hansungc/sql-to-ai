# Day 21 “AI가 답만 주고 멈추면, 실행은 누가 하죠?”–에이전트와 클로드 코드

> 교재 438~449쪽과 함께 사용합니다. 아래 블록은 위에서 아래로 실행하고, 설명과 해석은 교재에서 읽습니다.

실습 위치는 저장소의 `5주차/harmony-analysis`입니다. Day 21에는 데이터베이스를 연결하지 않습니다.

명령을 시작하기 전에 저장소 루트로 이동합니다. Git으로 내려받지 않고 ZIP을 풀었다면 이 두 줄 대신 압축을 푼 저장소 루트로 직접 이동하세요.

```bash
# macOS·Linux·WSL
REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"
```

```powershell
# Windows PowerShell
$RepoRoot = git rev-parse --show-toplevel
Set-Location $RepoRoot
```

## 챗봇과 에이전트–답하고 멈추는 것에서, 스스로 끝까지 해내는 것으로

### 예제 1 · [439쪽] 같은 분석 요청

```text
Celestial 신곡 Universe의 7월 일별 스트리밍을 보여 줘.
```

오늘은 요청 형태만 확인합니다. 실제 DB 실행과 기대값 검산은 Day 22에서 합니다.

## 5분 만에 첫 성공–설치부터 첫 변경 승인까지

### 예제 2 · [440쪽] Claude Code 설치

```bash
# macOS·Linux·WSL
curl -fsSL https://claude.ai/install.sh | bash
```

```powershell
# Windows PowerShell
irm https://claude.ai/install.ps1 | iex
```

Windows는 설치 뒤 한 줄이 더 필요합니다. 설치 스크립트가 `claude.exe`를
`%USERPROFILE%\.local\bin`에 놓기만 하고 `PATH`에는 넣지 않아서, 그대로 새 터미널을 열면
`'claude' 용어가 ... 인식되지 않습니다` 오류가 납니다.

```powershell
[Environment]::SetEnvironmentVariable('Path', "$env:USERPROFILE\.local\bin;" +
  [Environment]::GetEnvironmentVariable('Path','User'), 'User')
```

새 터미널을 연 뒤 확인합니다. 새 창은 홈 폴더에서 시작하므로 저장소 루트로 다시 이동합니다.

```bash
# macOS·Linux·WSL
claude --version
claude doctor
REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"
5주차/환경셋업/check-environment.sh 21 preflight
```

```powershell
# Windows PowerShell
claude --version
claude doctor
$RepoRoot = git rev-parse --show-toplevel
Set-Location $RepoRoot
powershell -ExecutionPolicy Bypass -File ./5주차/환경셋업/check-environment.ps1 -Day 21 -Phase preflight
```

업데이트가 필요할 때만 실행합니다.

```bash
claude update
```

### 예제 3 · [441~443쪽] 프로젝트에서 첫 실행

> **교재와 폴더가 다릅니다.** 교재 441쪽의 `mkdir ~/harmony-analysis` 대신,
> 이미 파일이 들어 있는 `5주차/harmony-analysis`로 이동합니다. 교재대로 빈 폴더에서
> 시작하려면 `mkdir ~/harmony-analysis` 후 이 폴더의 파일을 복사해 넣으세요.

```bash
# macOS·Linux·WSL
cd 5주차/harmony-analysis
claude
```

```powershell
# Windows PowerShell
Set-Location 5주차/harmony-analysis
claude
```

처음 실행하면 로그인 화면과 이 폴더를 신뢰할지 묻는 화면이 차례로 나옵니다. 화면에 뜬 경로가 방금 내려받은 실습 폴더가 맞는지 확인한 뒤 승인하세요.

### 예제 4 · [442쪽] 폴더 탐색

Claude Code 입력창에 차례로 붙여 넣습니다.

```text
이 폴더에 뭐가 있어?
```

```text
queries/daily_streams.sql이 무슨 쿼리인지 설명해 줘.
파일을 수정하지 마.
```

확인: 답변에 실제 경로 `harmony_v1.sql`, `queries/daily_streams.sql`, `queries/churn_analysis.sql`, `notes.md`가 나와야 합니다.

### 예제 5 · [442~443쪽] 첫 변경 승인

```text
queries/daily_streams.sql 맨 위에 이 쿼리가 무엇을 분석하는지 한 줄 주석을 달아 줘.
변경 내용을 먼저 보여 주고 내 승인을 받은 뒤 수정해 줘.
```

확인: 제안된 파일과 한 줄만 바뀌는지 본 뒤 승인합니다. 이미 주석이 있다면 삭제하지 말고 더 명확하게 고치도록 요청합니다.

## 대화로 다루는 다섯 가지 습관–구체적, 멈추기, 되돌리기, 검증, 탐색

### 예제 6 · [443쪽] 조건과 결과 모양 지정

```text
fan_activities에서 최근 30일 로그인이 0인데 구독은 유지 중인 팬을 추리고,
subscription_history로 상태를 확인해 명단을 만들어 줘.
출력은 fan_id, 이름, 마지막 로그인일로 보여 줘.
지금은 계획만 세우고 실행하지 마.
```

```text
queries/churn_analysis.sql에서 NULL인 행을 빠뜨릴 가능성을 점검해 줘.
필요하면 LEFT JOIN으로 바꾸고, 구독 이력이 없는 팬도 결과에 남게 할 수정안을 보여 줘.
아직 파일은 수정하지 마.
```

파일 선택 기능을 쓰려면 입력창에서 `@`를 입력한 뒤 다음 경로를 고릅니다.

```text
@queries/churn_analysis.sql
```

### 예제 7 · [444쪽] 중지와 되돌리기

진행 방향이 다르면 `Esc`로 현재 작업을 멈춥니다. 승인한 파일 변경을 되돌릴 때는 다음처럼 요청하거나 `/rewind`에서 체크포인트를 선택합니다.

```text
방금 바꾼 파일 변경만 되돌려 줘. 다른 파일은 건드리지 마.
```

이미 DB에 실행된 `DELETE`, `UPDATE`, `DROP`은 파일 체크포인트로 복구되지 않습니다.

### 예제 8 · [444쪽] 검증 기준 함께 주기

```text
Celestial 신곡 Universe의 2026년 7월 일별 스트리밍을 계산해 줘.
일별 값의 합계와 같은 기간 Universe 전체 스트리밍 합계가 일치하는지도 검산하고,
실행한 SQL을 함께 보여 줘. 지금은 DB가 연결되지 않았다면 실행한 척하지 마.
```

### 예제 9 · [445~447쪽] 탐색→계획→실행

교재의 분석 요청

```text
2026년 7월에 Phoenix를 스트리밍한 팬과 그들의 구독 상태를 한 표로 만들어 줘.
```

바로 실행하려 하면 다음처럼 계획부터 요청합니다.

```text
방금 요청은 아직 실행하지 말고 다음 네 단계를 포함한 계획만 보여 줘.
1. 2026년 7월 streaming에서 Phoenix 트랙 필터링
2. 스트리밍한 팬 식별
3. subscription_history와 조인해 구독 상태 확인
4. 결과를 reports/phoenix_july.csv에 저장
```

조인 조건까지 확인했다면 여기까지입니다. Day 21에는 아직 데이터베이스가 없으니 실행할 SQL 파일만 만들어 둡니다.

```text
방금 합의한 계획에서 SELECT SQL을 queries/phoenix_july.sql로 작성해 줘.
아직 DB가 연결되지 않았으므로 실행하거나 결과 행 수를 지어내지 말고,
reports/phoenix_july.csv는 Day 22에서 실행한 뒤 만들 수 있도록 남겨 둬.
파일 diff를 먼저 보여 주고 승인 후 저장해 줘.
```

확인: Day 21에서는 SQL 파일 변경만 생기고 결과 CSV는 없어야 합니다. DB 실행은 Day 22의 MCP 연결 후 같은 SQL을 요청해 진행합니다.

## 큰 일을 안심하고 맡기기–모드와 권한

### 예제 10 · [445~446쪽] 계획 모드

현재 Claude Code 세션에서 `/exit`한 뒤 새 세션을 계획 모드로 시작합니다.

```bash
claude --permission-mode plan
```

세션 안에서는 `Shift+Tab`을 누를 때마다 모드가 차례로 바뀝니다. 화면에 보이는 모드가 교재와 다르면 `/help`가 안내하는 현재 버전을 따르세요.

매번 옵션을 붙이는 대신, 교재 446쪽처럼 `.claude/settings.json`에 기본 모드를 적어 두면
이 폴더에서는 늘 계획 모드로 열립니다.

```json
{
  "permissions": {
    "defaultMode": "plan"
  }
}
```

저장소의 `settings.json`에는 **`defaultMode`를 넣지 않았습니다.** 이 폴더를 늘 계획 모드로 열면
Day 22 이후 MCP 조회까지 계획 모드에 걸리기 때문입니다. 위 설정을 직접 넣었다면 Day 22를
시작하기 전에 지우거나 세션에서 `Shift+Tab`으로 모드를 바꾸세요. 예제 11은 권한 규칙만 다룹니다.

다음 명령은 권한 확인을 모두 건너뛰므로 이 실습에서 실행하지 않습니다.

```bash
# 실행하지 않음
claude --dangerously-skip-permissions
```

### 예제 11 · [447쪽] 최소 권한 설정

대상: `.claude/settings.json`

```json
{
  "permissions": {
    "allow": ["Read"],
    "ask": ["Edit", "Write"],
    "deny": ["Bash(rm *)", "Read(./.env)", "Read(./.env.*)"]
  }
}
```

> **교재와 표기가 다릅니다.** 교재 447쪽의 `Bash(rm:*)`·`Read(**/.env)` 대신 현재
> Claude Code 문서 표기인 `Bash(rm *)`·`Read(./.env)`를 썼습니다. 교재의 `Read(**)`·
> `Write(**)`·`Edit(**)`도 도구 전체를 뜻하는 `Read`·`Write`·`Edit`로 적었습니다. 적용 후 `/permissions`로
> 실제 해석을 확인하고, 버전에 따라 다르면 그 화면 표기를 따르세요.
> 저장소의 `settings.json`에는 `*.sql.local`과 하위 폴더 `.env`도 차단에 더해 두었습니다.

저장소에는 이 설정이 준비되어 있습니다. 다음 프롬프트로 읽기만 확인합니다.

```text
.claude/settings.json을 읽고 허용, 확인 필요, 차단 작업을 구분해 줘.
설정이나 파일은 수정하지 마.
```

## 반복은 한 줄로–슬래시 명령

### 예제 12 · [448~449쪽] 세션 명령 확인

입력창에서 필요한 명령을 한 줄씩 실행합니다.

```text
/login
/help
/doctor
/context
/permissions
```

다음 명령도 이후 실습에서 사용합니다.

```text
/init
/clear
/compact
/rewind
/config
/mcp
/usage
/model
/resume
/exit
```

설치 버전에 따라 목록이 달라질 수 있으므로 `/help`에 표시되는 명령을 우선합니다.

## 막힐 때

| 증상 | 바로 확인할 것 |
|---|---|
| `claude: command not found` | 설치 후 새 터미널을 열고 `claude doctor`를 실행합니다. |
| 로그인 창이 열리지 않음 | 출력된 로그인 URL을 브라우저에 직접 열고 터미널로 돌아옵니다. |
| 편집 전에 승인을 묻지 않음 | `/permissions`와 `.claude/settings.json`을 확인합니다. 이전에 넓은 권한을 허용했다면 세션 권한도 줄입니다. |
| 파일을 찾지 못함 | 현재 위치가 `5주차/harmony-analysis`인지 확인합니다. |
| 교재 화면과 메뉴가 다름 | `claude --version`, `/help`, `/doctor`의 현재 출력 기준으로 진행합니다. |

## 완료 확인

- [ ] Claude Code 버전과 진단을 확인했다.
- [ ] 프로젝트 파일을 읽게 했다.
- [ ] 한 줄 변경의 diff를 보고 승인했다.
- [ ] 중지와 파일 되돌리기를 실행했다.
- [ ] 탐색→계획→실행 프롬프트를 구분했다.
- [ ] 최소 권한 설정을 확인했다.

다음: [Day 22–MCP로 데이터베이스 직접 연결](../day22/day22.md)
