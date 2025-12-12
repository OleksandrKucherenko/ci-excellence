#!/usr/bin/env bash
set -euo pipefail

# CI Script: Commit Version Changes
# Purpose: Commit and push version bump changes

TARGET_BRANCH="${1:-main}"
VERSION="${2:-}"

if [ -z "$VERSION" ]; then
  echo "Version is required" >&2
  exit 1
fi

./scripts/ci/setup/ci-30-github-actions-bot.sh

git add .
git commit -m "chore(release): bump version to ${VERSION}" || echo "No changes to commit"
git push origin "HEAD:${TARGET_BRANCH}" || echo "Nothing to push"
