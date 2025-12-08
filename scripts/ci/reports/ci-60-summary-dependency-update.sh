#!/usr/bin/env bash
set -euo pipefail

# CI Script: Dependency Update Summary
# Purpose: Generate dependency update summary for GitHub step summary

HAS_CHANGES="${1:-false}"

{
  echo "## Dependency Update Summary"
  echo ""
  if [ "$HAS_CHANGES" == "true" ]; then
    echo "Dependencies updated. PR created for review."
  else
    echo "All dependencies are up to date."
  fi
} >> "${GITHUB_STEP_SUMMARY}"
