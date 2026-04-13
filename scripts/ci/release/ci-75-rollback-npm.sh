#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Rollback NPM Release
# Purpose: Deprecate NPM package version
# Hooks: begin, rollback, end (automatic)
#   ci-cd/ci-75-rollback-npm/begin_*.sh    - pre-rollback setup
#   ci-cd/ci-75-rollback-npm/rollback_*.sh - npm rollback commands
#   ci-cd/ci-75-rollback-npm/end_*.sh      - post-rollback verification

echo:Release "Rolling Back NPM Release"
ci:param release "CI_VERSION" "${CI_VERSION:?CI_VERSION is required}"
ci:secret release "NODE_AUTH_TOKEN" "${NODE_AUTH_TOKEN:-}"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

hooks:declare rollback
hooks:do rollback

echo:Success "NPM Rollback Complete"
