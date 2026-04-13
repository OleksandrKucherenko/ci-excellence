#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Apply Stability Tag
# Purpose: Tag a version as stable/unstable per STATES.md convention
# Tags follow format: v{SemVer}-stable or v{SemVer}-unstable

TAG_NAME="${CI_STABILITY_TAG:-}"
VERSION="${CI_VERSION:-}"

echo:Release "Applying Stability Tag"
ci:param release "CI_STABILITY_TAG" "$TAG_NAME"
ci:param release "CI_VERSION" "$VERSION"

hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

if [ -z "$TAG_NAME" ] || [ -z "$VERSION" ]; then
  echo:Release "Usage: CI_STABILITY_TAG=<stable|unstable> CI_VERSION=<version> $0"
  exit 1
fi

# Strip 'v' prefix if provided to normalize
VERSION="${VERSION#v}"

./scripts/ci/setup/ci-30-github-actions-bot.sh

# Resolve the version tag to a commit
TARGET_COMMIT=$(git rev-list -n 1 "v${VERSION}" 2>/dev/null || echo "")
if [ -z "$TARGET_COMMIT" ]; then
  echo:Error "Error: Tag v${VERSION} not found"
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

echo:Success "Stability Tag Applied"
