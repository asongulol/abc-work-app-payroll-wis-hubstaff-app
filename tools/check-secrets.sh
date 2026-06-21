#!/usr/bin/env bash
#
# tools/check-secrets.sh
#
# Blocks commits that would leak credentials or contractor PII. Scans STAGED
# changes only (fast, and matches what's actually about to be committed).
#
# Catches:
#   - Supabase service-role / JWT secrets, Wise & Hubstaff API tokens
#   - Generic "sk-..." / bearer tokens / long hex/base64 secrets in assignments
#   - PII data files (*.csv) sneaking in despite .gitignore (e.g. via `git add -f`)
#
# Exit non-zero => commit is aborted. Override a known-safe match with:
#     git commit --no-verify     (use sparingly)

set -uo pipefail
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

fail=0

# 1) Block staged CSVs outright (contractor PII).
staged_csv="$(git diff --cached --name-only --diff-filter=A | grep -iE '\.csv$' || true)"
if [ -n "$staged_csv" ]; then
  echo "❌ Refusing to commit CSV file(s) — these may contain contractor PII:" >&2
  echo "$staged_csv" | sed 's/^/   - /' >&2
  echo "   If this is genuinely safe, remove it from staging or use --no-verify." >&2
  fail=1
fi

# 2) Scan the staged diff content for secret-looking strings.
#    Only added lines (+) are scanned. Exclude this scanner and the hook files —
#    they legitimately contain the very keywords (service_role, token, password…)
#    we search for, so scanning them would false-positive on their own patterns.
added="$(git diff --cached --no-color -U0 -- . ':(exclude)tools/check-secrets.sh' ':(exclude)tools/hooks' | grep -E '^\+' | grep -vE '^\+\+\+' || true)"

# Patterns: provider-specific + generic high-entropy assignments.
patterns=(
  'eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}'          # JWT (Supabase anon/service-role)
  'service[_-]?role[_a-z]*["'\'']?[[:space:]]*[:=][[:space:]]*["'\'']?[A-Za-z0-9._-]{20,}'  # service-role key VALUE in an assignment (not the bare role name in GRANTs / the SUPABASE_SERVICE_ROLE_KEY env-var name / prose). Real keys are JWTs — also caught by the eyJ pattern above.
  'sk-[A-Za-z0-9]{20,}'                                 # OpenAI/Anthropic-style keys
  'sk_live_[A-Za-z0-9]{20,}'                            # Stripe-style live keys
  '(WISE|HUBSTAFF)[A-Z_]*(TOKEN|KEY|SECRET)\s*[:=]\s*[A-Za-z0-9._-]{12,}'
  '(api[_-]?key|secret|token|password)\s*[:=]\s*["'\''][A-Za-z0-9._-]{16,}["'\'']'
  'Bearer\s+[A-Za-z0-9._-]{20,}'
)

for p in "${patterns[@]}"; do
  hits="$(echo "$added" | grep -nEi "$p" || true)"
  if [ -n "$hits" ]; then
    echo "❌ Possible secret in staged changes (pattern: $p):" >&2
    echo "$hits" | sed 's/^/   /' >&2
    fail=1
  fi
done

if [ "$fail" -ne 0 ]; then
  echo "" >&2
  echo "Commit blocked by tools/check-secrets.sh." >&2
  echo "Secrets belong in Supabase secrets / your local env, never in git." >&2
  exit 1
fi

exit 0
