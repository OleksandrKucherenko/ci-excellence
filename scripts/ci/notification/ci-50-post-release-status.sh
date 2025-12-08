#!/usr/bin/env bash
set -euo pipefail

# CI Script: Post-Release Status
# Purpose: Determine post-release notification status and message

VERIFY_RESULT="${1:-unknown}"
TAG_STABLE_RESULT="${2:-unknown}"
TAG_UNSTABLE_RESULT="${3:-unknown}"
ROLLBACK_RESULT="${4:-unknown}"

if [ "$ROLLBACK_RESULT" == "success" ]; then
  echo "status=warning" >> "$GITHUB_OUTPUT"
  echo "message=Rollback Completed ⚠️" >> "$GITHUB_OUTPUT"
elif [ "$TAG_STABLE_RESULT" == "success" ]; then
  echo "status=success" >> "$GITHUB_OUTPUT"
  echo "message=Version Tagged as Stable ✅" >> "$GITHUB_OUTPUT"
elif [ "$VERIFY_RESULT" == "success" ]; then
  echo "status=success" >> "$GITHUB_OUTPUT"
  echo "message=Deployment Verified ✅" >> "$GITHUB_OUTPUT"
elif [ "$ROLLBACK_RESULT" == "failure" ]; then
  echo "status=failure" >> "$GITHUB_OUTPUT"
  echo "message=Rollback Failed ❌" >> "$GITHUB_OUTPUT"
else
  echo "status=info" >> "$GITHUB_OUTPUT"
  echo "message=Post-Release Actions Completed ℹ️" >> "$GITHUB_OUTPUT"
fi
