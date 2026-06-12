#!/usr/bin/env bash
#
# tools/deploy.sh — one-command deploy for the HR & Payroll app.
#
# Does, in order:
#   1. Pre-flight: clean working tree check + run lint/build:check.
#   2. Build: stamp build info + precompile single-file apps into dist/.
#   3. Frontend: `wrangler deploy` each app (admin + portal) as static-asset Workers.
#   4. Backend: deploy ONLY the Supabase edge functions that changed since last deploy.
#
# Usage:
#   bash tools/deploy.sh                # full deploy (asks before each prod step)
#   bash tools/deploy.sh --frontend     # only build + deploy the Workers
#   bash tools/deploy.sh --functions    # only deploy changed edge functions
#   bash tools/deploy.sh --all-functions# redeploy every function (ignore diff)
#   bash tools/deploy.sh --yes          # skip confirmation prompts (CI/non-interactive)
#
# Requires: wrangler, supabase CLI, node. Run `supabase link` once beforehand.

set -uo pipefail
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

DO_FRONTEND=1; DO_FUNCTIONS=1; ALL_FUNCTIONS=0; ASSUME_YES=0
for arg in "$@"; do
  case "$arg" in
    --frontend)      DO_FRONTEND=1; DO_FUNCTIONS=0 ;;
    --functions)     DO_FRONTEND=0; DO_FUNCTIONS=1 ;;
    --all-functions) DO_FRONTEND=0; DO_FUNCTIONS=1; ALL_FUNCTIONS=1 ;;
    --yes|-y)        ASSUME_YES=1 ;;
    *) echo "Unknown arg: $arg" >&2; exit 2 ;;
  esac
done

confirm() {
  [ "$ASSUME_YES" -eq 1 ] && return 0
  read -r -p "$1 [y/N] " ans
  case "$ans" in y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
}

require() { command -v "$1" >/dev/null 2>&1 || { echo "❌ '$1' not found in PATH. $2" >&2; exit 1; }; }

# ---- 1. Pre-flight ---------------------------------------------------------
echo "▶ Pre-flight checks…"
require node "Install Node."
if [ -n "$(git status --porcelain)" ]; then
  echo "⚠  Working tree is not clean. Deploying built output from current files anyway."
  confirm "Continue with uncommitted changes?" || { echo "Aborted."; exit 1; }
fi
npm run --silent lint     || { echo "❌ lint failed."; exit 1; }
npm run --silent build:check || { echo "❌ build:check failed."; exit 1; }
echo "✓ Pre-flight passed."

# ---- 2. Frontend: stamp + push (Cloudflare auto-builds from main) ----------
# Per README, the live frontend deploy IS `git push origin main` — both Workers
# are git-connected and rebuild in ~15s. So the script's job here is to ensure
# the build stamp is fresh and remind you to push; it does NOT wrangler-deploy
# prod (that would be a second, divergent deploy path).
if [ "$DO_FRONTEND" -eq 1 ]; then
  echo "▶ Stamping build footer + version.txt…"
  npm run --silent stamp || { echo "❌ stamp failed."; exit 1; }
  echo "✓ Stamped. (app/index.html, portal/index.html, version.txt updated.)"
  echo ""
  echo "Frontend deploys by pushing to main (Cloudflare auto-builds, ~15s):"
  echo "    git add -A && git commit -m 'deploy: <summary>' && git push origin main"
  echo ""
  echo "Verify after the push:"
  echo "    curl -s https://abc-work-app-payroll-wis-hubstaff-app.asongulol.workers.dev/ | grep 'const BUILD'"
  if confirm "Stage, commit, and push the stamp now?"; then
    git add -A
    git commit -m "deploy: stamp build $(git rev-parse --short HEAD 2>/dev/null)" || true
    git push origin main || { echo "❌ git push failed."; exit 1; }
    echo "✓ Pushed — Cloudflare is rebuilding."
  else
    echo "↷ Not pushed. Push manually when ready."
  fi
fi

# ---- 4. Backend: changed Supabase edge functions --------------------------
if [ "$DO_FUNCTIONS" -eq 1 ]; then
  require supabase "Install the Supabase CLI: https://supabase.com/docs/guides/cli"
  FUNCS_DIR="supabase/functions"
  LAST_TAG="$(git tag --list 'deploy-fn-*' --sort=-creatordate | head -n1)"

  if [ "$ALL_FUNCTIONS" -eq 1 ] || [ -z "$LAST_TAG" ]; then
    changed="$(ls -d "$FUNCS_DIR"/*/ 2>/dev/null | xargs -n1 basename)"
    [ "$ALL_FUNCTIONS" -eq 1 ] && echo "▶ Deploying ALL functions (forced)." \
                               || echo "▶ No previous deploy-fn tag; deploying ALL functions (first run)."
  else
    changed="$(git diff --name-only "$LAST_TAG"..HEAD -- "$FUNCS_DIR" \
               | sed -nE "s#^$FUNCS_DIR/([^/]+)/.*#\1#p" | sort -u)"
    if [ -z "$changed" ]; then
      echo "▶ No edge functions changed since $LAST_TAG. Nothing to deploy."
    else
      echo "▶ Changed functions since $LAST_TAG:"; echo "$changed" | sed 's/^/   - /'
    fi
  fi

  if [ -n "$changed" ]; then
    if confirm "Deploy the above function(s) to PROD Supabase?"; then
      for fn in $changed; do
        echo "  → supabase functions deploy $fn"
        supabase functions deploy "$fn" || { echo "❌ deploy failed for $fn"; exit 1; }
      done
      git tag "deploy-fn-$(date -u +%Y%m%d%H%M%S)" >/dev/null 2>&1 || true
      echo "✓ Functions deployed and tagged."
    else
      echo "↷ Skipped function deploy."
    fi
  fi
fi

echo "✅ Deploy script finished."
