#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

echo:Release "Parse Tag"
ci:param release "REF" "${1:?Git ref is required}"

REF="${1:?Git ref is required}"
TAG=${REF#refs/tags/}
VERSION="${TAG##*v}"

if [[ "$VERSION" == *"-"* ]]; then
  IS_PRERELEASE="true"
else
  IS_PRERELEASE="false"
fi

ci:output release "version" "$VERSION"
ci:output release "is-prerelease" "$IS_PRERELEASE"

echo:Release "Detected Version: $VERSION"
echo:Release "Is Pre-release: $IS_PRERELEASE"

echo:Release "Parse Tag Done"
