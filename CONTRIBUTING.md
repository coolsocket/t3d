# Contributing to t3d

Thanks for considering a contribution. t3d is intentionally small — don't be
shy to ship a tight 10-line PR.

---

## Local dev loop

```bash
git clone https://github.com/coolsocket/t3d.git
cd t3d

# install locally as a Claude Code plugin from this checkout:
claude plugin marketplace add ./.
claude plugin install t3d
claude plugin list                                # confirm t3d@t3d, enabled

# after edits:
claude plugin validate .                          # manifest + marketplace sanity
bash -n hooks/*.sh                                # shell syntax
claude plugin marketplace update t3d              # refresh cache
claude plugin uninstall t3d && claude plugin install t3d   # re-pull
```

Test hooks in a temp dir:

```bash
mkdir /tmp/t3d-test && cd /tmp/t3d-test
# example: trigger the domain-purity hook with a fake Edit event
echo '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/t3d-test/contexts/foo/domain/x.py","new_string":"import fastapi"}}' \
  | CLAUDE_PROJECT_DIR=/tmp/t3d-test bash ~/.claude/plugins/cache/t3d/*/hooks/check-domain-purity.sh
# expect: {"hookSpecificOutput": {..., "permissionDecision": "deny", ...}}
```

---

## Releasing

t3d uses semantic-ish versioning. Any user-visible behavior change → bump.

1. Edit `.claude-plugin/plugin.json` `version`
2. Edit `.claude-plugin/marketplace.json` `plugins[0].version` (must match)
3. `claude plugin validate .`
4. `git commit -am "t3d vX.Y.Z: <one-line change>"`
5. `git push`
6. Optional: `git tag t3d--vX.Y.Z && git push --tags`

---

## PR conventions

- **Title**: imperative, short. "Fix `check-domain-purity` regex for relative imports", not "fix the bug".
- **One concern per PR**. Hook fix + new skill + README rewrite ≠ same PR.
- **Fill the [PR template](.github/pull_request_template.md)** — especially the test-evidence section.

---

## What good PRs look like

- A **new pitfall in PITFALLS.md** with a clear `_Source:_` line proving cross-session recurrence (not just "I think this might happen").
- A **bug fix to a hook** with: failing-case JSON example before, passing-case JSON example after, and a one-line `bash -n` verification.
- A **new skill** with frontmatter, when-to-use docs, and integration into the `README.md` "Skills" table.
- A **template improvement** with a note on what user-pain it fixes.

---

## What we'd push back on

- Adding heavy dependencies (Node, Python runtime, Docker) — t3d is intentionally bash + jq + (project-side) python.
- Generalizing for "any framework" too early. The DDD/TDD shape t3d enforces is opinionated. Forks are welcome for radically different stacks.
- Skills that just wrap one-line bash. Skills should carry actual reasoning instructions.

For open-ended questions, prefer [GitHub Discussions](https://github.com/coolsocket/t3d/discussions) over an issue.

For security disclosures, see [`SECURITY.md`](./SECURITY.md).
