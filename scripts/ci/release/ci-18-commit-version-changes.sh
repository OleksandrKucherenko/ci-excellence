#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Commit Version Changes
# Purpose: Commit and push version bump changes
# Hooks: begin, commit, end (automatic)
#   ci-cd/ci-18-commit-version-changes/commit_*.sh - override commit strategy
#
# Default strategy: git add . && commit with conventional message && push.

echo:Release "Committing Version Changes"
ci:param release "CI_TARGET_BRANCH" "${CI_TARGET_BRANCH:-main}"
ci:param release "CI_VERSION" "${CI_VERSION:-}"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

if ci:has_hooks commit; then
  set +eu
  hooks:declare commit
  hooks:do commit
  set -eu
else
  # Default: conventional commit and push
  VERSION="${CI_VERSION:-}"
  TARGET="${CI_TARGET_BRANCH:-main}"

  if [ -z "$VERSION" ]; then
    echo:Release "No version specified, skipping commit"
  else
    git add .
    git commit -m "chore(release): bump version to ${VERSION}" || echo:Release "No changes to commit"
    git push origin "HEAD:${TARGET}" || echo:Release "Nothing to push"
  fi
fi

echo:Success "Version Changes Committed"
