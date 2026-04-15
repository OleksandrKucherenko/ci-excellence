#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Generate Changelog
# Purpose: Generate or update CHANGELOG.md
# Hooks: begin, generate, end (automatic)
#   ci-cd/ci-20-generate-changelog/generate_*.sh - override changelog generation
#
# Default strategy: git-cliff with conventional commits.
# Monorepo: when CI_PACKAGE_PATH is set, generates per-package changelog.

echo:Release "Generating Changelog"
ci:param release "CI_VERSION" "${CI_VERSION:?CI_VERSION is required}"
ci:param release "CI_PACKAGE_PATH" "${CI_PACKAGE_PATH:-}"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

if ci:has_hooks generate; then
  set +eu
  hooks:declare generate
  hooks:do generate
  set -eu
else
  PKG_PATH="${CI_PACKAGE_PATH:-}"

  # Build tag and path filter for monorepo support
  CLIFF_ARGS=()
  OUTPUT="CHANGELOG.md"
  if [ -n "$PKG_PATH" ]; then
    CLIFF_ARGS+=(--include-path "${PKG_PATH}/**")
    CLIFF_ARGS+=(--tag "${PKG_PATH}/v${CI_VERSION}")
    OUTPUT="${PKG_PATH}/CHANGELOG.md"
  else
    CLIFF_ARGS+=(--tag "v${CI_VERSION}")
  fi

  if command -v git-cliff &>/dev/null; then
    echo:Release "Using git-cliff to generate ${OUTPUT}"
    git-cliff "${CLIFF_ARGS[@]}" -o "$OUTPUT"
    echo:Release "${OUTPUT} updated for v${CI_VERSION}"
  else
    echo:Release "git-cliff not found, generating from git log"
    {
      echo "# Changelog"
      echo ""
      echo "## [${CI_VERSION}] - $(date +%Y-%m-%d)"
      echo ""
      PREVIOUS_TAG=$(git describe --tags --abbrev=0 HEAD^ 2>/dev/null || echo "")
      if [ -n "$PREVIOUS_TAG" ]; then
        git log "${PREVIOUS_TAG}..HEAD" --pretty=format:"- %s (%h)" --reverse ${PKG_PATH:+-- "$PKG_PATH"}
      else
        git log --pretty=format:"- %s (%h)" --reverse ${PKG_PATH:+-- "$PKG_PATH"}
      fi
      echo ""
    } > "$OUTPUT"
    echo:Release "${OUTPUT} generated from git log"
  fi
fi

echo:Success "Changelog Generated"
