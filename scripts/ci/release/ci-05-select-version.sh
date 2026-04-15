#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Select Version
# Purpose: Choose version based on event context and expose via GITHUB_OUTPUT
# Hooks: begin, select, end (automatic)
#   ci-cd/ci-05-select-version/select_*.sh - override version selection strategy
#
# Default strategy: release event tag > input version > error.

echo:Release "Selecting Version"
ci:param release "CI_EVENT_NAME" "${CI_EVENT_NAME:-}"
ci:param release "CI_RELEASE_TAG" "${CI_RELEASE_TAG:-}"
ci:param release "CI_VERSION" "${CI_VERSION:-}"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

if ci:has_hooks select; then
  set +eu
  hooks:declare select
  hooks:do select
  set -eu
else
  # Default: prefer release tag, fallback to input version
  if [ "${CI_EVENT_NAME:-}" == "release" ] && [ -n "${CI_RELEASE_TAG:-}" ]; then
    VERSION="$CI_RELEASE_TAG"
  elif [ -n "${CI_VERSION:-}" ]; then
    VERSION="$CI_VERSION"
  else
    echo:Release "Version not provided"
    exit 1
  fi

  ci:output release "version" "$VERSION"
fi

echo:Success "Version Selected"
