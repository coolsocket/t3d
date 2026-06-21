# CLAUDE.md — contributing to the t3d plugin itself

This repo IS the [t3d](https://github.com/coolsocket/t3d) Claude Code plugin.
It's small on purpose: 5 shell hooks + 3 layer rules + 4 skills + project
templates + a starter PITFALLS log.

If you're using t3d in another project, see that project's `CLAUDE.md`
(installed by `/t3d-init`) for the DDD + TDD workflow it enforces.
**This file is just for editing t3d itself.**

## What lives where

```
.claude-plugin/         plugin manifest + marketplace manifest
hooks/                  5 bash scripts + hooks.json
rules/                  3 markdown layer rules (auto-loaded by Claude Code path-matching)
skills/<name>/SKILL.md  4 slash commands
templates/              files copied into user projects by /t3d-init
PITFALLS.md             cross-project pitfalls (this repo's responsibility to curate)
```

## Editing rules

| Editing this | Do this |
|---|---|
| `hooks/*.sh` | Keep it pure bash + jq. No Python, no Node. Run `bash -n` before commit. Test by piping a fake JSON event to it. |
| `hooks/hooks.json` | After any edit, `claude plugin validate .` |
| `skills/<name>/SKILL.md` | Front-matter `name:` + `description:` are required. Keep description specific enough that Claude knows when to invoke. |
| `rules/*.md` | These are loaded as Claude system reminders when path matches — keep them short, opinionated, scannable. |
| `templates/**` | These get copied verbatim into user projects. Don't reference the t3d repo or maintainer specifics here. |
| `.claude-plugin/plugin.json` | Bump `version` whenever shipped behavior changes. Sync `.claude-plugin/marketplace.json` version too. |

## Release flow

1. Bump both `plugin.json` and `marketplace.json` `version`
2. `claude plugin validate .`
3. Run all hook scripts through `bash -n`
4. `git commit -am "t3d v0.X.Y: <one-line change>"`
5. `git push`
6. Users re-fetch via `/plugin marketplace update t3d && /plugin update t3d`

## When NOT to add stuff

- **A new skill** that just wraps a 3-line bash command — keep skills load-bearing.
- **A new pitfall** that's only happened to you once — wait for cross-session recurrence (this is what `/t3d-sinkin` is for).
- **A new template file** that's project-specific — projects ship their own.

## When adding things

- New hook → add to `hooks/`, register in `hooks/hooks.json`, document trigger + action in `README.md`.
- New skill → `skills/<name>/SKILL.md` with frontmatter; mention in `README.md` "Skills" table.
- New pitfall → `PITFALLS.md` under the right category, with `_Source:_` line for traceability.
- New template file → drop into `templates/` mirroring the structure it should land in user projects.

## Reference: what t3d enforces in user projects (NOT in this repo)

If you're confused why this repo doesn't have `contexts/` or `INVARIANTS.md`:
this repo is the **harness**, not a project that uses the harness. The
`templates/` directory is what `/t3d-init` copies into a user project to give
them the DDD/TDD shape this plugin enforces.
