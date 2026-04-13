#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

echo:Ops "Mark Stability"
ci:param ops "ACTION" "${1:?Action required: stable|deprecated}"
ci:param ops "VERSION" "${2:?Version is required}"

ACTION="${1:?Action required: stable|deprecated}"
VERSION="${2:?Version is required}"

echo:Ops "Marking ${VERSION} as ${ACTION}..."

case "$ACTION" in
  stable)
    ./scripts/ci/release/ci-07-apply-stability-tag.sh stable "$VERSION"
    ;;
  deprecated)
    ./scripts/ci/maintenance/ci-80-deprecate-github-releases.sh "$VERSION"
    ;;
  *)
    echo:Ops "Error: Unknown action '${ACTION}'. Use 'stable' or 'deprecated'."
    exit 1
    ;;
esac

echo:Ops "Mark Stability Done"
