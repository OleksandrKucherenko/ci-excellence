#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Dependency Update Summary
# Purpose: Generate dependency update summary for GitHub step summary

echo:Report "Generating Dependency Update Summary"

HAS_CHANGES="${1:-false}"

ci:param report "HAS_CHANGES" "$HAS_CHANGES"

{
  echo "## Dependency Update Summary"
  echo ""
  if [ "$HAS_CHANGES" == "true" ]; then
    echo "Dependencies updated. PR created for review."
  else
    echo "All dependencies are up to date."
  fi
} >> "${GITHUB_STEP_SUMMARY}"

echo:Report "Dependency Update Summary Generated"
