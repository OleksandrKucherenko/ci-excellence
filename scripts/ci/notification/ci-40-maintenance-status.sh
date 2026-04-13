#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Maintenance Status
# Purpose: Determine maintenance pipeline status for notifications

echo:Notify "--- Determining Maintenance Status ---"

CLEANUP_RESULT="${1:-unknown}"
SYNC_RESULT="${2:-unknown}"
DEPRECATION_RESULT="${3:-unknown}"
SECURITY_RESULT="${4:-unknown}"
DEPENDENCY_RESULT="${5:-unknown}"

if [ "$SECURITY_RESULT" == "failure" ]; then
  echo "status=failure" >> "$GITHUB_OUTPUT"
  echo "message=Maintenance: Security Audit Failed ❌" >> "$GITHUB_OUTPUT"
elif [ "$DEPENDENCY_RESULT" == "success" ]; then
  echo "status=success" >> "$GITHUB_OUTPUT"
  echo "message=Maintenance: Dependencies Updated ✅" >> "$GITHUB_OUTPUT"
elif [ "$SYNC_RESULT" == "success" ]; then
  echo "status=success" >> "$GITHUB_OUTPUT"
  echo "message=Maintenance: Files Synced ✅" >> "$GITHUB_OUTPUT"
else
  echo "status=success" >> "$GITHUB_OUTPUT"
  echo "message=Maintenance Completed ✅" >> "$GITHUB_OUTPUT"
fi

echo:Notify "--- Maintenance Status Determined ---"
