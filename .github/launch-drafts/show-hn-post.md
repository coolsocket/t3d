# Show HN — t3d

## When to post

Tuesday or Wednesday, 9:00–10:30 ET (entry hits the front page algorithm window). Sit on the thread for 4 hours minimum and reply within 10 min to every top-level comment — engagement compounds early upvotes.

**Prerequisites before posting**:
- [ ] README has a 30-second asciinema OR animated GIF above the fold showing a hook DENY-ing a bad edit
- [ ] coolsocket/t3d has at least 3 stars (not 0 — looks abandoned)
- [ ] Composio PR has either been merged OR you've cross-linked it in the thread

---

## Title (use the first one)

```
Show HN: t3d – Claude Code hooks that block AI from breaking architectural invariants
```

Alternatives if the first feels stale:

```
Show HN: t3d – Stop Claude from quietly importing fastapi into your domain layer
```

```
Show HN: t3d – I made Claude actually do TDD instead of pretending to
```

## URL field

```
https://github.com/coolsocket/t3d
```

## Text field (this is the post body shown under the title)

```
I was building a small Claude Code usage tracker in Python with strict DDD
layering and TDD discipline. Claude knew the rules — they were spelled out
in CLAUDE.md. But under deadline pressure the model would quietly slip
`import fastapi` into a Domain file, or do `from contexts.pricing.domain
import X` from another context (which should have gone through
application.api), or skip the failing-test-first step when the fix felt
"obvious".

System-prompt-level pleading didn't work — rules drift in the context
window. Hooks did. Claude Code's PreToolUse hooks let me deny edits before
they're applied, with a structured reason the model reads and obeys.

t3d is the 5 hooks + 4 skills I ended up with, packaged as a plugin:

  - check-domain-purity.sh — DENY framework imports in Domain layers and
    cross-context internal imports (only application.api or shared kernel
    allowed)
  - mark-domain-dirty.sh + record-test-result.sh + enforce-tests-on-stop.sh
    — block Stop if Domain was edited this session but tests are red
  - classify-prompt.sh — inject workflow reminder based on prompt keywords

Plus skills for scaffolding new bounded contexts, design-time interrogation,
and a periodic drift audit (sinkin) that also mines past session JSONLs for
pitfall candidates.

It's small (5 bash + jq scripts, 4 SKILL.md files, project templates) and
self-contained. Fork it for non-Python stacks by swapping the import regex.

Install:
  /plugin marketplace add coolsocket/t3d
  /plugin install t3d
  /t3d-init

A few things I learned that surprised me:
  - Hooks teach Claude faster than CLAUDE.md does. A clear
    permissionDecisionReason gets internalized; system-prompt rules drift.
  - Trust exit codes, not output. I burned an hour on a false-red because
    my hook grepped stdout for "failed" and matched test names.
  - State files belong under ${CLAUDE_PROJECT_DIR}/.claude/state/, never
    in /tmp or anywhere shared between projects.

Repo + docs: https://github.com/coolsocket/t3d
Demo: <link to asciinema or short GIF here>

Happy to answer anything about the hook design, the sinkin drift-audit
skill, or why I chose this particular DDD shape.
```

## After posting

- Open the thread in another tab. Refresh every 5–10 min for the first hour.
- For each top-level comment:
  - Acknowledge what they said specifically (not "thanks!")
  - Answer technically and concisely
  - If they hit a real point, say "you're right, I'll fix" and link the GitHub issue you opened in response
- Don't reply to your own post. Don't sock-puppet upvotes.
- Don't ask anyone to upvote.

## Common rebuttals to prepare for

| Probable comment | Honest answer |
|---|---|
| "Just put it in CLAUDE.md" | I tried; system-prompt rules drift in long sessions. Hooks fire deterministically. |
| "Bash + jq feels fragile" | It is, but you can audit every hook in 30 seconds. A heavier runtime (Python, Node) is a bigger security ask for code that runs with shell privileges. |
| "Why DDD for a Python script?" | The harness isn't *just* for DDD — the hooks would enforce any architectural shape you encode in the regex. DDD is just the example I built it for. |
| "What about TypeScript?" | The hook scripts are language-agnostic in spirit. The regex in `check-domain-purity.sh` is the only TS/Python-specific bit. PRs welcome. |
| "Doesn't this slow Claude down?" | Per-edit overhead is one bash exec + jq parse ≈ 5ms. Stop-hook check is a `test -f`. Sub-millisecond. |
| "What if I want to ship something the hook rejects?" | `/plugin disable t3d` in that project, or git-ignore the hook state. The escape hatch is intentional. |
