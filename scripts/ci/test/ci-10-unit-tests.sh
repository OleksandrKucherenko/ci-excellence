#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Unit Tests
# Purpose: Run unit tests
# Hooks: begin, test, end (automatic)
#   ci-cd/ci-10-unit-tests/begin_*.sh - pre-test setup (fixtures, mocks)
#   ci-cd/ci-10-unit-tests/test_*.sh  - test commands
#   ci-cd/ci-10-unit-tests/end_*.sh   - post-test cleanup (coverage upload)

echo:Test "Running Unit Tests"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

hooks:declare test
hooks:do test

echo:Success "Unit Tests Complete"
