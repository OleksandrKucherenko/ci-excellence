# BATS Quick Reference Guide
## Fast Lookup for Common Tasks

---

## Installation (One-Liner)

```bash
# As submodules (recommended)
git submodule add https://github.com/bats-core/bats-core.git test/bats && \
git submodule add https://github.com/bats-core/bats-support.git test/test_helper/bats-support && \
git submodule add https://github.com/bats-core/bats-assert.git test/test_helper/bats-assert && \
git submodule add https://github.com/bats-core/bats-file.git test/test_helper/bats-file
```

---

## Most Common Commands

| Task | Command |
|------|---------|
| Run all tests | `bats test/` |
| Run recursively | `bats -r test/` |
| Parallel execution | `bats --jobs 4 test/` |
| Filter by name | `bats --filter "login" test/` |
| Filter by tags | `bats --filter-tags api,!slow test/` |
| JUnit report | `bats --formatter junit --output ./reports test/` |
| Show timing | `bats --timing test/` |
| Count tests | `bats --count test/` |

---

## Test Template (Copy-Paste Ready)

```bash
#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper/bats-file/load'

setup() {
    # Runs before each test
    TEST_DIR="$BATS_TEST_TMPDIR"
    export PATH="$BATS_TEST_DIRNAME/../src:$PATH"
}

teardown() {
    # Runs after each test
    rm -rf "$TEST_DIR"
}

@test "describe what this test does" {
    run your_command arg1 arg2
    
    assert_success
    assert_output "expected output"
}
```

---

## Essential Assertions (bats-assert)

```bash
# Exit status
assert_success              # $status == 0
assert_failure              # $status != 0
assert_failure 1            # $status == 1

# Output matching
assert_output "exact"       # Exact match
assert_output --partial "sub"  # Contains substring
assert_output --regexp "^[0-9]+$"  # Regex match

# Line matching
assert_line "first line"    # Any line matches
assert_line --index 0 "first"  # Specific line
assert_line --partial "sub"    # Contains substring

# Negations
refute_output "not this"
refute_line "not in output"
```

---

## File Assertions (bats-file)

```bash
# File existence
assert_file_exists "/path/to/file"
assert_dir_exists "/path/to/dir"

# File properties
assert_file_executable "/path/to/script"
assert_file_not_empty "/path/to/file"

# File content
assert_file_contains "/path/to/file" "search text"
```

---

## The `run` Helper - Quick Guide

```bash
run command arg1 arg2

# Available after run:
$status              # Exit code
$output              # Combined stdout+stderr
${lines[@]}          # Array of output lines
${lines[0]}          # First line
$BATS_RUN_COMMAND    # Command that was executed

# With status check (BATS 1.5+)
run -1 command       # Expect exit code 1
run ! command        # Expect non-zero exit
run -0 command       # Expect success

# Separate streams
run --separate-stderr command
echo "$output"       # stdout only
echo "$stderr"       # stderr only
```

---

## Lifecycle Hooks Cheat Sheet

```bash
setup_file()    # Once before all tests in file (expensive setup)
setup()         # Before each test (test-specific setup)
@test           # The actual test
teardown()      # After each test (cleanup)
teardown_file() # Once after all tests in file (final cleanup)
```

---

## Temp Directories

| Variable | Scope | Use When |
|----------|-------|----------|
| `$BATS_TEST_TMPDIR` | Per test | Always (for isolation) |
| `$BATS_FILE_TMPDIR` | Per file | Shared across tests in file |
| `$BATS_RUN_TMPDIR` | Per BATS run | Shared across all files |

```bash
# Best practice
@test "use test temp" {
    echo "data" > "$BATS_TEST_TMPDIR/file.txt"
    # Automatically cleaned up
}
```

---

## Mocking External Commands

```bash
@test "mock curl" {
    # Create mock directory
    mkdir -p "$BATS_TEST_TMPDIR/bin"
    
    # Create mock script
    cat > "$BATS_TEST_TMPDIR/bin/curl" <<'EOF'
#!/bin/bash
echo '{"status":"ok"}'
EOF
    chmod +x "$BATS_TEST_TMPDIR/bin/curl"
    
    # Override PATH
    export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
    
    # Test now uses mock
    run my_script_using_curl
}
```

---

## Skip Tests

```bash
# Unconditional skip
@test "not ready" {
    skip "Feature not implemented"
}

# Conditional skip
@test "requires docker" {
    command -v docker || skip "Docker not installed"
    run docker ps
}

# Skip in setup
setup() {
    [ -f required_file ] || skip "Required file missing"
}
```

---

## Debugging Tests

```bash
# 1. Print to terminal
@test "debug output" {
    echo "Debug info" >&3  # Goes to terminal, not captured
}

# 2. Focus on one test
# bats test_tags=bats:focus
@test "debug this test" {
    # Only this test runs
}

# 3. Run with bash trace
bash -x test/bats/bin/bats test/test.bats

# 4. Add breakpoint
@test "pause for inspection" {
    read -p "Press enter to continue"
}
```

---

## Common Gotchas - Quick Fixes

### Negation doesn't work
```bash
# WRONG
! true  # Doesn't fail test

# RIGHT
run ! true  # BATS 1.5+
! true || false  # Older versions
```

### Pipes don't work with run
```bash
# WRONG
run echo "test" | grep "test"

# RIGHT
run bash -c "echo 'test' | grep 'test'"
run bats_pipe echo "test" \| grep "test"
```

### Variables lost after run
```bash
# WRONG
run export VAR="value"
echo "$VAR"  # Empty!

# RIGHT
export VAR="value"  # Don't use run for assignments
```

### Background tasks hang tests
```bash
# WRONG
long_task &  # Holds file descriptors

# RIGHT
long_task &
exec 3>&-  # Close FD 3
```

---

## CI/CD Integration Quick Start

### GitHub Actions

```yaml
- name: Run tests
  run: ./test/bats/bin/bats --formatter junit --output ./reports test/
  
- name: Publish results
  uses: EnricoMi/publish-unit-test-result-action@v2
  if: always()
  with:
    files: reports/report.xml
```

### GitLab CI

```yaml
test:
  script:
    - bats --formatter junit --output reports/ test/
  artifacts:
    reports:
      junit: reports/report.xml
```

---

## Tags Quick Reference

```bash
# Define tags
# bats test_tags=api,smoke,slow
@test "user login" { }

# Run tests with tags
bats --filter-tags api test/           # Has 'api'
bats --filter-tags api,smoke test/     # Has both (AND)
bats --filter-tags api,!slow test/     # Has 'api' but not 'slow'
bats --filter-tags api --filter-tags smoke test/  # Has 'api' OR 'smoke'
```

---

## Project Structure Template

```
project/
├── src/
│   └── my_script.sh           # Code to test
├── test/
│   ├── bats/                  # Submodule
│   ├── test_helper/
│   │   ├── bats-support/      # Submodule
│   │   ├── bats-assert/       # Submodule
│   │   ├── bats-file/         # Submodule
│   │   ├── common-setup.bash  # Shared setup
│   │   ├── mocks/             # Mock scripts
│   │   └── fixtures/          # Test data
│   ├── unit/
│   │   └── parser.bats
│   └── integration/
│       └── api.bats
└── .gitmodules
```

---

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `$BATS_VERSION` | BATS version |
| `$BATS_TEST_FILENAME` | Full path to test file |
| `$BATS_TEST_DIRNAME` | Directory of test file |
| `$BATS_TEST_NAME` | Name of current test |
| `$BATS_TEST_NUMBER` | Index of current test (1-based) |
| `$BATS_TMPDIR` | Base temp directory |
| `$BATS_RUN_TMPDIR` | Temp for this run |
| `$BATS_FILE_TMPDIR` | Temp for this file |
| `$BATS_TEST_TMPDIR` | Temp for this test |
| `$BATS_TEST_TIMEOUT` | Timeout in seconds |

---

## Performance Tips

```bash
# 1. Use setup_file for expensive operations
setup_file() {
    docker-compose up -d  # Start once for all tests
}

# 2. Run tests in parallel
bats --jobs $(nproc) test/

# 3. Skip slow tests in development
# bats test_tags=slow
@test "long running test" {
    skip "Slow test"
}

# Then: bats --filter-tags '!slow' test/

# 4. Cache compiled artifacts
setup_file() {
    if [ ! -f "$BATS_FILE_TMPDIR/binary" ]; then
        compile_binary
    fi
}
```

---

## Troubleshooting Decision Tree

```
Test failing?
├─ Check $status explicitly? → Use assert_success/assert_failure
├─ Using pipes? → Use bats_pipe or bash -c
├─ Using negation? → Use run ! or || false
├─ Variables disappear? → Don't use run for assignments
├─ Can't see output? → Use assert_output or echo >&3
├─ Test hangs? → Check for background tasks, close FD 3
└─ Tests interfere? → Check for shared state, use $BATS_TEST_TMPDIR
```

---

## One-Minute Test Setup

```bash
# 1. Create test file
cat > test/quick.bats <<'EOF'
#!/usr/bin/env bats

@test "first test" {
    run echo "hello"
    [ "$status" -eq 0 ]
    [ "$output" = "hello" ]
}
EOF

# 2. Run it
./test/bats/bin/bats test/quick.bats

# 3. Success? Add more tests!
```

---

## Most Important Rule

**Always use `run` to capture output and check `$status` explicitly!**

```bash
# GOOD
@test "check command" {
    run my_command
    assert_success
    assert_output "expected"
}

# BAD
@test "check command" {
    my_command  # No output capture
}
```

---

## Getting Help

```bash
# View manual pages
man 1 bats     # Usage manual
man 7 bats     # Writing tests manual

# Command help
bats --help

# Version
bats --version
```

---

## Resources

- **Docs**: https://bats-core.readthedocs.io
- **GitHub**: https://github.com/bats-core/bats-core
- **Examples**: https://github.com/bats-core/bats-core/wiki/Projects-Using-Bats

---

*Keep this guide handy for quick lookups during development!*
