#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Create Tag
# Purpose: Create and push a git tag for release
# Hooks: begin, tag, end (automatic)
#   ci-cd/ci-08-create-tag/begin_*.sh - pre-tag setup
#   ci-cd/ci-08-create-tag/tag_*.sh   - tag creation commands
#   ci-cd/ci-08-create-tag/end_*.sh   - post-tag verification

echo:Release "Create Tag"
ci:param release "CI_VERSION" "${CI_VERSION:?CI_VERSION is required}"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

hooks:declare tag
hooks:do tag

echo:Success "Create Tag Done"
