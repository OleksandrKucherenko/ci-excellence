#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Bundle/Package
# Purpose: Create distribution packages
# Hooks: begin, bundle, end (automatic)
#   ci-cd/ci-40-bundle/begin_*.sh  - pre-bundle setup
#   ci-cd/ci-40-bundle/bundle_*.sh - bundling commands
#   ci-cd/ci-40-bundle/end_*.sh    - post-bundle verification

echo:Build "Creating Bundle/Package"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

hooks:declare bundle
hooks:do bundle

echo:Success "Bundling Complete"
