#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Post-Release Actions Summary
# Purpose: Generate post-release actions summary table

echo:Report "Generating Post-Release Summary"

VERIFY_RESULT="${1:-unknown}"
TAG_STABLE_RESULT="${2:-unknown}"
TAG_UNSTABLE_RESULT="${3:-unknown}"
ROLLBACK_RESULT="${4:-unknown}"

ci:param report "VERIFY_RESULT" "$VERIFY_RESULT"
ci:param report "TAG_STABLE_RESULT" "$TAG_STABLE_RESULT"
ci:param report "TAG_UNSTABLE_RESULT" "$TAG_UNSTABLE_RESULT"
ci:param report "ROLLBACK_RESULT" "$ROLLBACK_RESULT"

{
  echo "## Post-Release Actions Summary"
  echo ""
  echo "| Action | Status |"
  echo "|--------|--------|"
  echo "| Verify Deployment | $VERIFY_RESULT |"
  echo "| Tag Stable | $TAG_STABLE_RESULT |"
  echo "| Tag Unstable | $TAG_UNSTABLE_RESULT |"
  echo "| Rollback | $ROLLBACK_RESULT |"
} >> "${GITHUB_STEP_SUMMARY}"

echo:Report "Post-Release Summary Generated"
