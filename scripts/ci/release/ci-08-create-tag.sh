#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

echo:Release "Create Tag"

./scripts/ci/setup/ci-30-github-actions-bot.sh

TAG="v${1}"
echo:Release "Creating tag: $TAG"
git tag -a "$TAG" -m "Release $TAG"
git push origin "$TAG"

echo:Release "Create Tag Done"
