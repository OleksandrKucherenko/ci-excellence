#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Select Version
# Purpose: Choose version based on event context and expose via GITHUB_OUTPUT

EVENT_NAME="${CI_EVENT_NAME:-}"
RELEASE_TAG="${CI_RELEASE_TAG:-}"
INPUT_VERSION="${CI_VERSION:-}"

echo:Release "Selecting Version"
ci:param release "CI_EVENT_NAME" "$EVENT_NAME"
ci:param release "CI_RELEASE_TAG" "$RELEASE_TAG"
ci:param release "CI_VERSION" "$INPUT_VERSION"

if [ "$EVENT_NAME" == "release" ] && [ -n "$RELEASE_TAG" ]; then
  VERSION="$RELEASE_TAG"
elif [ -n "$INPUT_VERSION" ]; then
  VERSION="$INPUT_VERSION"
else
  echo:Release "Version not provided"
  exit 1
fi

ci:output release "version" "$VERSION"

echo:Success "Version Selected"
