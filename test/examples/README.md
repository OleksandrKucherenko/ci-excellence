# CI Testing Examples

This directory contains example scripts demonstrating how to use the local CI testing framework.

## Available Examples

### 1. Test All Scenarios (`test-all-scenarios.sh`)

Runs all predefined scenarios for the pre-release workflow.

**Usage:**
```bash
./test/examples/test-all-scenarios.sh
```

**What it tests:**
- Happy path (all jobs succeed)
- Unit tests failure
- Lint failure
- Build failure
- Security scan failure

**Expected output:**
```
Testing All Pre-Release Scenarios
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Scenario: happy-path
Expected: Should succeed
✅ Scenario 'happy-path' completed

Scenario: unit-tests-fail
Expected: Should fail at unit tests
✅ Scenario 'unit-tests-fail' failed as expected

...

Test Results Summary
Total Scenarios: 5
Passed: 5
Failed: 0
All tests passed!
```

---

### 2. Test Single Job (`test-single-job.sh`)

Tests a single job in all possible states (ok, failed, stuck).

**Usage:**
```bash
# Test default job (unit-tests)
./test/examples/test-single-job.sh

# Test specific job
./test/examples/test-single-job.sh lint

# Test specific job in specific workflow
./test/examples/test-single-job.sh e2e-tests pre-release
```

**Arguments:**
- `$1` - Job name (default: `unit-tests`)
- `$2` - Workflow name (default: `pre-release`)

**What it tests:**
- Job succeeds in OK state
- Job fails in FAILED state
- Job times out in STUCK state

---

### 3. Test Timeout Scenarios (`test-timeout-scenarios.sh`)

Demonstrates different timeout configurations and behaviors.

**Usage:**
```bash
./test/examples/test-timeout-scenarios.sh
```

**What it tests:**
- Job completes within timeout (5s delay, 10s timeout)
- Job exceeds timeout (stuck for 60s, 15s timeout)
- Multiple jobs with different delays

**Learning points:**
- How to set delays with `MOCK_DELAY`
- How timeouts are enforced
- Per-job delay configuration

---

## Running Examples

### Prerequisites

Ensure you have the test framework set up:
```bash
# Check if test runner exists
ls -la scripts/local-ci-test.sh

# Make all scripts executable
chmod +x scripts/local-ci-test.sh
chmod +x scripts/lib/*.sh
chmod +x test/examples/*.sh
```

### Quick Start

1. **Run all scenarios:**
   ```bash
   cd /path/to/ci-excellence
   ./test/examples/test-all-scenarios.sh
   ```

2. **Test a single job:**
   ```bash
   ./test/examples/test-single-job.sh lint
   ```

3. **Test timeouts:**
   ```bash
   ./test/examples/test-timeout-scenarios.sh
   ```

---

## Creating Your Own Test Scripts

Use these examples as templates for creating custom test scripts:

### Template Structure

```bash
#!/usr/bin/env bash
set -euo pipefail

# Setup paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TEST_RUNNER="${PROJECT_ROOT}/scripts/local-ci-test.sh"

# Your test logic here
bash "$TEST_RUNNER" <workflow> <scenario> [options]
```

### Example: Test Multiple Workflows

```bash
#!/usr/bin/env bash
workflows=("pre-release" "release" "maintenance")

for workflow in "${workflows[@]}"; do
    echo "Testing workflow: $workflow"
    bash scripts/local-ci-test.sh "$workflow" happy-path
done
```

### Example: Parallel Testing

```bash
#!/usr/bin/env bash
jobs=("lint" "compile" "unit-tests")

for job in "${jobs[@]}"; do
    (
        bash scripts/local-ci-test.sh pre-release --job "$job" --state random
    ) &
done

wait
echo "All tests completed"
```

---

## Common Patterns

### Testing with Environment Variables

```bash
#!/usr/bin/env bash
MOCK_ENABLED=true \
MOCK_MODE=ok \
MOCK_DELAY=3 \
bash scripts/local-ci-test.sh pre-release
```

### Testing with Custom Timeouts

```bash
#!/usr/bin/env bash
bash scripts/local-ci-test.sh pre-release \
    --timeout 300 \
    --job unit-tests \
    --state ok
```

### Testing Failure Scenarios

```bash
#!/usr/bin/env bash
# Test each job failing independently
jobs=("compile" "lint" "unit-tests")

for job in "${jobs[@]}"; do
    bash scripts/local-ci-test.sh pre-release \
        --job "$job" \
        --state failed
done
```

---

## Tips

1. **Start simple**: Begin with `test-all-scenarios.sh` to understand the basics
2. **Modify delays**: Adjust `MOCK_DELAY` to speed up or slow down tests
3. **Use verbose mode**: Add `--verbose` flag to see detailed output
4. **Check results**: Review logs in `.ci-test-results/` directory
5. **Combine tests**: Chain multiple test scripts for comprehensive testing

---

## Next Steps

1. Run the example scripts to understand the framework
2. Modify examples to test your specific use cases
3. Create custom scenarios in `test/scenarios/`
4. Integrate testing into your development workflow
5. Add tests to pre-commit hooks for automatic validation

---

For more information, see [LOCAL_TESTING.md](../LOCAL_TESTING.md)
