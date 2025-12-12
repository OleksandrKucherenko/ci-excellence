#!/usr/bin/env bash
set -euo pipefail

# CI Script: Set Version Outputs
# Purpose: Determine version and prerelease flag and write to GITHUB_OUTPUT

RELEASE_TYPE="${1:-patch}"
PRE_RELEASE_INPUT="${2:-false}"

VERSION=$(./scripts/ci/release/ci-10-determine-version.sh "$RELEASE_TYPE")

IS_PRERELEASE="$PRE_RELEASE_INPUT"
if [[ "$VERSION" == *"-"* ]]; then
  IS_PRERELEASE="true"
fi

echo "version=$VERSION" >> "$GITHUB_OUTPUT"
echo "is-prerelease=$IS_PRERELEASE" >> "$GITHUB_OUTPUT"
