#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Generate Changelog
# Purpose: Generate or update changelog
# Hooks: begin, generate, end (automatic)
#   ci-cd/ci-20-generate-changelog/begin_*.sh    - pre-generate setup
#   ci-cd/ci-20-generate-changelog/generate_*.sh - changelog generation commands
#   ci-cd/ci-20-generate-changelog/end_*.sh      - post-generate verification

echo:Release "Generating Changelog"
ci:param release "CI_VERSION" "${CI_VERSION:?CI_VERSION is required}"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

set +eu
hooks:declare generate
hooks:do generate
set -eu

echo:Success "Changelog Generated"
