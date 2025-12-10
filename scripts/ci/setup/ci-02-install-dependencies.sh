#!/usr/bin/env bash
set -euo pipefail

# CI Script: Install Dependencies
# Purpose: Install project dependencies

echo "Installing dependencies..."
./scripts/setup/install-dependencies.sh
