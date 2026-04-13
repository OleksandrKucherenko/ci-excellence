#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Check for Failures
# Purpose: Check if any pipeline job failed
# Hooks: begin, check, end (automatic)
#   ci-cd/ci-60-check-failures/check_*.sh - override failure check strategy
#
# Default strategy: fail if any RESULT_* env var equals "failure".

echo:Build "Checking Pipeline Results"
ci:param build "RESULT_SETUP" "${RESULT_SETUP:-success}"
ci:param build "RESULT_COMPILE" "${RESULT_COMPILE:-success}"
ci:param build "RESULT_LINT" "${RESULT_LINT:-success}"
ci:param build "RESULT_UNIT_TESTS" "${RESULT_UNIT_TESTS:-success}"
ci:param build "RESULT_INTEGRATION_TESTS" "${RESULT_INTEGRATION_TESTS:-success}"
ci:param build "RESULT_E2E_TESTS" "${RESULT_E2E_TESTS:-success}"
ci:param build "RESULT_SECURITY_SCAN" "${RESULT_SECURITY_SCAN:-success}"
ci:param build "RESULT_BUNDLE" "${RESULT_BUNDLE:-success}"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

if ci:has_hooks check; then
  set +eu
  hooks:declare check
  hooks:do check
  set -eu
else
  # Default: check all RESULT_* variables for "failure"
  if [ "${RESULT_SETUP:-success}" == "failure" ] || \
     [ "${RESULT_COMPILE:-success}" == "failure" ] || \
     [ "${RESULT_LINT:-success}" == "failure" ] || \
     [ "${RESULT_UNIT_TESTS:-success}" == "failure" ] || \
     [ "${RESULT_INTEGRATION_TESTS:-success}" == "failure" ] || \
     [ "${RESULT_E2E_TESTS:-success}" == "failure" ] || \
     [ "${RESULT_SECURITY_SCAN:-success}" == "failure" ] || \
     [ "${RESULT_BUNDLE:-success}" == "failure" ]; then
    echo:Error "One or more pipeline jobs failed"
    echo "::error::One or more pipeline jobs failed"
    exit 1
  fi
fi

echo:Success "Pipeline Check Complete"
