#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Determine Version
# Purpose: Calculate next version based on release type
# Hooks: begin, determine, end (automatic)
#   ci-cd/ci-10-determine-version/begin_*.sh     - pre-determine setup
#   ci-cd/ci-10-determine-version/determine_*.sh - version calculation commands
#   ci-cd/ci-10-determine-version/end_*.sh       - post-determine verification

echo:Release "Determining Next Version"
ci:param release "CI_RELEASE_SCOPE" "${CI_RELEASE_SCOPE:-patch}"
ci:param release "CI_PRE_RELEASE_TYPE" "${CI_PRE_RELEASE_TYPE:-alpha}"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

ci:skip_if_no_hooks determine

set +eu
hooks:declare determine
hooks:do determine
set -eu

echo:Success "Version Determination Complete"
