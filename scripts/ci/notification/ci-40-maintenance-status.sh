#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Maintenance Status
# Purpose: Determine maintenance pipeline status for notifications

echo:Notify "Determining Maintenance Status"

CLEANUP_RESULT="${RESULT_CLEANUP:-unknown}"
SYNC_RESULT="${RESULT_SYNC:-unknown}"
DEPRECATION_RESULT="${RESULT_DEPRECATION:-unknown}"
SECURITY_RESULT="${RESULT_SECURITY:-unknown}"
DEPENDENCY_RESULT="${RESULT_DEPENDENCY:-unknown}"

ci:param notify "RESULT_CLEANUP" "$CLEANUP_RESULT"
ci:param notify "RESULT_SYNC" "$SYNC_RESULT"
ci:param notify "RESULT_DEPRECATION" "$DEPRECATION_RESULT"
ci:param notify "RESULT_SECURITY" "$SECURITY_RESULT"
ci:param notify "RESULT_DEPENDENCY" "$DEPENDENCY_RESULT"

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
