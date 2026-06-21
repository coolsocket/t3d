#!/usr/bin/env bash
# .claude/hooks/check-domain-purity.sh
# PreToolUse hook (Edit|Write) — 两道硬拦截：
#   A) Domain 层禁用外部框架/库 import
#   B) 跨 context 调用只允许 contexts.<X>.application.api
#
# Requires: bash, jq, grep
# Input (stdin): PreToolUse JSON payload
# Output (stdout): deny 决策 JSON（或静默 = 放行）

set -euo pipefail

input=$(cat)
tool=$(echo "$input" | jq -r '.tool_name // empty')
file=$(echo "$input" | jq -r '.tool_input.file_path // empty')

# 不在 contexts/ 下的 .py 文件直接放行
case "$file" in
  *"/contexts/"*.py) ;;
  *) exit 0 ;;
esac

# 读出本次写入/编辑的内容（Write 用 .content，Edit 用 .new_string）
content=$(echo "$input" | jq -r '.tool_input.content // .tool_input.new_string // empty')
[ -z "$content" ] && exit 0

# ---------- Check A: Domain 层禁用 import ----------
if [[ "$file" == *"/contexts/"*"/domain/"* ]]; then
  FORBIDDEN_RE='^[[:space:]]*(import|from)[[:space:]]+(fastapi|flask|django|starlette|aiohttp|httpx|requests|urllib3?|sqlalchemy|peewee|tortoise|pymongo|redis|asyncpg|psycopg|celery|rq|kombu|boto3|google\.cloud|litellm|openai|anthropic)\b'
  match=$(echo "$content" | grep -nE "$FORBIDDEN_RE" | head -5 || true)
  if [ -n "$match" ]; then
    jq -n --arg f "$file" --arg m "$match" '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: ("🚫 Domain 层禁止外部框架/库依赖。\n文件: " + $f + "\n违规 import:\n" + $m + "\n\n修复方案:\n1. 在 contexts/<ctx>/domain/port/ 声明抽象接口（Port）\n2. 在 contexts/<ctx>/infrastructure/ 实现 Port（这里可以用 sqlalchemy/httpx 等）\n3. Application 层通过 Port 调用 infrastructure 实现")
      }
    }'
    exit 0
  fi
fi

# ---------- Check B: 跨 context 调用 ----------
# 用 bash 参数展开提取本文件所属 context 名
tmp_path="${file#*/contexts/}"
current_ctx="${tmp_path%%/*}"

if [ -n "$current_ctx" ]; then
  CROSS_RE='^[[:space:]]*(from|import)[[:space:]]+contexts\.[a-zA-Z_][a-zA-Z0-9_]*'
  violations=""
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    # 用 grep 提取被引用的 context 名（contexts.XXX 中的 XXX）
    other=$(echo "$line" | grep -oE 'contexts\.[a-zA-Z_][a-zA-Z0-9_]*' | head -1 | cut -d. -f2)
    [ -z "$other" ] && continue
    # 同 context / shared_kernel 放行
    if [ "$other" = "$current_ctx" ] || [ "$other" = "_shared_kernel" ]; then
      continue
    fi
    # 必须是 `from contexts.<other>.application.api ...`（精确匹配 application.api 路径）
    if ! echo "$line" | grep -qE "^[[:space:]]*from[[:space:]]+contexts\.${other}\.application\.api([[:space:]]|$|\.)"; then
      violations="${violations}${line}"$'\n'
    fi
  done < <(echo "$content" | grep -E "$CROSS_RE" || true)

  if [ -n "$violations" ]; then
    jq -n --arg f "$file" --arg v "$violations" '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: ("🚫 跨 context 调用违规。只能 import `contexts.<other>.application.api`，不能 import 任何其他内部模块。\n文件: " + $f + "\n违规 import:\n" + $v + "\n修复方案:\n- 同步只读：from contexts.<other>.application.api import OtherAPI\n- 异步写：本 context 发事件，对方在 ui/event_consumer/ 订阅\n- 共享值对象：from contexts._shared_kernel import ...")
      }
    }'
    exit 0
  fi
fi

exit 0
