#!/usr/bin/env bash
# .claude/hooks/mark-domain-dirty.sh
#
# PostToolUse hook (Edit|Write) — touches a state file when Domain layer is modified.
# Paired with .claude/hooks/enforce-tests-on-stop.sh to enforce "test green before exit".
#
# Requires: bash, jq

set -euo pipefail

input=$(cat)
tool=$(echo "$input" | jq -r '.tool_name // empty')
file=$(echo "$input" | jq -r '.tool_input.file_path // empty')

# Only Domain layer files
case "$file" in
  *"/contexts/"*"/domain/"*) ;;
  *) exit 0 ;;
esac

root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
state_dir="$root/.claude/state"
mkdir -p "$state_dir"
touch "$state_dir/domain-dirty"

# Optional: scan for "tests are red" hint by checking pytest exit code marker.
# (We don't run pytest here — too slow. We rely on a separate hook or manual run
# to write/remove last-test-red. For MVP, the enforce hook only checks if BOTH
# domain-dirty AND last-test-red exist.)

exit 0
