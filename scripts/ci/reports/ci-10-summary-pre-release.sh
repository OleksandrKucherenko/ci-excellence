#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Pre-Release Summary
# Purpose: Generate pre-release pipeline summary

echo:Report "Generating Pre-Release Summary"

SETUP_RESULT="${1:-unknown}"
COMPILE_RESULT="${2:-unknown}"
LINT_RESULT="${3:-unknown}"
UNIT_RESULT="${4:-unknown}"
INTEGRATION_RESULT="${5:-unknown}"
E2E_RESULT="${6:-unknown}"
SECURITY_RESULT="${7:-unknown}"
BUNDLE_RESULT="${8:-unknown}"

ENABLE_COMPILE="${ENABLE_COMPILE:-false}"
ENABLE_LINT="${ENABLE_LINT:-false}"
ENABLE_UNIT_TESTS="${ENABLE_UNIT_TESTS:-false}"
ENABLE_INTEGRATION_TESTS="${ENABLE_INTEGRATION_TESTS:-false}"
ENABLE_E2E_TESTS="${ENABLE_E2E_TESTS:-false}"
ENABLE_SECURITY_SCAN="${ENABLE_SECURITY_SCAN:-false}"
ENABLE_BUNDLE="${ENABLE_BUNDLE:-false}"

ci:param report "SETUP_RESULT" "$SETUP_RESULT"
ci:param report "COMPILE_RESULT" "$COMPILE_RESULT"
ci:param report "LINT_RESULT" "$LINT_RESULT"
ci:param report "UNIT_RESULT" "$UNIT_RESULT"
ci:param report "INTEGRATION_RESULT" "$INTEGRATION_RESULT"
ci:param report "E2E_RESULT" "$E2E_RESULT"
ci:param report "SECURITY_RESULT" "$SECURITY_RESULT"
ci:param report "BUNDLE_RESULT" "$BUNDLE_RESULT"
ci:param report "ENABLE_COMPILE" "$ENABLE_COMPILE"
ci:param report "ENABLE_LINT" "$ENABLE_LINT"
ci:param report "ENABLE_UNIT_TESTS" "$ENABLE_UNIT_TESTS"
ci:param report "ENABLE_INTEGRATION_TESTS" "$ENABLE_INTEGRATION_TESTS"
ci:param report "ENABLE_E2E_TESTS" "$ENABLE_E2E_TESTS"
ci:param report "ENABLE_SECURITY_SCAN" "$ENABLE_SECURITY_SCAN"
ci:param report "ENABLE_BUNDLE" "$ENABLE_BUNDLE"
ENABLE_LINT="${ENABLE_LINT:-false}"
ENABLE_UNIT_TESTS="${ENABLE_UNIT_TESTS:-false}"
ENABLE_INTEGRATION_TESTS="${ENABLE_INTEGRATION_TESTS:-false}"
ENABLE_E2E_TESTS="${ENABLE_E2E_TESTS:-false}"
ENABLE_SECURITY_SCAN="${ENABLE_SECURITY_SCAN:-false}"
ENABLE_BUNDLE="${ENABLE_BUNDLE:-false}"

{
    echo "## Pre-Release Pipeline Summary"
    echo ""
    echo "| Job | Status | Enabled |"
    echo "|-----|--------|---------|"
    echo "| Setup | $SETUP_RESULT | Always |"
    echo "| Compile | $COMPILE_RESULT | $ENABLE_COMPILE |"
    echo "| Lint | $LINT_RESULT | $ENABLE_LINT |"
    echo "| Unit Tests | $UNIT_RESULT | $ENABLE_UNIT_TESTS |"
    echo "| Integration Tests | $INTEGRATION_RESULT | $ENABLE_INTEGRATION_TESTS |"
    echo "| E2E Tests | $E2E_RESULT | $ENABLE_E2E_TESTS |"
    echo "| Security Scan | $SECURITY_RESULT | $ENABLE_SECURITY_SCAN |"
    echo "| Bundle | $BUNDLE_RESULT | $ENABLE_BUNDLE |" 
} >> "${GITHUB_STEP_SUMMARY}"

echo:Report "Pre-Release Summary Generated"
