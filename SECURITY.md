# Security Policy

## Reporting a vulnerability

**Don't open a public issue.** Use GitHub's private channel:

> https://github.com/coolsocket/t3d/security/advisories/new

If that's unavailable, contact the maintainer via the email in `git log` (most
recent maintainer commit's `Author:`).

## What to include

- Affected file path + version of t3d
- Clear description of the vulnerability + proof-of-concept (if you have one)
- Your assessment of severity

## What to expect

- Initial acknowledgment within 72 hours
- Coordinated disclosure — patched release ships before the advisory becomes public
- Public credit unless you ask to remain anonymous

---

## Threat-modeled surfaces

These deserve the closest review by anyone auditing this code:

- **`hooks/*.sh`** — these run with Claude Code's invoking-shell privileges on
  every Edit / Write / Bash / Stop / UserPromptSubmit. Pay attention to:
  - Input validation (untrusted JSON via `jq`)
  - Command construction (no eval, no unquoted vars in command position)
  - State file paths (must stay under `${CLAUDE_PROJECT_DIR}/.claude/state/`, not
    `/tmp` or anywhere world-writable)
- **`skills/t3d-sinkin/SKILL.md`** — its Section 4 reads user session JSONLs
  from `~/.claude/projects/`. Anyone modifying the extractor must respect the
  no-PII / no-credentials rule in the skill's hard rules.
- **`templates/**`** — these get copied verbatim into user projects via
  `/t3d-init`. A malicious template = malicious code in every user project.

## Out of scope

- Vulnerabilities in user projects that adopt t3d — those belong to the user.
- Issues in third-party tools t3d shells out to (`bash`, `jq`, `claude` CLI).
- Cosmetic markdown issues (use a regular issue).

Thank you for keeping t3d users safe.
