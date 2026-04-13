#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

echo:Ops "Promote Release"
ci:param ops "VERSION" "${1}"

echo:Ops "Promoting version ${1}..."
echo:Ops ""
echo:Ops "Auto-promotion is not yet implemented."
echo:Ops "Please use the Release Pipeline to promote a pre-release:"
echo:Ops "  gh workflow run release.yml -f release-scope=... -f pre-release-type=..."
echo:Ops ""
echo:Ops "See: Actions > Release Pipeline > Run workflow"

echo:Ops "Promote Release Done"
