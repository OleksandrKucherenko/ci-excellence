#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Write Release Notes Output
# Purpose: Generate release notes and expose via GITHUB_OUTPUT
# Hooks: begin, write, end (automatic)
#   ci-cd/ci-27-write-release-notes-output/begin_*.sh - pre-write setup
#   ci-cd/ci-27-write-release-notes-output/write_*.sh - write output commands
#   ci-cd/ci-27-write-release-notes-output/end_*.sh   - post-write verification

echo:Release "Writing Release Notes Output"
ci:param release "CI_VERSION" "${CI_VERSION:?CI_VERSION is required}"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

set +eu
hooks:declare write
hooks:do write
set -eu

echo:Success "Release Notes Output Written"
