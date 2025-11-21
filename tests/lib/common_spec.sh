#!/usr/bin/env bash
# ShellSpec tests for Common Utilities
# Tests the common.sh library functionality

set -euo pipefail

# Load the library under test
# shellcheck disable=SC1090,SC1091
. "$(dirname "$0")/../../../scripts/lib/common.sh" 2>/dev/null || {
  echo "Failed to source common.sh" >&2
  exit 1
}

# Setup test environment
setup_test_environment() {
  export DEBUG="${DEBUG:-false}"
  export LOG_TIMESTAMP="${LOG_TIMESTAMP:-true}"

  # Create test directory
  mkdir -p "/tmp/common-test"
}

# Cleanup test environment
cleanup_test_environment() {
  rm -rf "/tmp/common-test"
}

Describe "Common Utilities Library"
  BeforeEach "setup_test_environment"
  AfterEach "cleanup_test_environment"

  Describe "logging functions"
    Context "with timestamp enabled"
      It "should include timestamp in log output"
        When call log_info "test message"
        The output should match pattern "[*] [*] test message"
        The output should match pattern "*[*] INFO *"
      End

      It "should log debug messages when DEBUG is true"
        BeforeEach "export DEBUG=true"
        When call log_debug "debug message"
        The output should include "DEBUG"
      End

      It "should not log debug messages when DEBUG is false"
        BeforeEach "export DEBUG=false"
        When call log_debug "debug message"
        The output should not include "DEBUG"
      End
    End

    Context "with timestamp disabled"
      BeforeEach "export LOG_TIMESTAMP=false"

      It "should not include timestamp in log output"
        When call log_info "test message"
        The output should match pattern "[*] test message"
        The output should not match pattern "*[*] [*] test message"
      End
    End

    Context "different log levels"
      It "should log success messages in green"
        When call log_success "success message"
        The output should include "SUCCESS"
      End

      It "should log error messages in red"
        When call log_error "error message"
        The output should include "ERROR"
      End

      It "should log warning messages in yellow"
        When call log_warn "warning message"
        The output should include "WARN"
      End

      It "should log critical messages in purple"
        When call log_critical "critical message"
        The output should include "CRITICAL"
      End
    End
  End

  Describe "testability utilities"
    Describe "get_script_behavior"
      Context "with pipeline-level override"
        BeforeEach "export PIPELINE_SCRIPT_TEST_BEHAVIOR=DRY_RUN"

        It "should return pipeline-level behavior"
          When call get_script_behavior "test" "EXECUTE"
          The output should equal "DRY_RUN"
        End
      End

      Context "with script-specific override"
        BeforeEach "export CI_TEST_BEHAVIOR=PASS"

        It "should return script-specific behavior"
          When call get_script_behavior "test" "EXECUTE"
          The output should equal "PASS"
        End
      End

      Context "with global test mode"
        BeforeEach "export CI_TEST_MODE=SKIP"

        It "should return global test mode"
          When call get_script_behavior "test" "EXECUTE"
          The output should equal "SKIP"
        End
      End

      Context "with no overrides"
        It "should return default behavior"
          When call get_script_behavior "test" "EXECUTE"
          The output should equal "EXECUTE"
        End
      End
    End

    Describe "validate_behavior"
      It "should accept valid behavior modes"
        When call validate_behavior "EXECUTE"
        The status should be success

        When call validate_behavior "DRY_RUN"
        The status should be success

        When call validate_behavior "PASS"
        The status should be success

        When call validate_behavior "FAIL"
        The status should be success

        When call validate_behavior "SKIP"
        The status should be success

        When call validate_behavior "TIMEOUT"
        The status should be success
      End

      It "should reject invalid behavior modes"
        When call validate_behavior "INVALID"
        The status should be failure
      End
    End
  End

  Describe "environment variable utilities"
    Describe "get_env_var"
      It "should return environment variable value"
        BeforeEach "export TEST_VAR=test_value"

        When call get_env_var "TEST_VAR"
        The output should equal "test_value"
      End

      It "should return default value when variable not set"
        When call get_env_var "UNSET_VAR" "default_value"
        The output should equal "default_value"
      End
    End

    Describe "validate_required_env"
      It "should succeed when required variable is set"
        BeforeEach "export REQUIRED_VAR=set_value"

        When call validate_required_env "REQUIRED_VAR" "test variable"
        The status should be success
      End

      It "should fail when required variable is not set"
        When call validate_required_env "MISSING_VAR" "test variable"
        The status should be failure
      End
    End
  End

  Describe "file and directory utilities"
    Describe "ensure_directory"
      It "should create directory if it doesn't exist"
        local test_dir="/tmp/common-test/new-dir"
        When call ensure_directory "$test_dir" "test directory"
        The path "$test_dir" should be directory
      End

      It "should not fail if directory already exists"
        local test_dir="/tmp/common-test/existing-dir"
        mkdir -p "$test_dir"
        When call ensure_directory "$test_dir" "test directory"
        The path "$test_dir" should be directory
      End
    End

    Describe "ensure_file_exists"
      It "should succeed when file exists"
        local test_file="/tmp/common-test/test-file.txt"
        echo "test content" > "$test_file"
        When call ensure_file_exists "$test_file" "test file"
        The status should be success
      End

      It "should fail when file doesn't exist"
        When call ensure_file_exists "/tmp/nonexistent-file.txt" "nonexistent file"
        The status should be failure
      End
    End

    Describe "safe_remove"
      It "should remove existing file or directory"
        local test_file="/tmp/common-test/remove-test.txt"
        echo "test" > "$test_file"
        When call safe_remove "$test_file" "test file"
        The path "$test_file" should not be exist
      End

      It "should not fail when path doesn't exist"
        When call safe_remove "/tmp/nonexistent" "nonexistent path"
        The status should be success
      End
    End
  End

  Describe "git utilities"
    BeforeEach "cd /tmp/common-test && git init >/dev/null 2>&1 && git config user.email 'test@example.com' && git config user.name 'Test User' && echo 'test' > test.txt && git add test.txt && git commit -m 'initial commit' >/dev/null 2>&1"

    Describe "get_git_info"
      It "should get commit hash"
        When call get_git_info "commit"
        The output should match pattern "^[a-f0-9]{40}$"
      End

      It "should get branch name"
        When call get_git_info "branch"
        The output should equal "main"
      End

      It "should get remote URL"
        When call get_git_info "remote"
        The output should equal "unknown"
      End

      It "should get tag information"
        When call get_git_info "tag"
        The output should equal "none"
      End

      It "should check if working tree is clean"
        When call get_git_info "is_clean"
        The output should equal "true"
      End
    End
  End

  Describe "string utilities"
    Describe "trim"
      It "should trim leading and trailing whitespace"
        When call trim "  test string  "
        The output should equal "test string"
      End

      It "should handle empty strings"
        When call trim ""
        The output should equal ""
      End
    End

    Describe "string_to_lower"
      It "should convert string to lowercase"
        When call string_to_lower "Test STRING"
        The output should equal "test string"
      End
    End

    Describe "string_to_upper"
      It "should convert string to uppercase"
        When call string_to_upper "test string"
        The output should equal "TEST STRING"
      End
    End
  End

  Describe "array utilities"
    Describe "array_contains"
      It "should return true when item is in array"
        When call array_contains "apple" "banana" "cherry" "apple"
        The status should be success
      End

      It "should return false when item is not in array"
        When call array_contains "orange" "banana" "cherry" "apple"
        The status should be failure
      End

      It "should handle empty arrays"
        When call array_contains "test"
        The status should be failure
      End
    End
  End

  Describe "time utilities"
    Describe "get_timestamp"
      It "should return ISO 8601 timestamp"
        When call get_timestamp
        The output should match pattern "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$"
      End
    End

    Describe "get_duration_seconds"
      It "should calculate duration between timestamps"
        local start_time=$(date +%s)
        sleep 1
        When call get_duration_seconds "$start_time"
        The output should match pattern "^[1-9]"
      End
    End

    Describe "format_duration"
      It "should format seconds as human readable duration"
        When call format_duration "3661"
        The output should equal "1h 1m 1s"
      End

      It "should handle minutes only"
        When call format_duration "125"
        The output should equal "2m 5s"
      End

      It "should handle seconds only"
        When call format_duration "45"
        The output should equal "45s"
      End
    End
  End

  Describe "validation utilities"
    Describe "validate_semver"
      It "should accept valid semantic versions"
        When call validate_semver "1.2.3"
        The status should be success

        When call validate_semver "10.20.30"
        The status should be success

        When call validate_semver "1.2.3-beta.1"
        The status should be success

        When call validate_semver "1.2.3+build.123"
        The status should be success
      End

      It "should reject invalid semantic versions"
        When call validate_semver "1.2"
        The status should be failure

        When call validate_semver "v1.2.3"
        The status should be failure

        When call validate_semver "invalid"
        The status should be failure
      End
    End

    Describe "validate_tag_format"
      It "should accept valid version tags"
        When call validate_tag_format "v1.2.3" "version"
        The status should be success
      End

      It "should accept valid environment tags"
        When call validate_tag_format "production" "environment"
        The status should be success

        When call validate_tag_format "staging" "environment"
        The status should be success
      End

      It "should accept valid state tags"
        When call validate_tag_format "v1.2.3-stable" "state"
        The status should be success

        When call validate_tag_format "v2.0.0-unstable" "state"
        The status should be success
      End

      It "should reject invalid tags"
        When call validate_tag_format "invalid" "version"
        The status should be failure

        When call validate_tag_format "invalid-env" "environment"
        The status should be failure
      End
    End
  End

  Describe "security utilities"
    Describe "sanitize_input"
      It "should sanitize alphanumeric input"
        When call sanitize_input "test123ABC" "alphanumeric"
        The output should equal "test123ABC"
      End

      It "should sanitize filename input"
        When call sanitize_input "test_file-123.txt" "filename"
        The output should equal "test_file-123.txt"
      End

      It "should sanitize URL input"
        When call sanitize_input "https://example.com/path?param=value" "url"
        The output should equal "https://example.com/pathparam=value"
      End
    End
  End
End