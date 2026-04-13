#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Publish to NPM
# Purpose: Publish package to NPM registry
# Hooks: begin, publish, end (automatic)
#   ci-cd/ci-65-publish-npm/begin_*.sh   - pre-publish setup
#   ci-cd/ci-65-publish-npm/publish_*.sh - npm publish commands
#   ci-cd/ci-65-publish-npm/end_*.sh     - post-publish verification

echo:Release "Publishing to NPM"
ci:param release "CI_NPM_TAG" "${CI_NPM_TAG:---tag latest}"
ci:secret release "NODE_AUTH_TOKEN" "${NODE_AUTH_TOKEN:-}"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

set +eu
hooks:declare publish
hooks:do publish
set -eu

echo:Success "NPM Publishing Complete"
