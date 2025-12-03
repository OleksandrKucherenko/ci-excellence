# Side Effects in BATS Testing - Expert Guidance

## Understanding Side Effects

**Analogy:** Side effects are like a chef who doesn't clean their cutting board between dishes - the garlic from the previous dish contaminates the dessert. Each test should start with a "clean kitchen."

## Types of Side Effects in Bash Testing

### 1. **Filesystem Side Effects**

```bash
# ❌ BAD: Pollutes shared space
@test "creates log file" {
    run ./script.sh
    assert_file_exists "/tmp/app.log"  # Dangerous!
}

# ✅ GOOD: Isolated temporary space
@test "creates log file" {
    # Each test gets unique directory
    export LOG_DIR="$BATS_TEST_TMPDIR"
    
    run ./script.sh
    
    assert_file_exists "$BATS_TEST_TMPDIR/app.log"
}
# Automatically cleaned up after test
```

**Detection Strategy:**
```bash
# Run tests twice - second run should have identical results
bats test/my_test.bats
bats test/my_test.bats  # Should still pass!

# Run in parallel to expose shared state
bats -j 4 test/
```

### 2. **Environment Variable Side Effects**

```bash
# ❌ BAD: Pollutes environment for subsequent tests
@test "exports configuration" {
    export DATABASE_URL="postgres://test"
    run ./configure.sh
    assert_success
}
# DATABASE_URL now leaks to other tests!

# ✅ GOOD: Explicit cleanup
@test "exports configuration" {
    export DATABASE_URL="postgres://test"
    
    run ./configure.sh
    
    assert_success
}

teardown() {
    # Clean up environment
    unset DATABASE_URL
}

# ✅ BETTER: Subshell isolation
@test "exports configuration" {
    (
        export DATABASE_URL="postgres://test"
        ./configure.sh
    )
    # DATABASE_URL never escapes subshell
}
```

### 3. **Working Directory Side Effects**

```bash
# ❌ BAD: Changes directory globally
@test "processes files in target directory" {
    cd "$BATS_TEST_TMPDIR/data"
    run process_files.sh
}
# All subsequent tests now run from wrong directory!

# ✅ GOOD: Restore directory
@test "processes files in target directory" {
    local original_dir="$PWD"
    cd "$BATS_TEST_TMPDIR/data"
    
    run process_files.sh
    
    cd "$original_dir"
}

# ✅ BETTER: Use subshell
@test "processes files in target directory" {
    (
        cd "$BATS_TEST_TMPDIR/data"
        process_files.sh
    )
    # Directory change contained in subshell
}

# ✅ BEST: Make script accept path parameter
@test "processes files in target directory" {
    run process_files.sh "$BATS_TEST_TMPDIR/data"
}
```

### 4. **Process/Background Job Side Effects**

```bash
# ❌ BAD: Background process never cleaned up
@test "starts server" {
    ./start_server.sh &
    sleep 2
    
    run curl http://localhost:8080
    assert_success
}
# Server keeps running, blocks port for other tests!

# ✅ GOOD: Explicit cleanup
@test "starts server" {
    ./start_server.sh &
    SERVER_PID=$!
    sleep 2
    
    run curl http://localhost:8080
    assert_success
    
    kill $SERVER_PID
    wait $SERVER_PID 2>/dev/null || true
}

# ✅ BETTER: Use teardown
setup() {
    ./start_server.sh &
    SERVER_PID=$!
    export SERVER_PID
    sleep 2
}

teardown() {
    if [[ -n "${SERVER_PID:-}" ]]; then
        kill $SERVER_PID 2>/dev/null || true
        wait $SERVER_PID 2>/dev/null || true
    fi
}

@test "server responds to requests" {
    run curl http://localhost:8080
    assert_success
}
```

### 5. **File Descriptor Side Effects**

```bash
# ❌ BAD: Leaves file descriptors open
@test "reads configuration" {
    exec 3< config.ini
    run process_config.sh
}
# FD 3 remains open, can cause hangs

# ✅ GOOD: Close file descriptors
@test "reads configuration" {
    exec 3< config.ini
    run process_config.sh
    exec 3>&-  # Close FD 3
}

# ✅ BETTER: Use automatic cleanup
teardown() {
    # Close any open file descriptors
    exec 3>&- 2>/dev/null || true
    exec 4>&- 2>/dev/null || true
}
```

### 6. **Network/External Service Side Effects**

```bash
# ❌ BAD: Actual API calls affect external state
@test "creates user in production database" {
    run create_user.sh "test@example.com"
    assert_success
}
# Creates real user! Can't be run repeatedly!

# ✅ GOOD: Mock external services
@test "creates user via API" {
    # Mock curl to prevent actual API call
    mkdir -p "$BATS_TEST_TMPDIR/bin"
    
    cat > "$BATS_TEST_TMPDIR/bin/curl" << 'EOF'
#!/bin/bash
# Spy: Record that API was called
echo "POST $*" >> "$API_CALLS_LOG"
# Fake success response
echo '{"id": 123, "email": "test@example.com"}'
exit 0
EOF
    chmod +x "$BATS_TEST_TMPDIR/bin/curl"
    
    export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
    export API_CALLS_LOG="$BATS_TEST_TMPDIR/api_calls.log"
    
    run create_user.sh "test@example.com"
    
    assert_success
    assert_file_contains "$API_CALLS_LOG" "POST"
}
```

## Testing Code with Intentional Side Effects

Some scripts are **designed** to have side effects (e.g., installer scripts, deployment tools). Here's how to test them safely:

### Pattern 1: Containerized Testing

```bash
setup_file() {
    # Create isolated Docker container for destructive tests
    export TEST_CONTAINER=$(docker run -d \
        --rm \
        -v "$(pwd):/workspace" \
        ubuntu:20.04 sleep 3600)
}

teardown_file() {
    docker stop "$TEST_CONTAINER"
}

@test "installer modifies system packages" {
    # Run installer inside container (safe to modify)
    docker exec "$TEST_CONTAINER" /workspace/install.sh
    
    # Verify side effects
    run docker exec "$TEST_CONTAINER" which myapp
    assert_success
}
```

### Pattern 2: Snapshot and Restore

```bash
setup() {
    # Save original state
    cp /etc/myapp/config.ini "$BATS_TEST_TMPDIR/config.backup"
}

teardown() {
    # Restore original state
    cp "$BATS_TEST_TMPDIR/config.backup" /etc/myapp/config.ini
}

@test "configuration script modifies system config" {
    run ./configure_system.sh
    
    assert_success
    assert_file_contains /etc/myapp/config.ini "production_mode=true"
}
# teardown restores original config
```

### Pattern 3: Dry-Run Mode

```bash
# Script should support --dry-run flag
@test "installer shows what it would do without modifying system" {
    run ./install.sh --dry-run
    
    assert_success
    assert_output --partial "Would install to /opt/myapp"
    assert_output --partial "Would create user 'myapp'"
    
    # Verify nothing was actually modified
    refute_dir_exists /opt/myapp
}
```

## Side Effect Detection Checklist

When reviewing a test suite, check for these warning signs:

```bash
# 🚩 RED FLAG: Tests must run in specific order
@test "01_setup_database" { }
@test "02_create_user" { }
@test "03_verify_user" { }

# ✅ FIXED: Each test is independent
@test "create_user works with clean database" {
    setup_test_database  # Each test gets fresh DB
    run create_user "test@example.com"
    assert_success
}

# 🚩 RED FLAG: Test fails when run alone but passes in suite
bats test/suite.bats           # Passes
bats --filter "my test" test/  # Fails!

# ✅ FIXED: Test is self-contained
@test "my test" {
    # Explicit setup - doesn't rely on previous tests
    create_test_fixtures
    run my_function
    assert_success
}

# 🚩 RED FLAG: Test passes first time, fails on second run
bats test/my_test.bats  # Pass
bats test/my_test.bats  # Fail! (leftover files)

# ✅ FIXED: Use isolated temp directories
@test "creates output file" {
    export OUTPUT_DIR="$BATS_TEST_TMPDIR"
    run generate_output.sh
    assert_file_exists "$OUTPUT_DIR/output.txt"
}

# 🚩 RED FLAG: Parallel tests fail but sequential passes
bats test/              # Pass
bats -j 4 test/        # Fail! (shared resources)

# ✅ FIXED: No shared resources
@test "uses unique port for server" {
    # Each test gets unique port
    local port=$((8000 + RANDOM % 1000))
    run start_server.sh --port "$port"
    assert_success
}
```

## Advanced Side Effect Management

### The "Golden Rule" Pattern

```bash
# Save, modify, assert, restore
@test "modifies global configuration safely" {
    # SAVE: Capture original state
    local original_path="$PATH"
    local original_pwd="$PWD"
    local original_vars=$(env | sort)
    
    # MODIFY: Make changes
    export PATH="/custom/bin:$PATH"
    cd "$BATS_TEST_TMPDIR"
    export TEST_VAR="test_value"
    
    # ASSERT: Verify behavior
    run ./script_that_depends_on_environment.sh
    assert_success
    
    # RESTORE: Clean up
    export PATH="$original_path"
    cd "$original_pwd"
    unset TEST_VAR
}
```

### Using `trap` for Guaranteed Cleanup

```bash
@test "ensures cleanup even on test failure" {
    # Set trap to clean up even if test fails
    trap 'docker stop test_db 2>/dev/null || true' EXIT
    
    # Start service
    docker run -d --name test_db postgres
    
    # Test might fail here
    run ./migrate_database.sh
    assert_success
    
    # Cleanup happens automatically via trap
}
```

### Detecting Hidden Side Effects

```bash
# Add this helper to your test_helper.bash
detect_side_effects() {
    local before="$1"
    local after="$2"
    
    # Compare filesystem
    diff <(find /tmp -type f 2>/dev/null | sort) \
         <(echo "$before") || \
         echo "WARNING: /tmp modified during test"
    
    # Compare environment
    diff <(env | sort) <(echo "$after") || \
         echo "WARNING: Environment variables modified"
}

@test "verifies no side effects" {
    local env_before=$(env | sort)
    local files_before=$(find /tmp -type f 2>/dev/null | sort)
    
    run ./supposedly_safe_script.sh
    
    detect_side_effects "$files_before" "$env_before"
}
```

## Recommended Actions for Side Effects

### When You Find Side Effects:

1. **Document:** Add comment explaining why side effect exists
   ```bash
   # NOTE: This test modifies /etc/hosts. Requires root and should
   # be run in isolated environment (container or VM).
   @test "installer adds hostname to /etc/hosts" { }
   ```

2. **Isolate:** Move tests with side effects to separate file
   ```bash
   test/
   ├── unit/              # No side effects, fast
   │   └── parsers.bats
   ├── integration/       # Controlled side effects
   │   └── database.bats
   └── destructive/       # System-modifying tests
       └── installer.bats # Requires container
   ```

3. **Tag:** Use BATS tags to mark dangerous tests
   ```bash
   # bats test_tags=destructive,requires-root
   @test "modifies system packages" { }
   ```

4. **Guard:** Add safety checks
   ```bash
   @test "destructive operation" {
       # Safety check
       if [[ "$CI" != "true" ]] && [[ "$ALLOW_DESTRUCTIVE_TESTS" != "1" ]]; then
           skip "Destructive test - set ALLOW_DESTRUCTIVE_TESTS=1 to run"
       fi
       
       run dangerous_operation.sh
   }
   ```

5. **Refactor:** Propose script changes for testability
   ```bash
   # BEFORE: Script has side effects
   install_package() {
       apt-get install -y mypackage
   }
   
   # AFTER: Script accepts dry-run flag
   install_package() {
       local dry_run="${DRY_RUN:-false}"
       
       if [[ "$dry_run" == "true" ]]; then
           echo "Would install: mypackage"
           return 0
       fi
       
       apt-get install -y mypackage
   }
   ```

## Pro/Con Analysis

| Approach               | Pros                                           | Cons                                 |
| ---------------------- | ---------------------------------------------- | ------------------------------------ |
| **Subshell isolation** | Automatic cleanup, no manual restoration       | Can't test variables set by script   |
| **Explicit teardown**  | Full control, visible cleanup                  | Must remember to restore all changes |
| **Container testing**  | Complete isolation, safe for destructive tests | Slower, requires Docker              |
| **Mocking**            | No real side effects, fast                     | May not catch real-world issues      |
| **Dry-run mode**       | Tests logic without side effects               | Requires script modification         |

## Recommended Best Practice

**Default to maximum isolation:**

```bash
setup() {
    # Create completely isolated environment
    TEST_TEMP_DIR="$(temp_make)"
    export HOME="$TEST_TEMP_DIR/home"
    export PATH="$TEST_TEMP_DIR/bin:$PATH"
    export TMPDIR="$TEST_TEMP_DIR/tmp"
    
    mkdir -p "$HOME" "$TMPDIR"
    
    # Save original state
    _ORIGINAL_PWD="$PWD"
    cd "$TEST_TEMP_DIR"
}

teardown() {
    # Restore original state
    cd "$_ORIGINAL_PWD"
    temp_del "$TEST_TEMP_DIR"
}

@test "your test here" {
    # Runs in completely isolated environment
    # Can't accidentally pollute anything
}
```

**The mantra:** "Leave no trace - each test should be invisible to all others."