#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Parse Tag
# Purpose: Parse git tag and extract version, prerelease status, and package path
# Hooks: begin, parse, end (automatic)
#   ci-cd/ci-09-parse-tag/parse_*.sh - override default tag parsing strategy
#
# Default strategy:
#   Unified:     refs/tags/v1.2.3        → version=1.2.3, package-path=""
#   Independent: refs/tags/packages/core/v1.2.3 → version=1.2.3, package-path=packages/core

echo:Release "Parse Tag"
ci:param release "CI_GIT_REF" "${CI_GIT_REF:?CI_GIT_REF is required}"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

if ci:has_hooks parse; then
  set +eu
  hooks:declare parse
  hooks:do parse
  set -eu
else
  TAG="${CI_GIT_REF#refs/tags/}"

  if [[ "$TAG" == */v* ]]; then
    # Independent: packages/core/v1.2.0
    PACKAGE_PATH="${TAG%/v*}"
    PACKAGE_NAME=$(basename "$PACKAGE_PATH")
    VERSION="${TAG##*/v}"
  else
    # Unified: v1.2.0
    PACKAGE_PATH=""
    PACKAGE_NAME=""
    VERSION="${TAG#v}"
  fi

  IS_PRERELEASE="false"
  [[ "$VERSION" == *"-"* ]] && IS_PRERELEASE="true"

  ci:output release "version" "$VERSION"
  ci:output release "is-prerelease" "$IS_PRERELEASE"
  ci:output release "package-path" "$PACKAGE_PATH"
  ci:output release "package-name" "$PACKAGE_NAME"

  echo:Release "Version: $VERSION (prerelease: $IS_PRERELEASE)"
  [ -n "$PACKAGE_PATH" ] && echo:Release "Package: $PACKAGE_NAME ($PACKAGE_PATH)"
fi

echo:Success "Parse Tag Done"
