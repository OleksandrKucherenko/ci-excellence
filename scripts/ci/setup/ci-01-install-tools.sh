#!/usr/bin/env bash
set -euo pipefail

# CI Script: Install Tools
# Purpose: Setup CI environment with required tools

echo "Making setup scripts executable..."
chmod +x scripts/setup/*.sh

echo "Installing required tools..."
./scripts/setup/install-tools.sh
