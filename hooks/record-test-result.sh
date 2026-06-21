#!/usr/bin/env bash
# Plugin-shipped PostToolUse hook (Bash matcher).
#
# When the user (or Claude) runs `pytest` / `make test` / `make check`, capture
# the exit code and write/remove ${CLAUDE_PROJECT_DIR}/.claude/state/last-test-red.
#
# This pairs with enforce-tests-on-stop.sh: if Domain was edited this session
# AND the last test run was red, Stop is blocked.
#
# Trust strategy: ONLY trust exit_code. The previous version grepped stdout for
# "failed" which produced false positives (e.g. a passing test named
# `test_does_not_silently_skip_failed_payloads`). Exit code is authoritative.
#
# Requires: bash, jq

set -euo pipefail

input=$(cat)
tool=$(echo "$input" | jq -r '.tool_name // empty')
[ "$tool" != "Bash" ] && exit 0

command=$(echo "$input" | jq -r '.tool_input.command // empty')
case "$command" in
  *pytest*|*"make test"*|*"make check"*) ;;
  *) exit 0 ;;
esac

exit_code=$(echo "$input" | jq -r '.tool_response.exit_code // empty')

root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
state_dir="$root/.claude/state"
mkdir -p "$state_dir"

# Authoritative: only exit code decides red/green.
# If exit_code missing (rare — pre-hook race), be conservative and assume red.
if [ -z "$exit_code" ] || [ "$exit_code" != "0" ]; then
  touch "$state_dir/last-test-red"
else
  rm -f "$state_dir/last-test-red" "$state_dir/domain-dirty"
fi

exit 0
