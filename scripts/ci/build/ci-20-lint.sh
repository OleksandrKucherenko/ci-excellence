#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Lint Code
# Purpose: Run linters and code style checks
# Hooks: begin, lint, end (automatic)
#   ci-cd/ci-20-lint/begin_*.sh - pre-lint setup
#   ci-cd/ci-20-lint/lint_*.sh  - lint commands (override default)
#   ci-cd/ci-20-lint/end_*.sh   - post-lint cleanup

# Default lint implementation: detects linter config and logs it.
# Override by adding ci-cd/ci-20-lint/lint_40_your-linter.sh
hook:lint() {
  if [ -f "eslint.config.js" ] || [ -f "eslint.config.mjs" ] || [ -f ".eslintrc.js" ] || [ -f ".eslintrc.json" ]; then
    echo:Build "ESLint config detected"
    # npx eslint . --max-warnings 0
  elif [ -f "tsconfig.json" ]; then
    echo:Build "TypeScript project detected (type-check available)"
    # npx tsc --noEmit
  elif [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
    echo:Build "Python project detected"
    # ruff check .
  elif [ -f "go.mod" ]; then
    echo:Build "Go project detected"
    # golangci-lint run
  elif [ -f "Cargo.toml" ]; then
    echo:Build "Rust project detected"
    # cargo clippy -- -D warnings
  else
    echo:Build "No linter config detected"
  fi
}

echo:Build "Running Linters"
hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

set +eu
hooks:declare lint
hooks:do lint
set -eu

echo:Success "Linting Complete"
