#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Maintenance Status
# Purpose: Determine maintenance pipeline status for notifications

echo:Notify "Determining Maintenance Status"

CLEANUP_RESULT="${1:-unknown}"
SYNC_RESULT="${2:-unknown}"
DEPRECATION_RESULT="${3:-unknown}"
SECURITY_RESULT="${4:-unknown}"
DEPENDENCY_RESULT="${5:-unknown}"

ci:param notify "CLEANUP_RESULT" "$CLEANUP_RESULT"
ci:param notify "SYNC_RESULT" "$SYNC_RESULT"
ci:param notify "DEPRECATION_RESULT" "$DEPRECATION_RESULT"
ci:param notify "SECURITY_RESULT" "$SECURITY_RESULT"
ci:param notify "DEPENDENCY_RESULT" "$DEPENDENCY_RESULT"

if [ "$SECURITY_RESULT" == "failure" ]; then
  ci:output notify "status" "failure"
  ci:output notify "message" "Maintenance: Security Audit Failed ❌"
elif [ "$DEPENDENCY_RESULT" == "success" ]; then
  ci:output notify "status" "success"
  ci:output notify "message" "Maintenance: Dependencies Updated ✅"
elif [ "$SYNC_RESULT" == "success" ]; then
  ci:output notify "status" "success"
  ci:output notify "message" "Maintenance: Files Synced ✅"
else
  ci:output notify "status" "success"
  ci:output notify "message" "Maintenance Completed ✅"
fi

echo:Notify "Maintenance Status Determined"
