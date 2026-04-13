#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Check for Changes
# Purpose: Check if git working tree has changes

echo:Maint "Checking for Changes"

if git diff --quiet; then
  echo "has-changes=false" >> $GITHUB_OUTPUT
  echo:Maint "No changes detected"
else
  echo "has-changes=true" >> $GITHUB_OUTPUT
  echo:Maint "Changes detected"
fi

echo:Maint "Change Check Complete"
