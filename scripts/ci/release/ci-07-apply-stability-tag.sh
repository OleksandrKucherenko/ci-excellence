#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Apply Stability Tag
# Purpose: Tag a version as stable/unstable per convention
# Hooks: begin, apply, end (automatic)
#   ci-cd/ci-07-apply-stability-tag/apply_*.sh - override tagging strategy
#
# Default strategy: creates v{VERSION}-{stable|unstable} tag pointing at v{VERSION}.

echo:Release "Applying Stability Tag"
ci:param release "CI_STABILITY_TAG" "${CI_STABILITY_TAG:-}"
ci:param release "CI_VERSION" "${CI_VERSION:-}"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

if ci:has_hooks apply; then
  set +eu
  hooks:declare apply
  hooks:do apply
  set -eu
else
  # Default: v{VERSION}-{stable|unstable} tag convention
  TAG_NAME="${CI_STABILITY_TAG:-}"
  VERSION="${CI_VERSION:-}"

  if [ -z "$TAG_NAME" ] || [ -z "$VERSION" ]; then
    echo:Error "CI_STABILITY_TAG and CI_VERSION are required"
    exit 1
  fi

  VERSION="${VERSION#v}"

  # Configure git identity for tagging
  ./scripts/ci/setup/ci-30-github-actions-bot.sh

  # Resolve version tag to commit
  TARGET_COMMIT=$(git rev-list -n 1 "v${VERSION}" 2>/dev/null || echo "")
  if [ -z "$TARGET_COMMIT" ]; then
    echo:Error "Tag v${VERSION} not found"
    exit 1
  fi

  STABILITY_TAG="v${VERSION}-${TAG_NAME}"
  echo:Release "Tagging ${TARGET_COMMIT:0:7} as ${STABILITY_TAG}"

  # Use GitHub API to create/update tag ref (avoids workflows permission issue with git push)
  if command -v gh &>/dev/null && [ -n "${GITHUB_REPOSITORY:-}" ]; then
    # Delete existing tag ref if present
    gh api "repos/${GITHUB_REPOSITORY}/git/refs/tags/${STABILITY_TAG}" -X DELETE 2>/dev/null || true
    # Create lightweight tag ref via API
    gh api "repos/${GITHUB_REPOSITORY}/git/refs" \
      -f ref="refs/tags/${STABILITY_TAG}" \
      -f sha="${TARGET_COMMIT}" 2>/dev/null \
      && echo:Release "Tag created via API" \
      || { echo:Error "API tag creation failed, trying git push"; git tag -f "$STABILITY_TAG" "$TARGET_COMMIT" && git push -f origin "$STABILITY_TAG"; }
  else
    git tag -f "$STABILITY_TAG" "$TARGET_COMMIT"
    git push -f origin "$STABILITY_TAG"
  fi

  echo:Release "Tagged: ${STABILITY_TAG}"
fi

echo:Success "Stability Tag Applied"
