<div align="center">

# t3d

**TDD + 3D — a small Claude Code plugin that gives any Python project DDD-shaped guardrails and a red-green-refactor pulse.**

[![Version 0.3.2](https://img.shields.io/badge/version-0.3.2-purple.svg)](./.claude-plugin/plugin.json)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE)
[![Hooks: 5](https://img.shields.io/badge/hooks-5-orange.svg)](./hooks/)
[![Skills: 4](https://img.shields.io/badge/skills-4-green.svg)](./skills/)
[![CI](https://github.com/coolsocket/t3d/actions/workflows/validate.yml/badge.svg)](https://github.com/coolsocket/t3d/actions/workflows/validate.yml)

🚀 [Install](#-install) · 🔧 [Daily workflow](#-daily-workflow) · 🪝 [Hooks](#-hooks) · 🧠 [Skills](#-skills) · 🗂️ [Templates](#-templates) · 🩺 [Troubleshooting](#-troubleshooting)

</div>

---

## 🎯 What it is

`t3d` is a single-purpose Claude Code plugin. It ships:

- **5 shell hooks** that enforce DDD layer purity + TDD red-green discipline at edit time.
- **3 markdown layer rules** auto-loaded by file path you're editing.
- **4 skills** — `init`, `new-context`, `grill-me`, `sinkin` (periodic drift audit + session-log mining).
- **Project templates** — `CLAUDE.md`, `CONTEXT-MAP.md`, a 4-layer `contexts/_TEMPLATE/`, a `_shared_kernel/` seed, ADR template.
- **A starter `PITFALLS.md`** seeded with 4 real cross-project lessons.

Designed for Python projects following Domain-Driven Design + Test-Driven Development. Fork it for other stacks — the hook regexes are the only stack-specific code.

---

## 🚀 Install

```bash
# In Claude Code:
/plugin marketplace add coolsocket/t3d
/plugin install t3d
```

Then, in any project where you want the harness active:

```
/t3d-init        # copy CLAUDE.md + contexts/_TEMPLATE + _shared_kernel into the current project
```

That's it — hooks fire automatically on every Edit / Write / Bash / Stop. The plugin lives at user scope, so it works in every project unless explicitly disabled (`/plugin disable t3d`).

Hooks are **harmless on non-t3d projects** — they path-match `contexts/**` and silently pass for repos that don't have that layout.

---

## 🔧 Daily workflow

```
/t3d-grill-me                     # interrogate the design BEFORE writing code
/t3d-new-context billing          # scaffold a new bounded context
# edit contexts/billing/INVARIANTS.md → add INV-001
# edit contexts/billing/tests/unit/test_inv_001_*.py → red ✗
# edit contexts/billing/domain/*.py   → green ✓ (hook denies bad imports)
make test                         # green = Stop allowed; red = blocked
/t3d-sinkin                       # weekly: drift audit + mine past sessions for pitfalls
```

---

## 🪝 Hooks

| Hook | Trigger | Action |
|------|---------|--------|
| `classify-prompt.sh` | UserPromptSubmit | Tag prompt as spike/feature/bug; inject workflow reminder |
| `check-domain-purity.sh` | PreToolUse on Edit/Write | DENY if writing `contexts/**/domain/**` with `import fastapi/sqlalchemy/...`; DENY cross-context internal imports |
| `mark-domain-dirty.sh` | PostToolUse on Edit/Write | Touch `.claude/state/domain-dirty` when Domain edited |
| `record-test-result.sh` | PostToolUse on Bash (`pytest` / `make test`) | Set/clear `.claude/state/last-test-red` from exit code |
| `enforce-tests-on-stop.sh` | Stop | Block exit if `domain-dirty` AND `last-test-red` both exist |

State files live under `${CLAUDE_PROJECT_DIR}/.claude/state/` — **per-project, not shared across projects.**

---

## 🧠 Skills

| Slash command | When to use | Cost |
|---|---|---|
| `/t3d-init` | Once per new project — copies harness templates | ~1 k tok on invoke |
| `/t3d-new-context <name>` | Every time you start a new bounded context | ~900 tok on invoke |
| `/t3d-grill-me` | BEFORE writing code on any non-trivial feature | ~500 tok on invoke |
| `/t3d-sinkin` | Weekly (or after a sprint) — full drift audit + lessons mining from past Claude Code session logs | ~10 k tok on invoke |

Always-on cost: **~770 tok per session** (loaded skill descriptions + 4 hooks).

---

## 🗂️ Templates

Shipped at `${CLAUDE_PLUGIN_ROOT}/templates/`:

```
templates/
├── CLAUDE.md                  generic harness rules (with FILL IN placeholders for project identity)
├── CONTEXT-MAP.md             empty bounded-context inventory
├── contexts/
│   ├── _TEMPLATE/             4-layer skeleton (domain · application · infrastructure · ui · tests · CONTEXT.md · INVARIANTS.md)
│   └── _shared_kernel/        example pure VOs (Money, Timestamp — LLM-specific ModelName/TokenCount marked optional)
└── docs/
    └── adr/                   ADR README (Matt Pocock 3 conditions) + template
```

---

## 🩺 Troubleshooting

| Symptom | Cause / Fix |
|---|---|
| Hooks fire on unrelated projects | By design — they path-match `contexts/**` and silently pass for repos without that directory. ~0 ms overhead. |
| `/t3d-init` refuses to overwrite my CLAUDE.md | By design. Rename your existing file, accept the overwrite prompt, or merge by hand. |
| Tests pass but Stop is still blocked | Run the failing test again — the hook clears `last-test-red` only on a fresh green run. If still stuck: `rm .claude/state/last-test-red .claude/state/domain-dirty`. |
| `${CLAUDE_PLUGIN_ROOT}` unrecognized | Update Claude Code (`claude --update`) — older versions lacked plugin path variables. |
| Want to disable in one specific project | `/plugin disable t3d` in that project's scope. |

---

## 🧪 Why "t3d"?

**T**DD + **3D** (DDD in leet). Three letters, two methodologies, one harness. Short enough to type, distinct enough to grep.

---

## 🤝 Contributing & forking

See [`CONTRIBUTING.md`](./CONTRIBUTING.md) for the development loop.

Forking for non-Python stacks is welcomed and easy:
- Swap the Python `import` regex in `hooks/check-domain-purity.sh` for TypeScript / Go / Rust.
- Replace the `contexts/<ctx>/` shape in `templates/` if your DDD layout differs.
- Ship as your own marketplace under your own GitHub org.

---

## 📄 License

MIT. See [`LICENSE`](./LICENSE).
