#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Set Version Outputs
# Purpose: Determine version and prerelease flag and write to GITHUB_OUTPUT
# Hooks: begin, resolve, end (automatic)
#   ci-cd/ci-12-set-version-outputs/resolve_*.sh - override version resolution
#
# Default strategy: find latest tag, increment based on CI_RELEASE_SCOPE.
# Monorepo: when CI_PACKAGE_PATH is set, matches package-scoped tags.

echo:Release "Setting Version Outputs"
ci:param release "CI_RELEASE_SCOPE" "${CI_RELEASE_SCOPE:-patch}"
ci:param release "CI_PRE_RELEASE_TYPE" "${CI_PRE_RELEASE_TYPE:-false}"
ci:param release "CI_PACKAGE_PATH" "${CI_PACKAGE_PATH:-}"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

if ci:has_hooks resolve; then
  set +eu
  hooks:declare resolve
  hooks:do resolve
  set -eu
else
  SCOPE="${CI_RELEASE_SCOPE:-patch}"
  PRE_TYPE="${CI_PRE_RELEASE_TYPE:-false}"
  PKG_PATH="${CI_PACKAGE_PATH:-}"

  # Tag pattern: package-scoped or repo-wide
  if [ -n "$PKG_PATH" ]; then
    TAG_MATCH="${PKG_PATH}/v*"
    TAG_PREFIX="${PKG_PATH}/v"
  else
    TAG_MATCH="v*"
    TAG_PREFIX="v"
  fi

  if ! CURRENT_TAG=$(git describe --tags --match "$TAG_MATCH" --abbrev=0 2>/dev/null); then
    CURRENT_TAG="${TAG_PREFIX}0.0.0"
    echo:Release "No existing tags matching ${TAG_MATCH}, starting from 0.0.0"
  fi

  # Strip tag prefix to get bare version
  CURRENT="${CURRENT_TAG#"$TAG_PREFIX"}"
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
  [ -n "$PKG_PATH" ] && ci:output release "package-path" "$PKG_PATH"

  echo:Release "Calculated: ${CURRENT} -> ${VERSION} (scope: ${SCOPE})"
fi

echo:Success "Version Outputs Set"
