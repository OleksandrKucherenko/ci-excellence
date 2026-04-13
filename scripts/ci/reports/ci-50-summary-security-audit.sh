#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Security Audit Summary
# Purpose: Generate security audit summary for GitHub step summary

{
  echo "## Security Audit Summary"
  echo ""
  echo "Security audit completed at $(date)"
} >> "${GITHUB_STEP_SUMMARY}"
