#!/usr/bin/env bash
set -euo pipefail

# CI Excellence: Show integration status
# Purpose: Display current ci-excellence version, available updates, customized files
# Usage: ./scripts/setup/ci-status.sh

CONFIG_FILE=".ci-excellence.yml"

echo "=== CI Excellence Status ==="
echo ""

# Check config
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Status: NOT INTEGRATED"
  echo "  Run ci-integrate.sh to get started."
  exit 0
fi

# Find remote
CI_REMOTE=""
for name in ci ci-excellence; do
  if git remote get-url "$name" &>/dev/null; then
    CI_REMOTE="$name"
    break
  fi
done

if [ -z "$CI_REMOTE" ]; then
  echo "Status: CONFIG EXISTS but no remote found"
  echo "  Run ci-integrate.sh to set up the remote."
  exit 1
fi

CI_URL="$(git remote get-url "$CI_REMOTE")"
echo "Remote: $CI_REMOTE ($CI_URL)"

# Parse branch from config
CI_BRANCH="dist"
branch_line="$(grep '^branch:' "$CONFIG_FILE" 2>/dev/null || true)"
if [ -n "$branch_line" ]; then
  CI_BRANCH="$(echo "$branch_line" | sed 's/branch:[[:space:]]*//')"
fi

# Current version (from last merge commit)
MERGE_COMMIT="$(git log --merges --format='%H' --grep='ci-excellence' -1 2>/dev/null || true)"
if [ -n "$MERGE_COMMIT" ]; then
  MERGE_DATE="$(git log -1 --format='%ci' "$MERGE_COMMIT")"
  MERGE_MSG="$(git log -1 --format='%s' "$MERGE_COMMIT")"
  echo "Current: $MERGE_MSG"
  echo "  Date: $MERGE_DATE"
  echo "  Commit: $(git rev-parse --short "$MERGE_COMMIT")"
else
  echo "Current: (no merge history found)"
fi

# Check for updates
echo ""
echo "Checking for updates..."
git fetch "$CI_REMOTE" "$CI_BRANCH" 2>/dev/null || { echo "  (fetch failed)"; exit 0; }

REMOTE_HEAD="$(git rev-parse --short "$CI_REMOTE/$CI_BRANCH")"
echo "Latest available: $REMOTE_HEAD"

if [ -n "$MERGE_COMMIT" ]; then
  if git merge-base --is-ancestor "$CI_REMOTE/$CI_BRANCH" HEAD 2>/dev/null; then
    echo "Status: UP TO DATE"
  else
    BEHIND="$(git rev-list --count HEAD.."$CI_REMOTE/$CI_BRANCH" 2>/dev/null || echo '?')"
    echo "Status: $BEHIND commits behind"
    echo ""
    echo "New changes:"
    git log --oneline "$MERGE_COMMIT".."$CI_REMOTE/$CI_BRANCH" 2>/dev/null | head -10
  fi
else
  echo "Status: INITIAL (not yet merged)"
fi

echo ""
echo "To upgrade: ./scripts/setup/ci-upgrade.sh"
echo "To rollback: ./scripts/setup/ci-rollback.sh"
