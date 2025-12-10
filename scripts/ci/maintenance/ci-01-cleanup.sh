#!/usr/bin/env bash
set -euo pipefail

# CI Script: Cleanup
# Purpose: Cleanup old workflow runs, artifacts, and caches

echo "Making maintenance scripts executable..."
chmod +x scripts/maintenance/*.sh

echo "Cleaning up old workflow runs..."
./scripts/maintenance/cleanup-workflow-runs.sh

echo "Cleaning up old artifacts..."
./scripts/maintenance/cleanup-artifacts.sh

echo "Cleaning up old caches..."
./scripts/maintenance/cleanup-caches.sh

echo "Cleanup completed successfully"
