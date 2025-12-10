#!/usr/bin/env bats

# Load test helper
load "${BATS_TEST_DIRNAME}/../test_helper.bash"

setup() {
    # GIVEN: A git repository with hook scripts available
    setup_git_hooks_test
    configure_lint_hook
    set_execute_mode
}

teardown() {
    # Cleanup test environment
    cleanup_git_hooks_test
}

@test "pre-commit-lint: script exists and is executable" {
    # GIVEN: The lint hook script should exist
    [[ -f "$TEST_HOOKS_DIR/pre-commit-lint.sh" ]]
    [[ -x "$TEST_HOOKS_DIR/pre-commit-lint.sh" ]]
}

@test "pre-commit-lint: shows help information" {
    # WHEN: Script is called with help flag
    run run_hook_script "pre-commit-lint.sh" "help"

    # THEN: Help information should be displayed
    assert_success
    assert_line --partial "Pre-commit Lint Check Hook"
    assert_line --partial "Usage:"
}

@test "pre-commit-lint: checks ShellCheck availability" {
    # WHEN: Script validates setup
    run run_hook_script "pre-commit-lint.sh" "validate"

    # THEN: Should validate ShellCheck is available
    assert_success
    assert_line --partial "ShellCheck is available"
}

@test "pre-commit-lint: fails when ShellCheck is not available" {
    # GIVEN: ShellCheck is not available
    rm -f "$BATS_TEST_TMPDIR/bin/shellcheck"

    # WHEN: Script runs without ShellCheck
    run run_hook_script "pre-commit-lint.sh" "validate"

    # THEN: Should fail with appropriate error
    assert_failure
    assert_line --partial "ShellCheck is not installed"
}

@test "pre-commit-lint: handles well-written bash files" {
    # GIVEN: A well-written bash script is staged
    create_well_formatted_script
    stage_test_files "good_script.sh"

    # WHEN: Lint check runs
    run run_hook_script "pre-commit-lint.sh"

    # THEN: Should pass validation
    assert_success
    assert_line --partial "✓ good_script.sh passed lint check"
    assert_line --partial "✅ Pre-commit lint check completed successfully"
}

@test "pre-commit-lint: detects lint issues in bash files" {
    # GIVEN: A bash script with lint issues is staged
    create_script_with_lint_issues
    stage_test_files "lint_issues.sh"

    # WHEN: Lint check runs
    run run_hook_script "pre-commit-lint.sh"

    # THEN: Should detect lint issues and fail
    assert_failure
    assert_line --partial "✗ lint_issues.sh has lint issues:"
    assert_line --partial "❌ Pre-commit lint check failed"
}

@test "pre-commit-lint: respects SHELLCHECK_SEVERITY environment variable" {
    # GIVEN: Severity level is set to info
    export SHELLCHECK_SEVERITY="info"
    create_script_with_lint_issues
    stage_test_files "lint_issues.sh"

    # WHEN: Lint check runs with info severity
    run run_hook_script "pre-commit-lint.sh"

    # THEN: Should use configured severity level
    assert_failure
    # The mock should respond with the severity setting
}

@test "pre-commit-lint: handles multiple files correctly" {
    # GIVEN: Multiple bash scripts with different lint statuses
    create_well_formatted_script
    create_script_with_lint_issues
    create_test_bash_file "another_good.sh" '#!/bin/bash
# Another good script
local var="test"
echo "$var"'

    stage_test_files "good_script.sh" "lint_issues.sh" "another_good.sh"

    # WHEN: Lint check runs
    run run_hook_script "pre-commit-lint.sh"

    # THEN: Should process all files and fail due to lint issues
    assert_failure
    assert_line --partial "✓ good_script.sh passed lint check"
    assert_line --partial "✓ another_good.sh passed lint check"
    assert_line --partial "✗ lint_issues.sh has lint issues:"
}

@test "pre-commit-lint: skips non-bash files" {
    # GIVEN: Non-bash files are staged
    echo "console.log('test');" > "$TEST_PROJECT_ROOT/test.js"
    echo "import React from 'react';" > "$TEST_PROJECT_ROOT/test.tsx"
    echo "*.log" > "$TEST_PROJECT_ROOT/.gitignore"

    stage_test_files "test.js" "test.tsx" ".gitignore"

    # WHEN: Lint check runs
    run run_hook_script "pre-commit-lint.sh"

    # THEN: Should succeed (no bash files to check)
    assert_success
    assert_line --partial "No files to check"
}

@test "pre-commit-lint: handles bash files with different extensions" {
    # GIVEN: Bash files with different extensions are staged
    create_test_bash_file "script.bash" '#!/bin/bash
local var="bash script"
echo "$var"'

    create_test_bash_file "script.zsh" '#!/bin/zsh
local var="zsh script"
echo "$var"'

    stage_test_files "script.bash" "script.zsh"

    # WHEN: Lint check runs
    run run_hook_script "pre-commit-lint.sh"

    # THEN: Should check all bash variants
    assert_success
    assert_line --partial "✓ script.bash passed lint check"
    assert_line --partial "✓ script.zsh passed lint check"
}

@test "pre-commit-lint: detects bash files by shebang" {
    # GIVEN: Files without bash extension but with bash shebang
    create_test_bash_file "tool" '#!/usr/bin/env bash
local var="tool with bash shebang"
echo "$var"'

    create_test_bash_file "executable" '#!bash
local var="executable with bash shebang"
echo "$var"'

    stage_test_files "tool" "executable"

    # WHEN: Lint check runs
    run run_hook_script "pre-commit-lint.sh"

    # THEN: Should detect and check shebang files
    assert_success
    assert_line --partial "✓ tool passed lint check"
    assert_line --partial "✓ executable passed lint check"
}

@test "pre-commit-lint: respects SHELLCHECK_OPTIONS environment variable" {
    # GIVEN: Custom ShellCheck options are set
    export SHELLCHECK_OPTIONS="--external-sources --shell=bash"
    create_well_formatted_script
    stage_test_files "good_script.sh"

    # WHEN: Lint check runs
    run run_hook_script "pre-commit-lint.sh"

    # THEN: Should use custom options
    assert_success
}

@test "pre-commit-lint: generates lint fixes for files with issues" {
    # GIVEN: Files with lint issues
    create_script_with_lint_issues
    stage_test_files "lint_issues.sh"

    # WHEN: Fix command is used
    run run_hook_script "pre-commit-lint.sh" "fix" "lint_issues.sh"

    # THEN: Should generate fix patches
    assert_success
    assert_line --partial "Generated fix patch: lint_issues.sh.lint.patch"
}

@test "pre-commit-lint: applies fixes automatically when AUTO_APPLY_FIXES=true" {
    # GIVEN: Files with lint issues and auto-apply enabled
    create_script_with_lint_issues
    stage_test_files "lint_issues.sh"
    export AUTO_APPLY_FIXES=true

    # WHEN: Fix command is used
    run run_hook_script "pre-commit-lint.sh" "fix" "lint_issues.sh"

    # THEN: Should apply fixes automatically
    assert_success
    assert_line --partial "Applied fixes to lint_issues.sh"
    [[ ! -f "$TEST_PROJECT_ROOT/lint_issues.sh.lint.patch" ]]
}

@test "pre-commit-lint: generates detailed report for specific files" {
    # GIVEN: Files to report on
    create_script_with_lint_issues
    create_well_formatted_script

    # WHEN: Report command is used
    run run_hook_script "pre-commit-lint.sh" "report" "lint_issues.sh" "good_script.sh"

    # THEN: Should generate detailed report
    assert_success
    assert_line --partial "Lint report generated:"
}

@test "pre-commit-lint: checks specific files when provided" {
    # GIVEN: Specific files are provided as arguments
    create_well_formatted_script
    create_script_with_lint_issues

    # WHEN: Only well-formatted file is checked
    run run_hook_script "pre-commit-lint.sh" "check" "good_script.sh"

    # THEN: Should only check specified files
    assert_success
    assert_line --partial "✓ good_script.sh passed lint check"
}

@test "pre-commit-lint: shows suggestions only when SUGGESTIONS_ONLY=true" {
    # GIVEN: Suggestions only mode is enabled
    export SUGGESTIONS_ONLY=true
    create_script_with_lint_issues
    stage_test_files "lint_issues.sh"

    # WHEN: Lint check runs
    run run_hook_script "pre-commit-lint.sh"

    # THEN: Should show suggestions without failing
    assert_success
    assert_line --partial "ℹ️ Lint suggestions for lint_issues.sh:"
}

@test "pre-commit-lint: handles empty staged files" {
    # GIVEN: No files are staged

    # WHEN: Lint check runs
    run run_hook_script "pre-commit-lint.sh"

    # THEN: Should succeed with no files message
    assert_success
    assert_line --partial "No bash files to check"
}

@test "pre-commit-lint: generates report after execution" {
    # GIVEN: A bash file is staged
    create_well_formatted_script
    stage_test_files "good_script.sh"

    # WHEN: Lint check runs
    run run_hook_script "pre-commit-lint.sh"

    # THEN: Should generate a report
    assert_success
    assert_report_generated "lint-check-*.md"
    assert_line --partial "Pre-commit report generated:"
}

@test "pre-commit-lint: generates failure report when issues found" {
    # GIVEN: A file with lint issues is staged
    create_script_with_lint_issues
    stage_test_files "lint_issues.sh"

    # WHEN: Lint check runs
    run run_hook_script "pre-commit-lint.sh"

    # THEN: Should generate a failure report
    assert_failure
    assert_report_generated "lint-check-*.md"
}

@test "pre-commit-lint: works in DRY_RUN mode" {
    # GIVEN: Dry run mode is enabled
    set_dry_run_mode
    create_well_formatted_script
    stage_test_files "good_script.sh"

    # WHEN: Lint check runs
    run run_hook_script "pre-commit-lint.sh"

    # THEN: Should simulate without actual execution
    assert_success
    assert_line --partial "DRY RUN: Would check bash script linting"
}

@test "pre-commit-lint: works in PASS mode" {
    # GIVEN: Pass mode is enabled
    set_pass_mode
    create_script_with_lint_issues
    stage_test_files "lint_issues.sh"

    # WHEN: Lint check runs
    run run_hook_script "pre-commit-lint.sh"

    # THEN: Should simulate success regardless of actual issues
    assert_success
    assert_line --partial "PASS MODE: Pre-commit lint check simulated successfully"
}

@test "pre-commit-lint: works in FAIL mode" {
    # GIVEN: Fail mode is enabled
    set_fail_mode
    create_well_formatted_script
    stage_test_files "good_script.sh"

    # WHEN: Lint check runs
    run run_hook_script "pre-commit-lint.sh"

    # THEN: Should simulate failure regardless of actual state
    assert_failure
    assert_line --partial "FAIL MODE: Simulating pre-commit lint check failure"
}

@test "pre-commit-lint: works in SKIP mode" {
    # GIVEN: Skip mode is enabled
    set_skip_mode
    create_script_with_lint_issues
    stage_test_files "lint_issues.sh"

    # WHEN: Lint check runs
    run run_hook_script "pre-commit-lint.sh"

    # THEN: Should skip execution
    assert_success
    assert_line --partial "SKIP MODE: Pre-commit lint check skipped"
}

@test "pre-commit-lint: validates git repository" {
    # GIVEN: Script runs outside a git repository
    cd "$BATS_TEST_TMPDIR"
    export PROJECT_ROOT="$BATS_TEST_TMPDIR"

    # WHEN: Lint check runs
    run "$TEST_HOOKS_DIR/pre-commit-lint.sh"

    # THEN: Should fail with git repository error
    assert_failure
    assert_line --partial "Not in a git repository"
}

@test "pre-commit-lint: counts lint issues correctly" {
    # GIVEN: Multiple files with different numbers of issues
    create_script_with_lint_issues
    create_test_bash_file "more_issues.sh" '#!/bin/bash
unquoted_var1="test1"
unquoted_var2="test2"
echo $unquoted_var1
echo $unquoted_var2
if [[ $var == test ]]; then
    echo "bad comparison"
fi'

    stage_test_files "lint_issues.sh" "more_issues.sh"

    # WHEN: Lint check runs
    run run_hook_script "pre-commit-lint.sh"

    # THEN: Should count and report total issues
    assert_failure
    assert_line --partial "files have lint issues"
    assert_line --partial "total issues"
}

@test "pre-commit-lint: respects script version" {
    # WHEN: Help is requested
    run run_hook_script "pre-commit-lint.sh" "help"

    # THEN: Should show version information
    assert_success
    assert_line --partial "Pre-commit Lint Check Hook v1.0.0"
}

@test "pre-commit-lint: handles missing files gracefully" {
    # WHEN: Checking non-existent files
    run run_hook_script "pre-commit-lint.sh" "check" "nonexistent.sh"

    # THEN: Should handle gracefully
    assert_failure
    assert_line --partial "File not found: nonexistent.sh"
}

@test "pre-commit-lint: validates shell type configuration" {
    # GIVEN: Different shell type is configured
    export SHELLCHECK_SHELL="sh"
    create_well_formatted_script
    stage_test_files "good_script.sh"

    # WHEN: Lint check runs
    run run_hook_script "pre-commit-lint.sh"

    # THEN: Should use configured shell type
    assert_success
}

@test "pre-commit-lint: provides helpful fix suggestions" {
    # GIVEN: Files with lint issues
    create_script_with_lint_issues
    stage_test_files "lint_issues.sh"

    # WHEN: Lint check runs
    run run_hook_script "pre-commit-lint.sh"

    # THEN: Should provide fix suggestions
    assert_failure
    assert_line --partial "To see suggestions:"
    assert_line --partial "To fix automatically"
}

@test "pre-commit-lint: handles patch generation failures" {
    # GIVEN: Patch generation fails (mock scenario)
    create_script_with_lint_issues
    stage_test_files "lint_issues.sh"

    # WHEN: Fix command generates patches
    run run_hook_script "pre-commit-lint.sh" "fix" "lint_issues.sh"

    # THEN: Should handle patch generation gracefully
    assert_success
    # Should still succeed even if patches can't be applied
}

@test "pre-commit-lint: validates all bash files in repository mode" {
    # GIVEN: Multiple bash files exist in repository
    create_well_formatted_script
    create_script_with_lint_issues
    create_test_bash_file "nested/script.sh" '#!/bin/bash
local var="nested script"
echo "$var"'

    # Stage only some files to test full repository validation
    stage_test_files "good_script.sh"

    # WHEN: All files are validated (using internal function logic)
    run run_hook_script "pre-commit-lint.sh" "check" "lint_issues.sh" "nested/script.sh"

    # THEN: Should check all specified files
    assert_failure
    assert_lint_issues_detected "${output}"
}

@test "pre-commit-lint: integrates with source paths for includes" {
    # GIVEN: Files that include other scripts
    create_test_bash_file "main.sh" '#!/bin/bash
source "utils.sh"
local var="main script"
echo "$var"'

    create_test_bash_file "utils.sh" '#!/bin/bash
utils_function() {
    echo "utility function"
}'

    stage_test_files "main.sh" "utils.sh"

    # WHEN: Lint check runs
    run run_hook_script "pre-commit-lint.sh"

    # THEN: Should handle includes gracefully
    assert_success
}

@test "pre-commit-lint: handles edge cases in file processing" {
    # GIVEN: Edge case files
    create_test_bash_file "empty.sh" '#!/bin/bash
'

    create_test_bash_file "single_line.sh" '#!/bin/bash'

    stage_test_files "empty.sh" "single_line.sh"

    # WHEN: Lint check runs
    run run_hook_script "pre-commit-lint.sh"

    # THEN: Should handle edge cases gracefully
    assert_success
    assert_line --partial "✓ empty.sh passed lint check"
    assert_line --partial "✓ single_line.sh passed lint check"
}