#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Set Version Outputs
# Purpose: Determine version and prerelease flag and write to GITHUB_OUTPUT

RELEASE_TYPE="${CI_RELEASE_SCOPE:-patch}"
PRE_RELEASE_INPUT="${CI_PRE_RELEASE_TYPE:-false}"

echo:Release "Setting Version Outputs"
ci:param release "CI_RELEASE_SCOPE" "$RELEASE_TYPE"
ci:param release "CI_PRE_RELEASE_TYPE" "$PRE_RELEASE_INPUT"


VERSION=$(./scripts/ci/release/ci-10-determine-version.sh)

IS_PRERELEASE="$PRE_RELEASE_INPUT"
if [[ "$VERSION" == *"-"* ]]; then
  IS_PRERELEASE="true"
fi

ci:output release "version" "$VERSION"
ci:output release "is-prerelease" "$IS_PRERELEASE"

echo:Success "Version Outputs Set"
