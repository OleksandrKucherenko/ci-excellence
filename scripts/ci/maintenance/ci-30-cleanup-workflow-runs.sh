#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Cleanup Old Workflow Runs
# Purpose: Delete old GitHub Actions workflow runs
# Hooks: begin, cleanup, end (automatic)
#   ci-cd/ci-30-cleanup-workflow-runs/begin_*.sh   - pre-cleanup setup
#   ci-cd/ci-30-cleanup-workflow-runs/cleanup_*.sh - workflow cleanup commands
#   ci-cd/ci-30-cleanup-workflow-runs/end_*.sh     - post-cleanup reporting

echo:Maint "Cleaning Up Old Workflow Runs"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

ci:skip_if_no_hooks cleanup

set +eu
hooks:declare cleanup
hooks:do cleanup
set -eu

echo:Success "Workflow Runs Cleanup Complete"
