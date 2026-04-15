#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Update Dependencies
# Purpose: Update project dependencies to latest versions
# Hooks: begin, update, end (automatic)
#   ci-cd/ci-90-update-dependencies/begin_*.sh  - pre-update setup
#   ci-cd/ci-90-update-dependencies/update_*.sh - dependency update commands
#   ci-cd/ci-90-update-dependencies/end_*.sh    - post-update verification

echo:Maint "Updating Dependencies"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

ci:skip_if_no_hooks update

set +eu
hooks:declare update
hooks:do update
set -eu

echo:Success "Dependency Update Complete"
