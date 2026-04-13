#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Identify Deprecated Versions
# Purpose: Identify versions that should be deprecated
# Hooks: begin, identify, end (automatic)
#   ci-cd/ci-70-identify-deprecated-versions/begin_*.sh    - pre-identify setup
#   ci-cd/ci-70-identify-deprecated-versions/identify_*.sh - version identification commands
#   ci-cd/ci-70-identify-deprecated-versions/end_*.sh      - post-identify reporting

echo:Maint "Identifying Deprecated Versions"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

ci:skip_if_no_hooks identify

set +eu
hooks:declare identify
hooks:do identify
set -eu

echo:Success "Deprecated Versions Identification Complete"
