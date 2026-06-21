# Promotion submissions — copy-paste content

Track which channels t3d has been submitted to, and keep the canonical
submission text in one place for re-use / re-submission.

---

## 1. ComposioHQ/awesome-claude-plugins ✅ DONE

- **Submitted**: 2026-06-21
- **Method**: PR (their format)
- **PR**: https://github.com/ComposioHQ/awesome-claude-plugins/pull/308
- **Section**: Backend & Architecture (alongside external-source entries like maestro-orchestrate)
- **Status**: awaiting review

---

## 2. hesreallyhim/awesome-claude-code ⏳ WAIT UNTIL 2026-06-28

**Why waiting**: their CONTRIBUTING enforces "Resources must be at least one week old". t3d was published 2026-06-21, so the earliest acceptable submission date is **2026-06-28**.

**How to submit**: open https://github.com/hesreallyhim/awesome-claude-code/issues/new?template=recommend-resource.yml in a browser (must be web UI — they ban `gh` CLI submissions). Fill the form with the values below.

> ⚠ DO NOT submit via PR or `gh issue create` — they explicitly ban this and may temp-ban your account.

### Form field values

| Field | Value |
|---|---|
| **Title** | `[Resource]: t3d` |
| **Display Name** | `t3d` |
| **Category** | `Agent Skills` |
| **Sub-Category** | `General` |
| **Primary Link** | `https://github.com/coolsocket/t3d` |
| **Author Name** | `coolsocket` |
| **Author Link** | `https://github.com/coolsocket` |
| **License** | `MIT` |
| **Other License** | _(leave blank)_ |

### Description (paste in `Description` textarea — no emojis, no second-person)

```
A small DDD + TDD harness shipped as a Claude Code plugin. Provides 5 shell hooks that deny external-framework imports inside Domain layers, deny cross-context internal imports, and block Stop when Domain files were edited but the latest test run was red. Ships 4 skills (init, new-context, grill-me, sinkin) plus a project template with a 4-layer bounded-context skeleton and a starter PITFALLS log seeded with cross-project lessons.
```

### Validate Claims (mandatory for plugin submissions — paste in that textarea)

```
1. Install: claude plugin marketplace add coolsocket/t3d && claude plugin install t3d
2. In any project: try to edit contexts/foo/domain/x.py with the content "import fastapi"
3. The PreToolUse hook returns permissionDecision=deny with a structured reason pointing to the Port/Adapter alternative in contexts/<ctx>/domain/port/.
The plugin manifest validates with `claude plugin validate .` and CI is green at https://github.com/coolsocket/t3d/actions.
```

### Specific Task

```
Install the plugin, then open a fresh empty directory and run /t3d-init. Verify that CLAUDE.md, CONTEXT-MAP.md, contexts/_TEMPLATE/, contexts/_shared_kernel/, and docs/adr/ all appear. Then run /t3d-new-context billing and verify a 4-layer skeleton appears under contexts/billing/.
```

### Specific Prompt

```
/t3d-init
/t3d-new-context billing
```

### Additional Comments

```
Hooks are harmless on non-t3d projects — they path-match contexts/** and silently pass for repos without that layout. Runs entirely locally; the only network call is to GitHub during /plugin install. No telemetry. No --dangerously-skip-permissions required.
```

### Recommendation Checklist (all required)

- [x] I have checked that this resource hasn't already been submitted
- [x] It has been over one week since the first public commit to the repo I am recommending  *(must be true on 2026-06-28 or later)*
- [x] All provided links are working and publicly accessible
- [x] I do NOT have any other open issues in this repository

---

## 3. Anthropic official marketplace ⏳ PENDING

**URL**: https://platform.claude.com/plugins/submit  (verify this resolves before promoting widely)

**Notes**: no published age restriction. Worth submitting now.

### Form fields (educated guesses — verify against the actual form)

| Field | Value |
|---|---|
| Plugin name | `t3d` |
| Version | `0.3.2` |
| Repository URL | `https://github.com/coolsocket/t3d` |
| Marketplace name | `t3d` |
| Category | `development-workflow` |
| Tags | `ddd, tdd, python, harness, bounded-context, audit` |
| License | `MIT` |

### Short description (1 sentence)

```
DDD + TDD harness for Claude Code — hooks enforce layer purity and red-green discipline; skills scaffold bounded contexts and audit drift.
```

### Long description (paragraph)

```
t3d is a small Claude Code plugin that gives any Python project bounded-context discipline at edit time. Five shell hooks enforce Domain layer purity (no framework imports), cross-context call rules (only via application.api or shared kernel), and the red-green-refactor cycle (Stop is blocked if Domain was edited but tests are red). Four skills — t3d-init, t3d-new-context, t3d-grill-me, and t3d-sinkin — cover one-time project setup, new bounded-context scaffolding, design-time grilling, and periodic drift audits (which also mine past session JSONLs for pitfall and workflow candidates). The plugin also ships project templates and a starter PITFALLS.md with four real cross-project lessons.
```

### Install command (for "users will install with")

```
/plugin marketplace add coolsocket/t3d
/plugin install t3d
```

---

## 4. Show HN (drafted, not posted) ⏳

Don't post until: README has a 30-second asciinema or GIF demo above the fold. Show HN landing without a visceral "here's what it does" moment scores poorly.

Three title options ranked:

1. `Show HN: t3d – Claude Code hooks that block AI from breaking architectural invariants` ← recommended
2. `Show HN: t3d – Stop Claude from quietly importing fastapi into your domain layer`
3. `Show HN: t3d – A DDD+TDD harness so Claude actually follows your layering rules`

Post Tuesday or Wednesday, 9–10am ET. Sit on the thread for 4 hours and reply within 10 min to every comment.

---

## 5. Reddit r/ClaudeCode (drafted, not posted) ⏳

Don't post until Show HN result is known (good or bad). If Show HN went well, lead with a snippet of that thread + the link.

Title: `Claude kept silently breaking our DDD layer rules until we shipped this — t3d hooks`
Post Wednesday or Thursday evening US.
Don't drop the repo link in the title; put it in the first comment.

---

## Cadence rule

**Never two channels on the same day.** Cross-channel-same-day reads as a marketing campaign and gets shadow-suppressed everywhere.
