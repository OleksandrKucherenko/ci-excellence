#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Apply Stability Tag
# Purpose: Tag a version as stable/unstable per STATES.md convention
# Hooks: begin, apply, end (automatic)
#   ci-cd/ci-07-apply-stability-tag/begin_*.sh - pre-apply setup
#   ci-cd/ci-07-apply-stability-tag/apply_*.sh - tagging commands
#   ci-cd/ci-07-apply-stability-tag/end_*.sh   - post-apply verification

echo:Release "Applying Stability Tag"
ci:param release "CI_STABILITY_TAG" "${CI_STABILITY_TAG:-}"
ci:param release "CI_VERSION" "${CI_VERSION:-}"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

hooks:declare apply
hooks:do apply

echo:Success "Stability Tag Applied"
