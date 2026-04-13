#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Pipeline Stub: Publish to NPM
# Purpose: Publish package to NPM registry
# Customize this script based on your NPM publishing needs

TAG="${CI_NPM_TAG:---tag latest}"

echo:Release "Publishing to NPM"
ci:param release "CI_NPM_TAG" "${TAG}"
ci:secret release "NODE_AUTH_TOKEN" "${NODE_AUTH_TOKEN:-}"

hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

# Check if NODE_AUTH_TOKEN is set
if [ -z "${NODE_AUTH_TOKEN:-}" ]; then
    echo:Error "⚠ NODE_AUTH_TOKEN is not set"
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
echo:Success "✓ NPM publish stub executed"
echo:Release "  Customize this script in scripts/ci/release/ci-65-publish-npm.sh"

echo:Success "NPM Publishing Complete"
