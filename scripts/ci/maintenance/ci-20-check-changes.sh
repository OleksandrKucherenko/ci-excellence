#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Check for Changes
# Purpose: Check if git working tree has changes

echo:Maint "Checking for Changes"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

if git diff --quiet; then
  ci:output maint "has-changes" "false"
  echo:Maint "No changes detected"
else
  ci:output maint "has-changes" "true"
  echo:Maint "Changes detected"
fi

echo:Success "Change Check Complete"
