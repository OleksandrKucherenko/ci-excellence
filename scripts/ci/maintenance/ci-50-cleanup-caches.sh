#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Cleanup Old Caches
# Purpose: Delete old GitHub Actions caches
# Hooks: begin, cleanup, end (automatic)
#   ci-cd/ci-50-cleanup-caches/begin_*.sh   - pre-cleanup setup
#   ci-cd/ci-50-cleanup-caches/cleanup_*.sh - cache cleanup commands
#   ci-cd/ci-50-cleanup-caches/end_*.sh     - post-cleanup reporting

echo:Maint "Cleaning Up Old Caches"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

ci:skip_if_no_hooks cleanup

set +eu
hooks:declare cleanup
hooks:do cleanup
set -eu

echo:Success "Caches Cleanup Complete"
