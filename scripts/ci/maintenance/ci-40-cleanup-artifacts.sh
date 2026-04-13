#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Cleanup Old Artifacts
# Purpose: Delete old GitHub Actions artifacts
# Hooks: begin, cleanup, end (automatic)
#   ci-cd/ci-40-cleanup-artifacts/begin_*.sh   - pre-cleanup setup
#   ci-cd/ci-40-cleanup-artifacts/cleanup_*.sh - artifact cleanup commands
#   ci-cd/ci-40-cleanup-artifacts/end_*.sh     - post-cleanup reporting

echo:Maint "Cleaning Up Old Artifacts"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

set +eu
hooks:declare cleanup
hooks:do cleanup
set -eu

echo:Success "Artifacts Cleanup Complete"
