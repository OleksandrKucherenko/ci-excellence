#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Write Release Notes Output
# Purpose: Generate release notes and expose via GITHUB_OUTPUT

VERSION="${CI_VERSION:?CI_VERSION is required}"

echo:Release "Writing Release Notes Output"
ci:param release "CI_VERSION" "$VERSION"

NOTES=$(./scripts/ci/release/ci-25-generate-release-notes.sh)

ci:output:multiline release "notes" "$NOTES"

echo:Release "Release Notes Output Written"
