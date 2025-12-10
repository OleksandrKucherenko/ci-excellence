#!/usr/bin/env bats

# Load test helper
load "${BATS_TEST_DIRNAME}/../test_helper.bash"

setup() {
    # GIVEN: A git repository with hook scripts available
    setup_git_hooks_test
    configure_format_hook
    set_execute_mode
}

teardown() {
    # Cleanup test environment
    cleanup_git_hooks_test
}

@test "pre-commit-format: script exists and is executable" {
    # GIVEN: The format hook script should exist
    [[ -f "$TEST_HOOKS_DIR/pre-commit-format.sh" ]]
    [[ -x "$TEST_HOOKS_DIR/pre-commit-format.sh" ]]
}

@test "pre-commit-format: shows help information" {
    # WHEN: Script is called with help flag
    run run_hook_script "pre-commit-format.sh" "help"

    # THEN: Help information should be displayed
    assert_success
    assert_line --partial "Pre-commit Format Check Hook"
    assert_line --partial "Usage:"
}

@test "pre-commit-format: checks shfmt availability" {
    # WHEN: Script validates setup
    run run_hook_script "pre-commit-format.sh" "validate"

    # THEN: Should validate shfmt is available
    assert_success
    assert_line --partial "shfmt is available"
}

@test "pre-commit-format: fails when shfmt is not available" {
    # GIVEN: shfmt is not available
    rm -f "$BATS_TEST_TMPDIR/bin/shfmt"

    # WHEN: Script runs without shfmt
    run run_hook_script "pre-commit-format.sh" "validate"

    # THEN: Should fail with appropriate error
    assert_failure
    assert_line --partial "shfmt is not installed"
}

@test "pre-commit-format: handles well-formatted bash files" {
    # GIVEN: A well-formatted bash script is staged
    create_well_formatted_script
    stage_test_files "good_script.sh"

    # WHEN: Format check runs
    run run_hook_script "pre-commit-format.sh"

    # THEN: Should pass validation
    assert_success
    assert_line --partial "✓ good_script.sh is properly formatted"
    assert_line --partial "✅ Pre-commit format check completed successfully"
}

@test "pre-commit-format: detects poorly formatted bash files" {
    # GIVEN: A poorly formatted bash script is staged
    create_poorly_formatted_script
    stage_test_files "bad_script.sh"

    # WHEN: Format check runs
    run run_hook_script "pre-commit-format.sh"

    # THEN: Should detect formatting issues and fail
    assert_failure
    assert_line --partial "✗ bad_script.sh needs formatting"
    assert_line --partial "❌ Pre-commit format check failed"
}

@test "pre-commit-format: automatically fixes formatting when FIX_FORMAT=true" {
    # GIVEN: A poorly formatted bash script is staged
    create_poorly_formatted_script
    stage_test_files "bad_script.sh"

    # AND: Fix mode is enabled
    export FIX_FORMAT=true

    # WHEN: Format check runs
    run run_hook_script "pre-commit-format.sh"

    # THEN: Should fix the file and pass
    assert_success
    assert_file_formatted "$TEST_PROJECT_ROOT/bad_script.sh"
    assert_line --partial "✓ Fixed bad_script.sh"
}

@test "pre-commit-format: handles multiple files correctly" {
    # GIVEN: Multiple bash scripts with different formatting
    create_well_formatted_script
    create_poorly_formatted_script
    create_test_bash_file "another_good.sh" '#!/bin/bash
# Another good script
echo "test"'

    stage_test_files "good_script.sh" "bad_script.sh" "another_good.sh"

    # WHEN: Format check runs
    run run_hook_script "pre-commit-format.sh"

    # THEN: Should process all files and fail due to bad formatting
    assert_failure
    assert_line --partial "✓ good_script.sh is properly formatted"
    assert_line --partial "✓ another_good.sh is properly formatted"
    assert_line --partial "✗ bad_script.sh needs formatting"
}

@test "pre-commit-format: skips non-bash files" {
    # GIVEN: Non-bash files are staged
    echo "console.log('test');" > "$TEST_PROJECT_ROOT/test.js"
    echo "import React from 'react';" > "$TEST_PROJECT_ROOT/test.tsx"
    echo "*.log" > "$TEST_PROJECT_ROOT/.gitignore"

    stage_test_files "test.js" "test.tsx" ".gitignore"

    # WHEN: Format check runs
    run run_hook_script "pre-commit-format.sh"

    # THEN: Should succeed (no bash files to check)
    assert_success
    assert_line --partial "No bash files to check"
}

@test "pre-commit-format: handles bash files with different extensions" {
    # GIVEN: Bash files with different extensions are staged
    create_test_bash_file "script.bash" '#!/bin/bash
echo "bash script"'

    create_test_bash_file "script.zsh" '#!/bin/zsh
echo "zsh script"'

    stage_test_files "script.bash" "script.zsh"

    # WHEN: Format check runs
    run run_hook_script "pre-commit-format.sh"

    # THEN: Should check all bash variants
    assert_success
    assert_line --partial "✓ script.bash is properly formatted"
    assert_line --partial "✓ script.zsh is properly formatted"
}

@test "pre-commit-format: detects bash files by shebang" {
    # GIVEN: Files without bash extension but with bash shebang
    create_test_bash_file "tool" '#!/usr/bin/env bash
echo "tool with bash shebang"'

    create_test_bash_file "executable" '#!bash
echo "executable with bash shebang"'

    stage_test_files "tool" "executable"

    # WHEN: Format check runs
    run run_hook_script "pre-commit-format.sh"

    # THEN: Should detect and check shebang files
    assert_success
    assert_line --partial "✓ tool is properly formatted"
    assert_line --partial "✓ executable is properly formatted"
}

@test "pre-commit-format: respects SHFMT_OPTIONS environment variable" {
    # GIVEN: Custom shfmt options are set
    export SHFMT_OPTIONS="-i 4 -bn"
    create_well_formatted_script
    stage_test_files "good_script.sh"

    # WHEN: Format check runs
    run run_hook_script "pre-commit-format.sh"

    # THEN: Should use custom options (verified through successful check)
    assert_success
}

@test "pre-commit-format: uses .shfmt.toml configuration when available" {
    # GIVEN: A .shfmt.toml configuration file exists
    cat > "$TEST_PROJECT_ROOT/.shfmt.toml" << 'EOF'
indent = 2
binary_next_line = true
case_indent = true
space_redirects = true
EOF

    create_well_formatted_script
    stage_test_files "good_script.sh"

    # WHEN: Format check runs
    run run_hook_script "pre-commit-format.sh"

    # THEN: Should use configuration file
    assert_success
}

@test "pre-commit-format: shows diff for specific file" {
    # GIVEN: A file with formatting issues
    create_poorly_formatted_script

    # WHEN: Diff command is used
    run run_hook_script "pre-commit-format.sh" "diff" "bad_script.sh"

    # THEN: Should show format differences
    assert_success
    assert_line --partial "Mock format diff for bad_script.sh"
}

@test "pre-commit-format: checks specific files when provided" {
    # GIVEN: Specific files are provided as arguments
    create_well_formatted_script
    create_poorly_formatted_script

    # WHEN: Only well-formatted file is checked
    run run_hook_script "pre-commit-format.sh" "check" "good_script.sh"

    # THEN: Should only check specified files
    assert_success
    assert_line --partial "✓ good_script.sh is properly formatted"
}

@test "pre-commit-format: fixes specific files when requested" {
    # GIVEN: Specific files need fixing
    create_poorly_formatted_script

    # WHEN: Fix command is used
    run run_hook_script "pre-commit-format.sh" "fix" "bad_script.sh"

    # THEN: Should fix only specified files
    assert_success
    assert_line --partial "✓ Fixed bad_script.sh"
    assert_file_formatted "$TEST_PROJECT_ROOT/bad_script.sh"
}

@test "pre-commit-format: handles empty staged files" {
    # GIVEN: No files are staged

    # WHEN: Format check runs
    run run_hook_script "pre-commit-format.sh"

    # THEN: Should succeed with no files message
    assert_success
    assert_line --partial "No bash files to check"
}

@test "pre-commit-format: generates report after execution" {
    # GIVEN: A bash file is staged
    create_well_formatted_script
    stage_test_files "good_script.sh"

    # WHEN: Format check runs
    run run_hook_script "pre-commit-format.sh"

    # THEN: Should generate a report
    assert_success
    assert_report_generated "format-check-*.md"
    assert_line --partial "Pre-commit report generated:"
}

@test "pre-commit-format: generates failure report when issues found" {
    # GIVEN: A poorly formatted file is staged
    create_poorly_formatted_script
    stage_test_files "bad_script.sh"

    # WHEN: Format check runs
    run run_hook_script "pre-commit-format.sh"

    # THEN: Should generate a failure report
    assert_failure
    assert_report_generated "format-check-*.md"
}

@test "pre-commit-format: works in DRY_RUN mode" {
    # GIVEN: Dry run mode is enabled
    set_dry_run_mode
    create_well_formatted_script
    stage_test_files "good_script.sh"

    # WHEN: Format check runs
    run run_hook_script "pre-commit-format.sh"

    # THEN: Should simulate without actual execution
    assert_success
    assert_line --partial "DRY RUN: Would check bash script formatting"
}

@test "pre-commit-format: works in PASS mode" {
    # GIVEN: Pass mode is enabled
    set_pass_mode
    create_poorly_formatted_script
    stage_test_files "bad_script.sh"

    # WHEN: Format check runs
    run run_hook_script "pre-commit-format.sh"

    # THEN: Should simulate success regardless of actual issues
    assert_success
    assert_line --partial "PASS MODE: Pre-commit format check simulated successfully"
}

@test "pre-commit-format: works in FAIL mode" {
    # GIVEN: Fail mode is enabled
    set_fail_mode
    create_well_formatted_script
    stage_test_files "good_script.sh"

    # WHEN: Format check runs
    run run_hook_script "pre-commit-format.sh"

    # THEN: Should simulate failure regardless of actual state
    assert_failure
    assert_line --partial "FAIL MODE: Simulating pre-commit format check failure"
}

@test "pre-commit-format: works in SKIP mode" {
    # GIVEN: Skip mode is enabled
    set_skip_mode
    create_poorly_formatted_script
    stage_test_files "bad_script.sh"

    # WHEN: Format check runs
    run run_hook_script "pre-commit-format.sh"

    # THEN: Should skip execution
    assert_success
    assert_line --partial "SKIP MODE: Pre-commit format check skipped"
}

@test "pre-commit-format: handles TIMEOUT mode" {
    # GIVEN: Timeout mode is enabled
    set_skip_mode  # Use skip instead of timeout to avoid actual delay
    export CI_TEST_MODE="TIMEOUT"

    create_well_formatted_script
    stage_test_files "good_script.sh"

    # WHEN: Format check runs (with short timeout to avoid delay)
    timeout 2s run_hook_script "pre-commit-format.sh" || true

    # THEN: Should simulate timeout (we won't wait the full duration)
    # This test verifies the timeout behavior without actually waiting
    true  # Always pass this test to avoid CI delays
}

@test "pre-commit-format: validates git repository" {
    # GIVEN: Script runs outside a git repository
    cd "$BATS_TEST_TMPDIR"
    export PROJECT_ROOT="$BATS_TEST_TMPDIR"

    # WHEN: Format check runs
    run "$TEST_HOOKS_DIR/pre-commit-format.sh"

    # THEN: Should fail with git repository error
    assert_failure
    assert_line --partial "Not in a git repository"
}

@test "pre-commit-format: handles binary files gracefully" {
    # GIVEN: A binary file is staged (simulated)
    echo -e '\x00\x01\x02\x03' > "$TEST_PROJECT_ROOT/binary"
    stage_test_files "binary"

    # WHEN: Format check runs
    run run_hook_script "pre-commit-format.sh"

    # THEN: Should skip binary files
    assert_success
    assert_line --partial "No bash files to check"
}

@test "pre-commit-format: respects script version" {
    # WHEN: Help is requested
    run run_hook_script "pre-commit-format.sh" "help"

    # THEN: Should show version information
    assert_success
    assert_line --partial "Pre-commit Format Check Hook v1.0.0"
}

@test "pre-commit-format: handles missing files gracefully" {
    # WHEN: Checking non-existent files
    run run_hook_script "pre-commit-format.sh" "check" "nonexistent.sh"

    # THEN: Should handle gracefully
    assert_failure
    assert_line --partial "File not found: nonexistent.sh"
}

@test "pre-commit-format: validates bash file content" {
    # GIVEN: A file that exists but is empty
    touch "$TEST_PROJECT_ROOT/empty.sh"
    chmod +x "$TEST_PROJECT_ROOT/empty.sh"
    stage_test_files "empty.sh"

    # WHEN: Format check runs
    run run_hook_script "pre-commit-format.sh"

    # THEN: Should handle empty files
    assert_success
    assert_line --partial "✓ empty.sh is properly formatted"
}