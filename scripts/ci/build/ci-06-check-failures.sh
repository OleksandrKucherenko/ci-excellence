#!/usr/bin/env bash
set -euo pipefail

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
