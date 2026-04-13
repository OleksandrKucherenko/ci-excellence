#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

echo:Release "Publish NPM Release"
ci:param release "IS_PRERELEASE" "${1:-false}"

if [ "${1:-false}" == "true" ]; then
  ./scripts/ci/release/ci-65-publish-npm.sh --tag next
else
  ./scripts/ci/release/ci-65-publish-npm.sh --tag latest
fi

echo:Release "Publish NPM Release Done"
