#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Commit Version Changes
# Purpose: Commit and push version bump changes
# Hooks: begin, commit, end (automatic)
#   ci-cd/ci-18-commit-version-changes/begin_*.sh  - pre-commit setup
#   ci-cd/ci-18-commit-version-changes/commit_*.sh - commit commands
#   ci-cd/ci-18-commit-version-changes/end_*.sh    - post-commit verification

echo:Release "Committing Version Changes"
ci:param release "CI_TARGET_BRANCH" "${CI_TARGET_BRANCH:-main}"
ci:param release "CI_VERSION" "${CI_VERSION:-}"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

set +eu
hooks:declare commit
hooks:do commit
set -eu

echo:Success "Version Changes Committed"
