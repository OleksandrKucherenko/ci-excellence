#!/usr/bin/env bash
set -euo pipefail

# CI Script: Check for Changes
# Purpose: Check if git working tree has changes

if git diff --quiet; then
  echo "has-changes=false" >> $GITHUB_OUTPUT
  echo "No changes detected"
else
  echo "has-changes=true" >> $GITHUB_OUTPUT
  echo "Changes detected"
fi
