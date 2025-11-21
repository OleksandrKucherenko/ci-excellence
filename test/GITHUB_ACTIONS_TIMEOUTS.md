# GitHub Actions Workflow Timeout Configuration

**Date:** 2025-11-20
**Status:** ✅ Implemented

This document outlines the timeout configurations added to all GitHub Actions workflows, following the [GitHub Actions workflow syntax documentation](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#jobsjob_idstepstimeout-minutes).

---

## Overview

Timeout limits have been added at the **job level** (`timeout-minutes`) for all workflows to prevent jobs from running indefinitely and consuming excessive resources. These timeouts align with the local testing framework timeout configuration defined in `scripts/lib/timeout-config.sh`.

---

## Workflow Timeout Summary

### Pre-Release Pipeline (`pre-release.yml`)

| Job | Timeout | Purpose |
|-----|---------|---------|
| setup | 15 min | Install tools (5min) + dependencies (10min) |
| compile | 15 min | Build/compile project |
| lint | 5 min | Run code linters |
| unit-tests | 10 min | Run unit tests |
| integration-tests | 20 min | Run integration tests |
| e2e-tests | 30 min | Run end-to-end tests |
| security-scan | 10 min | Security vulnerability scanning |
| bundle | 10 min | Create bundles/packages |
| summary | 5 min | Generate pipeline summary |
| notify | 5 min | Send notifications |

**Total maximum runtime:** ~135 minutes (if all jobs run sequentially)

---

### Release Pipeline (`release.yml`)

| Job | Timeout | Purpose |
|-----|---------|---------|
| prepare | 10 min | Version determination, changelog generation |
| build | 20 min | Build release artifacts |
| test | 15 min | Test release build |
| publish-npm | 5 min | Publish to NPM registry |
| publish-github | 5 min | Create GitHub release |
| publish-docker | 15 min | Build and push Docker images |
| publish-documentation | 10 min | Build and publish documentation |
| notify | 5 min | Send release notifications |

**Total maximum runtime:** ~85 minutes (if all jobs run sequentially)

---

### Post-Release Pipeline (`post-release.yml`)

| Job | Timeout | Purpose |
|-----|---------|---------|
| verify-deployment | 10 min | Verify deployments and run smoke tests |
| tag-stable | 5 min | Tag version as stable |
| tag-unstable | 5 min | Tag version as unstable |
| rollback | 10 min | Rollback release operations |
| notify | 5 min | Send post-release notifications |

**Total maximum runtime:** ~35 minutes (jobs are mutually exclusive)

---

### Maintenance Pipeline (`maintenance.yml`)

| Job | Timeout | Purpose |
|-----|---------|---------|
| cleanup | 10 min | Clean old artifacts, workflows, caches |
| sync-files | 5 min | Sync repository files |
| deprecate-old-versions | 5 min | Deprecate old package versions |
| security-audit | 10 min | Run security audits |
| dependency-update | 10 min | Update dependencies |
| notify | 5 min | Send maintenance summary |

**Total maximum runtime:** ~45 minutes (if all jobs run sequentially)

---

## Step-Level Timeouts

In addition to job-level timeouts, critical steps within jobs also have step-level timeouts to provide finer-grained control:

### Pre-Release Pipeline

```yaml
# setup job
- name: Setup environment
  timeout-minutes: 5

- name: Install dependencies
  timeout-minutes: 10

# All main execution steps (compile, lint, tests, etc.)
- name: Run [task]
  timeout-minutes: [appropriate limit]
```

### Summary Steps

```yaml
# summary and notify jobs
- name: Generate summary
  timeout-minutes: 3

- name: Check for failures
  timeout-minutes: 2

- name: Check if notifications enabled
  timeout-minutes: 1

- name: Determine pipeline status
  timeout-minutes: 1

- name: Send notification
  timeout-minutes: 2
```

---

## Timeout Configuration Alignment

The GitHub Actions timeouts align with the local testing framework configuration:

| Component | Configuration File | Applies To |
|-----------|-------------------|------------|
| Local Testing | `scripts/lib/timeout-config.sh` | Local test runner execution |
| GitHub Actions | `.github/workflows/*.yml` | CI/CD pipeline execution |

### Consistency Table

| Task Type | Local Timeout | GHA Job Timeout | GHA Step Timeout |
|-----------|---------------|-----------------|------------------|
| Install Tools | 5 min | 15 min (job) | 5 min (step) |
| Install Dependencies | 10 min | 15 min (job) | 10 min (step) |
| Compile | 15 min | 15 min | 15 min |
| Lint | 5 min | 5 min | 5 min |
| Security Scan | 10 min | 10 min | 10 min |
| Bundle | 10 min | 10 min | 10 min |
| Unit Tests | 10 min | 10 min | 10 min |
| Integration Tests | 20 min | 20 min | 20 min |
| E2E Tests | 30 min | 30 min | 30 min |
| NPM Publish | 5 min | 5 min | - |
| Docker Publish | 15 min | 15 min | - |

---

## Benefits

### 1. **Resource Protection**
- Prevents runaway jobs from consuming GitHub Actions minutes
- Protects against infinite loops or hung processes
- Provides predictable resource usage

### 2. **Fast Failure Detection**
- Quickly identifies stuck or hanging jobs
- Reduces time to detect infrastructure issues
- Enables faster feedback loops

### 3. **Cost Control**
- Limits maximum execution time per workflow
- Prevents unexpected billing from stuck jobs
- Provides budget predictability

### 4. **Debugging Support**
- Timeout failures indicate specific problematic jobs
- Helps identify performance regressions
- Provides clear signals for investigation

### 5. **Consistency**
- Uniform timeout policy across all workflows
- Matches local testing behavior
- Easier to reason about workflow behavior

---

## Timeout Behavior

### When a Timeout Occurs

**Job-Level Timeout:**
```yaml
jobs:
  compile:
    timeout-minutes: 15  # Job must complete within 15 minutes
```
- GitHub Actions cancels the entire job
- Job status: `cancelled`
- Exit code: `143` (SIGTERM)
- All steps in the job are terminated

**Step-Level Timeout:**
```yaml
steps:
  - name: Run tests
    timeout-minutes: 10  # Step must complete within 10 minutes
```
- GitHub Actions cancels only that step
- Step status: `cancelled`
- Subsequent steps may still run (depending on `if` conditions)

### Handling Timeouts

**Always block:**
```yaml
- name: Upload results
  if: always()  # Runs even if previous steps timeout
```

**Cleanup operations:**
```yaml
- name: Cleanup resources
  if: cancelled()  # Runs only if job was cancelled (including timeout)
```

---

## Monitoring and Adjusting Timeouts

### Signs a Timeout is Too Short

1. **Frequent timeout failures** in successful workflows
2. **Timeout occurs** during normal operation (not hung state)
3. **Job completes successfully** when re-run without changes

### Signs a Timeout is Too Long

1. **Jobs rarely finish** near the timeout limit
2. **Typical execution time** is much shorter than timeout
3. **Hung jobs** take full timeout to fail

### Adjustment Process

1. **Monitor workflow run times** over multiple executions
2. **Identify P95/P99** execution times
3. **Set timeout** to P99 + 50% buffer
4. **Test** with various scenarios

Example:
```
P99 execution time: 8 minutes
Buffer (50%): 4 minutes
Total timeout: 12 minutes → Round to 15 minutes
```

---

## Override Timeouts

### Repository Level

GitHub Actions allows repository-level timeout defaults:
- **Settings → Actions → General → Workflow permissions**
- Default: 360 minutes (6 hours)
- Can be reduced for tighter control

### Workflow Level

Set a maximum timeout for the entire workflow:
```yaml
name: Pre-Release Pipeline

on:
  pull_request:
    branches: [main]

# Maximum time for entire workflow
timeout-minutes: 60

jobs:
  # Individual job timeouts...
```

### Job Level (Current Implementation)

Set timeout for each job:
```yaml
jobs:
  compile:
    timeout-minutes: 15
```

### Step Level (Current Implementation)

Set timeout for critical steps:
```yaml
steps:
  - name: Run tests
    timeout-minutes: 10
```

---

## Testing Timeout Configuration

Use the local CI testing framework to test timeout behavior:

### Test Job Timeout

```bash
# Simulate stuck job with 90s timeout
./scripts/local-ci-test.sh pre-release e2e-stuck --timeout 90
```

### Test Specific Job States

```bash
# Test unit tests timing out
MOCK_ENABLED=true \
MOCK_MODE_UNIT_TESTS=stuck \
MOCK_STUCK_DURATION=300 \
./scripts/local-ci-test.sh pre-release --job unit-tests --timeout 120
```

### Validate Timeout Configuration

```bash
# Run all scenarios to validate timeouts
./test/examples/test-timeout-scenarios.sh
```

---

## Implementation Details

### Files Modified

1. `.github/workflows/pre-release.yml`
   - 10 jobs with timeouts
   - 15+ steps with timeouts

2. `.github/workflows/release.yml`
   - 8 jobs with timeouts

3. `.github/workflows/post-release.yml`
   - 5 jobs with timeouts

4. `.github/workflows/maintenance.yml`
   - 6 jobs with timeouts

**Total:** 4 workflows, 29 jobs with timeouts configured

### Syntax Reference

GitHub Actions timeout syntax:
```yaml
jobs:
  job-name:
    runs-on: ubuntu-latest
    timeout-minutes: 15  # Job-level timeout
    steps:
      - name: Step name
        timeout-minutes: 10  # Step-level timeout
        run: command
```

Documentation: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#jobsjob_idstepstimeout-minutes

---

## Troubleshooting

### Issue: Job times out unexpectedly

**Diagnosis:**
```bash
# Check average execution time
gh run list --workflow=pre-release.yml --limit=10 --json conclusion,durationMs

# Check specific job duration
gh run view <run-id> --log
```

**Solution:**
- Increase timeout if legitimate workload
- Investigate hung processes if consistently timing out
- Check for external service dependencies

### Issue: Step timeout vs. job timeout conflict

**Problem:** Step timeout is longer than job timeout
```yaml
jobs:
  test:
    timeout-minutes: 10  # Job timeout
    steps:
      - name: Run tests
        timeout-minutes: 15  # ❌ This will never be reached
```

**Solution:** Ensure step timeouts are less than job timeout
```yaml
jobs:
  test:
    timeout-minutes: 15  # Job timeout
    steps:
      - name: Run tests
        timeout-minutes: 10  # ✅ Step timeout < job timeout
```

### Issue: Timeout doesn't account for setup time

**Problem:** Job times out during setup, not main task
```yaml
jobs:
  test:
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@v4  # 1 min
      - name: Setup  # 8 min
      - name: Run tests  # Times out!
```

**Solution:** Account for all step time in job timeout
```yaml
jobs:
  test:
    timeout-minutes: 15  # Checkout (1m) + Setup (8m) + Tests (5m) + buffer
```

---

## Future Enhancements

### Potential Improvements

1. **Dynamic Timeouts**
   - Adjust based on historical execution times
   - Use GitHub API to monitor and tune

2. **Workflow-Level Timeouts**
   - Set maximum time for entire workflow
   - Prevent cascade failures

3. **Timeout Alerting**
   - Notify on repeated timeouts
   - Track timeout trends

4. **Adaptive Timeouts**
   - Increase timeout for retries
   - Shorter timeout for canary runs

5. **Per-Branch Timeouts**
   - Longer timeouts for main branch
   - Shorter timeouts for feature branches

---

## Summary

✅ **All workflows** now have timeout configuration
✅ **29 jobs** with job-level timeouts
✅ **15+ critical steps** with step-level timeouts
✅ **Aligned** with local testing framework
✅ **Documented** timeout strategy and best practices
✅ **Testable** via local CI testing framework

**Benefits:**
- Resource protection and cost control
- Fast failure detection
- Consistent behavior across workflows
- Production-ready timeout configuration

---

**See Also:**
- [Local Testing Documentation](../test/LOCAL_TESTING.md)
- [Timeout Configuration Library](../scripts/lib/timeout-config.sh)
- [GitHub Actions Workflow Syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax)
