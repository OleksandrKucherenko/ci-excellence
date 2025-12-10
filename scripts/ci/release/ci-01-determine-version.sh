#!/usr/bin/env bash
set -euo pipefail

# CI Script: Determine Version
# Purpose: Calculate next version based on release type

echo "Making release scripts executable..."
chmod +x scripts/release/*.sh

echo "Determining next version..."
./scripts/release/determine-version.sh
