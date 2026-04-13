#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

echo:Ops "Validate Inputs"
ci:param ops "ACTION" "${1:-}"
ci:param ops "VERSION" "${2:-}"

if [[ -z "${2:-}" ]]; then
  echo:Ops "Error: Version is required"
  exit 1
fi

echo:Ops "Validate Inputs Done"
