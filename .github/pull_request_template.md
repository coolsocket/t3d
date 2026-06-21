<!-- Thanks for the PR. Fill in what applies; delete the rest. -->

## What

<!-- One paragraph. -->

## Why

<!-- The problem this solves or feature it adds. Link issue: Closes #N -->

## Type

- [ ] 🪝 Hook change (`hooks/*.sh` or `hooks/hooks.json`)
- [ ] 🧠 Skill change (`skills/<name>/SKILL.md`)
- [ ] 📐 Layer rule change (`rules/*.md`)
- [ ] 🗂️ Template change (`templates/**`)
- [ ] 📚 Docs only
- [ ] 🚨 Breaking change for users (explain compat below)

## Test evidence

<!-- For hook changes: paste a stdin JSON example + the resulting stdout. -->

```
# stdin → hook
echo '{...}' | CLAUDE_PROJECT_DIR=/tmp/x bash hooks/your-hook.sh
# stdout:
{...}
```

## Checklist

- [ ] `claude plugin validate .` passes
- [ ] `bash -n hooks/*.sh` clean
- [ ] `version` bumped in BOTH `.claude-plugin/plugin.json` AND `.claude-plugin/marketplace.json` (if user-visible)
- [ ] README "Hooks" / "Skills" table updated if relevant
- [ ] No new heavy dependencies introduced
