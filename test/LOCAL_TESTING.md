# Local CI Testing Framework

A comprehensive framework for testing CI pipelines locally with mock states, timeouts, and scenario-based testing.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Quick Start](#quick-start)
- [Mock Framework](#mock-framework)
- [Test Runner](#test-runner)
- [Scenarios](#scenarios)
- [Timeout Management](#timeout-management)
- [Integrating with CI Scripts](#integrating-with-ci-scripts)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)

---

## Overview

This framework allows you to:

1. **Test CI pipelines locally** before pushing to GitHub
2. **Simulate different states** (OK, FAILED, STUCK) for any job
3. **Control execution flow** with timeouts and delays
4. **Run specific scenarios** to test edge cases
5. **Debug CI issues** without consuming GitHub Actions minutes

---

## Features

### ✅ Mock State Simulation

Simulate three execution states for any CI job:

- **OK**: Job completes successfully
- **FAILED**: Job fails with configurable exit code
- **STUCK**: Job hangs and requires timeout
- **RANDOM**: Randomly select one of the above states

### ⏱️ Timeout Management

All CI steps have configurable timeouts:

- **Default timeouts** for each job type
- **Per-script overrides** for specific needs
- **Automatic timeout enforcement** with graceful termination

### 🎯 Scenario-Based Testing

Pre-configured scenarios for common situations:

- Happy path (all jobs succeed)
- Specific job failures (lint, tests, build, etc.)
- Timeout scenarios
- Chaos testing with random states

### 📊 Detailed Results

- Job-by-job execution logs
- Duration tracking
- Exit code capture
- JSON result metadata

---

## Quick Start

### 1. List available workflows and scenarios

```bash
./scripts/local-ci-test.sh --list
```

### 2. Run a workflow with happy path

```bash
./scripts/local-ci-test.sh pre-release happy-path
```

### 3. Test a specific failure scenario

```bash
./scripts/local-ci-test.sh pre-release unit-tests-fail
```

### 4. Run specific job with custom state

```bash
./scripts/local-ci-test.sh pre-release --job lint --state failed
```

---

## Mock Framework

### Environment Variables

Control mock behavior using environment variables:

#### Global Mock Control

```bash
MOCK_ENABLED=true           # Enable/disable mock mode (default: false)
MOCK_MODE=<ok|failed|stuck|random>  # Default state for all jobs
MOCK_VERBOSE=true           # Enable verbose mock output
```

#### State-Specific Configuration

```bash
# OK state
MOCK_DELAY=5                # Delay before completion (seconds)

# FAILED state
MOCK_EXIT_CODE=1            # Exit code for failed state (default: 1)

# STUCK state
MOCK_STUCK_DURATION=300     # How long to stay stuck (default: 300s)

# RANDOM state
MOCK_RANDOM_SEED=42         # Seed for reproducible randomness
```

#### Per-Job Overrides

Override settings for specific jobs by appending the job name:

```bash
# Make only unit tests fail
MOCK_MODE=ok                        # All jobs succeed
MOCK_MODE_UNIT_TESTS=failed         # Except unit tests
MOCK_DELAY_UNIT_TESTS=10            # With 10s delay
```

Job name format: Uppercase with underscores (e.g., `UNIT_TESTS`, `E2E_TESTS`)

### Mock Functions

When integrating mock framework into scripts:

```bash
# Source the framework
source "${SCRIPT_DIR}/lib/mock-framework.sh"

# Check if in mock mode
if is_mock_mode; then
    mock_handler "Job Description" || exit $?
    exit 0
fi

# Or conditionally execute
mock_or_execute "Build Application" npm run build

# Print current configuration
print_mock_config
```

---

## Test Runner

### Usage

```bash
./scripts/local-ci-test.sh [OPTIONS] <workflow> [scenario]
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `-l, --list` | List available workflows and scenarios | - |
| `-v, --verbose` | Enable verbose output | false |
| `-m, --mock` | Enable mock mode | true |
| `-t, --timeout <sec>` | Global timeout for all jobs | 3600 |
| `-j, --job <name>` | Run only specific job(s) | all |
| `-s, --state <state>` | Override all job states | - |
| `-d, --delay <sec>` | Add delay to all jobs | 0 |
| `-o, --output <dir>` | Output directory for results | .ci-test-results |
| `-h, --help` | Show help message | - |

### Workflows

Available workflows:

- `pre-release` - PR and feature branch checks
- `release` - Version bumping and publishing
- `post-release` - Post-release verification
- `maintenance` - Scheduled maintenance tasks

### Job Names

Common job names across workflows:

**Pre-release:**
- `setup`, `compile`, `lint`, `unit-tests`, `integration-tests`, `e2e-tests`, `security-scan`, `bundle`, `summary`, `notify`

**Release:**
- `prepare`, `build`, `test`, `publish-npm`, `publish-github`, `publish-docker`, `publish-documentation`, `notify`

**Maintenance:**
- `cleanup`, `sync-files`, `deprecation`, `security-audit`, `dependency-update`

---

## Scenarios

Scenarios are YAML files that configure mock behavior and feature flags for testing specific situations.

### Location

```
test/scenarios/*.yml
```

### Built-in Scenarios

| Scenario | Description |
|----------|-------------|
| `happy-path.yml` | All jobs succeed |
| `unit-tests-fail.yml` | Unit tests fail |
| `lint-fail.yml` | Linting fails |
| `build-fail.yml` | Compilation fails |
| `security-fail.yml` | Security scan fails |
| `e2e-stuck.yml` | E2E tests hang |
| `chaos-random.yml` | Random states for all jobs |
| `release-major.yml` | Successful major release |
| `release-publish-fail.yml` | NPM publish fails |
| `maintenance-all.yml` | All maintenance tasks |

### Scenario Format

```yaml
# Scenario Name and Description
name: Unit Tests Failure
description: Simulate unit tests failing while other jobs pass

# Global mock settings
MOCK_ENABLED: true
MOCK_MODE: ok
MOCK_DELAY: 1
MOCK_VERBOSE: true

# Per-job overrides
MOCK_MODE_UNIT_TESTS: failed
MOCK_EXIT_CODE: 1
MOCK_DELAY_UNIT_TESTS: 3

# Feature flags
ENABLE_COMPILE: true
ENABLE_LINT: true
ENABLE_UNIT_TESTS: true
ENABLE_INTEGRATION_TESTS: false
```

### Creating Custom Scenarios

1. Create a new YAML file in `test/scenarios/`
2. Define mock settings and feature flags
3. Run with: `./scripts/local-ci-test.sh <workflow> <scenario-name>`

---

## Timeout Management

### Default Timeouts

| Job Type | Timeout | Variable |
|----------|---------|----------|
| Install Tools | 5 min | `TIMEOUT_INSTALL_TOOLS` |
| Install Dependencies | 10 min | `TIMEOUT_INSTALL_DEPENDENCIES` |
| Compile | 15 min | `TIMEOUT_COMPILE` |
| Lint | 5 min | `TIMEOUT_LINT` |
| Security Scan | 10 min | `TIMEOUT_SECURITY_SCAN` |
| Bundle | 10 min | `TIMEOUT_BUNDLE` |
| Unit Tests | 10 min | `TIMEOUT_UNIT_TESTS` |
| Integration Tests | 20 min | `TIMEOUT_INTEGRATION_TESTS` |
| E2E Tests | 30 min | `TIMEOUT_E2E_TESTS` |
| NPM Publish | 5 min | `TIMEOUT_PUBLISH_NPM` |
| Docker Publish | 15 min | `TIMEOUT_PUBLISH_DOCKER` |

### Overriding Timeouts

```bash
# Override specific timeout
export TIMEOUT_UNIT_TESTS=1200  # 20 minutes

# Run test with custom timeout
TIMEOUT_E2E_TESTS=3600 ./scripts/local-ci-test.sh pre-release
```

### Using Timeouts in Scripts

```bash
# Source timeout config
source "${SCRIPT_DIR}/lib/timeout-config.sh"

# Run command with timeout
run_with_timeout npm test

# Get current script's timeout
timeout=$(get_script_timeout)
echo "Running with ${timeout}s timeout"
```

---

## Integrating with CI Scripts

### Step 1: Source Libraries

Add to the beginning of your CI script:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

# Source libraries
source "${SCRIPT_DIR}/../../lib/mock-framework.sh" 2>/dev/null || true
source "${SCRIPT_DIR}/../../lib/timeout-config.sh" 2>/dev/null || true
```

### Step 2: Add Mock Handler

Check for mock mode before executing real work:

```bash
# Mock handler
if is_mock_mode 2>/dev/null; then
    print_mock_config
    mock_handler "Job Name" || exit $?
    exit 0
fi
```

### Step 3: Add Timeout Wrapper

Wrap long-running commands:

```bash
# Main execution
if command -v run_with_timeout >/dev/null 2>&1; then
    run_with_timeout npm test
else
    npm test
fi
```

### Complete Example

See `scripts/ci/test/ci-01-unit-tests.sh` for a complete integration example.

---

## Examples

### Example 1: Test Happy Path

```bash
# Run pre-release workflow with all jobs succeeding
./scripts/local-ci-test.sh pre-release happy-path
```

Expected output:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Running Workflow: pre-release
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

▶ Running job: setup
✅ Job 'setup' completed successfully (2s)

▶ Running job: compile
✅ Job 'compile' completed successfully (2s)

...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Workflow Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Total Duration: 25s
  Successful Jobs: 8
  Failed Jobs: 0

✅ Workflow completed successfully!
```

### Example 2: Test Specific Failure

```bash
# Test unit tests failing
./scripts/local-ci-test.sh pre-release unit-tests-fail
```

Expected output:
```
...
▶ Running job: unit-tests
❌ Job 'unit-tests' failed with exit code 1 (3s)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Workflow Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Failed Jobs: 1

Failed:
  ❌ unit-tests
```

### Example 3: Test Timeout

```bash
# Test E2E tests getting stuck
./scripts/local-ci-test.sh pre-release e2e-stuck --timeout 90
```

Expected output:
```
▶ Running job: e2e-tests
⏳ E2E Tests is stuck...
Still running... (30s elapsed)
Still running... (60s elapsed)
❌ Job 'e2e-tests' timed out after 90s
```

### Example 4: Run Specific Job Only

```bash
# Test only the lint job with failure
./scripts/local-ci-test.sh pre-release --job lint --state failed
```

### Example 5: Chaos Testing

```bash
# Run with random states
./scripts/local-ci-test.sh pre-release chaos-random
```

### Example 6: Custom Inline Configuration

```bash
# Run with environment variables
MOCK_ENABLED=true \
MOCK_MODE=ok \
MOCK_MODE_LINT=failed \
MOCK_DELAY=3 \
./scripts/local-ci-test.sh pre-release
```

### Example 7: Test Release Workflow

```bash
# Test major release
./scripts/local-ci-test.sh release release-major

# Test publish failure
./scripts/local-ci-test.sh release release-publish-fail
```

### Example 8: Test Maintenance

```bash
# Run all maintenance tasks
./scripts/local-ci-test.sh maintenance maintenance-all
```

---

## Troubleshooting

### Issue: Mock mode not working

**Solution:** Ensure `MOCK_ENABLED=true` is set:

```bash
MOCK_ENABLED=true ./scripts/local-ci-test.sh pre-release
```

### Issue: Timeouts not enforced

**Solution:** Check if `timeout` command is available:

```bash
which timeout
# If not found, install coreutils:
# Ubuntu/Debian: apt-get install coreutils
# macOS: brew install coreutils
```

### Issue: Script not found for job

**Solution:** Update job-to-script mapping in `local-ci-test.sh`:

```bash
get_job_script() {
    case "$job" in
        your-job-name)
            echo "${SCRIPT_DIR}/path/to/script.sh"
            ;;
    esac
}
```

### Issue: Scenario not loading

**Solution:** Check YAML syntax and file location:

```bash
# Verify file exists
ls -la test/scenarios/your-scenario.yml

# Check YAML syntax
cat test/scenarios/your-scenario.yml
```

### Issue: Jobs running in wrong order

**Note:** The test runner executes jobs in the order they appear in the workflow file. Dependencies between jobs are not automatically enforced in local mode.

### Issue: Verbose output not showing

**Solution:** Enable verbose mode:

```bash
./scripts/local-ci-test.sh --verbose pre-release happy-path
```

---

## Advanced Usage

### Testing All Possible States

Create a test matrix script:

```bash
#!/bin/bash
for state in ok failed stuck; do
    echo "Testing with state: $state"
    ./scripts/local-ci-test.sh pre-release --state "$state" --timeout 120
done
```

### Creating CI Test Suite

```bash
#!/bin/bash
# Test all scenarios
scenarios=(
    "happy-path"
    "unit-tests-fail"
    "lint-fail"
    "build-fail"
    "security-fail"
)

for scenario in "${scenarios[@]}"; do
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Testing: $scenario"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    ./scripts/local-ci-test.sh pre-release "$scenario"
done
```

### Parallel Job Testing

```bash
#!/bin/bash
# Test jobs in parallel
jobs=("lint" "compile" "unit-tests")

for job in "${jobs[@]}"; do
    (
        echo "Testing job: $job"
        ./scripts/local-ci-test.sh pre-release --job "$job" --state random
    ) &
done

wait
echo "All parallel tests completed"
```

---

## Best Practices

1. **Test locally before pushing**: Always run relevant scenarios before pushing to GitHub
2. **Use realistic timeouts**: Set timeouts similar to GitHub Actions limits
3. **Create custom scenarios**: Add scenarios for your specific edge cases
4. **Integrate early**: Add mock framework to scripts as you create them
5. **Document scenarios**: Add clear descriptions to scenario files
6. **Version control**: Commit scenarios and test results to your repository
7. **CI/CD integration**: Run local tests as part of pre-commit hooks

---

## Files and Directories

```
ci-excellence/
├── scripts/
│   ├── local-ci-test.sh              # Main test runner
│   ├── lib/
│   │   ├── mock-framework.sh         # Mock state simulation
│   │   └── timeout-config.sh         # Timeout configuration
│   └── ci/                           # CI scripts (mock-enabled)
│
├── test/
│   ├── LOCAL_TESTING.md              # This documentation
│   ├── scenarios/                    # Test scenarios
│   │   ├── happy-path.yml
│   │   ├── unit-tests-fail.yml
│   │   ├── lint-fail.yml
│   │   ├── build-fail.yml
│   │   ├── security-fail.yml
│   │   ├── e2e-stuck.yml
│   │   ├── chaos-random.yml
│   │   ├── release-major.yml
│   │   ├── release-publish-fail.yml
│   │   └── maintenance-all.yml
│   └── examples/                     # Example test scripts
│
└── .ci-test-results/                 # Test execution results (gitignored)
    ├── job-*.log                     # Job execution logs
    └── job-*.json                    # Job metadata
```

---

## Next Steps

1. **Try the quick start examples** to get familiar with the framework
2. **Create custom scenarios** for your specific use cases
3. **Integrate mock framework** into your existing CI scripts
4. **Set up pre-commit hooks** to run tests automatically
5. **Expand test coverage** by adding more scenarios

---

## Support

For issues or questions:

1. Check this documentation
2. Review example scripts in `scripts/ci/test/ci-01-unit-tests.sh`
3. Examine scenario files in `test/scenarios/`
4. Review mock framework source in `scripts/lib/mock-framework.sh`

---

**Happy Testing! 🚀**
