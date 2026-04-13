#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Verify NPM Deployment
# Purpose: Verify that package is available on NPM
# Hooks: begin, verify, end (automatic)
#   ci-cd/ci-70-verify-npm-deployment/begin_*.sh  - pre-verify setup
#   ci-cd/ci-70-verify-npm-deployment/verify_*.sh - npm verification commands
#   ci-cd/ci-70-verify-npm-deployment/end_*.sh    - post-verify reporting

echo:Release "Verifying NPM Deployment"
ci:param release "CI_VERSION" "${CI_VERSION:?CI_VERSION is required}"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

hooks:declare verify
hooks:do verify

echo:Success "NPM Deployment Verification Complete"
