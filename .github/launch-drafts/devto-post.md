---
title: How I stopped Claude from quietly breaking my DDD layering — a 5-hook recipe
published: false
description: A working set of Claude Code hooks that deny external imports in Domain layers and cross-context internal imports — at edit time, before the bad code even lands.
tags: claudecode, ddd, tdd, python
cover_image: ""
canonical_url: ""
---

> **TL;DR** — Claude Code's PreToolUse hooks let you reject edits before they're applied. Five small bash scripts give a Python project DDD layer purity and TDD red-green discipline without a single line of "please don't do this" in your CLAUDE.md.

## The problem

I was building a small Claude Code usage tracker. Five bounded contexts (DDD), strict layering inside each (`domain` / `application` / `infrastructure` / `ui`), tests-first for every invariant. Standard stuff.

Claude knew the rules. CLAUDE.md spelled them out. The model nodded, agreed, then **quietly slipped `import fastapi` into a Domain file** when a refactor felt convenient. Or `from contexts.pricing.domain import PriceTable` from inside the analytics context, where it should have gone through `application.api` instead. Or skipped the failing-test-first step when the fix was "obvious".

These weren't malicious — they were the path of least resistance. The model wanted to ship.

Pleading at the system-prompt level didn't help. The rules drifted under deadline pressure. I needed **enforcement at edit time**, not a reminder in the context window.

## The hooks

Claude Code ships a hook system. Each hook is a shell script that receives a JSON event on stdin and decides whether the tool call proceeds. If it returns `permissionDecision: "deny"`, the edit just doesn't happen — and Claude sees a structured reason and adjusts.

Here are the five I ended up with:

### 1. `check-domain-purity.sh` (PreToolUse on Edit/Write)

Two checks fused into one hook:

```bash
#!/usr/bin/env bash
set -euo pipefail
input=$(cat)
tool=$(echo "$input" | jq -r '.tool_name // empty')
[ "$tool" != "Edit" ] && [ "$tool" != "Write" ] && exit 0

file=$(echo "$input" | jq -r '.tool_input.file_path // empty')
new=$(echo "$input" | jq -r '.tool_input.new_string // .tool_input.content // empty')

# Domain layer? No external frameworks.
if echo "$file" | grep -qE '/contexts/[^/]+/domain/'; then
  banned=$(echo "$new" | grep -nE '^(from|import) (fastapi|sqlalchemy|httpx|requests|django|flask|pymongo|redis|boto3|google\.cloud|litellm|openai|anthropic)' || true)
  if [ -n "$banned" ]; then
    jq -n --arg f "$file" --arg b "$banned" '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: "🚫 Domain 层禁止外部框架依赖.\n文件: \($f)\n违规 import:\n\($b)\n\n修复:\n1. 在 contexts/<ctx>/domain/port/ 声明 Port 接口\n2. 在 contexts/<ctx>/infrastructure/ 实现\n3. Application 层通过 Port 调用"
      }
    }'
    exit 0
  fi
fi

# Cross-context internal imports? Only application.api or _shared_kernel allowed.
if echo "$file" | grep -qE '/contexts/'; then
  src_ctx=$(echo "$file" | sed -E 's|^.*contexts/([^/]+)/.*|\1|')
  bad=$(echo "$new" | grep -nE "^(from|import) contexts\." \
    | grep -vE "^[0-9]+:(from|import) contexts\._shared_kernel" \
    | grep -vE "^[0-9]+:(from|import) contexts\.${src_ctx}\." \
    | grep -vE "^[0-9]+:from contexts\.[a-z_]+\.application\.api" || true)
  if [ -n "$bad" ]; then
    jq -n --arg f "$file" --arg b "$bad" '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: "🚫 跨 context 调用违规.\n文件: \($f)\n违规 import:\n\($b)\n\n修复:\n- 同步: from contexts.<other>.application.api import OtherAPI\n- 异步: 发事件, 对方在 ui/event_consumer/ 订阅"
      }
    }'
    exit 0
  fi
fi

exit 0
```

The `permissionDecisionReason` is the key — it tells Claude *exactly* what to do instead. Within one or two retries, the model learns and stops trying that pattern.

### 2. `mark-domain-dirty.sh` (PostToolUse on Edit/Write)

Touches `.claude/state/domain-dirty` whenever a Domain file gets edited. State, not a side effect.

```bash
file=$(echo "$input" | jq -r '.tool_input.file_path // empty')
case "$file" in
  */contexts/*/domain/*) mkdir -p .claude/state && touch .claude/state/domain-dirty ;;
esac
```

### 3. `record-test-result.sh` (PostToolUse on Bash)

When Claude runs `pytest` or `make test`, capture the exit code and write/clear `.claude/state/last-test-red`. Trust only the exit code — grepping stdout for "failed" produces false positives on test names like `test_does_not_silently_skip_failed_payloads` (ask me how I know).

```bash
cmd=$(echo "$input" | jq -r '.tool_input.command // empty')
case "$cmd" in *pytest*|*"make test"*) ;; *) exit 0 ;; esac
ec=$(echo "$input" | jq -r '.tool_response.exit_code // empty')
mkdir -p .claude/state
if [ "$ec" = "0" ]; then rm -f .claude/state/last-test-red .claude/state/domain-dirty
else touch .claude/state/last-test-red; fi
```

### 4. `enforce-tests-on-stop.sh` (Stop hook)

If Domain was touched AND tests are red, block Stop:

```bash
if [ -f .claude/state/domain-dirty ] && [ -f .claude/state/last-test-red ]; then
  jq -n '{decision: "block", reason: "🛑 Domain edited this session but tests are red. Run make test to green before stopping."}'
fi
```

This is the closing of the loop. The model can't "just leave it" mid-refactor — it has to bring tests back to green.

### 5. `classify-prompt.sh` (UserPromptSubmit)

Pattern-matches the user prompt for `spike` / `bug` / `feature` keywords and injects a workflow reminder back into the context. Tiny ceremony, big effect: tells Claude "you're in feature mode, follow red-green-refactor" or "you're spiking, skip the ceremony".

## What I learned

- **Path-scoped enforcement is the trick.** Hooks fire on every file edit, but mine only DENY for `contexts/**/domain/**`. The rest of the codebase is unaffected. Zero false positives so far.
- **Hooks teach Claude faster than CLAUDE.md does.** A clear `permissionDecisionReason` is read and obeyed; a system-prompt rule drifts.
- **Trust exit codes, not output.** I burned an hour debugging a false-red on a test named `test_failed_payload_handling`. The grep on "failed" matched the test name. Now I only read `tool_response.exit_code`.
- **State files belong under `${CLAUDE_PROJECT_DIR}/.claude/state/`** — never in `/tmp` or anywhere shared between projects. The harness is per-project.

## How to install

I packaged this set as a Claude Code plugin called **t3d** (TDD + 3D, where 3D is DDD in leet):

```
/plugin marketplace add coolsocket/t3d
/plugin install t3d
/t3d-init                   # in any Python project
```

It ships the 5 hooks above plus 4 skills (`t3d-init`, `t3d-new-context`, `t3d-grill-me`, `t3d-sinkin` for periodic drift audits) and a project template with the 4-layer bounded-context skeleton.

Repo: https://github.com/coolsocket/t3d — MIT, fork it for non-Python stacks by swapping the import regex.

## What's next

Three things on my list:
- An MCP server that lets Claude query the running tracker for "did this kind of edit cause a regression before?" — closing the loop between sinkin's pitfall log and edit-time decisions.
- A TypeScript / Go variant of `check-domain-purity` (would love PRs).
- A "loop-until-dry" mode for `t3d-sinkin` that escalates audit depth automatically.

If you've shipped your own Claude Code hooks, I'd love to see them — especially anything that bites you regularly. PRs to `PITFALLS.md` welcome at the repo.
