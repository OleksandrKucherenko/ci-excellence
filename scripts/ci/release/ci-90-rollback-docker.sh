#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Rollback Docker Release
# Purpose: Tag Docker images as deprecated
# Hooks: begin, rollback, end (automatic)
#   ci-cd/ci-90-rollback-docker/begin_*.sh    - pre-rollback setup
#   ci-cd/ci-90-rollback-docker/rollback_*.sh - docker rollback commands
#   ci-cd/ci-90-rollback-docker/end_*.sh      - post-rollback verification

echo:Release "Rolling Back Docker Release"
ci:param release "CI_VERSION" "${CI_VERSION:?CI_VERSION is required}"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

ci:skip_if_no_hooks rollback

set +eu
hooks:declare rollback
hooks:do rollback
set -eu

echo:Success "Docker Rollback Complete"
