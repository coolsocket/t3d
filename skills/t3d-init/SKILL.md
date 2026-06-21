---
name: t3d-init
description: Initialize the current project with the DDD+TDD harness — copies CLAUDE.md, CONTEXT-MAP.md, contexts/_TEMPLATE/, contexts/_shared_kernel/, and docs/adr/ from the plugin. Use when adopting the harness in a fresh repo or onboarding an existing one. Run from the project root.
---

# t3d-init

Copy the harness templates into the **current project root** (the directory
where Claude Code was launched).

## Plan

1. Resolve the project root from `${CLAUDE_PROJECT_DIR}`. Print it.
2. For each template file under `${CLAUDE_PLUGIN_ROOT}/templates/`:
   - Compute destination path under `${CLAUDE_PROJECT_DIR}/`.
   - If destination exists, **ask the user** before overwriting (do NOT silently clobber `CLAUDE.md`).
   - Otherwise, `cp` it across, preserving directory structure.
3. After copying, print a "next steps" message:
   - Open `CLAUDE.md` and fill the `<!-- FILL IN -->` project-identity section.
   - Open `CONTEXT-MAP.md` and list your bounded contexts.
   - Run `/t3d-new-context <your-first-context>` to scaffold the first context.

## Required tool calls

You must use the `Bash` tool to run `cp -r`. Do not use the `Write` tool for
copying — it would re-author files and lose timestamps/perms.

## Templates to copy

The plugin ships this layout under `${CLAUDE_PLUGIN_ROOT}/templates/`:

```
templates/
├── CLAUDE.md                # generic harness rules (with FILL IN placeholders)
├── CONTEXT-MAP.md           # empty bounded-context inventory
├── contexts/
│   ├── _TEMPLATE/           # 4-layer skeleton — copy-paste source for new contexts
│   └── _shared_kernel/      # example pure value objects (Money, Timestamp, ModelName, TokenCount)
└── docs/
    └── adr/
        ├── README.md        # Matt Pocock 3-condition ADR rule
        └── NNNN-template.md # ADR template
```

## Conflict handling

If `${CLAUDE_PROJECT_DIR}/CLAUDE.md` already exists, ask the user one of:
- `keep` — leave existing, don't copy CLAUDE.md (default)
- `overwrite` — replace with plugin version
- `view-diff` — show diff first

Do not overwrite `contexts/_shared_kernel/` if it exists either — that
directory often has project-specific value objects.

## Done criteria

After running, the user should be able to:
- Edit a file at `contexts/anything/domain/x.py` containing `import fastapi` and
  see the PreToolUse hook DENY it.
- Run `/t3d-new-context billing` and see `contexts/billing/` appear with the
  full 4-layer skeleton.
