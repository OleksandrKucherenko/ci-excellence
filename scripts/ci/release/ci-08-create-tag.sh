#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Create Tag
# Purpose: Create and push a git tag for release
# Hooks: begin, tag, end (automatic)
#   ci-cd/ci-08-create-tag/tag_*.sh - override tag creation strategy
#
# Default strategy: creates annotated tag v{VERSION} and pushes to origin.

echo:Release "Create Tag"
ci:param release "CI_VERSION" "${CI_VERSION:?CI_VERSION is required}"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

if ci:has_hooks tag; then
  set +eu
  hooks:declare tag
  hooks:do tag
  set -eu
else
  # Default: annotated tag with v prefix
  TAG="v${CI_VERSION}"
  echo:Release "Creating tag: $TAG"
  git tag -a "$TAG" -m "Release $TAG"
  git push origin "$TAG"
fi

echo:Success "Create Tag Done"
