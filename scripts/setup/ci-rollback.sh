#!/usr/bin/env bash
set -euo pipefail

# CI Excellence: Rollback last upgrade
# Purpose: Revert the last ci-excellence merge commit
# Usage: ./scripts/setup/ci-rollback.sh [--dry-run]

DRY_RUN=false
[ "${1:-}" = "--dry-run" ] && DRY_RUN=true

# Find the last merge commit from ci-excellence
MERGE_COMMIT="$(git log --merges --format='%H %s' --grep='ci-excellence' -1 2>/dev/null || true)"

if [ -z "$MERGE_COMMIT" ]; then
  echo "Error: no ci-excellence merge commit found in history."
  exit 1
fi

MERGE_HASH="$(echo "$MERGE_COMMIT" | cut -d' ' -f1)"
MERGE_MSG="$(echo "$MERGE_COMMIT" | cut -d' ' -f2-)"
MERGE_SHORT="$(git rev-parse --short "$MERGE_HASH")"

echo "=== CI Excellence Rollback ==="
echo "  Merge to revert: $MERGE_SHORT ($MERGE_MSG)"
echo ""
echo "Changes that will be reverted:"
git diff "$MERGE_HASH"..HEAD --stat 2>/dev/null || git show "$MERGE_HASH" --stat
echo ""

if [ "$DRY_RUN" = true ]; then
  echo "Dry run: no changes applied."
  exit 0
fi

# Revert the merge commit (keep the main branch side, revert ci-excellence side)
git revert -m 1 --no-edit "$MERGE_HASH"

echo ""
echo "=== Rollback Complete ==="
echo "  Reverted: $MERGE_SHORT"
echo "  To undo this rollback: git revert HEAD"
