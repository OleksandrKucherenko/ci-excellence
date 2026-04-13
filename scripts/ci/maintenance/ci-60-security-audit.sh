#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Security Audit
# Purpose: Run security audits on dependencies
# Hooks: begin, audit, end (automatic)
#   ci-cd/ci-60-security-audit/begin_*.sh - pre-audit setup
#   ci-cd/ci-60-security-audit/audit_*.sh - security audit commands
#   ci-cd/ci-60-security-audit/end_*.sh   - post-audit reporting

echo:Maint "Running Security Audit"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

set +eu
hooks:declare audit
hooks:do audit
set -eu

echo:Success "Security Audit Complete"
