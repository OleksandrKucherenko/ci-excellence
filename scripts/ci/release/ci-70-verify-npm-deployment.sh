#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Pipeline Stub: Verify NPM Deployment
# Purpose: Verify that package is available on NPM
# Customize this script based on your verification needs

VERSION="${CI_VERSION:?CI_VERSION is required}"

echo:Release "Verifying NPM Deployment"
ci:param release "CI_VERSION" "$VERSION"

# Example: Verify NPM package availability
# if [ -f "package.json" ]; then
#     PACKAGE_NAME=$(jq -r '.name' package.json)
#
#     echo "Checking NPM registry for $PACKAGE_NAME@$VERSION..."
#     if npm view "$PACKAGE_NAME@$VERSION" version &> /dev/null; then
#         echo "✓ Package found on NPM"
#
#         # Verify package integrity
#         PUBLISHED_VERSION=$(npm view "$PACKAGE_NAME@$VERSION" version)
#         if [ "$PUBLISHED_VERSION" == "$VERSION" ]; then
#             echo "✓ Version matches"
#         else
#             echo "⚠ Version mismatch: expected $VERSION, got $PUBLISHED_VERSION"
#             exit 1
#         fi
#     else
#         echo "⚠ Package not found on NPM"
#         exit 1
#     fi
# fi

# Add your NPM verification commands here
echo:Success "✓ NPM deployment verification stub executed"
echo:Release "  Customize this script in scripts/ci/release/ci-70-verify-npm-deployment.sh"

echo:Success "NPM Deployment Verification Complete"
