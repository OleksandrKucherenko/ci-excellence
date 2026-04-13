#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Write Release Notes Output
# Purpose: Generate release notes and expose via GITHUB_OUTPUT
# Hooks: begin, write, end (automatic)
#   ci-cd/ci-27-write-release-notes-output/write_*.sh - override output strategy
#
# Default strategy: call ci-25-generate-release-notes.sh and write to GITHUB_OUTPUT.

echo:Release "Writing Release Notes Output"
ci:param release "CI_VERSION" "${CI_VERSION:?CI_VERSION is required}"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

if ci:has_hooks write; then
  set +eu
  hooks:declare write
  hooks:do write
  set -eu
else
  # Default: capture release notes from ci-25 and write to GITHUB_OUTPUT
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  NOTES=$("$SCRIPT_DIR/ci-25-generate-release-notes.sh" 2>/dev/null || echo "Release ${CI_VERSION}")
  ci:output:multiline release "notes" "$NOTES"
fi

echo:Success "Release Notes Output Written"
