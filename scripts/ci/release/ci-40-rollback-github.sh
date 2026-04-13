#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Pipeline Stub: Rollback GitHub Release
# Purpose: Mark GitHub release as draft or delete it

VERSION="${CI_VERSION:?CI_VERSION is required}"
TAG="v$VERSION"

echo:Release "Rolling Back GitHub Release"
ci:param release "CI_VERSION" "$VERSION"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply


# Example: Mark release as draft using gh CLI
# if command -v gh &> /dev/null; then
#     echo "Marking release as draft..."
#     gh release edit "$TAG" --draft
# fi

# Example: Delete release using gh CLI
# if command -v gh &> /dev/null; then
#     echo "Deleting release..."
#     gh release delete "$TAG" --yes
# fi

# Example: Update release description to warn users
# if command -v gh &> /dev/null; then
#     gh release edit "$TAG" --notes "⚠️ WARNING: This release has been rolled back. Please do not use."
# fi


echo:Success "GitHub Rollback Complete"
