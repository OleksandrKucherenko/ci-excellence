#!/usr/bin/env bash
set -euo pipefail

# CI Script: Pre-Release Summary
# Purpose: Generate pre-release pipeline summary

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

echo "## Pre-Release Pipeline Summary" >> $GITHUB_STEP_SUMMARY
echo "" >> $GITHUB_STEP_SUMMARY
echo "| Job | Status | Enabled |" >> $GITHUB_STEP_SUMMARY
echo "|-----|--------|---------|" >> $GITHUB_STEP_SUMMARY
echo "| Setup | $SETUP_RESULT | Always |" >> $GITHUB_STEP_SUMMARY
echo "| Compile | $COMPILE_RESULT | $ENABLE_COMPILE |" >> $GITHUB_STEP_SUMMARY
echo "| Lint | $LINT_RESULT | $ENABLE_LINT |" >> $GITHUB_STEP_SUMMARY
echo "| Unit Tests | $UNIT_RESULT | $ENABLE_UNIT_TESTS |" >> $GITHUB_STEP_SUMMARY
echo "| Integration Tests | $INTEGRATION_RESULT | $ENABLE_INTEGRATION_TESTS |" >> $GITHUB_STEP_SUMMARY
echo "| E2E Tests | $E2E_RESULT | $ENABLE_E2E_TESTS |" >> $GITHUB_STEP_SUMMARY
echo "| Security Scan | $SECURITY_RESULT | $ENABLE_SECURITY_SCAN |" >> $GITHUB_STEP_SUMMARY
echo "| Bundle | $BUNDLE_RESULT | $ENABLE_BUNDLE |" >> $GITHUB_STEP_SUMMARY
