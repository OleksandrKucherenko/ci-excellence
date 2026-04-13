#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Generate Changelog
# Purpose: Generate or update CHANGELOG.md
# Hooks: begin, generate, end (automatic)
#   ci-cd/ci-20-generate-changelog/generate_*.sh - override changelog generation
#
# Default strategy: git-cliff with conventional commits.
# Requires git-cliff (installed via mise). Falls back to git log if unavailable.

echo:Release "Generating Changelog"
ci:param release "CI_VERSION" "${CI_VERSION:?CI_VERSION is required}"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

if ci:has_hooks generate; then
  set +eu
  hooks:declare generate
  hooks:do generate
  set -eu
else
  # Default: use git-cliff for changelog generation
  if command -v git-cliff &>/dev/null; then
    echo:Release "Using git-cliff to generate CHANGELOG.md"
    git-cliff --tag "v${CI_VERSION}" -o CHANGELOG.md
    echo:Release "CHANGELOG.md updated for v${CI_VERSION}"
  else
    echo:Release "git-cliff not found, generating from git log"
    {
      echo "# Changelog"
      echo ""
      echo "## [${CI_VERSION}] - $(date +%Y-%m-%d)"
      echo ""
      PREVIOUS_TAG=$(git describe --tags --abbrev=0 HEAD^ 2>/dev/null || echo "")
      if [ -n "$PREVIOUS_TAG" ]; then
        git log "${PREVIOUS_TAG}..HEAD" --pretty=format:"- %s (%h)" --reverse
      else
        git log --pretty=format:"- %s (%h)" --reverse
      fi
      echo ""
    } > CHANGELOG.md
    echo:Release "CHANGELOG.md generated from git log"
  fi
fi

echo:Success "Changelog Generated"
