#!/usr/bin/env bash
set -euo pipefail

# CI Script: Bundle/Package
# Purpose: Create distributable bundles

echo "Making build scripts executable..."
chmod +x scripts/build/*.sh

echo "Creating bundles..."
./scripts/build/bundle.sh
