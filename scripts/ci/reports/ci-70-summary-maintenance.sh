#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Maintenance Pipeline Summary
# Purpose: Generate maintenance pipeline summary table

echo:Report "Generating Maintenance Summary"

CLEANUP_RESULT="${1:-unknown}"
SYNC_RESULT="${2:-unknown}"
DEPRECATION_RESULT="${3:-unknown}"
SECURITY_RESULT="${4:-unknown}"
DEPENDENCY_RESULT="${5:-unknown}"

ENABLE_CLEANUP="${ENABLE_CLEANUP:-false}"
ENABLE_FILE_SYNC="${ENABLE_FILE_SYNC:-false}"
ENABLE_DEPRECATION="${ENABLE_DEPRECATION:-false}"
ENABLE_SECURITY_AUDIT="${ENABLE_SECURITY_AUDIT:-false}"
ENABLE_DEPENDENCY_UPDATE="${ENABLE_DEPENDENCY_UPDATE:-false}"

ci:param report "CLEANUP_RESULT" "$CLEANUP_RESULT"
ci:param report "SYNC_RESULT" "$SYNC_RESULT"
ci:param report "DEPRECATION_RESULT" "$DEPRECATION_RESULT"
ci:param report "SECURITY_RESULT" "$SECURITY_RESULT"
ci:param report "DEPENDENCY_RESULT" "$DEPENDENCY_RESULT"
ci:param report "ENABLE_CLEANUP" "$ENABLE_CLEANUP"
ci:param report "ENABLE_FILE_SYNC" "$ENABLE_FILE_SYNC"
ci:param report "ENABLE_DEPRECATION" "$ENABLE_DEPRECATION"
ci:param report "ENABLE_SECURITY_AUDIT" "$ENABLE_SECURITY_AUDIT"
ci:param report "ENABLE_DEPENDENCY_UPDATE" "$ENABLE_DEPENDENCY_UPDATE"
ENABLE_FILE_SYNC="${ENABLE_FILE_SYNC:-false}"
ENABLE_DEPRECATION="${ENABLE_DEPRECATION:-false}"
ENABLE_SECURITY_AUDIT="${ENABLE_SECURITY_AUDIT:-false}"
ENABLE_DEPENDENCY_UPDATE="${ENABLE_DEPENDENCY_UPDATE:-false}"

{
  echo "## Maintenance Pipeline Summary"
  echo ""
  echo "| Task | Status | Enabled |"
  echo "|------|--------|---------|"
  echo "| Cleanup | $CLEANUP_RESULT | $ENABLE_CLEANUP |"
  echo "| File Sync | $SYNC_RESULT | $ENABLE_FILE_SYNC |"
  echo "| Deprecate Old Versions | $DEPRECATION_RESULT | $ENABLE_DEPRECATION |"
  echo "| Security Audit | $SECURITY_RESULT | $ENABLE_SECURITY_AUDIT |"
  echo "| Dependency Update | $DEPENDENCY_RESULT | $ENABLE_DEPENDENCY_UPDATE |"
} >> "${GITHUB_STEP_SUMMARY}"

echo:Report "Maintenance Summary Generated"
