#!/usr/bin/env bash
set -euo pipefail

# CI Script: Unit Tests
# Purpose: Run unit tests

echo "Making test scripts executable..."
chmod +x scripts/test/*.sh

echo "Running unit tests..."
./scripts/test/unit.sh
