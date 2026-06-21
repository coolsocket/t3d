---
name: t3d-sinkin
description: Periodic project audit for t3d (DDD+TDD) workspaces. Checks FOUR things hooks can't catch — (1) docs↔code freshness drift (INVARIANTS↔tests parity, CONTEXT-MAP↔contexts/ parity, CLAUDE.md path validity), (2) folder structure conformance to the t3d layout (4-layer skeleton, cross-context import legality, _shared_kernel growth vs ADRs), (3) playground promotion candidates (spikes ready to become contexts/skills or distill into docs), (4) session lessons — scans past Claude Code session JSONLs for user-correction signals (→ pitfall candidates) and user-approval moments (→ workflow/skill candidates), classifying each as PLUGIN-level (generalizable) or PROJECT-level (specific to this repo). Use periodically (weekly, or after a sprint) — or whenever the user says "sink in", "consolidate", "check drift", or "summarize past sessions". The skill REPORTS only, it does NOT auto-fix; it ends with a prioritized HIGH/MED/LOW action list for the user to act on.
---

# t3d-sinkin

You are running a **non-mutating audit** of a t3d-harnessed project.
Read-only. **Do not edit files.** Your job is to produce a structured report
with a prioritized action list.

## Why this skill exists

The t3d harness's hooks (`check-domain-purity.sh`, `enforce-tests-on-stop.sh`,
etc.) enforce things at **edit time**. They cannot catch drift that accumulates
*between* edits:

| Drift the hooks miss | Why |
|----------------------|-----|
| `INVARIANTS.md` lists INV-007 but no test references it | hooks don't parse INVARIANTS.md |
| A test named `test_inv_007_*` exists but INV-007 not in INVARIANTS.md | hooks don't audit test names |
| `CONTEXT-MAP.md` lists a context that was deleted | hooks see edit-time only |
| `_shared_kernel/` quietly grew to 6 VOs without ADRs | hooks see one add at a time |
| A playground spike has been referenced from `contexts/` for 90 days | hooks don't check time / external use |
| CLAUDE.md mentions `.claude/skills/grill` but it was renamed | hooks don't grep CLAUDE.md |

This skill walks all three audits and reports findings. It does **not** fix
anything — the user must decide and act.

## Procedure

Run the three sections in order. **Use the Bash tool** to execute each block
verbatim from the project root (`${CLAUDE_PROJECT_DIR}`). Capture the output of
each block, then compose a final report at the end.

If the project does not look like a t3d workspace (no `contexts/` directory,
no `CLAUDE.md`), abort early and tell the user to run `/t3d-init` first.

---

### Section 1: Docs ↔ Code freshness

#### 1a. INV-NNN declared vs tested (per context)

For each non-skeleton context, compare `INVARIANTS.md` entries against
references in `tests/`. A test reference is any occurrence of `INV-NNN` in
either a test filename OR a test file's source (docstring/comment).

```bash
for ctx in contexts/*/; do
  name=$(basename "$ctx")
  [[ "$name" =~ ^_ ]] && continue
  inv_file="$ctx/INVARIANTS.md"
  if [ ! -f "$inv_file" ]; then
    echo "  ✗ $name: MISSING INVARIANTS.md"
    continue
  fi
  grep -oE '\| INV-[0-9]+' "$inv_file" | grep -oE 'INV-[0-9]+' | sort -u > /tmp/t3d_declared
  find "$ctx/tests" -name "test_*.py" 2>/dev/null \
    | xargs grep -hoE 'INV-[0-9]+' 2>/dev/null | sort -u > /tmp/t3d_tested
  decl=$(wc -l < /tmp/t3d_declared)
  test_n=$(wc -l < /tmp/t3d_tested)
  miss=$(comm -23 /tmp/t3d_declared /tmp/t3d_tested | tr '\n' ' ')
  orph=$(comm -13 /tmp/t3d_declared /tmp/t3d_tested | tr '\n' ' ')
  status="✓"
  [ -n "$miss" -o -n "$orph" ] && status="⚠"
  printf "  %s %-15s declared=%2d tested=%2d" "$status" "$name" "$decl" "$test_n"
  [ -n "$miss" ] && printf " MISS_TEST:[%s]" "$miss"
  [ -n "$orph" ] && printf " ORPHAN_TEST:[%s]" "$orph"
  echo
done
```

Findings to flag:
- `MISS_TEST:[INV-XXX]` → invariant declared but no test → **HIGH** (violates the 1:1 rule)
- `ORPHAN_TEST:[INV-XXX]` → test exists but not registered → **HIGH** (likely missing INVARIANTS row)
- Missing `INVARIANTS.md` → **HIGH**

#### 1b. CLAUDE.md path references

Find file/dir paths mentioned in `CLAUDE.md` and check they exist. Skip
relative-pattern fragments (`<ctx>/CONTEXT.md`, `NNNN-template.md`-style
placeholders) — only flag literal paths that look concrete.

```bash
# Match only PATH-shaped references: must contain '/' (i.e. directory) or start with './'
# This avoids false positives on bare filename mentions like "CONTEXT.md" or "TECH_DEBT.md"
# (which appear in CLAUDE.md as relative patterns: "<ctx>/CONTEXT.md", "docs/TECH_DEBT.md").
grep -oE '(\./)?[a-zA-Z._-][a-zA-Z0-9_.-]*/[a-zA-Z0-9_./-]+\.(md|py|json|toml|sh|yaml|yml)|\.claude/[a-zA-Z0-9_./-]+|contexts/_[A-Z][A-Z_]+' CLAUDE.md \
  | grep -vE '^/' \
  | grep -vE '<[^>]+>' \
  | grep -vE 'NNNN' \
  | sort -u | while read p; do
    rel="${p#./}"
    [ -e "$rel" ] || [ -e "$p" ] || echo "  ✗ broken ref: $p"
  done
echo "  (no '✗' line above ⇒ all literal paths resolve)"
```

Findings: each `✗ broken ref:` → **MED** (CLAUDE.md drifted from reality).

#### 1c. CONTEXT-MAP.md vs `contexts/` directory parity

```bash
ls -d contexts/*/ 2>/dev/null | xargs -n1 basename | grep -v '^_' | sort > /tmp/t3d_actual
grep -oE 'contexts/[a-z_][a-z0-9_]*' CONTEXT-MAP.md 2>/dev/null \
  | grep -oE '[a-z_][a-z0-9_]*$' | grep -v '^_' | sort -u > /tmp/t3d_mapped
echo "  in repo: $(tr '\n' ' ' < /tmp/t3d_actual)"
echo "  in MAP:  $(tr '\n' ' ' < /tmp/t3d_mapped)"
miss=$(comm -23 /tmp/t3d_actual /tmp/t3d_mapped | tr '\n' ' ')
extra=$(comm -13 /tmp/t3d_actual /tmp/t3d_mapped | tr '\n' ' ')
[ -n "$miss" ]  && echo "  ⚠ in repo but NOT in MAP: $miss"
[ -n "$extra" ] && echo "  ⚠ in MAP but NOT in repo: $extra"
```

Findings: each mismatch → **MED**. New contexts should be added to the map;
deleted ones removed. "P2 / planned" entries in the map without a `contexts/<name>/`
directory are OK if explicitly labeled as future work.

---

### Section 2: Folder structure conformance

#### 2a. 4-layer skeleton + required docs per context

```bash
for ctx in contexts/*/; do
  name=$(basename "$ctx")
  [[ "$name" =~ ^_ ]] && continue
  missing=""
  for layer in domain application infrastructure ui tests; do
    [ -d "$ctx/$layer" ] || missing="$missing $layer/"
  done
  for f in CONTEXT.md INVARIANTS.md; do
    [ -f "$ctx/$f" ] || missing="$missing $f"
  done
  status="✓"
  [ -n "$missing" ] && status="⚠"
  printf "  %s %-15s%s\n" "$status" "$name" "$missing"
done
```

Findings: any missing layer or doc → **HIGH** (breaks the t3d shape).

#### 2b. Cross-context internal imports

The PreToolUse hook stops *new* violations, but historical code (or code that
slipped in before the plugin was installed) is invisible to it. Scan all
`contexts/**/*.py` for imports of *other* contexts' internals.

Allowed only: `contexts.<other>.application.api`, `contexts._shared_kernel`,
same-context imports.

```bash
viol=0
for src in $(find contexts -name "*.py" -not -path "*_TEMPLATE*" -not -path "*__pycache__*"); do
  src_ctx=$(echo "$src" | sed -E 's|^contexts/([^/]+)/.*|\1|')
  bad=$(grep -E "^(from|import) contexts\." "$src" \
        | grep -vE "^(from|import) contexts\._shared_kernel" \
        | grep -vE "^from contexts\.${src_ctx}\." \
        | grep -vE "^import contexts\.${src_ctx}\." \
        | grep -vE "^from contexts\.[a-z_]+\.application\.api" \
        | grep -vE "^import contexts\.[a-z_]+\.application\.api" )
  if [ -n "$bad" ]; then
    viol=$((viol+1))
    echo "  ✗ $src"
    echo "$bad" | sed 's/^/      /'
  fi
done
[ $viol -eq 0 ] && echo "  ✓ no cross-context internal imports detected"
```

Findings: each violation → **HIGH**. Move the import to go via `application.api`
or refactor.

#### 2c. `_shared_kernel/` growth vs ADRs

The rule: **every shared-kernel VO needs an ADR** (because cross-context
shared state is high-coupling and merits explicit justification).

```bash
vo=$(find contexts/_shared_kernel -maxdepth 1 -name "*.py" -not -name "__init__.py" 2>/dev/null | wc -l)
adr=$(grep -rliE 'shared.?kernel' docs/adr/ 2>/dev/null | wc -l)
echo "  $vo VOs in shared kernel, $adr ADRs mentioning shared-kernel"
if [ "$vo" -gt 0 ] && [ "$adr" -lt "$vo" ]; then
  echo "  ⚠ fewer ADRs ($adr) than VOs ($vo) — write retroactive ADRs or remove unjustified VOs"
fi
```

Findings: `adr < vo` → **LOW** (debt, not block). Write retroactive ADRs.

---

### Section 3: Playground promotion candidates

Each `playground/<topic>/` is a spike. Audit each for promotion readiness.

```bash
[ ! -d playground ] && echo "  (no playground/ directory)" && return
for topic in playground/*/; do
  [ -d "$topic" ] || continue
  name=$(basename "$topic")
  age_days=$(( ($(date +%s) - $(stat -c %Y "$topic")) / 86400 ))
  loc=$(find "$topic" -type f \( -name "*.py" -o -name "*.ts" -o -name "*.tsx" -o -name "*.md" -o -name "*.sh" \) 2>/dev/null \
        | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}')
  loc=${loc:-0}
  [ -f "$topic/README.md" ] && rdme="Y" || rdme="N"
  ext_refs=$(grep -rlE "playground[/.]${name}" contexts/ apps/ 2>/dev/null | wc -l)
  sug=""
  [ "$ext_refs" -gt 0 ] && sug="→ PROMOTE (cited by $ext_refs files outside playground)"
  [ -z "$sug" ] && [ "$age_days" -gt 30 ] && [ "$loc" -gt 100 ] && sug="→ REVIEW (aged + non-trivial; sink to ctx/skill/docs or delete)"
  [ -z "$sug" ] && [ "$rdme" = "N" ] && sug="→ ADD README (capture what the spike concluded)"
  [ -z "$sug" ] && sug="✓ ok"
  printf "  %-30s age=%3dd loc=%4s readme=%s ext_refs=%d  %s\n" \
    "$name" "$age_days" "$loc" "$rdme" "$ext_refs" "$sug"
done
```

Findings and suggested classification:

| Signal | Suggested action | Priority |
|--------|-----------------|----------|
| `ext_refs > 0` | PROMOTE to a context (`/t3d-new-context X`) — code outside playground depends on it | **HIGH** |
| `age > 30d && loc > 100 && ext_refs = 0` | REVIEW — either promote, distill the insight into `docs/`, or delete | **MED** |
| `readme = N` | Write a 3-line README documenting what the spike concluded | **LOW** |
| Recent + has README + no refs | Leave alone; it's still active exploration | (no action) |

---

### Section 4: Session lessons (post-mortem from past sessions)

The harness fails at edit time; **patterns** of failure only show up across
sessions. Scan past session JSONLs to surface:

- **Pitfall candidates** — places where the user corrected behavior. Each is
  a candidate for a written-down "don't do X" rule.
- **Workflow candidates** — sequences of tool calls that the user approved
  ("perfect", "可以", "完美"). Each is a candidate for a reusable skill.

Run the extractor below. **It produces high-recall candidates with significant
false positives — your judgment is required** to separate real signals from
noise (e.g. "嗯嗯" often opens a new task, not approval of past work).

**Output discipline — read this first**:

- **Cap output at 2-3 per category per run.** No matter how many candidates
  extract finds, surface only the 2-3 strongest (cross-session-recurring,
  unambiguous, actionable). Append a single line
  `"N more candidates available — ask me to deep-dive into <category>"`
  if there are more.
- **Always dedup against what already exists** (step 4b below). A "new" pitfall
  that's already in `PITFALLS.md` is noise, not a finding.
- **Look for gaps too** — categories the existing files don't yet cover.

#### 4a. Run the extractor

```bash
# Locate this project's session JSONLs. Slug is project path with non-alphanum → '-'.
python3 << 'PY'
import json, re, os
from collections import Counter
from pathlib import Path

PROJECT  = os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd()
WINDOW_D = int(os.environ.get("T3D_LESSONS_DAYS", "30"))   # default: last 30 days
TOP_N    = int(os.environ.get("T3D_LESSONS_TOP", "6"))     # raw extract count — filter to 2-3 after

slug = re.sub(r'[^a-zA-Z0-9]', '-', PROJECT)
sess_dir = Path.home() / ".claude" / "projects" / slug
if not sess_dir.exists():
    print(f"  (no session log dir at {sess_dir} — is Claude Code in use here?)"); raise SystemExit

CORRECTION = ['不要', '别这样', '不对', '错了', '不行', '应该', '下次', '记住', '不是吧', 'wrong', "don't"]
APPROVAL   = ['perfect', '可以的', '完美', '对了']  # NOTE: '嗯嗯'/'好的' deliberately excluded — too noisy

import time; cutoff = time.time() - WINDOW_D*86400
files = [p for p in sess_dir.glob("*.jsonl") if p.stat().st_mtime > cutoff]
print(f"# scanning {len(files)} session(s) in last {WINDOW_D}d under {sess_dir}")

pitfalls, approvals, all_seqs = [], [], []

for jp in files:
    sid, prev = jp.stem, None
    rolling = []
    for line in open(jp):
        try: d = json.loads(line)
        except: continue
        t = d.get('type')

        if t == 'assistant':
            content = d.get('message', {}).get('content', [])
            tools, text = [], ''
            if isinstance(content, list):
                for b in content:
                    if not isinstance(b, dict): continue
                    if b.get('type') == 'tool_use': tools.append(b.get('name', ''))
                    elif b.get('type') == 'text':  text += b.get('text', '')
            if tools:
                rolling = (rolling + tools)[-12:]
            prev = {'tools': tools, 'text': text[:240], 'sid': sid}

        elif t == 'user':
            msg = d.get('message', {}).get('content', '')
            text = msg if isinstance(msg, str) else ''
            if isinstance(msg, list):
                text = ' '.join(b.get('text', '') for b in msg if isinstance(b, dict) and b.get('type') == 'text')
            if not isinstance(text, str) or len(text.strip()) < 3: continue
            # filter: tool_result lines + context-compaction summaries
            if text.startswith('<') or 'tool_use_id' in text: continue
            if 'This session is being continued' in text or 'context window' in text: continue
            tlc = text.lower()
            if any(k in tlc for k in CORRECTION):
                pitfalls.append({'sid': sid, 'user': text, 'prev': prev})
            if any(k in tlc for k in APPROVAL):
                approvals.append({'sid': sid, 'user': text, 'prev': prev, 'recent': rolling[-6:]})
                all_seqs.append(tuple(rolling[-6:]))

print(f"\n# {len(pitfalls)} pitfall candidates, {len(approvals)} approval candidates")
print(f"\n## TOP {TOP_N} PITFALL CANDIDATES (most recent)\n")
for i, p in enumerate(pitfalls[-TOP_N:], 1):
    pa = p['prev'] or {}
    print(f"[{i}] session={p['sid'][:8]}…")
    print(f"    user: {p['user'][:200].replace(chr(10),' ⏎ ')}")
    print(f"    prior_tools: {pa.get('tools', [])[:5]}")
    print(f"    prior_text:  {(pa.get('text','') or '').replace(chr(10),' ⏎ ')[:120]}")
    print()

print(f"## TOP {TOP_N} APPROVAL → WORKFLOW SEEDS\n")
for i, a in enumerate(approvals[-TOP_N:], 1):
    pa = a['prev'] or {}
    print(f"[{i}] session={a['sid'][:8]}…")
    print(f"    user: {a['user'][:160].replace(chr(10),' ⏎ ')}")
    print(f"    recent 6 tools: {' → '.join(a['recent']) or '(none)'}")
    print(f"    prior_text:  {(pa.get('text','') or '').replace(chr(10),' ⏎ ')[:120]}")
    print()

# Repeated 3-tool sequences before approval (workflow signature)
ngrams = Counter()
for seq in all_seqs:
    for i in range(len(seq) - 2):
        ngrams[seq[i:i+3]] += 1
print("## REPEATED 3-TOOL SEQUENCES BEFORE APPROVAL (>=3x)\n")
for tri, n in ngrams.most_common(20):
    if n >= 3:
        print(f"  {n:2}x: {' → '.join(tri)}")
PY
```

> Override defaults: `T3D_LESSONS_DAYS=7 T3D_LESSONS_TOP=15 ...`. For
> deep-history audit use `T3D_LESSONS_DAYS=365`.

#### 4b. Load existing pitfalls + skills (for dedup + gap analysis)

Before surfacing any candidate, read what's already documented. **Don't
re-suggest things that already exist; do flag categories that aren't yet
covered.**

```bash
# Plugin-level pitfalls (the cross-project canonical list)
PITFALL_PLUGIN="${CLAUDE_PLUGIN_ROOT}/PITFALLS.md"
[ -f "$PITFALL_PLUGIN" ] && {
  echo "── existing plugin-level pitfalls (categories + titles) ──"
  awk '/^## / {print "  CAT: " substr($0,4)} /^### / {print "       - " substr($0,5)}' "$PITFALL_PLUGIN"
} || echo "  (no plugin PITFALLS.md)"

# Project-level pitfalls (this repo's specific ones)
PITFALL_PROJ=".claude/PITFALLS.md"
[ -f "$PITFALL_PROJ" ] && {
  echo "── existing project-level pitfalls ──"
  awk '/^## / {print "  CAT: " substr($0,4)} /^### / {print "       - " substr($0,5)}' "$PITFALL_PROJ"
} || echo "  (no .claude/PITFALLS.md yet)"

# Existing t3d skills (so we don't re-propose a workflow that already has a skill)
echo "── existing t3d-shipped skills ──"
ls -d "${CLAUDE_PLUGIN_ROOT}/skills"/*/ 2>/dev/null | xargs -n1 basename | sed 's/^/  - /'

# Local draft skills (the user may have already started one)
echo "── existing local draft skills ──"
ls -d .claude/skills/draft-*/ plugin/t3d/skills/draft-*/ 2>/dev/null | xargs -n1 basename | sed 's/^/  - /' || echo "  (none)"
```

#### 4c. Filter the noise + dedup (CLAUDE judgment, not regex)

For each candidate from 4a, walk this 3-step filter:

**Step A — is it real?** Reject unless you can quote a specific behavior to
fix or reproduce. Common false positives:
- User says "嗯嗯" or "好的" then gives a *new* task (transition, not approval)
- User asks "为什么 X" as a curious question, not a correction
- User pastes a long spec (the "spec mentions 不对 in passing" trap)
- User reads a long context-compaction summary that includes earlier "错" mentions

**Step B — is it already documented?** Compare against the lists from 4b:
- Same rule already in `plugin/t3d/PITFALLS.md` or `.claude/PITFALLS.md`?
  → SKIP (or, if you have a fresh source, suggest adding the new
  `_Source:_` line to the existing entry)
- Same workflow already covered by `t3d-init` / `t3d-new-context` /
  `t3d-grill-me` / `t3d-sinkin` / any local `draft-*` skill?
  → SKIP

**Step C — is it actionable AND general enough?** Could a future agent
benefit from this exact rule? If only "you, today, with this exact file
structure" → skip.

After A/B/C, you should have many fewer survivors. **Pick the top 2-3
strongest** by these tie-breakers:
1. Cross-session recurrence (same rule triggered in N different sessions)
2. Cost of the original mistake (data loss > confusion > minor friction)
3. Unambiguousness (clear quote-able rule > vibes)

#### 4d. Gap analysis: what's missing from existing PITFALLS

Walk the categories you found in 4b's existing files. Are there obvious
**categories** with zero entries that this scan suggests should exist?

Examples:
- Existing `plugin/t3d/PITFALLS.md` has "Shell" + "LLM semantics" + "plugin dev"
  but you saw 5 candidates around "git workflow" → **GAP: no "Git" category**
- Existing covers "things to avoid" but you saw repeated successful patterns
  worth their own positive-form section → **GAP: no "Recommended patterns"**

Report gaps separately (NOT as new candidates) — they're meta-observations
the user might want to act on independently.

#### 4e. Classify surviving 2-3: PLUGIN-level vs PROJECT-level

For each surviving candidate ask: **would another t3d user benefit?**

| Signal | Goes to |
|--------|---------|
| Generic Claude Code / shell / DDD pitfall (e.g. "pkill -f kills its own shell") | PLUGIN — `plugin/t3d/PITFALLS.md` |
| Specific to this project's domain / files / business rules | PROJECT — `<project>/.claude/PITFALLS.md` |
| Reusable workflow involving t3d itself (init / new-context / sinkin) | PLUGIN — draft skill at `plugin/t3d/skills/draft-<name>/SKILL.md` |
| Reusable workflow specific to *this* repo (e.g. "backfill from transcripts then run analytics") | PROJECT — draft skill at `<project>/.claude/skills/draft-<name>/SKILL.md` |

#### 4f. Report format (Section 4 part of final report)

Strict cap: **2-3 pitfalls, 2-3 workflow seeds.** No exceptions.

```markdown
## Section 4: Session lessons

Scanned: N session(s), last 30 days.
Raw candidates: P pitfalls, A approvals. After dedup + filter: <≤3 + ≤3>.

### New pitfalls (≤3, cross-checked against existing PITFALLS.md):
1. **[PLUGIN | new]** "<one-line rule>"
   - Evidence: saw 3x in sessions XX, YY, ZZ. Last quote: "<short>"
   - Suggested entry: under `## <category>` in plugin/t3d/PITFALLS.md
2. **[PROJECT | new]** "<one-line rule>"
   - Evidence: ...
   - Suggested entry: under `## <category>` in .claude/PITFALLS.md

<single line if applicable: "N more candidates available — ask me to deep-dive into pitfalls">

### Updates to existing pitfalls (≤3):
- "<existing entry title>" — saw a fresh case in session XX, suggest appending
  `_Source: session XX, YYYY-MM-DD_` to the existing entry.

### New workflow seeds (≤3, deduped against existing skills):
1. **[PLUGIN | new]** "<name>" — tools `A → B → C`, recurring Nx.
   Suggested draft: `plugin/t3d/skills/draft-<name>/SKILL.md`
2. **[PROJECT | new]** "<name>" — ...

<single line if applicable: "N more candidates available — ask me to deep-dive into workflows">

### Gaps (categories that may be missing entirely):
- `plugin/t3d/PITFALLS.md` has no "<category>" section, but I saw 4 candidates fitting it.
  Suggest adding a new section before the next sinkin run.

### Skipped:
- <bucket name>: N items (e.g. "嗯嗯 transitions": 22, "context-summary echoes": 5)
```

#### 4g. Promote commands (suggestions only — user decides)

Don't write any of these files yourself. Just suggest the user run:

```bash
# To add a plugin-level pitfall (after user confirms wording)
cat >> "${CLAUDE_PLUGIN_ROOT}/PITFALLS.md" << 'EOF'
## <category>
- **<rule>**: <why / when it happens / how to avoid>
  - Source: session XX, MM-DD
EOF

# To add a project-level pitfall
mkdir -p .claude && cat >> .claude/PITFALLS.md << 'EOF'
... (same shape)
EOF

# To draft a new skill
mkdir -p plugin/t3d/skills/draft-<name>
$EDITOR plugin/t3d/skills/draft-<name>/SKILL.md  # or .claude/skills/draft-<name>/
```

---

## Final report format

After running all four sections, compose a single Markdown report:

```markdown
# t3d-sinkin report — <today's date>

## Health summary
- Contexts: <N total>, <X> fully passing structure checks
- Drift items: <count by HIGH/MED/LOW>
- Playground items needing action: <count>
- Session lessons: <P real pitfalls, W workflow seeds, S skipped>

## Section 1: Docs ↔ Code
<paste section 1 output>

## Section 2: Folder structure
<paste section 2 output>

## Section 3: Playground
<paste section 3 output>

## Section 4: Session lessons
<paste filtered + classified section 4 output>

## Action list (prioritized)

### 🔴 HIGH (fix this week)
1. <specific action>: <file>, e.g. "Write test for INV-014 in contexts/ingestion/tests/unit/"
2. PROMOTE pitfall #1 to plugin/t3d/PITFALLS.md (user must confirm wording)
...

### 🟡 MED (next sprint)
1. <specific action>
...

### 🟢 LOW (tech-debt log)
1. <specific action> — consider adding to `docs/TECH_DEBT.md`
...

## What's healthy
- <highlights — keep team morale; don't only list problems>
```

## Hard rules

- **NEVER edit files in this skill.** It's a read-only audit. If the user asks
  you to fix what you found, do that in a separate turn outside the skill.
- **Don't lecture.** If everything is green, say so in one line and stop.
- **Be specific in the action list.** "Add tests" is bad; "Write
  `contexts/ingestion/tests/unit/test_inv_014_merge_priority.py` covering INV-014"
  is good.
- **Don't auto-promote playground items or session lessons.** Just suggest;
  the user decides whether something is ready and approves the wording.
- **Don't run the checks twice if the user asks "again".** Cache the previous
  report and offer to re-run only a specific section.
- **Session lessons require judgment, not just regex.** Reject any candidate
  where you can't quote specific behavior. False positives waste user attention.
- **Privacy.** Section 4 quotes user messages verbatim. Don't promote pitfalls
  containing PII or credentials. Truncate or paraphrase.
- **Cap Section 4 at 2-3 new pitfalls + 2-3 new workflows + ≤3 updates per run.**
  More findings overwhelm the user; better to surface the strongest signals
  every week than a flood once. If there are more, end with a single
  `"N more available — ask me to deep-dive into <category>"` invitation.
- **Always dedup first.** Read `plugin/t3d/PITFALLS.md` and
  `.claude/PITFALLS.md` (if it exists) plus the existing skill list before
  proposing. A "new" finding that's already documented is noise.
