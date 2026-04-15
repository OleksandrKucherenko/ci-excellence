#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Confirm Rollback
# Purpose: Print rollback warning and planned actions
# Hooks: begin, confirm, end (automatic)
#   ci-cd/ci-77-confirm-rollback/confirm_*.sh - override rollback confirmation
#
# Default strategy: log warning with planned actions.

echo:Release "Confirming Rollback"
ci:param release "CI_VERSION" "${CI_VERSION:-unknown}"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

if ci:has_hooks confirm; then
  set +eu
  hooks:declare confirm
  hooks:do confirm
  set -eu
else
  # Default: log rollback warning
  VERSION="${CI_VERSION:-unknown}"
  echo:Release "WARNING: Rolling back version ${VERSION}"
  echo:Release "  This action will:"
  echo:Release "    - Deprecate NPM package version (if enabled)"
  echo:Release "    - Mark GitHub release as draft (if enabled)"
  echo:Release "    - Tag Docker images as deprecated (if enabled)"
fi

echo:Success "Rollback Confirmed"
