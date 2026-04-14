#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Determine Version
# Purpose: Calculate next version based on release type using e-bash semver lib
# Hooks: begin, determine, end (automatic)
#   ci-cd/ci-10-determine-version/begin_*.sh     - pre-determine setup
#   ci-cd/ci-10-determine-version/determine_*.sh - override version calculation
#   ci-cd/ci-10-determine-version/end_*.sh       - post-determine verification
#
# Default strategy: semver increment (major/minor/patch/pre*) via ci:determine_version

echo:Release "Determining Next Version"
ci:param release "CI_RELEASE_SCOPE" "${CI_RELEASE_SCOPE:-patch}"
ci:param release "CI_PRE_RELEASE_TYPE" "${CI_PRE_RELEASE_TYPE:-alpha}"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

if ci:has_hooks determine; then
  set +eu
  hooks:declare determine
  hooks:do determine
  set -eu
else
  ci:determine_version "${CI_RELEASE_SCOPE:-patch}" "${CI_PRE_RELEASE_TYPE:-alpha}"
fi

echo:Success "Version Determination Complete"
