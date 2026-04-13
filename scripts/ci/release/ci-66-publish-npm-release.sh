#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

IS_PRERELEASE="${CI_IS_PRERELEASE:-false}"

echo:Release "Publish NPM Release"
ci:param release "CI_IS_PRERELEASE" "$IS_PRERELEASE"


if [ "$IS_PRERELEASE" == "true" ]; then
  export CI_NPM_TAG="--tag next"
else
  export CI_NPM_TAG="--tag latest"
fi

./scripts/ci/release/ci-65-publish-npm.sh

echo:Success "Publish NPM Release Done"
