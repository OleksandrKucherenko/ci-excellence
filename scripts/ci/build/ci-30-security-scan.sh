#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Security Scan
# Purpose: Run security vulnerability scans
# Hooks: begin, scan, end (automatic)
#   ci-cd/ci-30-security-scan/begin_*.sh - pre-scan setup
#   ci-cd/ci-30-security-scan/scan_*.sh  - security scan commands
#   ci-cd/ci-30-security-scan/end_*.sh   - post-scan reporting

echo:Security "Running Security Scans"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

hooks:declare scan
hooks:do scan

echo:Success "Security Scan Complete"
