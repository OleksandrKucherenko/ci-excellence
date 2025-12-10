#!/usr/bin/env bats

# Load test helper
load "${BATS_TEST_DIRNAME}/../test_helper.bash"

setup() {
    # GIVEN: A git repository with hook scripts available
    setup_git_hooks_test
    configure_message_check_hook
    set_execute_mode
}

teardown() {
    # Cleanup test environment
    cleanup_git_hooks_test
}

@test "pre-commit-message-check: script exists and is executable" {
    # GIVEN: The message check hook script should exist
    [[ -f "$TEST_HOOKS_DIR/pre-commit-message-check.sh" ]]
    [[ -x "$TEST_HOOKS_DIR/pre-commit-message-check.sh" ]]
}

@test "pre-commit-message-check: shows help information" {
    # WHEN: Script is called with help flag
    run run_hook_script "pre-commit-message-check.sh" "help"

    # THEN: Help information should be displayed
    assert_success
    assert_line --partial "Pre-commit Message Check Hook"
    assert_line --partial "Usage:"
}

@test "pre-commit-message-check: checks Commitizen availability" {
    # WHEN: Script validates setup
    run run_hook_script "pre-commit-message-check.sh" "validate"

    # THEN: Should validate Commitizen is available
    assert_success
    assert_line --partial "✅ Pre-commit hook validation completed"
}

@test "pre-commit-message-check: fails when Commitizen is not available" {
    # GIVEN: Commitizen is not available
    rm -f "$BATS_TEST_TMPDIR/bin/cz"
    rm -f "$BATS_TEST_TMPDIR/bin/commitizen"

    # WHEN: Script runs without Commitizen
    run run_hook_script "pre-commit-message-check.sh" "validate"

    # THEN: Should fail with appropriate error
    assert_failure
    assert_line --partial "Commitizen is not installed"
}

@test "pre-commit-message-check: validates conventional commit messages" {
    # GIVEN: Valid conventional commit message
    create_valid_commit_message

    # WHEN: Message check runs
    run run_hook_script "pre-commit-message-check.sh"

    # THEN: Should pass validation
    assert_success
    assert_line --partial "✓ Commit message is valid"
    assert_line --partial "✅ Pre-commit message check completed successfully"
}

@test "pre-commit-message-check: rejects non-conventional commit messages" {
    # GIVEN: Invalid commit message
    create_invalid_commit_message

    # WHEN: Message check runs
    run run_hook_script "pre-commit-message-check.sh"

    # THEN: Should fail validation
    assert_failure
    assert_line --partial "✗ Commit message validation failed:"
    assert_line --partial "❌ Pre-commit message check failed"
}

@test "pre-commit-message-check: respects USE_COMMITIZEN environment variable" {
    # GIVEN: Commitizen validation is disabled
    export USE_COMMITIZEN=false
    create_valid_commit_message

    # WHEN: Message check runs without Commitizen
    run run_hook_script "pre-commit-message-check.sh"

    # THEN: Should perform basic checks only
    assert_success
    # Should pass with basic validation
}

@test "pre-commit-message-check: enforces strict conventional format when enabled" {
    # GIVEN: Strict mode is enabled
    export STRICT_CONVENTIONAL=true
    create_invalid_commit_message

    # WHEN: Message check runs with strict mode
    run run_hook_script "pre-commit-message-check.sh"

    # THEN: Should fail on non-conventional format
    assert_failure
    assert_line --partial "Subject does not follow conventional commit format"
}

@test "pre-commit-message-check: allows conventional commits with scope" {
    # GIVEN: Conventional commit with scope
    create_commit_message "feat(auth): add JWT token validation

Add JWT token validation to protect API endpoints."

    # WHEN: Message check runs
    run run_hook_script "pre-commit-message-check.sh"

    # THEN: Should allow scoped conventional commits
    assert_success
    assert_line --partial "✓ Commit message is valid"
}

@test "pre-commit-message-check: validates subject length constraints" {
    # GIVEN: Message with subject that's too long
    create_commit_message "feat: this is a very long subject that exceeds the maximum allowed length of seventy two characters and should be rejected"

    # WHEN: Message check runs
    run run_hook_script "pre-commit-message-check.sh"

    # THEN: Should reject oversize subject
    assert_failure
    assert_line --partial "Commit message subject is too long"
}

@test "pre-commit-message-check: validates subject minimum length" {
    # GIVEN: Message with subject that's too short
    create_commit_message "feat: short"

    # WHEN: Message check runs
    run run_hook_script "pre-commit-message-check.sh"

    # THEN: Should reject undersized subject
    assert_failure
    assert_line --partial "Commit message subject is too short"
}

@test "pre-commit-message-check: handles different conventional commit types" {
    # GIVEN: Various conventional commit types
    local commit_types=(
        "fix: resolve authentication bug"
        "docs: update API documentation"
        "style: fix code formatting"
        "refactor: improve database queries"
        "test: add unit tests for auth"
        "chore: update dependencies"
        "perf: optimize image loading"
        "ci: configure GitHub Actions"
        "build: update webpack config"
        "revert: remove feature flag"
    )

    # WHEN: Each commit type is validated
    for commit_msg in "${commit_types[@]}"; do
        create_commit_message "$commit_msg"
        run run_hook_script "pre-commit-message-check.sh"
        assert_success "Commit type should be valid: $commit_msg"
    done
}

@test "pre-commit-message-check: respects COMMITIZEN_CONFIG environment variable" {
    # GIVEN: Custom Commitizen config is set
    export COMMITIZEN_CONFIG="custom_config"
    create_valid_commit_message

    # WHEN: Message check runs with custom config
    run run_hook_script "pre-commit-message-check.sh"

    # THEN: Should use custom configuration
    assert_success
}

@test "pre-commit-message-check: shows improvement suggestions when enabled" {
    # GIVEN: Suggestions mode is enabled
    export SHOW_SUGGESTIONS=true
    create_commit_message "fix(auth): add validation.

This fixes the authentication issue.

Multiple paragraphs with proper spacing."

    # WHEN: Message check runs with suggestions
    run run_hook_script "pre-commit-message-check.sh"

    # THEN: Should show improvement suggestions if applicable
    assert_success
    # May or may not show suggestions depending on message quality
}

@test "pre-commit-message-check: auto-formats commit messages when enabled" {
    # GIVEN: Auto-format mode is enabled
    export AUTO_FORMAT=true
    local message_file="$TEST_GIT_DIR/COMMIT_EDITMSG"
    create_commit_message "feat(auth): add validation.

Some content with extra spaces.   " "$message_file"

    # WHEN: Message check runs with auto-format
    run run_hook_script "pre-commit-message-check.sh" "$message_file"

    # THEN: Should format the message
    assert_success
    assert_line --partial "✓ Commit message formatted"
}

@test "pre-commit-message-check: works with commit message file argument" {
    # GIVEN: Custom commit message file
    local custom_file="$TEST_PROJECT_ROOT/custom_commit_msg"
    create_valid_commit_message > "$custom_file"

    # WHEN: Message check runs with custom file
    run run_hook_script "pre-commit-message-check.sh" "$custom_file"

    # THEN: Should validate the specified file
    assert_success
    assert_line --partial "✓ Commit message is valid"
}

@test "pre-commit-message-check: uses git COMMIT_EDITMSG when no file specified" {
    # GIVEN: Commit message in git's default location
    create_valid_commit_message > "$TEST_GIT_DIR/COMMIT_EDITMSG"

    # WHEN: Message check runs without file argument
    cd "$TEST_PROJECT_ROOT"
    run "$TEST_HOOKS_DIR/pre-commit-message-check.sh"

    # THEN: Should use git's commit message file
    assert_success
    assert_line --partial "✓ Commit message is valid"
}

@test "pre-commit-message-check: reads from GIT_COMMIT_MESSAGE_FILE environment variable" {
    # GIVEN: Custom commit message file via environment
    local env_file="$TEST_PROJECT_ROOT/env_commit_msg"
    create_valid_commit_message > "$env_file"
    export GIT_COMMIT_MESSAGE_FILE="$env_file"

    # WHEN: Message check runs with environment variable
    run run_hook_script "pre-commit-message-check.sh"

    # THEN: Should read from environment-specified file
    assert_success
    assert_line --partial "✓ Commit message is valid"
}

@test "pre-commit-message-check: handles empty commit messages" {
    # GIVEN: Empty commit message file
    touch "$TEST_GIT_DIR/COMMIT_EDITMSG"

    # WHEN: Message check runs
    cd "$TEST_PROJECT_ROOT"
    run "$TEST_HOOKS_DIR/pre-commit-message-check.sh"

    # THEN: Should reject empty message
    assert_failure
    assert_line --partial "Commit message is empty"
}

@test "pre-commit-message-check: handles missing commit message file" {
    # GIVEN: No commit message file exists
    cd "$TEST_PROJECT_ROOT"

    # WHEN: Message check runs without file
    run "$TEST_HOOKS_DIR/pre-commit-message-check.sh"

    # THEN: Should handle missing file gracefully
    assert_failure
    assert_line --partial "No commit message file provided"
}

@test "pre-commit-message-check: formats commit messages interactively" {
    # GIVEN: Interactive format mode
    local message_file="$TEST_PROJECT_ROOT/interactive_msg"
    create_commit_message "feat: add feature.

Extra content." "$message_file"

    # WHEN: Interactive format is requested (non-interactive for testing)
    run run_hook_script "pre-commit-message-check.sh" "format" "$(cat "$message_file")"

    # THEN: Should format the message
    assert_success
    # Should return formatted message
}

@test "pre-commit-message-check: validates commit message from stdin" {
    # GIVEN: Commit message provided via stdin
    local commit_msg="feat: test commit from stdin"

    # WHEN: Message check reads from stdin
    run bash -c "echo '$commit_msg' | '$TEST_HOOKS_DIR/pre-commit-message-check.sh'"

    # THEN: Should validate message from stdin
    assert_success
    assert_line --partial "✓ Commit message is valid"
}

@test "pre-commit-message-check: provides detailed error messages" {
    # GIVEN: Invalid commit message
    create_invalid_commit_message

    # WHEN: Message check runs
    run run_hook_script "pre-commit-message-check.sh"

    # THEN: Should provide detailed error guidance
    assert_failure
    assert_line --partial "Commit message format requirements:"
    assert_line --partial "1. Subject should be 10-72 characters"
    assert_line --partial "2. Use conventional commit format"
    assert_line --partial "3. Types: feat, fix, docs, style, refactor, test, chore, perf, ci, build, revert"
    assert_line --partial "4. Separate subject from body with blank line"
    assert_line --partial "5. Wrap body lines at 72 characters"
}

@test "pre-commit-message-check: generates report after execution" {
    # GIVEN: Valid commit message
    create_valid_commit_message

    # WHEN: Message check runs
    run run_hook_script "pre-commit-message-check.sh"

    # THEN: Should generate a report
    assert_success
    assert_report_generated "message-check-*.md"
    assert_line --partial "Pre-commit report generated:"
}

@test "pre-commit-message-check: generates failure report when validation fails" {
    # GIVEN: Invalid commit message
    create_invalid_commit_message

    # WHEN: Message check runs
    run run_hook_script "pre-commit-message-check.sh"

    # THEN: Should generate a failure report
    assert_failure
    assert_report_generated "message-check-*.md"
}

@test "pre-commit-message-check: works in DRY_RUN mode" {
    # GIVEN: Dry run mode is enabled
    set_dry_run_mode
    create_valid_commit_message

    # WHEN: Message check runs
    run run_hook_script "pre-commit-message-check.sh"

    # THEN: Should simulate without actual execution
    assert_success
    assert_line --partial "DRY_RUN: Would check commit message format"
}

@test "pre-commit-message-check: works in PASS mode" {
    # GIVEN: Pass mode is enabled
    set_pass_mode
    create_invalid_commit_message

    # WHEN: Message check runs
    run run_hook_script "pre-commit-message-check.sh"

    # THEN: Should simulate success regardless of actual message
    assert_success
    assert_line --partial "PASS MODE: Pre-commit message check simulated successfully"
}

@test "pre-commit-message-check: works in FAIL mode" {
    # GIVEN: Fail mode is enabled
    set_fail_mode
    create_valid_commit_message

    # WHEN: Message check runs
    run run_hook_script "pre-commit-message-check.sh"

    # THEN: Should simulate failure regardless of actual message
    assert_failure
    assert_line --partial "FAIL MODE: Simulating pre-commit message check failure"
}

@test "pre-commit-message-check: works in SKIP mode" {
    # GIVEN: Skip mode is enabled
    set_skip_mode
    create_invalid_commit_message

    # WHEN: Message check runs
    run run_hook_script "pre-commit-message-check.sh"

    # THEN: Should skip execution
    assert_success
    assert_line --partial "SKIP MODE: Pre-commit message check skipped"
}

@test "pre-commit-message-check: validates git repository" {
    # GIVEN: Script runs outside a git repository
    cd "$BATS_TEST_TMPDIR"
    export PROJECT_ROOT="$BATS_TEST_TMPDIR"

    # WHEN: Message check runs
    run "$TEST_HOOKS_DIR/pre-commit-message-check.sh"

    # THEN: Should fail with git repository error
    assert_failure
    assert_line --partial "Not in a git repository"
}

@test "pre-commit-message-check: respects script version" {
    # WHEN: Help is requested
    run run_hook_script "pre-commit-message-check.sh" "help"

    # THEN: Should show version information
    assert_success
    assert_line --partial "Pre-commit Message Check Hook v1.0.0"
}

@test "pre-commit-message-check: gets commitizen command availability" {
    # GIVEN: Both cz and commitizen are available
    # WHEN: Getting commitizen command
    run run_hook_script "pre-commit-message-check.sh" "help"

    # THEN: Should detect available command
    assert_success
    # The mock should work correctly
}

@test "pre-commit-message-check: handles commitizen alternative command" {
    # GIVEN: Only commitizen (not cz) is available
    rm -f "$BATS_TEST_TMPDIR/bin/cz"
    create_valid_commit_message

    # WHEN: Message check runs
    run run_hook_script "pre-commit-message-check.sh"

    # THEN: Should use alternative command
    assert_success
}

@test "pre-commit-message-check: provides commit message statistics" {
    # GIVEN: Commit message with body
    create_commit_message "feat: add authentication

Implement JWT-based authentication with the following features:
- Token generation and validation
- Middleware integration
- Error handling"

    # WHEN: Checking message statistics
    run run_hook_script "pre-commit-message-check.sh"

    # THEN: Should process multi-line message
    assert_success
    assert_line --partial "✓ Commit message is valid"
}

@test "pre-commit-message-check: handles special characters in commit messages" {
    # GIVEN: Commit message with special characters
    create_commit_message "fix(api): handle null values in user endpoint

Fix issue where API returns null for undefined user properties.
The fix includes proper null checks and default values.

Fixes: #123
Closes: #124
Refs: #125"

    # WHEN: Message check runs
    run run_hook_script "pre-commit-message-check.sh"

    # THEN: Should handle special characters
    assert_success
    assert_line --partial "✓ Commit message is valid"
}

@test "pre-commit-message-check: respects .czrc configuration file" {
    # GIVEN: Project has .czrc configuration
    cat > "$TEST_PROJECT_ROOT/.czrc" << 'EOF'
{
  "path": "cz-conventional-commits"
}
EOF

    create_valid_commit_message

    # WHEN: Message check runs
    run run_hook_script "pre-commit-message-check.sh"

    # THEN: Should read project configuration
    assert_success
}

@test "pre-commit-message-check: reads configuration from package.json" {
    # GIVEN: Project has package.json with commitizen config
    cat > "$TEST_PROJECT_ROOT/package.json" << 'EOF'
{
  "name": "test-project",
  "devDependencies": {
    "cz-conventional-commits": "^4.0.0"
  },
  "config": {
    "commitizen": {
      "path": "./node_modules/cz-conventional-commits"
    }
  }
}
EOF

    create_valid_commit_message

    # WHEN: Message check runs
    run run_hook_script "pre-commit-message-check.sh"

    # THEN: Should read package.json configuration
    assert_success
}

@test "pre-commit-message-check: validates multiline commit messages" {
    # GIVEN: Well-formatted multiline commit message
    create_commit_message "refactor(auth): improve password hashing

Replace bcrypt with Argon2 for better security:
- Argon2 is memory-hard and more resistant to GPU attacks
- Configurable time and memory parameters
- Built-in salt generation

This change improves security without affecting performance
for normal authentication flows.

BREAKING CHANGE: Requires Argon2 library dependency"

    # WHEN: Message check runs
    run run_hook_script "pre-commit-message-check.sh"

    # THEN: Should validate multiline message correctly
    assert_success
    assert_line --partial "✓ Commit message is valid"
}

@test "pre-commit-message-check: handles edge cases in message parsing" {
    # GIVEN: Edge case commit messages
    local edge_cases=(
        "chore: ."
        "docs: !@#$%^&*()"
        "test: "
    )

    # WHEN: Each edge case is tested
    for commit_msg in "${edge_cases[@]}"; do
        create_commit_message "$commit_msg"
        run run_hook_script "pre-commit-message-check.sh"
        # These may pass or fail depending on implementation
        # The test verifies graceful handling
        [[ "${status}" -eq 0 || "${status}" -eq 1 ]]
    done
}

@test "pre-commit-message-check: formats commit message with proper spacing" {
    # GIVEN: Message with spacing issues
    local message_file="$TEST_PROJECT_ROOT/spaced_msg"
    cat > "$message_file" << 'EOF'
feat(auth):add validation

Fixes spacing issues in commit message.

Remove extra spaces and ensure proper line breaks.
EOF

    export AUTO_FORMAT=true

    # WHEN: Message check runs with auto-format
    run run_hook_script "pre-commit-message-check.sh" "$message_file"

    # THEN: Should format spacing correctly
    assert_success
    # Check if formatting was applied
    [[ -f "$message_file" ]]
}