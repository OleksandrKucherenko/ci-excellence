#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Update Version
# Purpose: Update version in project files
# Hooks: begin, update, end (automatic)
#   ci-cd/ci-15-update-version/begin_*.sh  - pre-update setup
#   ci-cd/ci-15-update-version/update_*.sh - version update commands
#   ci-cd/ci-15-update-version/end_*.sh    - post-update verification

echo:Release "Updating Version Files"
ci:param release "CI_VERSION" "${CI_VERSION:?CI_VERSION is required}"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

ci:skip_if_no_hooks update

set +eu
hooks:declare update
hooks:do update
set -eu

echo:Success "Version Files Updated"
