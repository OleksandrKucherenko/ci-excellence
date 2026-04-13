#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Parse Tag
# Purpose: Parse git tag and extract version and prerelease status
# Hooks: begin, parse, end (automatic)
#   ci-cd/ci-09-parse-tag/parse_*.sh - override default tag parsing strategy
#
# Default strategy: strips refs/tags/ prefix and v prefix, detects prerelease by dash.
# Override to support custom tag formats (e.g. release/1.2.3, build-42).

echo:Release "Parse Tag"
ci:param release "CI_GIT_REF" "${CI_GIT_REF:?CI_GIT_REF is required}"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

if ci:has_hooks parse; then
  # Custom parsing strategy via hooks
  set +eu
  hooks:declare parse
  hooks:do parse
  set -eu
else
  # Default: v{major}.{minor}.{patch}[-prerelease] tag convention
  TAG="${CI_GIT_REF#refs/tags/}"
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
fi

echo:Success "Parse Tag Done"
