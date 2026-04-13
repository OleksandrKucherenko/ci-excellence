#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Select Version
# Purpose: Choose version based on event context and expose via GITHUB_OUTPUT

EVENT_NAME="${1:-}"
RELEASE_TAG="${2:-}"
INPUT_VERSION="${3:-}"

echo:Release "Selecting Version"
ci:param release "EVENT_NAME" "$EVENT_NAME"
ci:param release "RELEASE_TAG" "$RELEASE_TAG"
ci:param release "INPUT_VERSION" "$INPUT_VERSION"

if [ "$EVENT_NAME" == "release" ] && [ -n "$RELEASE_TAG" ]; then
  VERSION="$RELEASE_TAG"
elif [ -n "$INPUT_VERSION" ]; then
  VERSION="$INPUT_VERSION"
else
  echo:Release "Version not provided"
  exit 1
fi

ci:output release "version" "$VERSION"

echo:Release "Version Selected"
