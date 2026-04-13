#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Post-Release Actions Summary
# Purpose: Generate post-release actions summary table

echo:Report "Generating Post-Release Summary"

VERIFY_RESULT="${RESULT_VERIFY:-unknown}"
TAG_STABLE_RESULT="${RESULT_TAG_STABLE:-unknown}"
TAG_UNSTABLE_RESULT="${RESULT_TAG_UNSTABLE:-unknown}"
ROLLBACK_RESULT="${RESULT_ROLLBACK:-unknown}"

ci:param report "RESULT_VERIFY" "$VERIFY_RESULT"
ci:param report "RESULT_TAG_STABLE" "$TAG_STABLE_RESULT"
ci:param report "RESULT_TAG_UNSTABLE" "$TAG_UNSTABLE_RESULT"
ci:param report "RESULT_ROLLBACK" "$ROLLBACK_RESULT"

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
