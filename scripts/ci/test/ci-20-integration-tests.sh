#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Integration Tests
# Purpose: Run integration tests
# Hooks: begin, test, end (automatic)
#   ci-cd/ci-20-integration-tests/begin_*.sh - pre-test setup (services, fixtures)
#   ci-cd/ci-20-integration-tests/test_*.sh  - integration test commands
#   ci-cd/ci-20-integration-tests/end_*.sh   - post-test cleanup (services teardown)

echo:Test "Running Integration Tests"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

hooks:declare test
hooks:do test

echo:Success "Integration Tests Complete"
