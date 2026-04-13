#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Unit Tests
# Purpose: Run unit tests
# Hooks: begin, test, end (automatic)
#   ci-cd/ci-10-unit-tests/begin_*.sh - pre-test setup (fixtures, mocks)
#   ci-cd/ci-10-unit-tests/test_*.sh  - test commands (override default)
#   ci-cd/ci-10-unit-tests/end_*.sh   - post-test cleanup (coverage upload)

# Default test implementation: detects test framework and logs it.
# Override by adding ci-cd/ci-10-unit-tests/test_40_your-tests.sh
hook:test() {
  if [ -f "jest.config.js" ] || [ -f "jest.config.ts" ]; then
    echo:Test "Jest config detected"
    # npm test -- --coverage
  elif [ -f "vitest.config.js" ] || [ -f "vitest.config.ts" ]; then
    echo:Test "Vitest config detected"
    # npm run test:unit
  elif [ -f "pytest.ini" ] || [ -f "pyproject.toml" ]; then
    echo:Test "Python project detected"
    # pytest --cov --cov-report=xml
  elif [ -f "go.mod" ]; then
    echo:Test "Go project detected"
    # go test -v -race -coverprofile=coverage.out ./...
  elif [ -f "Cargo.toml" ]; then
    echo:Test "Rust project detected"
    # cargo test
  elif [ -f "package.json" ]; then
    echo:Test "Node.js project detected"
    # npm test
  else
    echo:Test "No test framework detected"
  fi
}

echo:Test "Running Unit Tests"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

set +eu
hooks:declare test
hooks:do test
set -eu

echo:Success "Unit Tests Complete"
