#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Check for Changes
# Purpose: Check if git working tree has changes
# Hooks: begin, check, end (automatic)
#   ci-cd/ci-20-check-changes/begin_*.sh - pre-check setup
#   ci-cd/ci-20-check-changes/check_*.sh - change detection commands
#   ci-cd/ci-20-check-changes/end_*.sh   - post-check reporting

echo:Maint "Checking for Changes"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

hooks:declare check
hooks:do check

echo:Success "Change Check Complete"
