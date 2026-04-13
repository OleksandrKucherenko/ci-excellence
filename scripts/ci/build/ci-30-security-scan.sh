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

ci:skip_if_no_hooks scan

set +eu
hooks:declare scan
hooks:do scan
set -eu

echo:Success "Security Scan Complete"
