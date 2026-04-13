#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Upload Release Assets
# Purpose: Upload build artifacts to GitHub release
# Hooks: begin, upload, end (automatic)
#   ci-cd/ci-30-upload-assets/begin_*.sh  - pre-upload setup
#   ci-cd/ci-30-upload-assets/upload_*.sh - asset upload commands
#   ci-cd/ci-30-upload-assets/end_*.sh    - post-upload verification

echo:Release "Uploading Release Assets"
ci:param release "CI_VERSION" "${CI_VERSION:?CI_VERSION is required}"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

set +eu
hooks:declare upload
hooks:do upload
set -eu

echo:Success "Release Assets Uploaded"
