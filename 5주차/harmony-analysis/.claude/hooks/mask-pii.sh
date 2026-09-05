#!/usr/bin/env bash
# .claude/hooks/mask-pii.sh
# (교재 472~473쪽) 실행 결과에서 이메일·전화번호를 가린 사본을 남기는 PostToolUse 훅

# 전제: jq 필요(없으면 마스킹 사본을 남길 수 없으므로 건너뜁니다).
command -v jq >/dev/null 2>&1 || { echo "[mask-pii] jq가 없어 마스킹 로그를 건너뜁니다." >&2; exit 0; }

payload=$(cat)

# 응답 객체 안의 모든 문자열을 순회해 가립니다. 객체 모양은 그대로 유지해야
# updatedToolOutput이 Bash와 MCP 결과 모두에서 적용됩니다.
masked=$(printf '%s' "$payload" | jq -c '
  def redact:
    gsub("[A-Za-z0-9._%+\\-]+@[A-Za-z0-9.\\-]+\\.[A-Za-z]{2,}"; "***@***")
    | gsub("01[0-9]-[0-9]{4}-[0-9]{4}"; "***-****-****");
  .tool_response | walk(if type == "string" then redact else . end)
')
# 가린 사본을 공유, 보관용 로그에 남긴다(폴더가 없으면 만든다).
# ※ 지면(473쪽)은 'mkdir -p .claude/logs'로 되어 있습니다. 이 상대 경로는 훅을 호출한
#   작업 디렉터리를 기준으로 하므로, 하위 폴더에서 실행되면 그곳에 .claude/logs/가
#   따로 생깁니다(.gitignore는 프로젝트 루트의 .claude/logs/만 막습니다).
#   결과 원문이 담기는 로그가 흩어지지 않도록 프로젝트 루트로 고정했습니다.
LOG_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}/.claude/logs"
mkdir -p "$LOG_DIR"
printf '%s\n' "$masked" >> "$LOG_DIR/masked-results.log"

# 마스킹 사본만 저장하는 데서 끝내지 않고 Claude가 보는 결과도 교체합니다.
jq -cn --argjson updated "$masked" '{
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    updatedToolOutput: $updated
  }
}'
exit 0
