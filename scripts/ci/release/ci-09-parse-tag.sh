#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

REF="${CI_GIT_REF:?CI_GIT_REF is required}"

echo:Release "Parse Tag"
ci:param release "CI_GIT_REF" "$REF"
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
