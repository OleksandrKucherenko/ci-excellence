#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Deprecate GitHub Releases
# Purpose: Mark old GitHub releases as pre-release or update their descriptions
# Hooks: begin, deprecate, end (automatic)
#   ci-cd/ci-80-deprecate-github-releases/begin_*.sh     - pre-deprecate setup
#   ci-cd/ci-80-deprecate-github-releases/deprecate_*.sh - github deprecation commands
#   ci-cd/ci-80-deprecate-github-releases/end_*.sh       - post-deprecate reporting

echo:Maint "Deprecating GitHub Releases"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

ci:skip_if_no_hooks deprecate

set +eu
hooks:declare deprecate
hooks:do deprecate
set -eu

echo:Success "GitHub Deprecation Complete"
