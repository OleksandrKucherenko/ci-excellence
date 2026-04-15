#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Verify GitHub Release
# Purpose: Verify that GitHub release exists and is published
# Hooks: begin, verify, end (automatic)
#   ci-cd/ci-35-verify-github-release/begin_*.sh  - pre-verify setup
#   ci-cd/ci-35-verify-github-release/verify_*.sh - verification commands
#   ci-cd/ci-35-verify-github-release/end_*.sh    - post-verify reporting

echo:Release "Verifying GitHub Release"
ci:param release "CI_VERSION" "${CI_VERSION:?CI_VERSION is required}"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

ci:skip_if_no_hooks verify

set +eu
hooks:declare verify
hooks:do verify
set -eu

echo:Success "GitHub Release Verification Complete"
