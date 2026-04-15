#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Rollback GitHub Release
# Purpose: Mark GitHub release as draft or delete it
# Hooks: begin, rollback, end (automatic)
#   ci-cd/ci-40-rollback-github/begin_*.sh    - pre-rollback setup
#   ci-cd/ci-40-rollback-github/rollback_*.sh - rollback commands
#   ci-cd/ci-40-rollback-github/end_*.sh      - post-rollback verification

echo:Release "Rolling Back GitHub Release"
ci:param release "CI_VERSION" "${CI_VERSION:?CI_VERSION is required}"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

ci:skip_if_no_hooks rollback

set +eu
hooks:declare rollback
hooks:do rollback
set -eu

echo:Success "GitHub Rollback Complete"
