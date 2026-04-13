#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Test After Update
# Purpose: Run tests after dependency update
# Hooks: begin, test, end (automatic)
#   ci-cd/ci-91-test-after-update/begin_*.sh - pre-test setup
#   ci-cd/ci-91-test-after-update/test_*.sh  - test commands
#   ci-cd/ci-91-test-after-update/end_*.sh   - post-test reporting

echo:Maint "Test After Update"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

ci:skip_if_no_hooks test

set +eu
hooks:declare test
hooks:do test
set -eu

echo:Success "Test After Update Done"
