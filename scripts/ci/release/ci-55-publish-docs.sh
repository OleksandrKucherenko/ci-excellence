#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Publish Documentation
# Purpose: Publish documentation to hosting platform
# Hooks: begin, publish, end (automatic)
#   ci-cd/ci-55-publish-docs/begin_*.sh   - pre-publish setup
#   ci-cd/ci-55-publish-docs/publish_*.sh - documentation publish commands
#   ci-cd/ci-55-publish-docs/end_*.sh     - post-publish verification

echo:Release "Publishing Documentation"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

ci:skip_if_no_hooks publish

set +eu
hooks:declare publish
hooks:do publish
set -eu

echo:Success "Documentation Publishing Complete"
