#!/usr/bin/env bash
# ShellSpec tests for Pre-push Tag Protection Hook
# Tests the tag protection logic for preventing manual environment tag assignments

set -euo pipefail

# Load the script under test
# shellcheck disable=SC1090,SC1091
. "$(dirname "$0")/../../../scripts/hooks/pre-push-tag-protection.sh" 2>/dev/null || {
  echo "Failed to source pre-push-tag-protection.sh" >&2
  exit 1
}

# Setup test environment
setup_test_environment() {
  # Create test directory
  mkdir -p "/tmp/tag-protection-test"
  cd "/tmp/tag-protection-test"

  # Initialize git repository
  git init >/dev/null 2>&1
  git config user.email "test@example.com"
  git config user.name "Test User"

  # Create initial commit
  echo "test content" > test.txt
  git add test.txt
  git commit -m "Initial commit" >/dev/null 2>&1

  # Create test hooks directory
  mkdir -p ".git/hooks"

  # Set test environment variables
  export TAG_PROTECTION_MODE="${TAG_PROTECTION_MODE:-ENFORCE}"
  export DEBUG="${DEBUG:-false}"
}

# Cleanup test environment
cleanup_test_environment() {
  cd - >/dev/null
  rm -rf "/tmp/tag-protection-test"
}

# Mock git commands for testing
mock_git_commands() {
  git() {
    case "$1" in
      "tag")
        case "$2" in
          "-l")
            echo "v1.0.0"
            echo "v1.1.0"
            echo "v1.2.0-testing"
            echo "production"
            echo "staging"
            echo "feature/branch-name"
            ;;
          "-a")
            # Mock tag creation
            shift 2
            echo "Created tag: $*"
            ;;
          "-d")
            # Mock tag deletion
            shift 2
            echo "Deleted tag: $1"
            ;;
          *)
            echo "git tag $*"
            ;;
        esac
        ;;
      "rev-parse")
        if [[ "$2" == "--git-dir" ]]; then
          echo ".git"
        else
          echo "abc123def456"
        fi
        ;;
      "show-ref")
        echo "abc123def456 refs/tags/v1.2.0"
        echo "def456abc123 refs/tags/production"
        ;;
      "log")
        echo "commit abc123def456"
        echo "Author: Test User <test@example.com>"
        echo "Date: Thu Nov 21 10:30:00 2025 +0000"
        echo ""
        echo "    Test commit message"
        ;;
      "diff")
        echo "diff --git a/.git/refs/tags/production b/.git/refs/tags/production"
        ;;
      *)
        echo "git $*"
        ;;
    esac
  }
}

# Mock logging functions
mock_logging_functions() {
  log_info() {
    echo "[INFO] $*"
  }

  log_success() {
    echo "[SUCCESS] $*"
  }

  log_error() {
    echo "[ERROR] $*"
  }

  log_warn() {
    echo "[WARN] $*"
  }

  log_debug() {
    echo "[DEBUG] $*"
  }
}

Describe "Pre-push Tag Protection Hook"
  BeforeEach "setup_test_environment"
  BeforeEach "mock_git_commands"
  BeforeEach "mock_logging_functions"
  AfterEach "cleanup_test_environment"

  Describe "tag pattern validation"
    Context "when validating allowed tags"
      It "should allow version tags"
        When call validate_tag_pattern "v1.2.3"
        The status should be success
      End

      It "should allow version tags with prerelease"
        When call validate_tag_pattern "v1.2.3-alpha.1"
        The status should be success
      End

      It "should allow version tags with build metadata"
        When call validate_tag_pattern "v1.2.3+build.123"
        The status should be success
      End

      It "should allow state tags"
        When call validate_tag_pattern "abc123-testing"
        The status should be success
      End

      It "should allow state tags with stable"
        When call validate_tag_pattern "def456-stable"
        The status should be success
      End

      It "should allow state tags with unstable"
        When call validate_tag_pattern "ghi789-unstable"
        The status should be success
      End

      It "should allow state tags with deprecated"
        When call validate_tag_pattern "jkl012-deprecated"
        The status should be success
      End

      It "should allow state tags with maintenance"
        When call validate_tag_pattern "mno345-maintenance"
        The status should be success
      End
    End

    Context "when validating forbidden tags"
      It "should reject environment tags in production"
        When call validate_tag_pattern "production"
        The status should be failure
        The output should include "Environment tag 'production' cannot be created manually"
      End

      It "should reject environment tags in staging"
        When call validate_tag_pattern "staging"
        The status should be failure
        The output should include "Environment tag 'staging' cannot be created manually"
      End

      It "should reject environment tags with custom names"
        When call validate_tag_pattern "custom-env"
        The status should be failure
        The output should include "Environment tag 'custom-env' cannot be created manually"
      End

      It "should reject feature branch tags"
        When call validate_tag_pattern "feature/new-feature"
        The status should be failure
        The output should include "Feature branch tag 'feature/new-feature' is not allowed"
      End

      It "should reject hotfix tags"
        When call validate_tag_pattern "hotfix/quick-fix"
        The status should be failure
        The output should include "Feature branch tag 'hotfix/quick-fix' is not allowed"
      End
    End
  End

  Describe "tag immutability validation"
    Context "when checking immutable tags"
      It "should allow creating new version tags"
        When call validate_tag_immutability "v2.0.0"
        The status should be success
      End

      It "should allow creating new state tags"
        When call validate_tag_immutability "xyz789-testing"
        The status should be success
      End

      It "should reject moving existing version tags"
        When call validate_tag_immutability "v1.2.0"
        The status should be failure
        The output should include "Version tag 'v1.2.0' already exists and is immutable"
      End

      It "should reject moving existing state tags"
        When call validate_tag_immutability "abc123-testing"
        The status should be failure
        The output should include "State tag 'abc123-testing' already exists and is immutable"
      End

      It "should allow moving environment tags"
        When call validate_tag_immutability "production"
        The status should be success
        The output should include "Environment tag 'production' is movable"
      End
    End
  End

  Describe "protection mode behavior"
    Context "when in ENFORCE mode"
      BeforeEach "export TAG_PROTECTION_MODE=ENFORCE"

      It "should block forbidden tag creation"
        When call check_tag_protection "production"
        The status should be failure
        The output should include "PROTECTION ENFORCED: Tag creation blocked"
      End

      It "should allow allowed tag creation"
        When call check_tag_protection "v2.0.0"
        The status should be success
        The output should include "Tag validation passed"
      End
    End

    Context "when in WARN mode"
      BeforeEach "export TAG_PROTECTION_MODE=WARN"

      It "should warn about forbidden tag creation but allow it"
        When call check_tag_protection "production"
        The status should be success
        The output should include "PROTECTION WARNING: Manual environment tag creation detected"
      End

      It "should allow allowed tag creation without warnings"
        When call check_tag_protection "v2.0.0"
        The status should be success
        The output should include "Tag validation passed"
        The output should not include "PROTECTION WARNING"
      End
    End

    Context "when in OFF mode"
      BeforeEach "export TAG_PROTECTION_MODE=OFF"

      It "should allow any tag creation"
        When call check_tag_protection "production"
        The status should be success
        The output should include "Tag protection is disabled"
      End
    End
  End

  Describe "tag type detection"
    It "should detect version tags"
      When call get_tag_type "v1.2.3"
      The output should equal "version"
    End

    It "should detect state tags"
      When call get_tag_type "abc123-testing"
      The output should equal "state"
    End

    It "should detect environment tags"
      When call get_tag_type "production"
      The output should equal "environment"
    End

    It "should detect feature branch tags"
      When call get_tag_type "feature/new-feature"
      The output should equal "feature"
    End

    It "should return unknown for unrecognizable patterns"
      When call get_tag_type "random-tag"
      The output should equal "unknown"
    End
  End

  Describe "batch tag validation"
    Context "when validating multiple tags"
      It "should succeed when all tags are valid"
        When call validate_tags "v2.0.0" "def456-stable" "feature/allowed"
        The status should be success
      End

      It "should fail when any tag is invalid"
        When call validate_tags "v2.0.0" "production" "def456-stable"
        The status should be failure
        The output should include "Invalid tags found"
        The output should include "production"
      End

      It "should report all invalid tags"
        When call validate_tags "v2.0.0" "production" "staging" "feature/invalid"
        The status should be failure
        The output should include "production"
        The output should include "staging"
        The output should include "feature/invalid"
      End
    End
  End

  Describe "pre-push hook integration"
    Context "when processing push references"
      It "should allow push with no tags"
        When call process_pre_push ""
        The status should be success
      End

      It "should allow push with valid tags"
        When call process_pre_push "refs/tags/v2.0.0 refs/tags/def456-stable"
        The status should be success
      End

      It "should block push with invalid tags in ENFORCE mode"
        BeforeEach "export TAG_PROTECTION_MODE=ENFORCE"

        When call process_pre_push "refs/tags/production refs/tags/v2.0.0"
        The status should be failure
        The output should include "Push blocked due to invalid tags"
      End

      It "should warn about invalid tags in WARN mode"
        BeforeEach "export TAG_PROTECTION_MODE=WARN"

        When call process_pre_push "refs/tags/production refs/tags/v2.0.0"
        The status should be success
        The output should include "PROTECTION WARNING"
      End
    End
  End

  Describe "configuration and environment"
    Context "protection mode configuration"
      It "should default to ENFORCE mode"
        BeforeEach "unset TAG_PROTECTION_MODE"

        When call get_protection_mode
        The output should equal "ENFORCE"
      End

      It "should respect environment override"
        BeforeEach "export TAG_PROTECTION_MODE=WARN"

        When call get_protection_mode
        The output should equal "WARN"
      End
    End

    Context "git repository validation"
      It "should detect valid git repository"
        When call validate_git_repository
        The status should be success
      End

      It "should fail when not in git repository"
        BeforeEach "cd /tmp"

        When call validate_git_repository
        The status should be failure
        The output should include "Not in a git repository"
      End
    End
  End
End