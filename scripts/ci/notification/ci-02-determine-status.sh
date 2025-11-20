#!/usr/bin/env bash
set -euo pipefail

# CI Script: Determine Notification Status
# Purpose: Determine pipeline status for notifications

SUMMARY_RESULT="${1:-unknown}"

if [ "$SUMMARY_RESULT" == "failure" ]; then
  echo "status=failure" >> $GITHUB_OUTPUT
  echo "message=Pre-Release Pipeline Failed ❌" >> $GITHUB_OUTPUT
elif [ "$SUMMARY_RESULT" == "success" ]; then
  echo "status=success" >> $GITHUB_OUTPUT
  echo "message=Pre-Release Pipeline Passed ✅" >> $GITHUB_OUTPUT
else
  echo "status=warning" >> $GITHUB_OUTPUT
  echo "message=Pre-Release Pipeline Completed with Issues ⚠️" >> $GITHUB_OUTPUT
fi
