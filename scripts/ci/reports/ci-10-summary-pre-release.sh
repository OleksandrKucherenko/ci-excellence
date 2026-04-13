#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Pre-Release Summary
# Purpose: Generate pre-release pipeline summary

echo:Report "Generating Pre-Release Summary"

SETUP_RESULT="${RESULT_SETUP:-unknown}"
COMPILE_RESULT="${RESULT_COMPILE:-unknown}"
LINT_RESULT="${RESULT_LINT:-unknown}"
UNIT_RESULT="${RESULT_UNIT_TESTS:-unknown}"
INTEGRATION_RESULT="${RESULT_INTEGRATION_TESTS:-unknown}"
E2E_RESULT="${RESULT_E2E_TESTS:-unknown}"
SECURITY_RESULT="${RESULT_SECURITY_SCAN:-unknown}"
BUNDLE_RESULT="${RESULT_BUNDLE:-unknown}"

ENABLE_COMPILE="${ENABLE_COMPILE:-false}"
ENABLE_LINT="${ENABLE_LINT:-false}"
ENABLE_UNIT_TESTS="${ENABLE_UNIT_TESTS:-false}"
ENABLE_INTEGRATION_TESTS="${ENABLE_INTEGRATION_TESTS:-false}"
ENABLE_E2E_TESTS="${ENABLE_E2E_TESTS:-false}"
ENABLE_SECURITY_SCAN="${ENABLE_SECURITY_SCAN:-false}"
ENABLE_BUNDLE="${ENABLE_BUNDLE:-false}"

ci:param report "RESULT_SETUP" "$SETUP_RESULT"
ci:param report "RESULT_COMPILE" "$COMPILE_RESULT"
ci:param report "RESULT_LINT" "$LINT_RESULT"
ci:param report "RESULT_UNIT_TESTS" "$UNIT_RESULT"
ci:param report "RESULT_INTEGRATION_TESTS" "$INTEGRATION_RESULT"
ci:param report "RESULT_E2E_TESTS" "$E2E_RESULT"
ci:param report "RESULT_SECURITY_SCAN" "$SECURITY_RESULT"
ci:param report "RESULT_BUNDLE" "$BUNDLE_RESULT"
ci:param report "ENABLE_COMPILE" "$ENABLE_COMPILE"
ci:param report "ENABLE_LINT" "$ENABLE_LINT"
ci:param report "ENABLE_UNIT_TESTS" "$ENABLE_UNIT_TESTS"
ci:param report "ENABLE_INTEGRATION_TESTS" "$ENABLE_INTEGRATION_TESTS"
ci:param report "ENABLE_E2E_TESTS" "$ENABLE_E2E_TESTS"
ci:param report "ENABLE_SECURITY_SCAN" "$ENABLE_SECURITY_SCAN"
ci:param report "ENABLE_BUNDLE" "$ENABLE_BUNDLE"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply
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

echo:Success "Pre-Release Summary Generated"
