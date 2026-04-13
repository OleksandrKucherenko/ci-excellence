#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Maintenance Pipeline Summary
# Purpose: Generate maintenance pipeline summary table

echo:Report "Generating Maintenance Summary"

CLEANUP_RESULT="${RESULT_CLEANUP:-unknown}"
SYNC_RESULT="${RESULT_SYNC:-unknown}"
DEPRECATION_RESULT="${RESULT_DEPRECATION:-unknown}"
SECURITY_RESULT="${RESULT_SECURITY:-unknown}"
DEPENDENCY_RESULT="${RESULT_DEPENDENCY:-unknown}"

ENABLE_CLEANUP="${ENABLE_CLEANUP:-false}"
ENABLE_FILE_SYNC="${ENABLE_FILE_SYNC:-false}"
ENABLE_DEPRECATION="${ENABLE_DEPRECATION:-false}"
ENABLE_SECURITY_AUDIT="${ENABLE_SECURITY_AUDIT:-false}"
ENABLE_DEPENDENCY_UPDATE="${ENABLE_DEPENDENCY_UPDATE:-false}"

ci:param report "RESULT_CLEANUP" "$CLEANUP_RESULT"
ci:param report "RESULT_SYNC" "$SYNC_RESULT"
ci:param report "RESULT_DEPRECATION" "$DEPRECATION_RESULT"
ci:param report "RESULT_SECURITY" "$SECURITY_RESULT"
ci:param report "RESULT_DEPENDENCY" "$DEPENDENCY_RESULT"
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
