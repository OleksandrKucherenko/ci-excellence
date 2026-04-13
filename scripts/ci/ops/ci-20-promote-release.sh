#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

VERSION="${OPS_VERSION:?OPS_VERSION is required}"

echo:Ops "Promote Release"
ci:param ops "OPS_VERSION" "$VERSION"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply


echo:Ops "Promoting version ${VERSION}..."
echo:Ops ""
echo:Ops "Auto-promotion is not yet implemented."
echo:Ops "Please use the Release Pipeline to promote a pre-release:"
echo:Ops "  gh workflow run release.yml -f release-scope=... -f pre-release-type=..."
echo:Ops ""
echo:Ops "See: Actions > Release Pipeline > Run workflow"

echo:Success "Promote Release Done"
