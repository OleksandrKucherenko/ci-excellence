#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Check for Changes
# Purpose: Check if git working tree has changes
# Hooks: begin, check, end (automatic)
#   ci-cd/ci-20-check-changes/check_*.sh - override change detection
#
# Default strategy: git diff --quiet, outputs has-changes=true/false.

echo:Maint "Checking for Changes"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

if ci:has_hooks check; then
  set +eu
  hooks:declare check
  hooks:do check
  set -eu
else
  # Default: check git working tree
  if git diff --quiet; then
    ci:output maint "has-changes" "false"
    echo:Maint "No changes detected"
  else
    ci:output maint "has-changes" "true"
    echo:Maint "Changes detected"
  fi
fi

echo:Success "Change Check Complete"
