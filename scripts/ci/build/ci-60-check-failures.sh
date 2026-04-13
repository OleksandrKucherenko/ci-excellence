#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Check for Failures
# Purpose: Check if any pipeline job failed

SETUP_RESULT="${1:-success}"
COMPILE_RESULT="${2:-success}"
LINT_RESULT="${3:-success}"
UNIT_RESULT="${4:-success}"
INTEGRATION_RESULT="${5:-success}"
E2E_RESULT="${6:-success}"
SECURITY_RESULT="${7:-success}"
BUNDLE_RESULT="${8:-success}"

echo:Build "Checking Pipeline Results"
ci:param build "SETUP_RESULT" "$SETUP_RESULT"
ci:param build "COMPILE_RESULT" "$COMPILE_RESULT"
ci:param build "LINT_RESULT" "$LINT_RESULT"
ci:param build "UNIT_RESULT" "$UNIT_RESULT"
ci:param build "INTEGRATION_RESULT" "$INTEGRATION_RESULT"
ci:param build "E2E_RESULT" "$E2E_RESULT"
ci:param build "SECURITY_RESULT" "$SECURITY_RESULT"
ci:param build "BUNDLE_RESULT" "$BUNDLE_RESULT"

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
