#!/usr/bin/env bash
set -euo pipefail

# CI Script: Compile/Build
# Purpose: Run compilation/build process

echo "Making build scripts executable..."
chmod +x scripts/build/*.sh

echo "Running compilation..."
./scripts/build/compile.sh
