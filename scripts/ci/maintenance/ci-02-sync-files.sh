#!/usr/bin/env bash
set -euo pipefail

# CI Script: Sync Files
# Purpose: Synchronize version files

echo "Making maintenance scripts executable..."
chmod +x scripts/maintenance/*.sh

echo "Syncing version files..."
./scripts/maintenance/sync-version-files.sh
