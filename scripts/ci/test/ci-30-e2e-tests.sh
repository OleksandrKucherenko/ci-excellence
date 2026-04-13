#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: E2E Tests
# Purpose: Run end-to-end tests
# Hooks: begin, test, end (automatic)
#   ci-cd/ci-30-e2e-tests/begin_*.sh - pre-test setup (browser, services)
#   ci-cd/ci-30-e2e-tests/test_*.sh  - e2e test commands
#   ci-cd/ci-30-e2e-tests/end_*.sh   - post-test cleanup

echo:Test "Running End-to-End Tests"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

ci:skip_if_no_hooks test

set +eu
hooks:declare test
hooks:do test
set -eu

echo:Success "E2E Tests Complete"
