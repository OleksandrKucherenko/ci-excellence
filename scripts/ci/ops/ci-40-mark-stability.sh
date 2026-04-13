#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

ACTION="${CI_STABILITY_TAG:?CI_STABILITY_TAG is required}"
VERSION="${OPS_VERSION:?OPS_VERSION is required}"

echo:Ops "Mark Stability"
ci:param ops "CI_STABILITY_TAG" "$ACTION"
ci:param ops "OPS_VERSION" "$VERSION"


echo:Ops "Marking ${VERSION} as ${ACTION}..."

export CI_VERSION="$VERSION"

case "$ACTION" in
  stable)
    ./scripts/ci/release/ci-07-apply-stability-tag.sh
    ;;
  deprecated)
    ./scripts/ci/maintenance/ci-80-deprecate-github-releases.sh
    ;;
  *)
    echo:Error "Error: Unknown action '${ACTION}'. Use 'stable' or 'deprecated'."
    exit 1
    ;;
esac

echo:Success "Mark Stability Done"
