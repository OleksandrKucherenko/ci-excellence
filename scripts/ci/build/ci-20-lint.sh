#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Lint Code
# Purpose: Run linters and code style checks
# Hooks: begin, lint, end (automatic)
#   ci-cd/ci-20-lint/begin_*.sh - pre-lint setup
#   ci-cd/ci-20-lint/lint_*.sh  - lint commands
#   ci-cd/ci-20-lint/end_*.sh   - post-lint cleanup

echo:Build "Running Linters"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

ci:skip_if_no_hooks lint

set +eu
hooks:declare lint
hooks:do lint
set -eu

echo:Success "Linting Complete"
