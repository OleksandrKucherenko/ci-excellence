# BATS Official Documentation - Consolidated Guide
## Complete Reference for Bash Automated Testing System

**Compiled from**: Official bats-core documentation (GitHub & ReadTheDocs)  
**Version**: Based on bats-core master branch (November 2025)  
**Target Audience**: IT professionals with 25+ years experience, focusing on practical DevOps implementation

---

## Table of Contents

1. [Core Concepts](#core-concepts)
2. [Installation & Setup](#installation--setup)
3. [Writing Tests - Complete Guide](#writing-tests---complete-guide)
4. [Usage & Command Line Options](#usage--command-line-options)
5. [Gotchas & Common Pitfalls](#gotchas--common-pitfalls)
6. [FAQ - Frequently Asked Questions](#faq---frequently-asked-questions)
7. [Docker Usage](#docker-usage)
8. [Advanced Patterns](#advanced-patterns)
9. [CI/CD Integration](#cicd-integration)
10. [DevOps Best Practices](#devops-best-practices)

---

## Core Concepts

### What is BATS?

**Analogy**: Think of BATS as **JUnit for Bash** - it brings structured, repeatable testing to shell scripts the same way JUnit did for Java.

BATS (Bash Automated Testing System) is a TAP-compliant testing framework for Bash 3.2+. It provides:

- **Test Anything Protocol (TAP)** compliance for CI/CD integration
- **Isolated test execution** with setup/teardown hooks
- **Simple syntax** that reads like natural language
- **Parallel execution** support for faster test runs
- **Rich assertion libraries** for common testing patterns

### Execution Model

**Critical Understanding**: Each `.bats` file is evaluated **n+1 times**:

1. **First pass**: Counts the number of test cases
2. **Subsequent passes**: Executes each test in its own isolated process

```bash
# This means:
# - Global code runs n+1 times
# - Each @test runs exactly once in isolation
# - Tests cannot share state unless explicitly designed to
```

**Analogy**: Like a chef preparing multiple dishes - the kitchen setup (counting ingredients) happens once, then each dish is cooked in its own clean pan (isolated process).

---

## Installation & Setup

### Recommended: Git Submodules (Vendoring)

**Why**: Ensures hermetic builds - your CI uses the exact BATS version you've tested locally.

```bash
# Project structure
project/
├── src/
│   └── my_script.sh
├── test/
│   ├── bats/                    # bats-core engine
│   ├── test_helper/
│   │   ├── bats-support/        # Output formatting
│   │   ├── bats-assert/         # Assertions
│   │   ├── bats-file/           # Filesystem assertions
│   │   └── common-setup.bash    # Shared setup logic
│   └── my_script.bats
└── .gitmodules

# Initialize submodules
git submodule add https://github.com/bats-core/bats-core.git test/bats
git submodule add https://github.com/bats-core/bats-support.git test/test_helper/bats-support
git submodule add https://github.com/bats-core/bats-assert.git test/test_helper/bats-assert
git submodule add https://github.com/bats-core/bats-file.git test/test_helper/bats-file

# Run tests
./test/bats/bin/bats test/
```

**Pros**:
- ✅ Version control for test framework
- ✅ No root access required
- ✅ Works on any POSIX system
- ✅ Reproducible CI builds

**Cons**:
- ❌ Requires Git submodule understanding
- ❌ Slightly more complex initial setup
- ❌ Must remember `git submodule update --init --recursive`

### Alternative: System Installation

```bash
# Homebrew (macOS)
brew install bats-core

# NPM (Cross-platform)
npm install -g bats

# APT (Debian/Ubuntu)
sudo apt-get install bats

# From source
git clone https://github.com/bats-core/bats-core.git
cd bats-core
sudo ./install.sh /usr/local
```

---

## Writing Tests - Complete Guide

### Basic Test Structure

```bash
#!/usr/bin/env bats

# Test files use @test annotation
@test "addition using bc" {
    result="$(echo 2+2 | bc)"
    [ "$result" -eq 4 ]
}

# Alternative: Bash-compliant syntax for linting
function test_addition_using_bc { #@test
    result="$(echo 2+2 | bc)"
    [ "$result" -eq 4 ]
}
```

**Key Point**: Each line is an implicit assertion. If any command returns non-zero, the test fails (due to `set -e`).

### The `run` Helper - Your Most Important Tool

```bash
@test "demonstrates run helper" {
    # run captures exit status and output
    run echo "hello world"
    
    # Available variables after run:
    echo "$status"              # Exit code (e.g., 0)
    echo "$output"              # Combined stdout+stderr
    echo "${lines[0]}"          # First line of output
    echo "${lines[@]}"          # All lines as array
    echo "$BATS_RUN_COMMAND"    # The command that was executed
}
```

**Critical Gotcha**: `run` always returns 0 to BATS, regardless of the command's exit status. You must explicitly check `$status`:

```bash
# WRONG - Test always passes
@test "bad example" {
    run false  # This doesn't fail the test!
}

# RIGHT - Explicit check
@test "good example" {
    run false
    [ "$status" -ne 0 ]  # Now it correctly fails
}

# BETTER - Use assertions
@test "best example" {
    load 'test_helper/bats-assert/load'
    run false
    assert_failure
}
```

### Implicit Exit Status Checks

BATS 1.5.0+ supports implicit status checks:

```bash
# Expect specific exit code
run -1 foo nonexistent_file
# Equivalent to: run foo ... && [ "$status" -eq 1 ]

# Expect non-zero exit
run ! foo
# Equivalent to: run foo ... && [ "$status" -ne 0 ]

# Expect any specific code (0-255)
run -127 missing_command
```

### Separating stdout and stderr

```bash
@test "separate output streams" {
    run --separate-stderr my_command
    
    # Now available:
    echo "$output"              # stdout only
    echo "$stderr"              # stderr only
    echo "${lines[@]}"          # stdout lines
    echo "${stderr_lines[@]}"   # stderr lines
}
```

### Setup and Teardown Lifecycle

```bash
# Runs ONCE before ALL tests in the file
setup_file() {
    export SHARED_RESOURCE="initialized"
    # Use for expensive operations:
    # - Starting Docker containers
    # - Compiling binaries
    # - Database initialization
}

# Runs BEFORE EACH test
setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'
    
    # Create test-specific temp directory
    TEST_TMPDIR="$(mktemp -d)"
    
    # Add scripts to PATH
    export PATH="$BATS_TEST_DIRNAME/../src:$PATH"
}

# Runs AFTER EACH test (even if test fails)
teardown() {
    rm -rf "$TEST_TMPDIR"
}

# Runs ONCE after ALL tests in the file
teardown_file() {
    # Cleanup shared resources
    docker stop "$TEST_CONTAINER" 2>/dev/null || true
}
```

**Performance Analogy**: 
- `setup_file` = Opening a restaurant once in the morning
- `setup` = Setting each table before a customer arrives
- `teardown` = Clearing each table after the meal
- `teardown_file` = Closing the restaurant at night

### Loading Libraries and Helpers

```bash
# load is BATS-specific - resolves relative to test file
load 'test_helper/bats-assert/load'

# source is standard Bash - use for .sh files
source "${BATS_TEST_DIRNAME}/../lib/utils.sh"

# Common pattern: Centralized setup
# test_helper/common-setup.bash
_common_setup() {
    export BATS_LIB_PATH="${BATS_TEST_DIRNAME}/test_helper"
    load "$BATS_LIB_PATH/bats-support/load"
    load "$BATS_LIB_PATH/bats-assert/load"
    load "$BATS_LIB_PATH/bats-file/load"
    
    # Add source directory to PATH
    PROJECT_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
    export PATH="$PROJECT_ROOT/src:$PATH"
}

# In test files:
setup() {
    load 'test_helper/common-setup'
    _common_setup
}
```

**⚠️ WARNING**: Avoid loading outside functions - errors in "free code" have terrible diagnostics.

### Working with Temporary Directories

BATS provides several temporary directory variables:

| Variable | Scope | Cleanup |
|----------|-------|---------|
| `$BATS_TMPDIR` | Base temp directory (usually `/tmp`) | Manual |
| `$BATS_RUN_TMPDIR` | Current BATS execution (PID-based) | Automatic |
| `$BATS_FILE_TMPDIR` | Shared across all tests in file | After file |
| `$BATS_TEST_TMPDIR` | Unique per test | After test |

```bash
@test "use test-specific temp directory" {
    # Always prefer $BATS_TEST_TMPDIR for test isolation
    echo "test data" > "$BATS_TEST_TMPDIR/file.txt"
    
    run cat "$BATS_TEST_TMPDIR/file.txt"
    assert_output "test data"
    
    # No cleanup needed - automatically removed
}
```

**Best Practice**: Always use `$BATS_TEST_TMPDIR` for parallel-safe tests.

---

## Usage & Command Line Options

### Basic Invocation

```bash
# Run single file
bats test/my_test.bats

# Run all files in directory (non-recursive)
bats test/

# Recursive search for .bats files
bats -r test/

# Run multiple specific files
bats test/unit/*.bats test/integration/*.bats
```

### Output Formats

```bash
# Pretty output (default for terminal)
bats test/

# TAP output (default for non-terminal/CI)
bats --formatter tap test/

# TAP13 format (extended TAP)
bats --formatter tap13 test/

# JUnit XML (for CI integration)
bats --formatter junit --output ./reports test/

# Custom formatter
bats --formatter /path/to/custom-formatter test/
```

### Filtering Tests

#### By Name (Regex)

```bash
# Run tests matching pattern
bats --filter "auth" test/

# Run tests matching exact name
bats --filter "^login successfully$" test/

# Exclude tests
bats --filter "test" --filter "!slow" test/
```

#### By Tags

```bash
# Tag tests in source
# bats test_tags=api,smoke
@test "user login via API" {
    # test code
}

# Run tests with all specified tags (AND)
bats --filter-tags api,smoke test/

# Run tests with tag but not another (NOT)
bats --filter-tags api,!slow test/

# Run tests matching any tag group (OR)
bats --filter-tags api,smoke --filter-tags integration test/
```

#### By Previous Status

```bash
# Run only tests that failed last time
bats --filter-status failed test/

# Run tests not present in last run
bats --filter-status missed test/
```

#### Focus Mode

```bash
# Focus on specific test during debugging
# bats test_tags=bats:focus
@test "debug this specific test" {
    # Only this test runs
}

# ⚠️ WARNING: Focus mode exits with status 1 even on success
# Override for git bisect:
BATS_NO_FAIL_FOCUS_RUN=1 bats test/
```

### Parallel Execution

```bash
# Run tests in parallel (requires GNU parallel)
bats --jobs 4 test/

# Auto-detect CPU count
bats --jobs $(nproc) test/

# Parallel within files, sequential across files
bats --jobs 4 --no-parallelize-across-files test/
```

**⚠️ WARNING**: Parallelization can expose hidden test dependencies. Run multiple times to identify race conditions.

### Timing and Performance

```bash
# Show test execution times
bats --timing test/

# Set timeout for all tests
BATS_TEST_TIMEOUT=60 bats test/

# Or in test file:
setup_file() {
    export BATS_TEST_TIMEOUT=30
}
```

### Counting Tests

```bash
# Count tests without running
bats --count test/

# Useful for CI validation
test_count=$(bats --count test/)
echo "Discovered $test_count tests"
```

### Version Requirements

```bash
# Require minimum BATS version in test file
bats_require_minimum_version 1.5.0

@test "uses features from BATS 1.5.0+" {
    run -1 failing_command
    assert_failure
}
```

---

## Gotchas & Common Pitfalls

### 1. Negation Doesn't Fail Tests

**Problem**:
```bash
@test "negation bug" {
    ! true  # This doesn't fail the test!
}
```

**Why**: Bash's `-e` option deliberately excludes negated commands from causing pipeline failure.

**Solutions**:
```bash
# Solution 1: Use run ! (BATS 1.5.0+)
@test "correct negation" {
    run ! true
}

# Solution 2: Explicit failure
@test "correct negation alternative" {
    ! true || false
}

# Solution 3: Check status
@test "check status" {
    run true
    [ "$status" -ne 0 ]
}
```

### 2. Pipes Don't Work with `run`

**Problem**:
```bash
@test "pipe bug" {
    run echo "test" | grep "test"  # grep runs outside run!
}
```

**Why**: Bash parses `|` before function calls, so it reads as `(run echo "test") | grep "test"`.

**Solutions**:
```bash
# Solution 1: Use bats_pipe
@test "correct pipe" {
    run bats_pipe echo "test" \| grep "test"
}

# Solution 2: Bash -c wrapper
@test "bash wrapper" {
    run bash -c "echo 'test' | grep 'test'"
}

# Solution 3: Helper function
my_piped_command() {
    echo "test" | grep "test"
}

@test "function wrapper" {
    run my_piped_command
}
```

### 3. run Always Succeeds

**Problem**:
```bash
@test "run always passes" {
    run false  # Test passes!
}
```

**Solution**: Always check `$status` explicitly or use assertions.

### 4. Cannot Register Tests in Loops

**Problem**:
```bash
# This doesn't work
for value in 1 2 3; do
    @test "test with $value" {
        run process "$value"
    }
done
```

**Why**: `@test` is preprocessed into functions. Loops just redefine the same function repeatedly.

**Workaround**:
```bash
@test "test multiple values" {
    for value in 1 2 3; do
        run process "$value"
        assert_success
    done
}
```

### 5. Background Tasks Prevent Test Termination

**Problem**:
```bash
@test "background task hangs" {
    long_running_process &
    # Test never completes - background job holds FD 3
}
```

**Solution**:
```bash
@test "close file descriptors" {
    long_running_process &
    disown
    exec 3>&-  # Close FD 3
}
```

Or use helper from BATS:
```bash
source test/fixtures/bats/issue-205.bats
close_non_std_fds  # Closes all FDs except 0,1,2
```

### 6. Variables Don't Persist After `run`

**Problem**:
```bash
@test "variable lost" {
    run export MY_VAR="value"
    echo "$MY_VAR"  # Empty! run uses subshell
}
```

**Solution**:
```bash
@test "direct execution" {
    # Don't use run for variable assignments
    export MY_VAR="value"
    echo "$MY_VAR"  # Works
}
```

### 7. `load` Only Loads `.bash` Files

**Problem**:
```bash
load 'my_script.sh'  # Error!
```

**Solution**:
```bash
# Use source for .sh files
source "${BATS_TEST_DIRNAME}/my_script.sh"

# Use load for .bash files
load 'test_helper/common'  # Automatically appends .bash
```

### 8. `[[` and `((` Don't Fail Tests on False

**Problem**:
```bash
@test "conditional doesn't fail" {
    [[ "foo" == "bar" ]]  # Test passes!
}
```

**Solution**:
```bash
@test "explicit check" {
    [[ "foo" == "bar" ]]
    [ $? -eq 0 ]  # Now it fails correctly
}

# Or use run
@test "with run" {
    run bash -c '[[ "foo" == "bar" ]]'
    assert_failure
}
```

---

## FAQ - Frequently Asked Questions

### Q: Why can't I see output from commands in failed tests?

**A**: `run` captures stdout/stderr into `$output`. To see it, print explicitly:

```bash
@test "debug output" {
    run my_command
    echo "Status: $status"
    echo "Output: $output"
    [ "$status" -eq 0 ]
}

# Or use assert_output which shows output on failure
@test "better approach" {
    load 'test_helper/bats-assert/load'
    run my_command
    assert_success
    assert_output "expected value"
}
```

### Q: How do I set the working directory for tests?

**A**: Use `cd` in `setup()` or `setup_file()`:

```bash
setup() {
    cd "$BATS_TEST_DIRNAME/../src" || exit 1
}
```

⚠️ **WARNING**: Code outside functions runs before setup and might interfere with BATS internals.

### Q: Can I exclude tests without deleting them?

**A**: Yes, multiple ways:

```bash
# Method 1: skip command
@test "not ready yet" {
    skip "Feature not implemented"
}

# Method 2: Conditional skip
@test "requires docker" {
    if ! command -v docker; then
        skip "Docker not installed"
    fi
    run docker ps
}

# Method 3: Skip in setup
setup() {
    if [ ! -f "required_file" ]; then
        skip "Required file missing"
    fi
}

# Method 4: Change file extension
# Rename test.bats to test.bats.disabled
```

### Q: How do I share setup logic across test files?

**A**: Extract common setup to a shared file:

```bash
# test_helper/common-setup.bash
common_setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'
    export PATH="$BATS_TEST_DIRNAME/../src:$PATH"
}

# In each test file:
setup() {
    load 'test_helper/common-setup'
    common_setup
}
```

### Q: Why can't I lint/format my `.bats` files?

**A**: `.bats` files use custom `@test` syntax that's not bash-compliant.

**Solutions**:

```bash
# Option 1: Use bash-compliant syntax
function my_test_name { #@test
    run my_command
}

# Option 2: Configure ShellCheck
# In .shellcheckrc or inline:
# shellcheck disable=SC2034,SC2154

# Option 3: Use bats-specific linters
```

### Q: How do I pass parameters to tests?

**A**: BATS doesn't support parameterization directly. Use environment variables:

```bash
# Run with parameter
TEST_PARAM="value" bats test/

# In test:
@test "uses parameter" {
    echo "Parameter: $TEST_PARAM"
}
```

### Q: How do I debug tests?

**A**: Multiple approaches:

```bash
# 1. Print debugging
@test "debug test" {
    echo "Debug: $variable" >&3  # Print to terminal
}

# 2. Use focus mode
# bats test_tags=bats:focus
@test "debug this" {
    # Only this runs
}

# 3. Run with bash -x
bash -x test/bats/bin/bats test/my_test.bats

# 4. Set breakpoint with read
@test "breakpoint" {
    echo "Pausing for inspection"
    read -p "Press enter to continue"
}
```

### Q: Can I use BATS for non-Bash scripts?

**A**: Yes! BATS can test any UNIX program:

```bash
@test "test Python script" {
    run python3 script.py
    assert_success
}

@test "test compiled binary" {
    run ./my_program arg1 arg2
    assert_output "expected result"
}
```

---

## Docker Usage

### Running BATS in Docker

```bash
# Official BATS Docker image
docker run -v "$(pwd):/code" bats/bats:latest /code/test

# With helper libraries
docker run -v "$(pwd):/code" \
    -v "$(pwd)/test/test_helper:/test_helper" \
    bats/bats:latest /code/test
```

### Dockerfile for Testing

```dockerfile
FROM bats/bats:latest

# Install helper libraries
RUN git clone --depth 1 https://github.com/bats-core/bats-support /opt/bats-support
RUN git clone --depth 1 https://github.com/bats-core/bats-assert /opt/bats-assert
RUN git clone --depth 1 https://github.com/bats-core/bats-file /opt/bats-file

WORKDIR /code
CMD ["bats", "/code/test"]
```

---

## Advanced Patterns

### Testing Functions vs Scripts

**Pattern 1: Testable Script Structure**

```bash
# script.sh
#!/bin/bash

# All logic in functions
greet() {
    echo "Hello, $1"
}

main() {
    greet "$1"
}

# Only execute if run directly, not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

**Pattern 2: Testing Functions**

```bash
@test "test function directly" {
    source script.sh
    
    run greet "World"
    assert_output "Hello, World"
}
```

### Mocking External Commands

```bash
@test "mock curl" {
    # Create mock directory
    MOCK_DIR="$BATS_TEST_TMPDIR/mocks"
    mkdir -p "$MOCK_DIR"
    
    # Create mock script
    cat > "$MOCK_DIR/curl" <<'EOF'
#!/bin/bash
echo '{"status":"ok"}'
exit 0
EOF
    chmod +x "$MOCK_DIR/curl"
    
    # Add to PATH
    export PATH="$MOCK_DIR:$PATH"
    
    # Test uses mock
    run my_script_that_uses_curl
    assert_output --partial "status"
}
```

### Retry Logic Testing

```bash
@test "test retry mechanism" {
    export ATTEMPT=0
    
    flaky_command() {
        ATTEMPT=$((ATTEMPT + 1))
        if [ "$ATTEMPT" -lt 3 ]; then
            return 1
        fi
        return 0
    }
    export -f flaky_command
    
    run retry_function flaky_command
    assert_success
    [ "$ATTEMPT" -eq 3 ]
}
```

### Testing with Fixtures

```bash
setup() {
    # Copy fixtures to temp directory
    cp -r "$BATS_TEST_DIRNAME/fixtures" "$BATS_TEST_TMPDIR/"
}

@test "processes fixture data" {
    run process_file "$BATS_TEST_TMPDIR/fixtures/sample.txt"
    assert_success
}
```

---

## CI/CD Integration

### GitHub Actions

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
        with:
          submodules: recursive  # Important for submodules
      
      - name: Run BATS tests
        run: ./test/bats/bin/bats test/
      
      - name: Generate JUnit report
        if: always()
        run: |
          ./test/bats/bin/bats --formatter junit \
            --output ./reports test/
      
      - name: Publish test results
        uses: EnricoMi/publish-unit-test-result-action@v2
        if: always()
        with:
          files: reports/report.xml
```

### GitLab CI

```yaml
test:
  image: bats/bats:latest
  script:
    - bats --formatter junit --output reports/ test/
  artifacts:
    reports:
      junit: reports/report.xml
    when: always
```

### Jenkins Pipeline

```groovy
pipeline {
    agent any
    
    stages {
        stage('Test') {
            steps {
                sh './test/bats/bin/bats --formatter junit --output reports test/'
            }
        }
    }
    
    post {
        always {
            junit 'reports/report.xml'
        }
    }
}
```

---

## DevOps Best Practices

### 1. Test Organization

```
test/
├── unit/              # Fast, isolated function tests
│   ├── parser.bats
│   └── validator.bats
├── integration/       # Tests with external dependencies
│   ├── api.bats
│   └── database.bats
├── e2e/              # Full system tests
│   └── deployment.bats
└── test_helper/
    ├── common-setup.bash
    ├── mocks/
    └── fixtures/
```

### 2. Naming Conventions

```bash
# Good test names describe behavior
@test "parse_config returns error when file is missing"
@test "deploy succeeds with valid credentials"
@test "retry mechanism attempts 3 times on failure"

# Bad test names
@test "test 1"
@test "check function"
@test "run command"
```

### 3. Test Independence

```bash
# GOOD - Each test is independent
@test "test A" {
    echo "data" > "$BATS_TEST_TMPDIR/file"
    run process_file "$BATS_TEST_TMPDIR/file"
}

@test "test B" {
    echo "data" > "$BATS_TEST_TMPDIR/file"
    run process_file "$BATS_TEST_TMPDIR/file"
}

# BAD - Tests depend on execution order
@test "create file" {
    echo "data" > /tmp/shared_file
}

@test "process file" {  # Fails if run alone
    run process_file /tmp/shared_file
}
```

### 4. Fail Fast

```bash
# Enable strict mode in scripts being tested
set -euo pipefail

# Verify critical prerequisites
@test "prerequisites" {
    command -v docker || skip "Docker required"
    [ -f config.yml ] || skip "Config file required"
}
```

### 5. Meaningful Assertions

```bash
# GOOD - Specific assertions
@test "good assertion" {
    load 'test_helper/bats-assert/load'
    run my_command
    assert_success
    assert_output --partial "Processing complete"
    assert_line --index 0 "Step 1: Started"
}

# BAD - Vague checks
@test "bad assertion" {
    run my_command
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}
```

### 6. Coverage Tracking

```bash
# Use kcov for coverage
kcov --include-path=src/ coverage/ bats test/

# Or bashcov
bashcov --skip-uncovered -- bats test/
```

### 7. Performance Monitoring

```bash
# Track test duration
bats --timing test/ | tee timing-report.txt

# Set timeouts
export BATS_TEST_TIMEOUT=30

# Optimize slow tests
@test "optimize with parallel" {
    run parallel process_item ::: item1 item2 item3
}
```

---

## Summary & Recommended Action

### Key Principles

1. **Isolation**: Every test should run independently
2. **Readability**: Test names should describe expected behavior
3. **Simplicity**: Avoid complex logic in tests
4. **Speed**: Fast tests encourage frequent execution
5. **Reliability**: Tests should never be flaky

### Analogy Recap

Think of BATS testing like **running a restaurant**:
- **setup_file**: Opening in the morning (once per service)
- **setup**: Setting each table before guests arrive
- **@test**: Serving each meal (isolated, repeatable)
- **teardown**: Clearing each table after the meal
- **teardown_file**: Closing at night (once per service)

### Code Sample: Complete Example

```bash
#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
    # Create isolated test environment
    TEST_DIR="$BATS_TEST_TMPDIR"
    
    # Make script available
    export PATH="$BATS_TEST_DIRNAME/../src:$PATH"
    
    # Mock external dependency
    cat > "$TEST_DIR/mock_api" <<'EOF'
#!/bin/bash
echo '{"status":"success"}'
EOF
    chmod +x "$TEST_DIR/mock_api"
    export PATH="$TEST_DIR:$PATH"
}

@test "script processes valid input successfully" {
    echo "test data" > "$TEST_DIR/input.txt"
    
    run my_script "$TEST_DIR/input.txt"
    
    assert_success
    assert_output --partial "Processing complete"
    assert_file_exists "$TEST_DIR/output.txt"
}

@test "script handles missing file gracefully" {
    run my_script "$TEST_DIR/nonexistent.txt"
    
    assert_failure
    assert_stderr --partial "File not found"
}
```

### Pros & Cons

**Pros**:
✅ Simple, readable syntax
✅ TAP-compliant (works with all CI systems)
✅ Excellent helper library ecosystem
✅ Supports parallel execution
✅ Active community and documentation

**Cons**:
❌ Custom syntax not bash-compliant (linting issues)
❌ Limited debugging capabilities
❌ No native parameterized tests
❌ Bash-specific quirks (pipes, negation, etc.)

### Recommended Action

**Start with this workflow**:

1. **Install BATS as submodule** for version control
2. **Create basic test structure** with helper libraries
3. **Write one test** for your most critical script
4. **Add CI integration** with JUnit reporting
5. **Gradually expand** test coverage
6. **Refactor scripts** to be more testable

**First Steps**:

```bash
# 1. Initialize BATS
git submodule add https://github.com/bats-core/bats-core.git test/bats
git submodule add https://github.com/bats-core/bats-support.git test/test_helper/bats-support
git submodule add https://github.com/bats-core/bats-assert.git test/test_helper/bats-assert

# 2. Create first test
cat > test/first.bats <<'EOF'
#!/usr/bin/env bats

@test "script runs successfully" {
    run ./src/my_script.sh --help
    [ "$status" -eq 0 ]
}
EOF

# 3. Run it
./test/bats/bin/bats test/

# 4. Iterate: Add assertions, expand coverage, refactor
```

---

## References

- **Official Documentation**: https://bats-core.readthedocs.io
- **GitHub Repository**: https://github.com/bats-core/bats-core
- **Helper Libraries**:
  - bats-support: https://github.com/bats-core/bats-support
  - bats-assert: https://github.com/bats-core/bats-assert
  - bats-file: https://github.com/bats-core/bats-file
- **Projects Using BATS**: https://github.com/bats-core/bats-core/wiki/Projects-Using-Bats

---

**Document compiled**: November 2025  
**Based on**: bats-core master branch, official documentation  
**Maintainer**: Community-maintained at bats-core organization
