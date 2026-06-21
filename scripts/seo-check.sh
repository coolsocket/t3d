#!/usr/bin/env bash
#
# scripts/seo-check.sh — reusable SEO health check for a GitHub repo
#
# Usage:
#   bash scripts/seo-check.sh                        # defaults to coolsocket/t3d
#   REPO=owner/name bash scripts/seo-check.sh        # check any other repo
#
# What it checks (no external SaaS needed — just gh + curl + grep):
#   1. Repo metadata completeness (description, topics count, releases, discussions)
#   2. Search ranking against a set of target keywords/topics
#   3. OG (Open Graph) + Twitter card metadata Github renders for your repo URL
#   4. Social-preview image availability + size
#   5. README link healthcheck (no 404s)
#   6. Star / fork / watcher counts (passive popularity)
#   7. Recent activity (last commit date, open PRs/issues)
#
# Output: pass/fail per check + final score X/N
#
# Exit code: 0 if score >= 70%, 1 otherwise.
#
# Requires: bash 4+, gh CLI logged in, curl, python3, jq

set -uo pipefail

REPO="${REPO:-coolsocket/t3d}"

# Target queries to test ranking. Tune for your project's positioning.
QUERIES=(
  "DDD claude-code"
  "TDD claude-code"
  "topic:claudecode-hooks"
  "topic:claude-plugin"
  "topic:bounded-context"
)

# colors
G="\033[32m"; Y="\033[33m"; R="\033[31m"; B="\033[34m"; N="\033[0m"
ok()   { printf "${G}✓${N} %s\n" "$*"; PASS=$((PASS+1)); }
warn() { printf "${Y}⚠${N} %s\n" "$*"; WARN=$((WARN+1)); }
fail() { printf "${R}✗${N} %s\n" "$*"; FAIL=$((FAIL+1)); }
sec()  { printf "\n${B}─── %s ───${N}\n" "$*"; }

PASS=0; WARN=0; FAIL=0
TOTAL_QUERIES=${#QUERIES[@]}

printf "${B}SEO check for %s${N}\n" "$REPO"

# ── 1. Repo metadata completeness ──
sec "1. Repo metadata"
meta=$(gh api "repos/$REPO" 2>/dev/null) || { fail "repo not found"; exit 1; }

desc=$(jq -r '.description // ""' <<<"$meta")
[ -n "$desc" ] && [ ${#desc} -gt 50 ] \
  && ok "description set (${#desc} chars)" \
  || warn "description short or missing (${#desc} chars; recommend ≥80)"

topic_count=$(gh api "repos/$REPO/topics" --jq '.names | length' 2>/dev/null)
if [ "$topic_count" -ge 15 ]; then ok "topics: $topic_count/20"
elif [ "$topic_count" -ge 5 ]; then warn "topics: $topic_count/20 (recommend 15+)"
else fail "topics: $topic_count/20"; fi

releases=$(gh api "repos/$REPO/releases" --jq '. | length' 2>/dev/null)
[ "$releases" -gt 0 ] && ok "releases: $releases" || warn "no releases (sidebar slot empty)"

has_disc=$(jq -r '.has_discussions' <<<"$meta")
[ "$has_disc" = "true" ] && ok "discussions enabled" || warn "discussions disabled"

[ -f CITATION.cff ] && ok "CITATION.cff present" || warn "CITATION.cff missing (no 'Cite' button in sidebar)"

# ── 2. Search ranking ──
sec "2. Search ranking"
ranked=0
for q in "${QUERIES[@]}"; do
  rank=$(gh search repos "$q" --limit 30 --json fullName,stargazersCount 2>/dev/null \
    | python3 -c "
import json, sys, os
data = json.load(sys.stdin)
target = os.environ['REPO']
for i, r in enumerate(data, 1):
    if r['fullName'] == target:
        print(f'{i}/{len(data)}')
        break
else:
    print(f'-/-')
" 2>/dev/null) || rank="-/-"

  if [ "$rank" = "-/-" ]; then
    warn "  '$q' → not ranked (top 30)"
  else
    pos="${rank%%/*}"
    if [ "$pos" -le 5 ]; then ok "  '$q' → #$rank ★"
    elif [ "$pos" -le 15 ]; then ok "  '$q' → #$rank"
    else warn "  '$q' → #$rank"; fi
    ranked=$((ranked+1))
  fi
done
echo "  ranked in $ranked/$TOTAL_QUERIES queries"

# ── 3. OG / Twitter card metadata ──
sec "3. OG + Twitter card metadata"
og=$(curl -sL "https://github.com/$REPO" 2>/dev/null)
twitter_card=$(echo "$og" | grep -oE 'name="twitter:card" content="[^"]*"' | head -1 | sed 's/.*content="//;s/"$//')
og_image=$(echo "$og" | grep -oE 'property="og:image" content="[^"]*"' | head -1 | sed 's/.*content="//;s/"$//')
og_desc=$(echo "$og" | grep -oE 'property="og:description" content="[^"]*"' | head -1 | sed 's/.*content="//;s/"$//')

if [ "$twitter_card" = "summary_large_image" ]; then ok "twitter:card = summary_large_image (big preview)"
else fail "twitter:card = '${twitter_card:-missing}' (want summary_large_image)"; fi

[ -n "$og_image" ] && ok "og:image set: ${og_image:0:60}..." || fail "og:image missing"
[ -n "$og_desc" ] && [ ${#og_desc} -gt 50 ] && ok "og:description set" || warn "og:description short"

# ── 4. Social-preview image actually loads ──
sec "4. Social-preview image"
img_status=$(curl -sIo /dev/null -w "%{http_code}" "$og_image" 2>/dev/null)
img_size=$(curl -sIo /dev/null -w "%{size_download}" "$og_image" 2>/dev/null)
img_bytes=$(curl -s "$og_image" 2>/dev/null | wc -c)

if [ "$img_status" = "200" ] && [ "$img_bytes" -gt 5000 ]; then
  ok "social-preview loads ($img_status, ${img_bytes} bytes)"
else
  fail "social-preview broken (HTTP $img_status, ${img_bytes} bytes)"
fi

# ── 5. README link healthcheck ──
sec "5. README links"
if [ -f README.md ]; then
  links=$(grep -oE 'https?://[^)[:space:]]+' README.md | sort -u)
  total=$(echo "$links" | wc -l)
  dead=0
  while IFS= read -r u; do
    [ -z "$u" ] && continue
    code=$(curl -sLo /dev/null -w "%{http_code}" --max-time 5 "$u" 2>/dev/null || echo TIME)
    case "$code" in
      2*|301|302|429) : ;;  # treat rate-limited as ok
      *) echo "    dead: $code  $u"; dead=$((dead+1)) ;;
    esac
  done <<< "$links"
  alive=$((total-dead))
  if [ "$dead" -eq 0 ]; then ok "README links: $alive/$total live"
  else fail "README links: $alive/$total ($dead dead)"; fi
else
  warn "no README.md to check"
fi

# ── 6. Popularity signals ──
sec "6. Popularity signals"
stars=$(jq -r '.stargazers_count' <<<"$meta")
forks=$(jq -r '.forks_count' <<<"$meta")
watchers=$(jq -r '.subscribers_count' <<<"$meta")
[ "$stars" -ge 100 ] && ok "stars: $stars" || warn "stars: $stars (search rank ≈ star-weighted)"
[ "$forks" -ge 1 ] && ok "forks: $forks" || warn "forks: 0"
[ "$watchers" -ge 1 ] && ok "watchers: $watchers" || warn "watchers: 0"

# ── 7. Recent activity ──
sec "7. Recent activity"
last_push=$(jq -r '.pushed_at' <<<"$meta")
days_ago=$(( ($(date +%s) - $(date -d "$last_push" +%s)) / 86400 ))
if [ "$days_ago" -le 30 ]; then ok "last push ${days_ago}d ago"
elif [ "$days_ago" -le 180 ]; then warn "last push ${days_ago}d ago (Google penalizes stale)"
else fail "last push ${days_ago}d ago (looks abandoned)"; fi

open_prs=$(gh pr list --repo "$REPO" --state open --json number --jq '. | length' 2>/dev/null || echo 0)
open_issues=$(jq -r '.open_issues' <<<"$meta")
echo "  open PRs: $open_prs"
echo "  open issues: $open_issues"

# ── Score ──
total_checks=$((PASS + WARN + FAIL))
sec "Score"
printf "  ${G}PASS${N}: %d   ${Y}WARN${N}: %d   ${R}FAIL${N}: %d\n" $PASS $WARN $FAIL
pct=$((PASS * 100 / total_checks))
printf "  Overall: ${B}%d%%${N}\n" $pct

[ $pct -ge 70 ] && exit 0 || exit 1
