#!/usr/bin/env bash
#
# tools/gen-changelog.sh
#
# Generates a plain-English changelog entry from the git diff of what you're
# about to push, using Claude Haiku, and prepends it to CHANGELOG.md.
#
# Token cost scales with diff SIZE only (we never send the whole repo, and we
# exclude lockfiles/build output and hard-cap the diff). Typically pennies/push.
#
# Called automatically by .git/hooks/pre-push, or run manually:
#     ANTHROPIC_API_KEY=sk-... bash tools/gen-changelog.sh
#
# Requirements: jq, curl, and an ANTHROPIC_API_KEY in your environment.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

# --- guard: need an API key -------------------------------------------------
if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
  echo "[gen-changelog] ANTHROPIC_API_KEY not set; skipping doc generation." >&2
  echo "[gen-changelog] (push continues normally.)" >&2
  exit 0
fi

# --- figure out what we're documenting --------------------------------------
# Diff against the last changelog marker tag, or the last commit if none.
LAST_TAG="$(git tag --list 'changelog-*' --sort=-creatordate | head -n1)"
if [ -z "$LAST_TAG" ]; then
  RANGE="HEAD~1..HEAD"
else
  RANGE="$LAST_TAG..HEAD"
fi

# Size-limited diff; skip noise that wastes tokens.
git diff "$RANGE" -- . \
  ':(exclude)package-lock.json' \
  ':(exclude)yarn.lock' \
  ':(exclude)pnpm-lock.yaml' \
  ':(exclude)dist/**' \
  ':(exclude)node_modules/**' \
  > /tmp/_changelog_diff.txt 2>/dev/null || true

# Hard cap (~12k chars) keeps cost predictable.
head -c 12000 /tmp/_changelog_diff.txt > /tmp/_changelog_diff_capped.txt
mv /tmp/_changelog_diff_capped.txt /tmp/_changelog_diff.txt

if [ ! -s /tmp/_changelog_diff.txt ]; then
  echo "[gen-changelog] No meaningful diff to document; skipping." >&2
  exit 0
fi

echo "[gen-changelog] Summarizing changes in $RANGE ..." >&2

# --- call the model ---------------------------------------------------------
PROMPT="You are writing a changelog entry for a payroll application (PH contractors, Supabase backend, Wise payouts, Hubstaff time tracking). Given the git diff below, write a concise plain-English summary of what changed and why it matters. Group under headings: Added / Changed / Fixed (omit any that don't apply). Use short bullet points. Do not invent changes that are not present in the diff. Diff follows:"

jq -n \
  --arg model "claude-haiku-4-5-20251001" \
  --arg prompt "$PROMPT" \
  --rawfile diff /tmp/_changelog_diff.txt \
  '{
    model: $model,
    max_tokens: 700,
    messages: [ { role: "user", content: ($prompt + "\n\n" + $diff) } ]
  }' > /tmp/_changelog_req.json

RESP="$(curl -s https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d @/tmp/_changelog_req.json)"

NOTE="$(echo "$RESP" | jq -r '.content[0].text // empty')"

if [ -z "$NOTE" ]; then
  echo "[gen-changelog] API returned no summary; leaving CHANGELOG.md untouched." >&2
  echo "[gen-changelog] Raw response: $RESP" >&2
  exit 0
fi

# --- prepend to CHANGELOG.md ------------------------------------------------
DATE="$(date -u +%Y-%m-%d)"
SHA="$(git rev-parse --short HEAD)"
{
  echo "## $DATE ($SHA)"
  echo ""
  echo "$NOTE"
  echo ""
  if [ -f CHANGELOG.md ]; then cat CHANGELOG.md; fi
} > /tmp/_changelog_new.md
mv /tmp/_changelog_new.md CHANGELOG.md

# Commit the changelog and drop a marker tag so the next run diffs from here.
git add CHANGELOG.md
git commit -m "docs: update changelog ($SHA)" >/dev/null 2>&1 || true
git tag "changelog-$(date -u +%Y%m%d%H%M%S)" >/dev/null 2>&1 || true

echo "[gen-changelog] CHANGELOG.md updated and committed." >&2
