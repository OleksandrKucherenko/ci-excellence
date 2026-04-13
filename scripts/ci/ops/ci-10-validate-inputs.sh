#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

ACTION="${OPS_ACTION:-}"
VERSION="${OPS_VERSION:-}"

echo:Ops "Validate Inputs"
ci:param ops "OPS_ACTION" "$ACTION"
ci:param ops "OPS_VERSION" "$VERSION"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply


if [[ -z "$VERSION" ]]; then
  echo:Error "Error: Version is required"
  exit 1
fi

echo:Success "Validate Inputs Done"
