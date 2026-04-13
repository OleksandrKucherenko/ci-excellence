#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Release Status
# Purpose: Determine release notification status and message

echo:Notify "Determining Release Status"

VERSION="${1:-unknown}"
PREPARE_RESULT="${2:-unknown}"
NPM_RESULT="${3:-unknown}"
GITHUB_RESULT="${4:-unknown}"
DOCKER_RESULT="${5:-unknown}"

ci:param notify "VERSION" "$VERSION"
ci:param notify "PREPARE_RESULT" "$PREPARE_RESULT"
ci:param notify "NPM_RESULT" "$NPM_RESULT"
ci:param notify "GITHUB_RESULT" "$GITHUB_RESULT"
ci:param notify "DOCKER_RESULT" "$DOCKER_RESULT"

if [ "$PREPARE_RESULT" == "failure" ] || \
   [ "$NPM_RESULT" == "failure" ] || \
   [ "$GITHUB_RESULT" == "failure" ] || \
   [ "$DOCKER_RESULT" == "failure" ]; then
  ci:output notify "status" "failure"
  ci:output notify "message" "Release $VERSION Failed ❌"
else
  ci:output notify "status" "success"
  ci:output notify "message" "Release $VERSION Published ✅"
fi

echo:Notify "Release Status Determined"
