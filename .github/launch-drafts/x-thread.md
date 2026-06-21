# X / Twitter launch thread — 6 tweets

**When to post**: 9:00–11:00 ET, same day OR the day after Show HN. Cross-link in the second post if Show HN is doing well.

**Format**: tweet 1 has the GIF/screenshot. Tweets 2–6 are text only with one trailing emoji each (or none — emojis are optional, don't overdo).

---

## Tweet 1 — the hook

```
Claude Code kept silently violating my DDD layering rules during refactors.

CLAUDE.md didn't help. Pleading didn't help.

PreToolUse hooks did — they reject the edit before it lands, with a reason Claude actually reads and obeys.

I packaged the 5 hooks I use into a plugin: t3d

[ATTACH: 30-sec GIF of a hook DENY-ing `import fastapi` in a domain file]
```

## Tweet 2 — install

```
Install:

/plugin marketplace add coolsocket/t3d
/plugin install t3d
/t3d-init

That's it. Hooks fire on every Edit/Write/Bash/Stop. Path-scoped to contexts/** so they're harmless on non-DDD projects.

https://github.com/coolsocket/t3d
```

## Tweet 3 — what each hook does (the meat)

```
The 5 hooks:

🚫 check-domain-purity → denies framework imports in Domain layers + cross-context internal imports (only application.api or shared kernel allowed)

🔴 mark-domain-dirty + record-test-result + enforce-tests-on-stop → blocks Stop if Domain was edited but tests are red

🏷️ classify-prompt → injects workflow reminder based on keywords (spike/bug/feature)
```

## Tweet 4 — the surprise insight

```
The lesson that surprised me most:

Hooks teach Claude faster than CLAUDE.md does.

A clear permissionDecisionReason gets internalized within 1-2 retries. A system-prompt rule drifts in a long session.

Stop pleading in the context window. Enforce at edit time.
```

## Tweet 5 — the gotcha

```
One trap I hit:

Don't grep stdout for "failed" to detect red tests — it matches test names like `test_handles_failed_payload`.

Trust only tool_response.exit_code. Sub-second, deterministic, zero false positives.

(One of 4 pitfalls already in t3d's PITFALLS.md.)
```

## Tweet 6 — invitation

```
The plugin is intentionally small: 5 bash+jq scripts, 4 skills, project templates. MIT.

Fork it for TypeScript / Go / Rust by swapping the import regex in one file.

Repo + docs: https://github.com/coolsocket/t3d

If you've built Claude Code hooks of your own — drop a link, I'd love to read them.
```

---

## Optional 7th tweet (if engagement is hot)

```
Bonus: there's a 4th skill in the plugin called /t3d-sinkin.

Weekly drift audit + scans past Claude Code session JSONLs for user-correction signals → pitfall candidates, capped at 2-3 per run.

The harness improves itself from how you've been using it.
```

---

## Tagging suggestions

Don't mass-tag — looks desperate. Tag at most 1-2 of these in tweet 1 IF they're actually relevant to your circles:

- @AnthropicAI (their DevRel sometimes retweets polished launches)
- @composio (the awesome-list maintainers — they reposted similar tools)
- Specific people whose work you cited: not in this case, but if t3d ever cites someone's blog post, tag them

Do NOT tag a list of 5+ accounts hoping for retweets. That's spam.

## After posting

- Don't quote-tweet yourself for "engagement". Reply to your own thread only to add a new piece of info (e.g. "Composio PR merged, t3d now in 2 awesome lists").
- Reply to every meaningful reply within ~30 minutes during the first 2 hours.
- DO save quote-tweets and replies from notable accounts — useful for the retro post on day 7.
