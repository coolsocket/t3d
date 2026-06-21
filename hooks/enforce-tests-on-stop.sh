#!/usr/bin/env bash
# .claude/hooks/enforce-tests-on-stop.sh
#
# Stop hook — enforces "tests must be green if Domain was touched this session".
#
# Trigger condition (all must be true):
#   1. Stop event firing
#   2. State file .claude/state/domain-dirty exists (set by check-domain-purity.sh
#      when a Domain layer file is edited; cleared on green test run)
#   3. Last `make test` exited non-zero (state file .claude/state/last-test-red exists)
#
# When triggered: blocks Stop with a message asking Claude to run tests + fix red.
#
# Otherwise: silent pass-through.
#
# Requires: bash, jq

set -euo pipefail

input=$(cat)
event=$(echo "$input" | jq -r '.hook_event_name // empty')

# Only act on Stop
if [ "$event" != "Stop" ]; then
  exit 0
fi

# Find project root from CLAUDE_PROJECT_DIR (set by Claude Code)
root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
state_dir="$root/.claude/state"
dirty_file="$state_dir/domain-dirty"
red_file="$state_dir/last-test-red"

if [ -f "$dirty_file" ] && [ -f "$red_file" ]; then
  reason="🛑 Domain 层在本 session 被修改过，但最近一次测试是红的。"
  reason+="\n\n请在结束前跑通 \`make test\` 让所有测试转绿。"
  reason+="\n违反 DDD+TDD 铁律的红→绿→重构循环 —— 见 CLAUDE.md。"
  reason+="\n\n如要绕过（极不推荐），清理状态：rm $dirty_file $red_file"
  jq -n --arg r "$reason" '{
    decision: "block",
    reason: $r
  }'
  exit 0
fi

# Allow Stop
exit 0
