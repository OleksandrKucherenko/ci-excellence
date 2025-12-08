#!/usr/bin/env bash
set -euo pipefail

# CI Script: Confirm Rollback
# Purpose: Print rollback warning and planned actions

VERSION="${1:-unknown}"

cat <<EOF
WARNING: Rolling back version ${VERSION}
This action will:
  - Deprecate NPM package version (if enabled)
  - Mark GitHub release as draft (if enabled)
  - Tag Docker images as deprecated (if enabled)
EOF
