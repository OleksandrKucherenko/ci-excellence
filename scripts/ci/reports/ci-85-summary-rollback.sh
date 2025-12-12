#!/usr/bin/env bash
set -euo pipefail

# CI Script: Rollback Summary
# Purpose: Generate rollback summary for GitHub step summary

VERSION="${1:-unknown}"

{
  echo "## Rollback Summary"
  echo ""
  echo "**Version:** $VERSION"
  echo ""
  echo "Rollback completed successfully"
} >> "${GITHUB_STEP_SUMMARY}"
