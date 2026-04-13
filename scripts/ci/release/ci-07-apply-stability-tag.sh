#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Apply Stability Tag
# Purpose: Tag a version as stable/unstable per STATES.md convention
# Tags follow format: v{SemVer}-stable or v{SemVer}-unstable

TAG_NAME="${1:-}"
VERSION="${2:-}"

echo:Release "========================================="
echo:Release "Applying Stability Tag"
echo:Release "========================================="

if [ -z "$TAG_NAME" ] || [ -z "$VERSION" ]; then
  echo:Release "Usage: $0 <stable|unstable> <version>"
  exit 1
fi

# Strip 'v' prefix if provided to normalize
VERSION="${VERSION#v}"

./scripts/ci/setup/ci-30-github-actions-bot.sh

# Resolve the version tag to a commit
TARGET_COMMIT=$(git rev-list -n 1 "v${VERSION}" 2>/dev/null || echo "")
if [ -z "$TARGET_COMMIT" ]; then
  echo:Release "Error: Tag v${VERSION} not found"
  exit 1
fi

# Create stability tag per STATES.md: v{SemVer}-stable / v{SemVer}-unstable
STABILITY_TAG="v${VERSION}-${TAG_NAME}"

echo:Release "Tagging ${TARGET_COMMIT:0:7} as ${STABILITY_TAG}"
git tag -f "$STABILITY_TAG" "$TARGET_COMMIT"
git push -f origin "$STABILITY_TAG"

{
  echo "## Stability Tagging"
  echo ""
  echo "**Version v${VERSION} tagged as ${TAG_NAME}**"
  echo "**Tag:** \`${STABILITY_TAG}\`"
} >> "${GITHUB_STEP_SUMMARY}"

echo:Release "========================================="
echo:Release "Stability Tag Applied"
echo:Release "========================================="
