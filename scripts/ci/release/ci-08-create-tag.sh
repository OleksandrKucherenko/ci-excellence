#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

VERSION="${CI_VERSION:?CI_VERSION is required}"

echo:Release "Create Tag"
ci:param release "CI_VERSION" "$VERSION"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply


./scripts/ci/setup/ci-30-github-actions-bot.sh

TAG="v${VERSION}"
echo:Release "Creating tag: $TAG"
git tag -a "$TAG" -m "Release $TAG"
git push origin "$TAG"

echo:Success "Create Tag Done"
