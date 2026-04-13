#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Set Version Outputs
# Purpose: Determine version and prerelease flag and write to GITHUB_OUTPUT
# Hooks: begin, resolve, end (automatic)
#   ci-cd/ci-12-set-version-outputs/resolve_*.sh - override version resolution
#
# Default strategy: find latest v* tag, increment based on CI_RELEASE_SCOPE.
# Requires git tags to exist. Falls back to 0.1.0 if no tags found.

echo:Release "Setting Version Outputs"
ci:param release "CI_RELEASE_SCOPE" "${CI_RELEASE_SCOPE:-patch}"
ci:param release "CI_PRE_RELEASE_TYPE" "${CI_PRE_RELEASE_TYPE:-false}"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

if ci:has_hooks resolve; then
  set +eu
  hooks:declare resolve
  hooks:do resolve
  set -eu
else
  # Default: simple semver increment from latest tag
  SCOPE="${CI_RELEASE_SCOPE:-patch}"
  PRE_TYPE="${CI_PRE_RELEASE_TYPE:-false}"

  if ! CURRENT_TAG=$(git describe --tags --match "v*" --abbrev=0 2>/dev/null); then
    CURRENT_TAG="v0.0.0"
    echo:Release "No existing tags found, starting from 0.0.0"
  fi

  CURRENT="${CURRENT_TAG#v}"
  IFS='.-' read -r MAJOR MINOR PATCH _ <<< "$CURRENT"
  MAJOR=${MAJOR:-0}; MINOR=${MINOR:-0}; PATCH=${PATCH:-0}

  case "$SCOPE" in
    major)    VERSION="$((MAJOR + 1)).0.0" ;;
    minor)    VERSION="${MAJOR}.$((MINOR + 1)).0" ;;
    patch)    VERSION="${MAJOR}.${MINOR}.$((PATCH + 1))" ;;
    prerelease|prepatch)
      VERSION="${MAJOR}.${MINOR}.$((PATCH + 1))-${PRE_TYPE}" ;;
    preminor) VERSION="${MAJOR}.$((MINOR + 1)).0-${PRE_TYPE}" ;;
    premajor) VERSION="$((MAJOR + 1)).0.0-${PRE_TYPE}" ;;
    *)        echo:Error "Unknown scope: $SCOPE"; exit 1 ;;
  esac

  IS_PRERELEASE="false"
  if [[ "$VERSION" == *"-"* ]] || [[ "$PRE_TYPE" != "false" && "$PRE_TYPE" != "" ]]; then
    IS_PRERELEASE="true"
  fi

  ci:output release "version" "$VERSION"
  ci:output release "is-prerelease" "$IS_PRERELEASE"

  echo:Release "Calculated: ${CURRENT} -> ${VERSION} (scope: ${SCOPE})"
fi

echo:Success "Version Outputs Set"
