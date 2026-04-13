#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Confirm Rollback
# Purpose: Print rollback warning and planned actions

VERSION="${1:-unknown}"

echo:Release "========================================="
echo:Release "Confirming Rollback"
echo:Release "========================================="

cat <<EOF
WARNING: Rolling back version ${VERSION}
This action will:
  - Deprecate NPM package version (if enabled)
  - Mark GitHub release as draft (if enabled)
  - Tag Docker images as deprecated (if enabled)
EOF

echo:Release "========================================="
echo:Release "Rollback Confirmed"
echo:Release "========================================="
