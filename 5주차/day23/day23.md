# Day 23 “같은 설명을 매번 해야 하나요?”–CLAUDE.md와 Skills

> 교재 458~468쪽과 함께 사용합니다. `CLAUDE.md`와 Skill은 완성본을 제공하지 않으며, 아래 프롬프트로 직접 만든 뒤 SQL과 기대값을 검산합니다.

새 터미널을 열었다면 Day 22의 `DB_PASSWORD`와 포트 환경 변수를 다시 적용해야 합니다. macOS·Linux·WSL은 로컬 `.env`를 불러온 뒤 Day 22 완료 상태를 검사합니다.

> ZIP으로 내려받아 git이 없다면 `git rev-parse` 두 줄 대신 압축을 푼 저장소 루트의
> `5주차/harmony-analysis`로 직접 이동하세요. `git check-ignore` 확인도 건너뛰면 됩니다.

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT/5주차/harmony-analysis"
set -a
. ./.env
set +a
../환경셋업/check-environment.sh 22 ready
claude
```

Windows PowerShell도 마찬가지입니다. Day 22 예제 2처럼 새 터미널에 `DB_PASSWORD`를 다시 설정하고, 포트를 바꿨다면 `HARMONY_DB_PORT`도 함께 지정한 뒤 실행하세요.

```powershell
$RepoRoot = git rev-parse --show-toplevel
Set-Location (Join-Path $RepoRoot '5주차/harmony-analysis')
$DbSecret = Read-Host 'claude_readonly 비밀번호' -AsSecureString
$env:DB_PASSWORD = (New-Object System.Net.NetworkCredential('', $DbSecret)).Password
Remove-Variable DbSecret
powershell -ExecutionPolicy Bypass -File ../환경셋업/check-environment.ps1 -Day 22 -Phase ready
claude
```

## CLAUDE.md–팀의 정의를 한 번 적어 두면 매번 적용된다

### 예제 1 · [458~459쪽] 프로젝트 메모리 만들기

Claude Code 입력창에서 실행합니다.

```text
/init
```

`CLAUDE.md`가 이미 있으면 새로 덮어쓰지 말고 내용을 읽은 뒤 다음 프롬프트로 수정합니다. 생성에 실패했을 때 사용할 뼈대는 `CLAUDE.md.example`에 있습니다.

로드된 프로젝트·개인 메모리를 확인합니다.

```text
/memory
```

확인: 목록에 프로젝트 루트의 `CLAUDE.md`가 보여야 합니다.

```text
이 프로젝트의 CLAUDE.md를 다음 기준으로 완성해 줘.
- 실습 기준일과 시간대: 2026-09-03, Asia/Seoul
- 활성 팬: 기준일을 포함한 최근 7일에 streaming 기록이 있거나 현재 subscription_history.status='active'인 팬
- 이탈 팬: 현재 subscription_history.status='churned'인 팬
- VIP: fans.membership_level='VIP'인 팬
- email 칼럼은 SELECT 결과와 리포트에 포함 금지
- INSERT, UPDATE, DELETE, DROP 실행 금지
- 보고 순서: 팩트→의미→제안
- 팀 용어는 @docs/회사-용어.md를 참고
- 실무 요청에 기준일이 없으면 임의로 정하지 말고 먼저 확인
200줄 이내의 짧고 검증 가능한 규칙으로 쓰고, 수정 전에 diff를 보여 줘.
```

직접 작성할 때의 구조

```markdown
# HARMONY 프로젝트 메모리

@docs/회사-용어.md

## 분석 기준

- 실습 기준일: 2026-09-03
- 시간대: Asia/Seoul
- 운영 분석에서 기준일이 없으면 추측하지 말고 사용자에게 확인

## 비즈니스 정의

<!-- 활성 팬, 이탈 팬, VIP의 SQL 판정 조건 -->

## 금지사항

<!-- 개인정보 출력과 데이터 변경 제한 -->

## 보고 톤

<!-- 팩트→의미→제안, 기간과 단위, 추정 표현 -->
```

### 예제 2 · [459~460쪽] 규칙 반영 확인

```text
우리 팀 기준의 활성 팬 정의를 한 문장으로 설명해 줘.
파일을 수정하거나 SQL을 실행하지 마.
```

```text
팬 활동 리포트에 email도 넣어 줘.
```

확인: 첫 답변에는 `최근 7일 streaming 또는 status='active'`가 들어가고, 두 번째 요청에서는 `email`을 제외해야 합니다.

### 예제 3 · [460~461쪽] 모호한 규칙 점검

```text
현재 CLAUDE.md에서 모호하거나 검증할 수 없는 규칙을 찾아 줘.
각 규칙을 SQL 조건이나 확인 가능한 행동으로 바꾼 문장을 제안하되 아직 수정하지 마.
```

데이터 변경 제한은 Day 22의 DB 권한이 담당하므로, 규칙을 고쳐도 그 방어선은 그대로입니다.

### 예제 4 · [458~459쪽] 개인 메모리와 외부 문서 연결

Claude Code 세션은 그대로 두고 새 터미널 탭을 엽니다. 프로젝트 폴더에서 개인 메모리를 추적하지 않는 파일로 복사한 뒤 Claude Code 탭으로 돌아옵니다.

```bash
# macOS·Linux·WSL
cp -n CLAUDE.local.md.example CLAUDE.local.md
git check-ignore CLAUDE.local.md
```

```powershell
# Windows PowerShell
if (-not (Test-Path CLAUDE.local.md)) {
  Copy-Item CLAUDE.local.md.example CLAUDE.local.md
}
git check-ignore CLAUDE.local.md
```

`CLAUDE.md`에는 다음 한 줄을 넣습니다.

```markdown
팀 용어와 기준일은 @docs/회사-용어.md를 참고합니다.
```

새 세션에서 `/memory`를 실행해 `CLAUDE.md`와 `CLAUDE.local.md`가 모두 로드됐는지 확인합니다. 비밀번호는 두 파일에 적지 않습니다.

## Skills–반복하는 일을 매뉴얼로 만들기

### 예제 5 · [462쪽] Skill 기본 형식

경로: `.claude/skills/<skill-name>/SKILL.md`

```markdown
---
name: skill-name
description: 무엇을 하고 언제 사용하는지 구체적으로 작성
---

# 스킬 제목

## 절차

<!-- 실행 순서 -->

## 검증

<!-- 결과 확인 기준 -->
```

### 예제 6 · [462~464쪽] 팬 이탈 분석 SQL

1단계, 구독 상태별 집계

```sql
SELECT status, COUNT(DISTINCT fan_id) AS fan_count
FROM subscription_history
GROUP BY status
ORDER BY fan_count DESC;
```

확인: `active 85`, `churned 12`, `reactivated 3`.

2단계, 이탈 팬 명단

```sql
SELECT f.fan_id,
  f.fan_name,
  sh.end_date AS churned_date
FROM fans f
JOIN subscription_history sh
  ON f.fan_id = sh.fan_id
  AND sh.status = 'churned'
ORDER BY sh.end_date
LIMIT 5;
```

확인: 다음 5행이 나와야 합니다.

```text
14 | Anna Lee      | 2025-03-15
55 | 황지수         | 2025-04-20
45 | 문지혜         | 2025-05-28
98 | Miguel Santos | 2025-05-30
34 | Linda Zhang   | 2025-06-18
```

### 예제 7 · [464쪽] 팬 이탈 Skill 만들기

새 터미널 탭을 열어 프로젝트 폴더로 갑니다. 자동으로 호출되지 않는 시작 파일을 실제 Skill 이름으로 복사한 뒤, Claude Code 탭으로 돌아옵니다.

```bash
# macOS·Linux·WSL
cp -n .claude/skills/fan-churn-analysis/SKILL.md.example \
   .claude/skills/fan-churn-analysis/SKILL.md
git check-ignore .claude/skills/fan-churn-analysis/SKILL.md
```

```powershell
# Windows PowerShell
if (-not (Test-Path .claude/skills/fan-churn-analysis/SKILL.md)) {
  Copy-Item .claude/skills/fan-churn-analysis/SKILL.md.example `
    .claude/skills/fan-churn-analysis/SKILL.md
}
git check-ignore .claude/skills/fan-churn-analysis/SKILL.md
```

복사했다면 다음 프롬프트로 `TODO` 본문을 완성합니다.

```text
팬 이탈 분석 Skill을 만들어 줘.
파일은 .claude/skills/fan-churn-analysis/SKILL.md야.
description에는 이탈/구독 취소/해지 요청 시 사용한다는 표현을 넣어 줘.
본문은 사용 시기, 관련 테이블, 비즈니스 정의,
1단계 구독 상태별 집계, 2단계 이탈 팬 명단, 검증 기준으로 구성해 줘.
이 데이터셋은 팬별 구독 행이 하나라는 전제에서 이탈은 subscription_history.status='churned' 기준이고 email은 조회하지 마.
SQL은 바로 위 교재 예제와 같은 칼럼·정렬을 사용해.
파일을 쓰기 전에 완성안을 보여 줘.
```

### 예제 8 · [464~465쪽] 자동 호출 검증

새 세션에서 이름을 말하지 않고 요청합니다.

```text
팬 이탈 분석해 줘.
실행 SQL과 검증 결과도 보여 줘.
```

확인: Skill을 선택하고 `상태별 집계→이탈 명단→검증` 순서로 실행하며, churned는 12이고 email은 없어야 합니다. **2단계 명단은 예시를 간결히 보이려 `LIMIT 5`를 두었으므로 5명만 나옵니다.** 전체 이탈 팬 수(12명)는 1단계 집계의 `churned` 값과 일치해야 합니다. 호출되지 않으면 `description`에 `이탈`, `구독 취소`, `해지`가 있는지 확인합니다.

## 어떻게 골라 꺼내나?–도서관에서 책 고르듯

### 예제 9 · [465~466쪽] 자동, 직접, 잠금 호출

자동 호출

```text
팬 이탈 분석해 줘.
```

직접 호출

```text
/fan-churn-analysis
```

외부 발송처럼 되돌리기 어려운 Skill의 자동 호출을 막는 머리말

```markdown
---
name: send-churn-report
description: 검증된 이탈 분석 결과를 경영진에게 이메일로 발송
disable-model-invocation: true
---
```

이 예제는 호출 제한 형식만 확인합니다. 메일 도구를 연결하거나 실제 발송하지 않습니다.

## Skills 더 잘 만들기–설명, 호출, 구성, 그리고 가볍게

### 예제 10 · [467쪽] 좋은 스킬의 구성 다섯 가지

교재 467쪽의 다섯 가지를 갖춘 완성형입니다. 예제 5의 최소 형식 대신 이 틀로 옮겨 적으면 됩니다.

```markdown
---
name: fan-churn-analysis
description: 구독 취소 팬 식별과 이탈 신호 분석. 이탈/구독 취소/해지 분석 요청 시 사용
---

# 팬 이탈 분석

## 사용 시기

- 팬 이탈 원인·트렌드 분석, 위험 신호 팬 식별

## 관련 테이블

- fans / subscription_history / fan_activities

## 비즈니스 정의

- 이탈(Churned): subscription_history.status='churned'

## 금지사항

- email 칼럼은 조회하지 않는다

## 표준 분석 절차

1단계 구독 상태별 집계 → 2단계 이탈 명단(각 쿼리와 기대 결과)
```

`금지사항`의 `email` 한 줄은 각 Day 끝의 `ready` 검사가 확인하는 항목입니다. 빼면 Skill이
완성되지 않은 것으로 판정됩니다.

본문이 길어지면 상세 자료를 `references/`로 옮깁니다. 폴더 구조는 다음과 같습니다.

```text
.claude/skills/fan-churn-analysis/
├── SKILL.md          # 절차 중심으로 짧게
└── references/       # 스키마 전체, 긴 정책 문서 등
```

### 예제 11 · [466~467쪽] 재사용 값과 실행 시점 값

호출할 때 받은 대상을 쓰는 자리 표시자

```markdown
분석 대상 아티스트: $ARGUMENTS
```

호출 시점에 오늘 날짜를 가져오는 예제

```markdown
## 수집 시점

마지막 갱신: !`date +%Y-%m-%d`
```

`!` 명령은 실제 셸 실행이므로 자신이 작성하고 검토한 Skill에서만 사용합니다. Windows 네이티브 PowerShell용 Skill은 `Get-Date -Format yyyy-MM-dd`로 바꿉니다.

### 예제 12 · [468쪽] Skill 생성 요청

```text
.claude/skills/fan-churn-analysis/SKILL.md를 검토하고 완성해 줘.
실습 기준일 2026-09-03을 포함한 최근 30일 동안
fan_activities에서 로그인이 없는데 구독은 유지 중인 팬을 추리고,
subscription_history로 상태를 확인하는 절차도 추가해.
각 단계에 실행 SQL, 출력 칼럼, 검증 기준을 넣되 email은 제외해.
수정 전에 계획과 diff를 먼저 보여 줘.
```

교재 468쪽의 **`skill-creator`**를 쓰려면 플러그인 마켓플레이스에서 설치한 뒤 `/help`로 이름을 확인하세요. 없어도 위 프롬프트로 같은 실습을 진행할 수 있습니다.

## 막힐 때

| 증상 | 바로 확인할 것 |
|---|---|
| `/init`이 파일을 만들지 않음 | 기존 `CLAUDE.md`가 있는지 확인합니다. 있으면 덮어쓰지 말고 수정 프롬프트를 사용합니다. |
| 새 규칙이 반영되지 않음 | `CLAUDE.md`가 프로젝트 루트에 있는지 확인하고 새 세션을 엽니다. |
| Skill이 목록에 없음 | 경로가 `.claude/skills/<이름>/SKILL.md`이고 파일명이 대문자 `SKILL.md`인지 확인합니다. |
| Skill이 자동 호출되지 않음 | YAML 머리말 문법과 `description`의 실제 요청 표현을 확인합니다. |
| 결과가 `85/12/3`과 다름 | `COUNT(DISTINCT fan_id)`와 `status` 조건, `harmony_db` 데이터 적재 상태를 확인합니다. |

## 완료 확인

Claude Code에서 `/exit`한 뒤 검사합니다.

`.example` 시작 파일에는 채울 자리를 `<!-- TODO: ... -->` 주석으로 표시해 두었습니다.
본문을 쓰면서 그 주석을 지우면 되고, 검사는 **그 자리가 실제로 채워졌는지**를 봅니다.
주석이 그대로 남아 있으면 "복사만 하고 아직 완성하지 않았다"는 뜻이라 실패로 표시합니다.

```bash
# macOS·Linux·WSL
../환경셋업/check-environment.sh 23 ready
```

```powershell
# Windows PowerShell
powershell -ExecutionPolicy Bypass -File ../환경셋업/check-environment.ps1 -Day 23 -Phase ready
```

- [ ] `CLAUDE.md`를 직접 만들고 세 규칙 영역을 채웠다.
- [ ] 규칙 반영 프롬프트 두 개를 통과했다.
- [ ] 팬 이탈 Skill을 프롬프트로 완성했다.
- [ ] 상태 집계 `85/12/3`과 이탈 명단을 검산했다.
- [ ] 자동 호출과 직접 호출을 확인했다.

다음: [Day 24–Hooks와 서브에이전트](../day24/day24.md)
