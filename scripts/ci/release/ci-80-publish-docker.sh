#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Publish Docker Image
# Purpose: Build and publish Docker images
# Hooks: begin, publish, end (automatic)
#   ci-cd/ci-80-publish-docker/begin_*.sh   - pre-publish setup
#   ci-cd/ci-80-publish-docker/publish_*.sh - docker publish commands
#   ci-cd/ci-80-publish-docker/end_*.sh     - post-publish verification

echo:Release "Publishing Docker Image"
ci:param release "CI_VERSION" "${CI_VERSION:?CI_VERSION is required}"
ci:param release "CI_IS_PRERELEASE" "${CI_IS_PRERELEASE:-false}"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

set +eu
hooks:declare publish
hooks:do publish
set -eu

echo:Success "Docker Publishing Complete"
