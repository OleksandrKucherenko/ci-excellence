#!/usr/bin/env bash
set -euo pipefail

# CI Pipeline Stub: Rollback NPM Release
# Purpose: Deprecate NPM package version
# Customize this script based on your rollback strategy

VERSION="${1:?Version is required}"

echo "========================================="
echo "Rolling Back NPM Release"
echo "Version: $VERSION"
echo "========================================="

# Check if NODE_AUTH_TOKEN is set
if [ -z "${NODE_AUTH_TOKEN:-}" ]; then
    echo "⚠ NODE_AUTH_TOKEN is not set"
    echo "  Set this secret in GitHub to enable NPM operations"
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
echo "✓ NPM rollback stub executed"
echo "  Customize this script in scripts/release/rollback-npm.sh"

echo "========================================="
echo "NPM Rollback Complete"
echo "========================================="
