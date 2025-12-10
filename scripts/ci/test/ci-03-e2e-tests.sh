#!/usr/bin/env bash
set -euo pipefail

# CI Script: E2E Tests
# Purpose: Run end-to-end tests

echo "Making test scripts executable..."
chmod +x scripts/test/*.sh

echo "Running E2E tests..."
./scripts/test/e2e.sh
