#!/usr/bin/env bash
set -euo pipefail

# CI Script: Apply Stability Tag
# Purpose: Tag a version as stable/unstable and push the tag

TAG_NAME="${1:-}"
VERSION="${2:-}"

if [ -z "$TAG_NAME" ] || [ -z "$VERSION" ]; then
  echo "Usage: $0 <stable|unstable> <version>" >&2
  exit 1
fi

./scripts/ci/setup/ci-30-github-actions-bot.sh

git tag -f "$TAG_NAME" "$VERSION"
git push -f origin "$TAG_NAME"

{
  echo "## Stability Tagging"
  echo ""
  echo "**Version $VERSION tagged as $TAG_NAME**"
} >> "${GITHUB_STEP_SUMMARY}"
