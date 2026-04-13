#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Deprecation Summary
# Purpose: Generate deprecation summary for GitHub step summary

echo:Report "Generating Deprecation Summary"

{
  echo "## Deprecation Summary"
  echo ""
  echo "Deprecated versions checked and updated"
} >> "${GITHUB_STEP_SUMMARY}"

echo:Success "Deprecation Summary Generated"
