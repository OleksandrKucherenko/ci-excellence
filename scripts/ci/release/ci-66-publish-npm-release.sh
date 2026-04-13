#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Publish NPM Release
# Purpose: Publish NPM release with appropriate tag
# Hooks: begin, release, end (automatic)
#   ci-cd/ci-66-publish-npm-release/begin_*.sh   - pre-release setup
#   ci-cd/ci-66-publish-npm-release/release_*.sh - npm release commands
#   ci-cd/ci-66-publish-npm-release/end_*.sh     - post-release verification

echo:Release "Publish NPM Release"
ci:param release "CI_IS_PRERELEASE" "${CI_IS_PRERELEASE:-false}"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

hooks:declare release
hooks:do release

echo:Success "Publish NPM Release Done"
