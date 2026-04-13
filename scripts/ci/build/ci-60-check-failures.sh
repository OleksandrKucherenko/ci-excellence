#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Check for Failures
# Purpose: Check if any pipeline job failed
# Hooks: begin, check, end (automatic)
#   ci-cd/ci-60-check-failures/begin_*.sh - pre-check setup
#   ci-cd/ci-60-check-failures/check_*.sh - failure check commands
#   ci-cd/ci-60-check-failures/end_*.sh   - post-check reporting

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

ci:skip_if_no_hooks check

set +eu
hooks:declare check
hooks:do check
set -eu

echo:Success "Pipeline Check Complete"
