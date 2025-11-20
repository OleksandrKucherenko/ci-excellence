#!/usr/bin/env bash
set -euo pipefail

# CI Script: Security Scan
# Purpose: Run security vulnerability scans

echo "Making build scripts executable..."
chmod +x scripts/build/*.sh

echo "Running security scans..."
./scripts/build/security-scan.sh
