#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Release Status
# Purpose: Determine release notification status and message

echo:Notify "Determining Release Status"

VERSION="${CI_VERSION:-unknown}"
PREPARE_RESULT="${RESULT_PREPARE:-unknown}"
NPM_RESULT="${RESULT_PUBLISH_NPM:-unknown}"
GITHUB_RESULT="${RESULT_PUBLISH_GITHUB:-unknown}"
DOCKER_RESULT="${RESULT_PUBLISH_DOCKER:-unknown}"

ci:param notify "CI_VERSION" "$VERSION"
ci:param notify "RESULT_PREPARE" "$PREPARE_RESULT"
ci:param notify "RESULT_PUBLISH_NPM" "$NPM_RESULT"
ci:param notify "RESULT_PUBLISH_GITHUB" "$GITHUB_RESULT"
ci:param notify "RESULT_PUBLISH_DOCKER" "$DOCKER_RESULT"

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
