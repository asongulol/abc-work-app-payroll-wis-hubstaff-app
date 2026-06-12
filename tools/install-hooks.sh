#!/usr/bin/env bash
#
# tools/install-hooks.sh
#
# One-time setup: links the tracked git hooks into .git/hooks/ and makes the
# tracked scripts executable. Run once after cloning, or after a hook changes.
#
#     npm run hooks:install      (or: bash tools/install-hooks.sh)

set -euo pipefail
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

for hook in pre-commit pre-push; do
  cp "tools/hooks/$hook" ".git/hooks/$hook"
  chmod +x ".git/hooks/$hook"
  echo "Installed $hook hook."
done

chmod +x tools/gen-changelog.sh tools/check-secrets.sh tools/deploy.sh 2>/dev/null || true

echo ""
echo "Hooks installed:"
echo "  pre-commit  → blocks secrets/PII (tools/check-secrets.sh)"
echo "  pre-push    → lint + build:check, then AI changelog (tools/gen-changelog.sh)"
echo ""
echo "For the changelog, set ANTHROPIC_API_KEY in your shell (e.g. ~/.zshrc):"
echo "  export ANTHROPIC_API_KEY=sk-ant-..."
