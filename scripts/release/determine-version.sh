#!/usr/bin/env bash
set -euo pipefail

# CI Pipeline Stub: Determine Version
# Purpose: Determine the next version number
# Customize this script based on your versioning strategy

RELEASE_TYPE="${1:-patch}"

echo "=========================================" >&2
echo "Determining Version" >&2
echo "Release Type: $RELEASE_TYPE" >&2
echo "=========================================" >&2

# Example: Get version from package.json
# if [ -f "package.json" ]; then
#     CURRENT_VERSION=$(jq -r '.version' package.json)
# fi

# Example: Get version from setup.py
# if [ -f "setup.py" ]; then
#     CURRENT_VERSION=$(grep -oP 'version="\K[^"]+' setup.py)
# fi

# Example: Get version from Cargo.toml
# if [ -f "Cargo.toml" ]; then
#     CURRENT_VERSION=$(grep -oP '^version = "\K[^"]+' Cargo.toml)
# fi

# Example: Get version from git tags
# CURRENT_VERSION=$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo "0.0.0")

# For now, use a stub version
CURRENT_VERSION="0.0.0"

# Simple semver bump logic (replace with proper semver tool in production)
IFS='.' read -r -a VERSION_PARTS <<< "$CURRENT_VERSION"
MAJOR="${VERSION_PARTS[0]}"
MINOR="${VERSION_PARTS[1]}"
PATCH="${VERSION_PARTS[2]}"

case "$RELEASE_TYPE" in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        ;;
    patch)
        PATCH=$((PATCH + 1))
        ;;
    premajor)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        NEW_VERSION="$MAJOR.$MINOR.$PATCH-alpha.0"
        echo "$NEW_VERSION"
        exit 0
        ;;
    preminor)
        MINOR=$((MINOR + 1))
        PATCH=0
        NEW_VERSION="$MAJOR.$MINOR.$PATCH-alpha.0"
        echo "$NEW_VERSION"
        exit 0
        ;;
    prepatch)
        PATCH=$((PATCH + 1))
        NEW_VERSION="$MAJOR.$MINOR.$PATCH-alpha.0"
        echo "$NEW_VERSION"
        exit 0
        ;;
    prerelease)
        # Increment pre-release version
        NEW_VERSION="$MAJOR.$MINOR.$PATCH-alpha.1"
        echo "$NEW_VERSION"
        exit 0
        ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"

echo "Current version: $CURRENT_VERSION" >&2
echo "New version: $NEW_VERSION" >&2
echo "$NEW_VERSION"

echo "=========================================" >&2
echo "Version Determined: $NEW_VERSION" >&2
echo "=========================================" >&2
