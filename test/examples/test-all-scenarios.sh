#!/usr/bin/env bash
# Test All Pre-Release Scenarios
# Run all predefined scenarios for the pre-release workflow

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TEST_RUNNER="${PROJECT_ROOT}/scripts/local-ci-test.sh"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Testing All Pre-Release Scenarios"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Define scenarios to test
scenarios=(
    "happy-path:Should succeed"
    "unit-tests-fail:Should fail at unit tests"
    "lint-fail:Should fail at lint"
    "build-fail:Should fail at build"
    "security-fail:Should fail at security scan"
)

results=()
passed=0
failed=0

for scenario_def in "${scenarios[@]}"; do
    IFS=':' read -r scenario description <<< "$scenario_def"

    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Scenario: ${scenario}${NC}"
    echo -e "${BLUE}Expected: ${description}${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    if bash "$TEST_RUNNER" pre-release "$scenario" 2>&1; then
        echo -e "${GREEN}✅ Scenario '$scenario' completed${NC}"
        results+=("✅ $scenario")
        ((passed++))
    else
        exit_code=$?
        if [[ "$scenario" == "happy-path" ]]; then
            # Happy path should succeed
            echo -e "${RED}❌ Scenario '$scenario' failed unexpectedly (exit code: $exit_code)${NC}"
            results+=("❌ $scenario (unexpected failure)")
            ((failed++))
        else
            # Failure scenarios should fail
            echo -e "${GREEN}✅ Scenario '$scenario' failed as expected${NC}"
            results+=("✅ $scenario (expected failure)")
            ((passed++))
        fi
    fi
done

# Print summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test Results Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Total Scenarios: ${#scenarios[@]}"
echo "Passed: $passed"
echo "Failed: $failed"
echo ""

for result in "${results[@]}"; do
    echo "  $result"
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ $failed -gt 0 ]]; then
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
else
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
fi
