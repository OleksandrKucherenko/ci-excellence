#!/usr/bin/env bash
set -euo pipefail

# CI Script: Integration Tests
# Purpose: Run integration tests

echo "Making test scripts executable..."
chmod +x scripts/test/*.sh

echo "Running integration tests..."
./scripts/test/integration.sh
