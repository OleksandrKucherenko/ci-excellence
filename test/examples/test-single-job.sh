#!/usr/bin/env bash
# Test Single Job with Different States
# Demonstrates testing a single job in all possible states

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TEST_RUNNER="${PROJECT_ROOT}/scripts/local-ci-test.sh"

JOB="${1:-unit-tests}"
WORKFLOW="${2:-pre-release}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Testing Job: ${JOB} (Workflow: ${WORKFLOW})"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

states=("ok" "failed" "stuck")

for state in "${states[@]}"; do
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Testing state: ${state}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    timeout=120
    if [[ "$state" == "stuck" ]]; then
        timeout=90  # Shorter timeout for stuck state
    fi

    if bash "$TEST_RUNNER" "$WORKFLOW" \
        --job "$JOB" \
        --state "$state" \
        --timeout "$timeout" \
        --verbose; then
        echo "✅ Job succeeded in state: ${state}"
    else
        exit_code=$?
        if [[ "$state" == "ok" ]]; then
            echo "❌ Job failed in OK state (unexpected!)"
        else
            echo "✅ Job failed as expected in state: ${state} (exit code: $exit_code)"
        fi
    fi

    echo ""
    sleep 2
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Single job testing complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
