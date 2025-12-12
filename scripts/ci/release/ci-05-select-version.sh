#!/usr/bin/env bash
set -euo pipefail

# CI Script: Select Version
# Purpose: Choose version based on event context and expose via GITHUB_OUTPUT

EVENT_NAME="${1:-}"
RELEASE_TAG="${2:-}"
INPUT_VERSION="${3:-}"

if [ "$EVENT_NAME" == "release" ] && [ -n "$RELEASE_TAG" ]; then
  VERSION="$RELEASE_TAG"
elif [ -n "$INPUT_VERSION" ]; then
  VERSION="$INPUT_VERSION"
else
  echo "Version not provided" >&2
  exit 1
fi

echo "version=$VERSION" >> "$GITHUB_OUTPUT"
