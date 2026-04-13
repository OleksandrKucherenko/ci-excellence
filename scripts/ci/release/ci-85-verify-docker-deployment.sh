#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Verify Docker Deployment
# Purpose: Verify that Docker image is available
# Hooks: begin, verify, end (automatic)
#   ci-cd/ci-85-verify-docker-deployment/begin_*.sh  - pre-verify setup
#   ci-cd/ci-85-verify-docker-deployment/verify_*.sh - docker verification commands
#   ci-cd/ci-85-verify-docker-deployment/end_*.sh    - post-verify reporting

echo:Release "Verifying Docker Deployment"
ci:param release "CI_VERSION" "${CI_VERSION:?CI_VERSION is required}"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

ci:skip_if_no_hooks verify

set +eu
hooks:declare verify
hooks:do verify
set -eu

echo:Success "Docker Deployment Verification Complete"
