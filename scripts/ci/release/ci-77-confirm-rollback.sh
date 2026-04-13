#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Confirm Rollback
# Purpose: Print rollback warning and planned actions
# Hooks: begin, confirm, end (automatic)
#   ci-cd/ci-77-confirm-rollback/begin_*.sh   - pre-confirm setup
#   ci-cd/ci-77-confirm-rollback/confirm_*.sh - rollback confirmation commands
#   ci-cd/ci-77-confirm-rollback/end_*.sh     - post-confirm verification

echo:Release "Confirming Rollback"
ci:param release "CI_VERSION" "${CI_VERSION:-unknown}"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

set +eu
hooks:declare confirm
hooks:do confirm
set -eu

echo:Success "Rollback Confirmed"
