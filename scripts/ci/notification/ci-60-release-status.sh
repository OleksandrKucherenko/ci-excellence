#!/usr/bin/env bash
set -euo pipefail

# CI Script: Release Status
# Purpose: Determine release notification status and message

VERSION="${1:-unknown}"
PREPARE_RESULT="${2:-unknown}"
NPM_RESULT="${3:-unknown}"
GITHUB_RESULT="${4:-unknown}"
DOCKER_RESULT="${5:-unknown}"

if [ "$PREPARE_RESULT" == "failure" ] || \
   [ "$NPM_RESULT" == "failure" ] || \
   [ "$GITHUB_RESULT" == "failure" ] || \
   [ "$DOCKER_RESULT" == "failure" ]; then
  echo "status=failure" >> "$GITHUB_OUTPUT"
  echo "message=Release $VERSION Failed ❌" >> "$GITHUB_OUTPUT"
else
  echo "status=success" >> "$GITHUB_OUTPUT"
  echo "message=Release $VERSION Published ✅" >> "$GITHUB_OUTPUT"
fi
