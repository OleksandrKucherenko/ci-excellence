#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Smoke Tests
# Purpose: Run basic smoke tests to verify deployment
# Hooks: begin, test, end (automatic)
#   ci-cd/ci-40-smoke-tests/begin_*.sh - pre-test setup
#   ci-cd/ci-40-smoke-tests/test_*.sh  - smoke test commands
#   ci-cd/ci-40-smoke-tests/end_*.sh   - post-test reporting

echo:Test "Running Smoke Tests"
ci:param test "CI_VERSION" "${CI_VERSION:-latest}"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

hooks:declare test
hooks:do test

echo:Success "Smoke Tests Complete"
