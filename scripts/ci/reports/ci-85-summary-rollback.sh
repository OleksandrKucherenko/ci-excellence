#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Rollback Summary
# Purpose: Generate rollback summary for GitHub step summary

echo:Report "Generating Rollback Summary"

VERSION="${CI_VERSION:-unknown}"

ci:param report "CI_VERSION" "$VERSION"

{
  echo "## Rollback Summary"
  echo ""
  echo "**Version:** $VERSION"
  echo ""
  echo "Rollback completed successfully"
} >> "${GITHUB_STEP_SUMMARY}"

echo:Success "Rollback Summary Generated"
