param(
  [ValidateSet(21, 22, 23, 24, 25)]
  [int]$Day = 21,
  [ValidateSet('preflight', 'ready')]
  [string]$Phase = 'preflight'
)

$Failed = $false
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Join-Path (Split-Path -Parent $ScriptDir) 'harmony-analysis'
$ComposeFile = Join-Path $ScriptDir 'docker-compose.yml'
$ComposeEnv = Join-Path $ScriptDir '.env'
$ComposeArgs = @('-f', $ComposeFile)
if (Test-Path $ComposeEnv) {
  $ComposeArgs = @('--env-file', $ComposeEnv, '-f', $ComposeFile)
}

function Pass([string]$Message) { Write-Host "OK   $Message" -ForegroundColor Green }
function Warn([string]$Message) { Write-Host "WARN $Message" -ForegroundColor Yellow }
function Fail([string]$Message) { Write-Host "FAIL $Message" -ForegroundColor Red; $script:Failed = $true }
function Test-CompletedFile {
  param(
    [string]$Path,
    [string]$Label,
    [string[]]$RequiredTerms = @()
  )
  if (-not (Test-Path $Path)) {
    Fail "$Label 파일이 없습니다: $Path"
    return
  }
  $Text = Get-Content -Raw $Path
  if ($Text -match '(?i)TODO') {
    Fail "$Label 에 시작 파일의 TODO 주석이 그대로 있습니다. 해당 Day의 프롬프트로 본문을 채우세요."
    return
  }
  foreach ($Term in $RequiredTerms) {
    if ($Text.IndexOf($Term, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
      Fail "$Label 파일에 필수 항목 '$Term'이 없습니다."
      return
    }
  }
  Pass "$Label 완성본 확인"
}
function Has-Command([string]$Name) { return [bool](Get-Command $Name -ErrorAction SilentlyContinue) }
function Need-Command([string]$Name) {
  $Command = Get-Command $Name -ErrorAction SilentlyContinue
  if ($Command) { Pass "$Name`: $($Command.Source)" } else { Fail "$Name 명령을 찾지 못했습니다." }
}

Need-Command 'claude'

# git은 필수가 아닙니다. 각 Day 첫머리의 'git rev-parse'와 'git check-ignore'에만 쓰입니다.
if (Has-Command 'git') {
  Pass "git: $((Get-Command git).Source)"
} else {
  Warn "git이 없습니다. 각 Day 첫머리의 'git rev-parse --show-toplevel' 두 줄 대신"
  Warn "     압축을 푼 저장소 루트로 직접 이동하세요. 'git check-ignore' 확인은 건너뜁니다."
}

$Backend = 'none'

if ($Day -ge 22) {
  Need-Command 'node'
  Need-Command 'npm'

  if (Has-Command 'node') {
    $VersionText = (node --version).TrimStart('v')
    $Version = [version]$VersionText
    if ($Version -ge [version]'22.5.0') { Pass "Node.js $VersionText`: DBHub 요구 버전 충족" }
    else { Fail "Node.js 22.5.0 이상이 필요합니다. 현재: $VersionText" }
  }

  $DockerAvailable = $false
  if (Has-Command 'docker') {
    docker info *> $null
    $DockerInfoOk = $LASTEXITCODE -eq 0
    docker compose version *> $null
    $DockerComposeOk = $LASTEXITCODE -eq 0
    $DockerAvailable = $DockerInfoOk -and $DockerComposeOk
  }
  $LocalMysqlAvailable = Has-Command 'mysql'
  $RequestedBackend = if ($env:HARMONY_DB_BACKEND) { $env:HARMONY_DB_BACKEND } else { 'auto' }

  switch ($RequestedBackend) {
    'docker' {
      if ($DockerAvailable) { $Backend = 'docker' }
      else { Fail 'Docker 엔진과 Compose를 사용할 수 없습니다.' }
    }
    'local' {
      if ($LocalMysqlAvailable) { $Backend = 'local' }
      else { Fail 'mysql 클라이언트를 찾지 못했습니다.' }
    }
    'auto' {
      $DockerServiceRunning = $false
      if ($Phase -eq 'ready' -and $DockerAvailable) {
        $Services = docker compose @ComposeArgs ps --status running --services 2>$null
        $DockerServiceRunning = $Services -contains 'harmony-mysql'
      }
      if ($DockerServiceRunning) { $Backend = 'docker' }
      elseif ($LocalMysqlAvailable) { $Backend = 'local' }
      elseif ($DockerAvailable) { $Backend = 'docker' }
      else { Fail 'Docker 또는 로컬 mysql 중 하나가 필요합니다.' }
    }
    default { Fail 'HARMONY_DB_BACKEND는 auto, docker, local 중 하나여야 합니다.' }
  }

  if ($Backend -ne 'none') { Pass "데이터베이스 실행 방식: $Backend" }
  if ($Phase -eq 'preflight') {
    if ($env:DB_PASSWORD) { Pass 'DB_PASSWORD 설정됨(값은 표시하지 않음)' }
    else { Warn 'DB_PASSWORD는 계정을 만든 뒤 harmony-analysis/.env에 설정합니다.' }
  }
}

function Invoke-DbQuery([string]$Query) {
  if ($Backend -eq 'docker') {
    $Previous = $env:MYSQL_PWD
    $env:MYSQL_PWD = $env:DB_PASSWORD
    try {
      return docker compose @ComposeArgs exec -T -e MYSQL_PWD harmony-mysql `
        mysql -h 127.0.0.1 -uclaude_readonly -N -B harmony_db -e $Query 2>$null
    } finally {
      $env:MYSQL_PWD = $Previous
    }
  }
  $Previous = $env:MYSQL_PWD
  $env:MYSQL_PWD = $env:DB_PASSWORD
  try {
    return mysql -h $(if ($env:HARMONY_DB_HOST) { $env:HARMONY_DB_HOST } else { '127.0.0.1' }) `
      -P $(if ($env:HARMONY_DB_PORT) { $env:HARMONY_DB_PORT } else { '3306' }) `
      -uclaude_readonly -N -B harmony_db -e $Query 2>$null
  } finally {
    $env:MYSQL_PWD = $Previous
  }
}

if ($Phase -eq 'ready' -and $Day -ge 22) {
  if ($env:DB_PASSWORD) { Pass 'DB_PASSWORD 설정됨(값은 표시하지 않음)' }
  else { Fail 'DB_PASSWORD가 비어 있습니다. harmony-analysis/.env를 적용하세요.' }

  $McpFile = Join-Path $ProjectDir '.mcp.json'
  if (Test-Path $McpFile) {
    try {
      $Mcp = Get-Content -Raw $McpFile | ConvertFrom-Json
      Pass '.mcp.json JSON 정상'
      $Server = $Mcp.mcpServers.harmony_db
      $ArgsText = @($Server.args) -join ' '
      if ($Server.command -eq 'cmd' -and
          $ArgsText -match '(^| )npx( |$)' -and
          $ArgsText -match '@bytebase/dbhub@1\.2\.3' -and
          $Server.env.DB_TYPE -eq 'mysql' -and
          $Server.env.DB_USER -eq 'claude_readonly' -and
          $Server.env.DB_PASSWORD -eq '${DB_PASSWORD}' -and
          $Server.env.DB_NAME -eq 'harmony_db') {
        Pass 'Windows cmd용 DBHub·읽기 전용 계정 설정 확인'
      } else {
        Fail '.mcp.json이 Windows용 견본과 다르거나 평문 비밀번호가 들어 있습니다.'
      }
    }
    catch { Fail '.mcp.json JSON 문법 오류' }
  } else { Fail '.mcp.json이 없습니다. Day 22 예제대로 복사하세요.' }

  if ($Backend -eq 'docker') {
    $Services = docker compose @ComposeArgs ps --status running --services 2>$null
    if ($Services -contains 'harmony-mysql') { Pass 'harmony-mysql 실행 중' }
    else { Fail 'harmony-mysql이 실행 중이 아닙니다.' }

    $Endpoint = (docker compose @ComposeArgs port harmony-mysql 3306 2>$null | Out-String).Trim()
    $PublishedPort = if ($Endpoint) { $Endpoint.Split(':')[-1] } else { '' }
    $ExpectedPort = if ($env:HARMONY_DB_PORT) { $env:HARMONY_DB_PORT } else { '3306' }
    if ($PublishedPort -eq $ExpectedPort) {
      Pass "MCP 환경 변수와 Docker 공개 포트 일치: $ExpectedPort"
    } else {
      Fail "Docker 공개 포트($PublishedPort)와 HARMONY_DB_PORT($ExpectedPort)가 다릅니다."
    }
  }

  if ($env:DB_PASSWORD) {
    $CountsSql = "SELECT CONCAT_WS(',',(SELECT COUNT(*) FROM artists),(SELECT COUNT(*) FROM fans),(SELECT COUNT(*) FROM tracks),(SELECT COUNT(*) FROM streaming),(SELECT COUNT(*) FROM orders),(SELECT COUNT(*) FROM subscription_history),(SELECT COUNT(*) FROM fan_activities));"
    $Counts = (Invoke-DbQuery $CountsSql | Out-String).Trim()
    if ($LASTEXITCODE -eq 0 -and $Counts -eq '15,111,104,375,234,100,140') {
      Pass "HARMONY 핵심 테이블 행 수 일치: $Counts"
    } else { Fail "HARMONY DB 접속 또는 행 수 검증 실패: $Counts" }

    $Grants = (Invoke-DbQuery 'SHOW GRANTS;' | Out-String)
    if ($LASTEXITCODE -eq 0 -and $Grants -match 'SELECT' -and $Grants -notmatch 'ALL PRIVILEGES|INSERT|UPDATE|DELETE|DROP') {
      Pass 'claude_readonly: SELECT 전용 권한 확인'
    } else { Fail 'claude_readonly 권한을 확인하세요.' }

    Invoke-DbQuery 'SELECT email FROM fans LIMIT 1;' *> $null
    if ($LASTEXITCODE -eq 0) { Fail 'claude_readonly가 fans.email을 읽을 수 있습니다.' }
    else { Pass 'fans.email 데이터베이스 권한 차단 확인' }
  }
}

if ($Phase -eq 'ready' -and $Day -ge 23) {
  Test-CompletedFile -Path (Join-Path $ProjectDir 'CLAUDE.md') `
    -Label 'CLAUDE.md' `
    -RequiredTerms @('2026-09-03', 'churned', 'VIP', 'email', '팩트')
  $FanSkill = Join-Path $ProjectDir '.claude/skills/fan-churn-analysis/SKILL.md'
  Test-CompletedFile -Path $FanSkill -Label 'fan-churn-analysis Skill' `
    -RequiredTerms @('churned', 'email')

  $SkillsDir = Join-Path $ProjectDir '.claude/skills'
  claude plugin validate --strict $SkillsDir *> $null
  if ($LASTEXITCODE -eq 0) { Pass 'Skill 문법 검사 통과' }
  else { Fail "Skill 문법 오류입니다: claude plugin validate --strict '$SkillsDir'" }
}

if ($Day -ge 24) {
  Fail 'Day 24~25의 교재 훅은 Bash 실습입니다. Windows에서는 WSL 터미널에서 check-environment.sh를 실행하세요.'
}

if ($Failed) {
  Write-Host "$Phase 점검 실패 항목을 고친 뒤 다시 실행하세요." -ForegroundColor Red
  exit 1
}

if ($Phase -eq 'preflight') {
  Write-Host "Day $Day 사전 도구 점검을 통과했습니다. 아직 DB·계정·MCP 준비 완료를 뜻하지 않습니다."
} else {
  Write-Host "Day $Day 실습 준비 검증을 통과했습니다."
}
