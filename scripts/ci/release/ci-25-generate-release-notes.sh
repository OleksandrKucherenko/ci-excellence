#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Generate Release Notes
# Purpose: Generate release notes for GitHub release (stdout)
# Hooks: begin, generate, end (automatic)
#   ci-cd/ci-25-generate-release-notes/generate_*.sh - override release notes
#
# Default strategy: git-cliff for current tag only (no header/footer).
# Output goes to stdout for capture by the calling workflow.

echo:Release "Generating Release Notes"
ci:param release "CI_VERSION" "${CI_VERSION:?CI_VERSION is required}"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

if ci:has_hooks generate; then
  set +eu
  hooks:declare generate
  hooks:do generate
  set -eu
else
  # Default: use git-cliff for release notes (current version only, no header)
  if command -v git-cliff &>/dev/null; then
    echo:Release "Using git-cliff to generate release notes" >&2
    git-cliff --tag "v${CI_VERSION}" --unreleased --strip header
  else
    echo:Release "git-cliff not found, generating from git log" >&2
    echo "## What's Changed"
    echo ""
    PREVIOUS_TAG=$(git describe --tags --abbrev=0 HEAD^ 2>/dev/null || echo "")
    if [ -n "$PREVIOUS_TAG" ]; then
      git log "${PREVIOUS_TAG}..HEAD" --pretty=format:"- %s (%h)" --reverse
    else
      git log --pretty=format:"- %s (%h)" --reverse
    fi
    echo ""
    echo ""
    echo "**Full Changelog**: See [CHANGELOG.md](CHANGELOG.md)"
  fi
fi

echo:Success "Release Notes Generated"
