#!/usr/bin/env bash
# Test Timeout Scenarios
# Demonstrates testing different timeout configurations

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TEST_RUNNER="${PROJECT_ROOT}/scripts/local-ci-test.sh"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Testing Timeout Scenarios"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 1: Job with delay less than timeout (should succeed)
echo "Test 1: Job with 5s delay and 10s timeout (should succeed)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
MOCK_ENABLED=true \
MOCK_MODE=ok \
MOCK_DELAY=5 \
bash "$TEST_RUNNER" pre-release --job unit-tests --timeout 10 --verbose

echo ""
echo "✅ Test 1 completed"
echo ""
sleep 2

# Test 2: Job stuck with short timeout (should timeout)
echo "Test 2: Stuck job with 15s timeout (should timeout)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
MOCK_ENABLED=true \
MOCK_MODE=stuck \
MOCK_STUCK_DURATION=60 \
bash "$TEST_RUNNER" pre-release --job e2e-tests --timeout 15 --verbose || true

echo ""
echo "✅ Test 2 completed (expected timeout)"
echo ""
sleep 2

# Test 3: Multiple jobs with different delays
echo "Test 3: Multiple jobs with varying delays"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
MOCK_ENABLED=true \
MOCK_MODE=ok \
MOCK_DELAY=2 \
MOCK_DELAY_LINT=5 \
MOCK_DELAY_COMPILE=8 \
MOCK_DELAY_UNIT_TESTS=10 \
bash "$TEST_RUNNER" pre-release \
    --job lint \
    --job compile \
    --job unit-tests \
    --verbose

echo ""
echo "✅ Test 3 completed"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "All timeout tests completed!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
