#!/usr/bin/env bash
set -euo pipefail

# CI Script: File Sync Summary
# Purpose: Generate file sync summary for GitHub

HAS_CHANGES="${1:-false}"

echo "## File Sync Summary" >> $GITHUB_STEP_SUMMARY
echo "" >> $GITHUB_STEP_SUMMARY
if [ "$HAS_CHANGES" == "true" ]; then
  echo "Files were out of sync. PR created for review." >> $GITHUB_STEP_SUMMARY
else
  echo "All files are in sync." >> $GITHUB_STEP_SUMMARY
fi
