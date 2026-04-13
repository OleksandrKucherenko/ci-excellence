#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

echo:Release "Parse Tag"

REF="${1:?Git ref is required}"
TAG=${REF#refs/tags/}
VERSION="${TAG##*v}"

if [[ "$VERSION" == *"-"* ]]; then
  IS_PRERELEASE="true"
else
  IS_PRERELEASE="false"
fi

echo "version=$VERSION" >> "$GITHUB_OUTPUT"
echo "is-prerelease=$IS_PRERELEASE" >> "$GITHUB_OUTPUT"

echo:Release "Detected Version: $VERSION"
echo:Release "Is Pre-release: $IS_PRERELEASE"

echo:Release "Parse Tag Done"
