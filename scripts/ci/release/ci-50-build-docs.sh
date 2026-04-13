#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Build Documentation
# Purpose: Build project documentation
# Hooks: begin, build, end (automatic)
#   ci-cd/ci-50-build-docs/begin_*.sh - pre-build setup
#   ci-cd/ci-50-build-docs/build_*.sh - documentation build commands
#   ci-cd/ci-50-build-docs/end_*.sh   - post-build verification

echo:Release "Building Documentation"
ci:param release "CI_VERSION" "${CI_VERSION:?CI_VERSION is required}"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

set +eu
hooks:declare build
hooks:do build
set -eu

echo:Success "Documentation Build Complete"
