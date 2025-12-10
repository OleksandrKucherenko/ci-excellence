#!/usr/bin/env bash
set -euo pipefail

# CI Script: Lint Code
# Purpose: Run code linting

echo "Making build scripts executable..."
chmod +x scripts/build/*.sh

echo "Running linter..."
./scripts/build/lint.sh
