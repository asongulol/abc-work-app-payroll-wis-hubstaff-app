#!/bin/bash
# One-shot script to initialize git and push this folder to GitHub.
# Run from your Mac terminal:  bash setup_github.sh
#
# Prerequisites:
#   1. You've created a private GitHub repo (don't initialize it with README/gitignore/license).
#   2. You have the repo URL handy (looks like git@github.com:olivertrinidad/hr-payroll-app.git
#      or https://github.com/olivertrinidad/hr-payroll-app.git).
#   3. You have git installed (run `git --version` to check).
#   4. If using SSH URL: you have an SSH key set up with GitHub.
#      If using HTTPS URL: you'll be prompted for a personal access token.

set -e

cd "$(dirname "$0")"

# Step 0: Clean up any stale .git from a previous attempt
if [ -d .git ]; then
  echo "Removing existing .git directory (clean slate)..."
  rm -rf .git
fi

# Step 1: Initialize
echo "==> Initializing git repo on main branch..."
git init -b main

# Step 2: Verify .gitignore is in place
if [ ! -f .gitignore ]; then
  echo "ERROR: .gitignore missing. Aborting before adding files."
  exit 1
fi

# Step 3: Stage everything (respecting .gitignore)
echo "==> Staging files..."
git add .

# Step 4: SANITY CHECK — no excluded files should be staged
echo "==> Verifying excluded files are not staged..."
BAD=$(git status --short | grep -E "node_modules|\.DS_Store|diagnose_jam|_select_|_All_.*\.csv|payroll_history|\.env|jam_diagnostic_output" || true)
if [ -n "$BAD" ]; then
  echo "ABORT — these files should not be staged:"
  echo "$BAD"
  exit 1
fi
echo "    OK — no excluded files staged."

# Step 5: Show what WILL be committed
echo ""
echo "==> Files about to be committed:"
git status --short
echo ""
read -p "Proceed with commit? (y/N) " yn
if [ "$yn" != "y" ] && [ "$yn" != "Y" ]; then
  echo "Aborted by user."
  exit 0
fi

# Step 6: Commit
echo "==> Committing..."
git config user.email "${GIT_EMAIL:-otrinidad@abckidsny.com}"
git config user.name "${GIT_NAME:-Oliver Trinidad}"
git commit -m "Initial commit: HR & Payroll app (Wise + Hubstaff + Supabase)"

# Step 7: Add remote + push
echo ""
read -p "Paste your GitHub repo URL (ssh or https): " REPO_URL
if [ -z "$REPO_URL" ]; then
  echo "No URL given. Commit is local-only for now. To push later:"
  echo "  git remote add origin <URL>"
  echo "  git push -u origin main"
  exit 0
fi

git remote add origin "$REPO_URL"
echo "==> Pushing to $REPO_URL ..."
git push -u origin main

echo ""
echo "Done. View your repo at: $REPO_URL"
