# Attribution

This skill is **inspired by** but **substantially rewritten from** the
`sinkin` skill (version 1.1.0) originally found in this project's
`.agents/skills/sinkin/SKILL.md`.

## What was kept (philosophy)

- The "周期性沉淀 / consolidation" idea — that a workspace needs a periodic
  audit complementary to real-time enforcement.
- Proactive structure verification.
- Structured report at the end.
- The "workspace first, global second" priority.

## What was changed (substance)

The original `sinkin` was a **generic workspace-solidification skill**
assuming a `docs/{core,UIUX,backend,tests}` layout, `src/` vs `scripts/`
code split, and a `README.md` per major directory.

This rewrite (`t3d-sinkin`) is specialized for **t3d (DDD+TDD) workspaces**:

| Original `sinkin` | `t3d-sinkin` |
|-------------------|--------------|
| `docs/{core,UIUX,backend,tests}` | `docs/adr/` + per-context `CONTEXT.md`/`INVARIANTS.md` |
| `src/` vs `scripts/` migration | `contexts/`/`apps/`/`playground/` shape check |
| README per directory | INVARIANTS↔tests parity, CONTEXT-MAP↔contexts parity |
| Generic decoupling audit | DDD-specific: cross-context import legality, _shared_kernel growth |
| Subagent deep-audit (mandatory) | Read-only Bash checks (deterministic, fast) |
| Mandatory prereq skills (`subagent_usage`, `gemini_cli_agent`, ...) | None — self-contained |
| Tone: ⚠️ MANDATORY / UNACCEPTABLE | Tone: structured findings + prioritized action list |
| May edit files | **Strictly read-only** |

## What was dropped

- The `STANDARDS.md` per-skill convention (CLAUDE.md + `rules/*.md` already covers this in t3d).
- The "every directory must have a README" convention (replaced by CONTEXT.md / INVARIANTS.md).
- Generic "industrialization_principles.md" doc requirement.

This adaptation is licensed under the same terms as the rest of the t3d plugin (MIT).
