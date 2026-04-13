#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Pipeline Stub: Publish to NPM
# Purpose: Publish package to NPM registry
# Customize this script based on your NPM publishing needs

TAG="${1:---tag latest}"

echo:Release "========================================="
echo:Release "Publishing to NPM"
echo:Release "Tag: $TAG"
echo:Release "========================================="

# Check if NODE_AUTH_TOKEN is set
if [ -z "${NODE_AUTH_TOKEN:-}" ]; then
    echo:Release "⚠ NODE_AUTH_TOKEN is not set"
    echo:Release "  Set this secret in GitHub to enable NPM publishing"
    exit 1
fi

# Example: Publish to NPM
# if [ -f "package.json" ]; then
#     echo "Publishing package to NPM..."
#     npm publish $TAG
# fi

# Example: Publish to GitHub Packages
# if [ -f "package.json" ]; then
#     echo "Publishing package to GitHub Packages..."
#     npm publish --registry=https://npm.pkg.github.com
# fi

# Add your NPM publishing commands here
echo:Release "✓ NPM publish stub executed"
echo:Release "  Customize this script in scripts/ci/release/ci-65-publish-npm.sh"

echo:Release "========================================="
echo:Release "NPM Publishing Complete"
echo:Release "========================================="
