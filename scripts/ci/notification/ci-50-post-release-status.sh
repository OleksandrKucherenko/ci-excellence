#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Post-Release Status
# Purpose: Determine post-release notification status and message

echo:Notify "Determining Post-Release Status"

VERIFY_RESULT="${1:-unknown}"
TAG_STABLE_RESULT="${2:-unknown}"
TAG_UNSTABLE_RESULT="${3:-unknown}"
ROLLBACK_RESULT="${4:-unknown}"

ci:param notify "VERIFY_RESULT" "$VERIFY_RESULT"
ci:param notify "TAG_STABLE_RESULT" "$TAG_STABLE_RESULT"
ci:param notify "TAG_UNSTABLE_RESULT" "$TAG_UNSTABLE_RESULT"
ci:param notify "ROLLBACK_RESULT" "$ROLLBACK_RESULT"

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

echo:Notify "Post-Release Status Determined"
