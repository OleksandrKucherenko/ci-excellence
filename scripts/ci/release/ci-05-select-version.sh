#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Select Version
# Purpose: Choose version based on event context and expose via GITHUB_OUTPUT
# Hooks: begin, select, end (automatic)
#   ci-cd/ci-05-select-version/begin_*.sh  - pre-select setup
#   ci-cd/ci-05-select-version/select_*.sh - version selection logic
#   ci-cd/ci-05-select-version/end_*.sh    - post-select verification

echo:Release "Selecting Version"
ci:param release "CI_EVENT_NAME" "${CI_EVENT_NAME:-}"
ci:param release "CI_RELEASE_TAG" "${CI_RELEASE_TAG:-}"
ci:param release "CI_VERSION" "${CI_VERSION:-}"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

set +eu
hooks:declare select
hooks:do select
set -eu

echo:Success "Version Selected"
