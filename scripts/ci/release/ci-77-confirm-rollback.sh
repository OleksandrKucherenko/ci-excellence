#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Confirm Rollback
# Purpose: Print rollback warning and planned actions

VERSION="${CI_VERSION:-unknown}"

echo:Release "Confirming Rollback"
ci:param release "CI_VERSION" "$VERSION"

hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

cat <<EOF
WARNING: Rolling back version ${VERSION}
This action will:
  - Deprecate NPM package version (if enabled)
  - Mark GitHub release as draft (if enabled)
  - Tag Docker images as deprecated (if enabled)
EOF

echo:Success "Rollback Confirmed"
