#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Deprecate NPM Versions
# Purpose: Deprecate old NPM package versions
# Hooks: begin, deprecate, end (automatic)
#   ci-cd/ci-75-deprecate-npm-versions/begin_*.sh     - pre-deprecate setup
#   ci-cd/ci-75-deprecate-npm-versions/deprecate_*.sh - npm deprecation commands
#   ci-cd/ci-75-deprecate-npm-versions/end_*.sh       - post-deprecate reporting

echo:Maint "Deprecating NPM Versions"
ci:secret maint "NODE_AUTH_TOKEN" "${NODE_AUTH_TOKEN:-}"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

hooks:declare deprecate
hooks:do deprecate

echo:Success "NPM Deprecation Complete"
