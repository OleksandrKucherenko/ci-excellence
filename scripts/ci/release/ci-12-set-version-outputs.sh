#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Set Version Outputs
# Purpose: Determine version and prerelease flag and write to GITHUB_OUTPUT
# Hooks: begin, resolve, end (automatic)
#   ci-cd/ci-12-set-version-outputs/begin_*.sh   - pre-resolve setup
#   ci-cd/ci-12-set-version-outputs/resolve_*.sh - version resolution commands
#   ci-cd/ci-12-set-version-outputs/end_*.sh     - post-resolve verification

echo:Release "Setting Version Outputs"
ci:param release "CI_RELEASE_SCOPE" "${CI_RELEASE_SCOPE:-patch}"
ci:param release "CI_PRE_RELEASE_TYPE" "${CI_PRE_RELEASE_TYPE:-false}"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

ci:skip_if_no_hooks resolve

set +eu
hooks:declare resolve
hooks:do resolve
set -eu

echo:Success "Version Outputs Set"
