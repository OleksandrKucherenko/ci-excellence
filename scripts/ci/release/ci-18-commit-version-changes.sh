#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Commit Version Changes
# Purpose: Commit and push version bump changes

TARGET_BRANCH="${CI_TARGET_BRANCH:-main}"
VERSION="${CI_VERSION:-}"

echo:Release "Committing Version Changes"
ci:param release "CI_TARGET_BRANCH" "$TARGET_BRANCH"
ci:param release "CI_VERSION" "$VERSION"

if [ -z "$VERSION" ]; then
  echo:Release "Version is required"
  exit 1
fi

./scripts/ci/setup/ci-30-github-actions-bot.sh

git add .
git commit -m "chore(release): bump version to ${VERSION}" || echo "No changes to commit"
git push origin "HEAD:${TARGET_BRANCH}" || echo "Nothing to push"

echo:Success "Version Changes Committed"
