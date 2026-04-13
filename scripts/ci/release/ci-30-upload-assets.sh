#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Pipeline Stub: Upload Release Assets
# Purpose: Upload build artifacts to GitHub release

VERSION="${CI_VERSION:?CI_VERSION is required}"
TAG="v${VERSION}"

echo:Release "Uploading Release Assets"
ci:param release "CI_VERSION" "$VERSION"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply


# Example: Upload assets using gh CLI
# if command -v gh &> /dev/null; then
#     echo "Uploading assets to GitHub release..."
#     gh release upload "$TAG" dist/*.tar.gz dist/*.zip --clobber
# fi

# Example: Upload specific files
# gh release upload "$TAG" \
#     dist/myapp-linux-amd64 \
#     dist/myapp-darwin-amd64 \
#     dist/myapp-windows-amd64.exe \
#     --clobber


echo:Success "Release Assets Uploaded"
