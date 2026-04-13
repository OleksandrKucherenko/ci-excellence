#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Write Release Notes Output
# Purpose: Generate release notes and expose via GITHUB_OUTPUT

VERSION="${1:?Version is required}"

NOTES=$(./scripts/ci/release/ci-25-generate-release-notes.sh "$VERSION")

{
  echo "notes<<EOF"
  echo "$NOTES"
  echo "EOF"
} >> "$GITHUB_OUTPUT"
