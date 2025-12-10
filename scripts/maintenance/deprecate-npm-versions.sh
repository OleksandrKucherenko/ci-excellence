#!/usr/bin/env bash
set -euo pipefail

# CI Pipeline Stub: Deprecate NPM Versions
# Purpose: Deprecate old NPM package versions
# Customize this script based on your deprecation policy

echo "========================================="
echo "Deprecating NPM Versions"
echo "========================================="

# Check if NODE_AUTH_TOKEN is set
if [ -z "${NODE_AUTH_TOKEN:-}" ]; then
    echo "⚠ NODE_AUTH_TOKEN is not set"
    echo "  Set this secret in GitHub to enable NPM operations"
    exit 1
fi

# Example: Deprecate specific versions
# if [ -f "package.json" ]; then
#     PACKAGE_NAME=$(jq -r '.name' package.json)
#
#     # Get versions to deprecate (e.g., old alpha/beta versions)
#     VERSIONS_TO_DEPRECATE=$(npm view "$PACKAGE_NAME" versions --json | \
#         jq -r '.[] | select(test("-alpha|-beta") and (. < "1.0.0"))')
#
#     echo "$VERSIONS_TO_DEPRECATE" | while read -r version; do
#         echo "Deprecating $PACKAGE_NAME@$version..."
#         npm deprecate "$PACKAGE_NAME@$version" \
#             "This pre-release version is deprecated. Please use a stable release."
#     done
# fi

# Add your NPM deprecation commands here
echo "✓ NPM deprecation stub executed"
echo "  Customize this script in scripts/maintenance/deprecate-npm-versions.sh"

echo "========================================="
echo "NPM Deprecation Complete"
echo "========================================="
