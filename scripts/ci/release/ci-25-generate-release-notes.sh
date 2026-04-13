#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Generate Release Notes
# Purpose: Generate release notes for GitHub release
# Hooks: begin, generate, end (automatic)
#   ci-cd/ci-25-generate-release-notes/begin_*.sh    - pre-generate setup
#   ci-cd/ci-25-generate-release-notes/generate_*.sh - release notes generation commands
#   ci-cd/ci-25-generate-release-notes/end_*.sh      - post-generate verification

echo:Release "Generating Release Notes"
ci:param release "CI_VERSION" "${CI_VERSION:?CI_VERSION is required}"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

hooks:declare generate
hooks:do generate

echo:Success "Release Notes Generated"
