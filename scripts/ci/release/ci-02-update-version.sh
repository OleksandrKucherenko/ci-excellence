#!/usr/bin/env bash
set -euo pipefail

# CI Script: Update Version
# Purpose: Update version in project files

echo "Making release scripts executable..."
chmod +x scripts/release/*.sh

echo "Updating version files..."
./scripts/release/update-version.sh
