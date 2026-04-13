#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Pipeline Stub: Rollback NPM Release
# Purpose: Deprecate NPM package version
# Customize this script based on your rollback strategy

VERSION="${CI_VERSION:?CI_VERSION is required}"

echo:Release "Rolling Back NPM Release"
ci:param release "CI_VERSION" "$VERSION"
ci:secret release "NODE_AUTH_TOKEN" "${NODE_AUTH_TOKEN:-}"


# Check if NODE_AUTH_TOKEN is set
if [ -z "${NODE_AUTH_TOKEN:-}" ]; then
    echo:Error "⚠ NODE_AUTH_TOKEN is not set"
    echo:Release "  Set this secret in GitHub to enable NPM operations"
    exit 1
fi

# Example: Deprecate NPM package version
# if [ -f "package.json" ]; then
#     PACKAGE_NAME=$(jq -r '.name' package.json)
#     echo "Deprecating $PACKAGE_NAME@$VERSION..."
#     npm deprecate "$PACKAGE_NAME@$VERSION" "This version has been rolled back due to issues"
# fi

# Note: npm unpublish can only be used within 72 hours of publishing
# and requires special permissions
# npm unpublish "$PACKAGE_NAME@$VERSION"

# Add your NPM rollback commands here
echo:Success "✓ NPM rollback stub executed"
echo:Release "  Customize this script in scripts/ci/release/ci-75-rollback-npm.sh"

echo:Success "NPM Rollback Complete"
