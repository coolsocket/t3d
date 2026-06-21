---
name: t3d-new-context
description: Scaffold a new bounded context by copying contexts/_TEMPLATE/ to contexts/<name>/. Use when starting a new bounded context — keeps the 4-layer DDD skeleton (domain/application/infrastructure/ui) + tests/ + CONTEXT.md + INVARIANTS.md consistent across all contexts.
---

# t3d-new-context

Create a fresh bounded context from the harness template.

## Required arguments

The user invokes this as `/t3d-new-context <context-name>` or types the name
when prompted. The name must:
- Be `snake_case` (e.g. `billing`, `user_profile`, `order_fulfillment`)
- NOT start with `_` (reserved for `_TEMPLATE` and `_shared_kernel`)
- NOT already exist under `${CLAUDE_PROJECT_DIR}/contexts/`

If the name is missing or invalid, ask the user before proceeding.

## Plan

1. Verify `${CLAUDE_PROJECT_DIR}/contexts/_TEMPLATE/` exists. If not, prompt
   the user to run `/t3d-init` first.
2. `cp -r contexts/_TEMPLATE contexts/<name>` (note: use the user's PROJECT
   `_TEMPLATE`, not the plugin's — `/t3d-init` should have copied it already,
   and the user may have customized it).
3. Print "next steps":
   - Open `contexts/<name>/CONTEXT.md` — add 1-3 bounded ubiquitous-language terms
   - Open `contexts/<name>/INVARIANTS.md` — add INV-001 (your first invariant)
   - Open `contexts/<name>/tests/unit/test_inv_001_*.py` — write the failing test
   - Then implement domain code until it passes (red → green → refactor)
4. (Optional) Add the new context to `CONTEXT-MAP.md`.

## Required tool calls

Use `Bash` for the directory copy. Do NOT use `Write` — preserve template
structure and any user customizations to `_TEMPLATE/`.

## Reminders

- The new context starts EMPTY. No domain model yet — that's intentional.
  TDD says: write the invariant + failing test FIRST, then add domain code.
- The 4 layers (`domain/`, `application/`, `infrastructure/`, `ui/`) and 4
  test categories (`unit/`, `integration/`, `contract/`, `use_case/`) are all
  pre-made as empty packages. Don't reorganize.
- The hooks shipped with this plugin will enforce:
  - No external imports in `domain/` (PreToolUse on Edit/Write)
  - No cross-context `domain/` imports from other contexts
  - Tests must be green at Stop if you touched `domain/`
