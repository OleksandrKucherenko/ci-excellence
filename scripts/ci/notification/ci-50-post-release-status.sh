#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Post-Release Status
# Purpose: Determine post-release notification status and message

echo:Notify "Determining Post-Release Status"

VERIFY_RESULT="${RESULT_VERIFY:-unknown}"
TAG_STABLE_RESULT="${RESULT_TAG_STABLE:-unknown}"
TAG_UNSTABLE_RESULT="${RESULT_TAG_UNSTABLE:-unknown}"
ROLLBACK_RESULT="${RESULT_ROLLBACK:-unknown}"

ci:param notify "RESULT_VERIFY" "$VERIFY_RESULT"
ci:param notify "RESULT_TAG_STABLE" "$TAG_STABLE_RESULT"
ci:param notify "RESULT_TAG_UNSTABLE" "$TAG_UNSTABLE_RESULT"
ci:param notify "RESULT_ROLLBACK" "$ROLLBACK_RESULT"

if [ "$ROLLBACK_RESULT" == "success" ]; then
  ci:output notify "status" "warning"
  ci:output notify "message" "Rollback Completed ⚠️"
elif [ "$TAG_STABLE_RESULT" == "success" ]; then
  ci:output notify "status" "success"
  ci:output notify "message" "Version Tagged as Stable ✅"
elif [ "$VERIFY_RESULT" == "success" ]; then
  ci:output notify "status" "success"
  ci:output notify "message" "Deployment Verified ✅"
elif [ "$ROLLBACK_RESULT" == "failure" ]; then
  ci:output notify "status" "failure"
  ci:output notify "message" "Rollback Failed ❌"
else
  ci:output notify "status" "info"
  ci:output notify "message" "Post-Release Actions Completed ℹ️"
fi

echo:Success "Post-Release Status Determined"
