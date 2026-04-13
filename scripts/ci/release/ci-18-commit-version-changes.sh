#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Commit Version Changes
# Purpose: Commit and push version bump changes

TARGET_BRANCH="${1:-main}"
VERSION="${2:-}"

echo:Release "--- Committing Version Changes ---"

if [ -z "$VERSION" ]; then
  echo:Release "Version is required"
  exit 1
fi

./scripts/ci/setup/ci-30-github-actions-bot.sh

git add .
git commit -m "chore(release): bump version to ${VERSION}" || echo "No changes to commit"
git push origin "HEAD:${TARGET_BRANCH}" || echo "Nothing to push"

echo:Release "--- Version Changes Committed ---"
