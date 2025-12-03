# BATS Gotchas & DevOps Tricks
## Advanced Patterns from Official Documentation

**Extracted from**: Official bats-core documentation  
**Focus**: Production pitfalls, edge cases, and battle-tested solutions

---

## Table of Contents

1. [Critical Gotchas](#critical-gotchas)
2. [Advanced Execution Patterns](#advanced-execution-patterns)
3. [Performance Optimization](#performance-optimization)
4. [Security Considerations](#security-considerations)
5. [DevOps Integration Tricks](#devops-integration-tricks)
6. [Debugging Techniques](#debugging-techniques)
7. [Production Antipatterns](#production-antipatterns)

---

## Critical Gotchas

### 1. File Evaluation Happens n+1 Times

**The Problem**: Every `.bats` file is evaluated multiple times:
- First pass: Counts test cases
- Subsequent passes: Runs each test

**Real-World Impact**:
```bash
# This code runs 11 times for 10 tests!
echo "Connecting to database..."
DB_CONN=$(expensive_db_connection)

@test "test 1" { }
@test "test 2" { }
# ... 8 more tests
```

**Solution**: Move expensive code into hooks:
```bash
setup_file() {
    # Runs only once
    export DB_CONN=$(expensive_db_connection)
}

@test "test 1" { use $DB_CONN }
```

**DevOps Trick**: If you see tests taking unexpectedly long, check for code outside functions.

---

### 2. Bash's `-e` Option and Negation

**The Problem**: Bash deliberately excludes negated commands from `set -e`.

```bash
@test "negation gotcha" {
    ! true  # Test PASSES (should fail!)
}
```

**Why**: Historic Bash behavior for pipeline compatibility.

**Solutions**:
```bash
# Option 1: Use run ! (BATS 1.5+)
@test "correct way" {
    run ! true
    # Now correctly fails
}

# Option 2: Explicit false
@test "force failure" {
    ! true || false
}

# Option 3: Status check
@test "check status" {
    run true
    [ "$status" -ne 0 ]
}
```

**DevOps Trick**: In CI pipelines, always use `run !` for negations to avoid silent failures.

---

### 3. File Descriptor Inheritance

**The Problem**: Background tasks inherit file descriptors, preventing test termination.

```bash
@test "hangs forever" {
    long_running_process &
    # Test never completes!
}
```

**Why**: Background process holds FD 3 (BATS internal communication).

**Solutions**:
```bash
# Solution 1: Close FD 3 explicitly
@test "fix with close" {
    long_running_process 3>&- &
    disown
}

# Solution 2: Use BATS helper
@test "fix with helper" {
    source test/fixtures/bats/issue-205.bats
    long_running_process &
    close_non_std_fds
}

# Solution 3: Trap cleanup
@test "fix with trap" {
    long_running_process &
    PID=$!
    trap "kill $PID 2>/dev/null" EXIT
}
```

**DevOps Trick**: Always close FD 3 when spawning background processes in tests.

---

### 4. Pipe Parsing Priority

**The Problem**: Bash parses pipes before function calls.

```bash
@test "pipe gotcha" {
    run echo "test" | grep "test"
    # Actually executes: (run echo "test") | grep "test"
    # The grep runs OUTSIDE run!
}
```

**Why**: Operator precedence in Bash.

**Solutions**:
```bash
# Solution 1: bats_pipe helper
@test "use bats_pipe" {
    run bats_pipe echo "test" \| grep "test"
    # Note: \| not |
}

# Solution 2: bash -c wrapper
@test "use bash -c" {
    run bash -c "echo 'test' | grep 'test'"
}

# Solution 3: Function wrapper
my_pipeline() {
    echo "test" | grep "test"
}

@test "use function" {
    run my_pipeline
}
```

**DevOps Trick**: In CI scripts, wrap pipelines in functions for better testability.

---

### 5. Subshell Variable Isolation

**The Problem**: `run` executes in a subshell.

```bash
@test "variable lost" {
    run export MY_VAR="value"
    echo "$MY_VAR"  # Empty!
    
    run cd /tmp
    pwd  # Still in original directory!
}
```

**Why**: Subshell changes don't propagate to parent shell.

**Solutions**:
```bash
# Solution 1: Don't use run for state changes
@test "direct execution" {
    export MY_VAR="value"
    echo "$MY_VAR"  # Works
}

# Solution 2: Test the side effect differently
@test "test export behavior" {
    run bash -c 'export MY_VAR="value"; echo $MY_VAR'
    assert_output "value"
}
```

**DevOps Trick**: When testing stateful operations, don't use `run` - test the side effects instead.

---

### 6. Test Registration in Loops

**The Problem**: Can't generate tests dynamically.

```bash
# This doesn't work!
for value in 1 2 3; do
    @test "test $value" {
        run process "$value"
    }
done
```

**Why**: `@test` is preprocessed into functions; loops just redefine the same function.

**Workarounds**:
```bash
# Workaround 1: Loop inside test
@test "process multiple values" {
    for value in 1 2 3; do
        run process "$value"
        assert_success
    done
}

# Workaround 2: Use environment variables
# test.sh wrapper:
#!/bin/bash
for value in 1 2 3; do
    TEST_VALUE=$value bats test/parameterized.bats
done

# test/parameterized.bats:
@test "process value" {
    run process "$TEST_VALUE"
}
```

**DevOps Trick**: For matrix testing, use CI matrix features rather than BATS loops:

```yaml
# .github/workflows/test.yml
strategy:
  matrix:
    value: [1, 2, 3]
steps:
  - run: TEST_VALUE=${{ matrix.value }} bats test/
```

---

## Advanced Execution Patterns

### 1. Conditional Test Execution

**Pattern**: Skip tests based on environment.

```bash
setup() {
    # Skip all tests in file if condition not met
    if ! command -v docker; then
        skip "Docker not available"
    fi
}

@test "docker operation" {
    run docker ps
    assert_success
}
```

**DevOps Trick**: Use this for environment-specific test suites:
```bash
setup() {
    case "$ENV" in
        prod)
            skip "Destructive test - not running in prod"
            ;;
        staging)
            [ -f .staging-approved ] || skip "Staging tests not approved"
            ;;
    esac
}
```

---

### 2. Test Timeout Management

**Pattern**: Prevent hanging tests.

```bash
# Set globally
export BATS_TEST_TIMEOUT=30

# Or in setup_file
setup_file() {
    export BATS_TEST_TIMEOUT=60
}

# Or per-test
@test "long operation" {
    BATS_TEST_TIMEOUT=120 run long_process
}
```

**DevOps Trick**: Set aggressive timeouts in CI, relaxed locally:
```bash
setup_file() {
    if [ -n "$CI" ]; then
        export BATS_TEST_TIMEOUT=30
    else
        export BATS_TEST_TIMEOUT=300
    fi
}
```

---

### 3. Parallel Execution Gotchas

**Problem**: Tests interfere when run in parallel.

```bash
# BAD - Shared state
@test "test A" {
    echo "data" > /tmp/shared_file
    run process /tmp/shared_file
}

@test "test B" {
    echo "data" > /tmp/shared_file  # Race condition!
}
```

**Solution**: Use test-specific temp dirs.

```bash
# GOOD - Isolated
@test "test A" {
    echo "data" > "$BATS_TEST_TMPDIR/file"
    run process "$BATS_TEST_TMPDIR/file"
}
```

**DevOps Trick**: Test parallelization locally before CI:
```bash
# Run multiple times to expose race conditions
for i in {1..10}; do
    bats --jobs 8 test/ || break
done
```

---

### 4. Test Status Filtering

**Pattern**: Re-run only failed tests.

```bash
# First run - some tests fail
bats test/

# Re-run only failures
bats --filter-status failed test/

# CI trick: Fail fast, then retry failures
bats --jobs 4 test/ || bats --filter-status failed test/
```

**DevOps Trick**: Implement "flaky test" detection:
```bash
#!/bin/bash
# run-until-failure.sh
for i in {1..20}; do
    echo "Attempt $i"
    bats test/ || break
done
```

---

## Performance Optimization

### 1. Smart Use of Lifecycle Hooks

**Analogy**: Think of test lifecycle like a restaurant:
- `setup_file`: Opening restaurant (once per day)
- `setup`: Setting table (per customer)
- Test: Serving meal (per dish)
- `teardown`: Clearing table (per customer)
- `teardown_file`: Closing restaurant (once per day)

**Optimization Pattern**:
```bash
# SLOW - Compiles 10 times
@test "test 1" {
    compile_project
    run ./binary arg1
}
@test "test 2" {
    compile_project  # Wasteful!
    run ./binary arg2
}

# FAST - Compiles once
setup_file() {
    compile_project
}

@test "test 1" {
    run ./binary arg1
}
@test "test 2" {
    run ./binary arg2
}
```

**DevOps Trick**: Profile setup time:
```bash
setup_file() {
    local start=$(date +%s)
    expensive_operation
    local end=$(date +%s)
    echo "Setup took $((end - start))s" >&3
}
```

---

### 2. Caching Between Tests

**Pattern**: Cache compiled artifacts.

```bash
setup_file() {
    # Cache directory persists between runs
    CACHE_DIR="$HOME/.cache/test-artifacts"
    mkdir -p "$CACHE_DIR"
    
    # Only compile if not cached
    if [ ! -f "$CACHE_DIR/binary-$(git rev-parse HEAD)" ]; then
        compile_project
        cp binary "$CACHE_DIR/binary-$(git rev-parse HEAD)"
    fi
    
    export BINARY="$CACHE_DIR/binary-$(git rev-parse HEAD)"
}
```

**DevOps Trick**: Use CI cache:
```yaml
# GitHub Actions
- uses: actions/cache@v3
  with:
    path: ~/.cache/test-artifacts
    key: test-cache-${{ hashFiles('src/**') }}
```

---

### 3. Parallel File Processing

**Pattern**: Use GNU parallel for data processing.

```bash
@test "process many files" {
    # Generate test files
    for i in {1..100}; do
        echo "data$i" > "$BATS_TEST_TMPDIR/file$i"
    done
    
    # Process in parallel
    run parallel process_file ::: "$BATS_TEST_TMPDIR"/file*
    
    assert_success
}
```

**DevOps Trick**: Combine with BATS parallelization:
```bash
# Parallel tests + parallel data processing
bats --jobs 4 test/  # BATS level
# Each test uses parallel internally
```

---

## Security Considerations

### 1. Temp Directory Security

**Problem**: Predictable temp paths are security risks.

```bash
# BAD - Predictable
TEST_DIR="/tmp/my_test"
mkdir "$TEST_DIR"

# GOOD - Random
TEST_DIR="$(mktemp -d)"
```

**DevOps Trick**: Always use BATS-provided temp dirs:
```bash
@test "secure temp" {
    # $BATS_TEST_TMPDIR is:
    # - Unique per test
    # - Properly permissioned
    # - Automatically cleaned
    echo "secret" > "$BATS_TEST_TMPDIR/credentials"
}
```

---

### 2. Secret Handling in Tests

**Pattern**: Never hardcode secrets.

```bash
# BAD
@test "api call" {
    run curl -H "Authorization: Bearer secret123" api.example.com
}

# GOOD
@test "api call" {
    [ -n "$API_TOKEN" ] || skip "API_TOKEN not set"
    run curl -H "Authorization: Bearer $API_TOKEN" api.example.com
}
```

**DevOps Trick**: Fail tests if secrets are committed:
```bash
setup_file() {
    if git grep -q "BEGIN RSA PRIVATE KEY" src/; then
        echo "ERROR: Private key found in source!"
        return 1
    fi
}
```

---

### 3. Privilege Escalation Tests

**Pattern**: Separate sudo tests.

```bash
# test/sudo/privileged.bats
@test "requires root" {
    [ "$EUID" -eq 0 ] || skip "Requires root"
    run iptables -L
    assert_success
}

# Run separately
sudo bats test/sudo/
```

**DevOps Trick**: Use Docker for privilege tests:
```bash
@test "test as root" {
    run docker run --rm -v "$(pwd):/code" ubuntu:22.04 \
        bash -c "cd /code && ./script.sh"
    assert_success
}
```

---

## DevOps Integration Tricks

### 1. Dynamic Test Discovery

**Pattern**: Generate test list for CI matrix.

```bash
#!/bin/bash
# discover-tests.sh
bats --count test/ | while read -r file; do
    count=$(bats --count "$file")
    echo "$file:$count"
done
```

**CI Integration**:
```yaml
# Generate matrix
- id: discover
  run: |
    echo "::set-output name=matrix::$(./discover-tests.sh | jq -R . | jq -s .)"

strategy:
  matrix:
    test: ${{ fromJson(steps.discover.outputs.matrix) }}
```

---

### 2. Flaky Test Detection

**Pattern**: Identify non-deterministic tests.

```bash
#!/bin/bash
# detect-flaky.sh
RUNS=20
declare -A failures

for i in $(seq 1 $RUNS); do
    bats --formatter tap test/ | grep "^not ok" | while read -r line; do
        test_name=$(echo "$line" | sed 's/^not ok [0-9]* //')
        ((failures["$test_name"]++))
    done
done

for test in "${!failures[@]}"; do
    rate=$((failures[$test] * 100 / RUNS))
    if [ $rate -gt 0 ] && [ $rate -lt 100 ]; then
        echo "FLAKY: $test ($rate% failure rate)"
    fi
done
```

---

### 3. Test Quarantine System

**Pattern**: Isolate problematic tests.

```bash
# Mark flaky tests
# bats test_tags=quarantine
@test "sometimes fails" {
    run flaky_operation
}

# Don't run in CI
bats --filter-tags '!quarantine' test/

# Run separately for investigation
bats --filter-tags quarantine test/
```

---

### 4. Coverage-Aware Testing

**Pattern**: Fail CI if coverage drops.

```bash
#!/bin/bash
# check-coverage.sh
kcov --include-path=src/ coverage/ bats test/

COVERAGE=$(grep -oP 'covered":"\K[0-9.]+' coverage/index.json)
THRESHOLD=80

if (( $(echo "$COVERAGE < $THRESHOLD" | bc -l) )); then
    echo "Coverage $COVERAGE% below threshold $THRESHOLD%"
    exit 1
fi
```

---

## Debugging Techniques

### 1. Verbose Output Control

**Pattern**: Toggle debug output.

```bash
debug() {
    [ -n "$DEBUG" ] && echo "DEBUG: $*" >&3
}

@test "with debugging" {
    debug "Starting test"
    run my_command
    debug "Status: $status"
    debug "Output: $output"
    assert_success
}

# Run with debugging
DEBUG=1 bats test/
```

---

### 2. Test Isolation Verification

**Pattern**: Ensure tests are truly isolated.

```bash
# Add canary test
@test "AAA_canary_isolation_check" {
    # First test sets state
    export CANARY="set"
    echo "canary" > /tmp/canary
}

@test "ZZZ_verify_no_leakage" {
    # Last test checks isolation
    [ -z "$CANARY" ] || fail "Environment leaked!"
    [ ! -f /tmp/canary ] || fail "Filesystem leaked!"
}
```

---

### 3. Binary Diffing for Assertions

**Pattern**: Compare output against golden files.

```bash
@test "output matches golden" {
    run my_command
    
    # Save output
    echo "$output" > "$BATS_TEST_TMPDIR/actual"
    
    # Compare with golden
    if ! diff -u \
        "$BATS_TEST_DIRNAME/fixtures/golden.txt" \
        "$BATS_TEST_TMPDIR/actual" > "$BATS_TEST_TMPDIR/diff"; then
        
        cat "$BATS_TEST_TMPDIR/diff" >&3
        fail "Output differs from golden file"
    fi
}
```

---

## Production Antipatterns

### ❌ Antipattern 1: Testing Implementation Details

```bash
# BAD - Tests internal function
@test "tests private function" {
    run _internal_parse_helper "data"
}

# GOOD - Tests public API
@test "tests public interface" {
    run my_script --parse "data"
}
```

---

### ❌ Antipattern 2: Brittle Assertions

```bash
# BAD - Exact match breaks with minor changes
@test "brittle" {
    run my_script
    assert_output "Processing file1.txt\nProcessing file2.txt\nDone"
}

# GOOD - Flexible assertions
@test "flexible" {
    run my_script
    assert_line --partial "Processing file1"
    assert_line --partial "Processing file2"
    assert_line --partial "Done"
}
```

---

### ❌ Antipattern 3: Test Data Pollution

```bash
# BAD - Modifies source tree
@test "bad" {
    echo "test" > src/data.txt
}

# GOOD - Uses temp directory
@test "good" {
    cp -r src "$BATS_TEST_TMPDIR/"
    echo "test" > "$BATS_TEST_TMPDIR/src/data.txt"
}
```

---

### ❌ Antipattern 4: Over-Mocking

```bash
# BAD - Mocks everything, tests nothing
@test "over-mocked" {
    stub curl ': echo "{}"'
    stub jq ': echo "value"'
    stub awk ': echo "result"'
    stub grep ': echo "found"'
    
    run my_script  # What are we even testing?
}

# GOOD - Mocks only external dependencies
@test "appropriate mocking" {
    stub curl ': cat test/fixtures/api-response.json'
    
    run my_script
    # Real jq, awk, grep process the response
}
```

---

## Summary: Production Checklist

Before deploying BATS tests to production CI:

- [ ] All tests use `$BATS_TEST_TMPDIR`
- [ ] No hardcoded secrets in tests
- [ ] Timeout set for all tests
- [ ] Parallel execution tested locally
- [ ] No background tasks without FD cleanup
- [ ] All pipes use `bats_pipe` or wrappers
- [ ] Negations use `run !` syntax
- [ ] Coverage threshold enforced
- [ ] Flaky tests identified and quarantined
- [ ] Test execution time monitored
- [ ] CI caching configured
- [ ] JUnit reports generated
- [ ] Failed tests are re-runnable
- [ ] Tests work on clean checkout
- [ ] No dependencies on execution order

---

## Final DevOps Wisdom

**Analogy**: Think of your BATS test suite like **infrastructure code**:
- Version controlled (submodules)
- Reproducible (hermetic builds)
- Fast (parallel execution)
- Reliable (no flaky tests)
- Maintainable (clear assertions)
- Secure (no secrets)

**Key Principle**: If a test fails in CI but passes locally, it's the *test* that's broken, not the code.

---

**Document Focus**: Production-ready patterns from official documentation  
**Last Updated**: November 2025  
**Maintainer**: bats-core organization
