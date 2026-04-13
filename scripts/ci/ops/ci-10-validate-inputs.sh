#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

echo:Ops "Validate Inputs"

echo:Ops "Action: $1"
echo:Ops "Version: $2"

if [[ -z "${2:-}" ]]; then
  echo:Ops "Error: Version is required"
  exit 1
fi

echo:Ops "Validate Inputs Done"
