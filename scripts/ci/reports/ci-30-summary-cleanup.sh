#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Cleanup Summary
# Purpose: Generate cleanup summary for GitHub

echo "## Cleanup Summary" >> $GITHUB_STEP_SUMMARY
echo "" >> $GITHUB_STEP_SUMMARY
echo "Cleanup completed at $(date)" >> $GITHUB_STEP_SUMMARY
