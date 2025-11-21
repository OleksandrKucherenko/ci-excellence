#!/usr/bin/env bash
set -euo pipefail

# CI Script: Unit Tests
# Purpose: Run unit tests

# ============================================================================
# Setup
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

# Source mock framework and timeout config
# shellcheck source=../../lib/mock-framework.sh
source "${SCRIPT_DIR}/../../lib/mock-framework.sh" 2>/dev/null || true
# shellcheck source=../../lib/timeout-config.sh
source "${SCRIPT_DIR}/../../lib/timeout-config.sh" 2>/dev/null || true

# ============================================================================
# Mock Handler
# ============================================================================

# Check if mock mode is enabled and handle accordingly
if is_mock_mode 2>/dev/null; then
    print_mock_config
    mock_handler "Unit Tests" || exit $?
    exit 0
fi

# ============================================================================
# Main Execution
# ============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Running Unit Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd "${PROJECT_ROOT}"

echo "Making test scripts executable..."
chmod +x scripts/test/*.sh

echo "Running unit tests..."
if command -v run_with_timeout >/dev/null 2>&1; then
    run_with_timeout ./scripts/test/unit.sh
else
    ./scripts/test/unit.sh
fi

echo "✅ Unit tests completed successfully"
