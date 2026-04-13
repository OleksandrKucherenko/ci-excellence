#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Security Audit Summary
# Purpose: Generate security audit summary for GitHub step summary

echo:Report "--- Generating Security Audit Summary ---"

{
  echo "## Security Audit Summary"
  echo ""
  echo "Security audit completed at $(date)"
} >> "${GITHUB_STEP_SUMMARY}"

echo:Report "--- Security Audit Summary Generated ---"
