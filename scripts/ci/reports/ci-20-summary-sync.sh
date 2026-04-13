#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: File Sync Summary
# Purpose: Generate file sync summary for GitHub

echo:Report "Generating Sync Summary"

HAS_CHANGES="${MAINT_HAS_CHANGES:-false}"

ci:param report "MAINT_HAS_CHANGES" "$HAS_CHANGES"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

echo "## File Sync Summary" >> $GITHUB_STEP_SUMMARY
echo "" >> $GITHUB_STEP_SUMMARY
if [ "$HAS_CHANGES" == "true" ]; then
  echo "Files were out of sync. PR created for review." >> $GITHUB_STEP_SUMMARY
else
  echo "All files are in sync." >> $GITHUB_STEP_SUMMARY
fi

echo:Success "Sync Summary Generated"
