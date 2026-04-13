#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Check for Failures
# Purpose: Check if any pipeline job failed

SETUP_RESULT="${RESULT_SETUP:-success}"
COMPILE_RESULT="${RESULT_COMPILE:-success}"
LINT_RESULT="${RESULT_LINT:-success}"
UNIT_RESULT="${RESULT_UNIT_TESTS:-success}"
INTEGRATION_RESULT="${RESULT_INTEGRATION_TESTS:-success}"
E2E_RESULT="${RESULT_E2E_TESTS:-success}"
SECURITY_RESULT="${RESULT_SECURITY_SCAN:-success}"
BUNDLE_RESULT="${RESULT_BUNDLE:-success}"

echo:Build "Checking Pipeline Results"
ci:param build "RESULT_SETUP" "$SETUP_RESULT"
ci:param build "RESULT_COMPILE" "$COMPILE_RESULT"
ci:param build "RESULT_LINT" "$LINT_RESULT"
ci:param build "RESULT_UNIT_TESTS" "$UNIT_RESULT"
ci:param build "RESULT_INTEGRATION_TESTS" "$INTEGRATION_RESULT"
ci:param build "RESULT_E2E_TESTS" "$E2E_RESULT"
ci:param build "RESULT_SECURITY_SCAN" "$SECURITY_RESULT"
ci:param build "RESULT_BUNDLE" "$BUNDLE_RESULT"

if [ "$SETUP_RESULT" == "failure" ] || \
   [ "$COMPILE_RESULT" == "failure" ] || \
   [ "$LINT_RESULT" == "failure" ] || \
   [ "$UNIT_RESULT" == "failure" ] || \
   [ "$INTEGRATION_RESULT" == "failure" ] || \
   [ "$E2E_RESULT" == "failure" ] || \
   [ "$SECURITY_RESULT" == "failure" ] || \
   [ "$BUNDLE_RESULT" == "failure" ]; then
  echo "::error::One or more pipeline jobs failed"
  exit 1
fi

echo:Build "Pipeline Check Complete"
