#!/usr/bin/env bash
# ShellSpec tests for Tag Assignment Script
# Tests the tag assignment logic for managing version, environment, and state tags

set -euo pipefail

# Load the script under test
# shellcheck disable=SC1090,SC1091
. "$(dirname "$0")/../../../scripts/release/50-ci-tag-assignment.sh" 2>/dev/null || {
  echo "Failed to source 50-ci-tag-assignment.sh" >&2
  exit 1
}

# Load tag utilities
# shellcheck disable=SC1090,SC1091
. "$(dirname "$0")/../../../scripts/lib/tag-utils.sh" 2>/dev/null || {
  echo "Failed to source tag-utils.sh" >&2
  exit 1
}

# Load common utilities
# shellcheck disable=SC1090,SC1091
. "$(dirname "$0")/../../../scripts/lib/common.sh" 2>/dev/null || {
  echo "Failed to source common.sh" >&2
  exit 1
}

# Setup test environment
setup_test_environment() {
  # Create test directory
  mkdir -p "/tmp/tag-assignment-test"
  cd "/tmp/tag-assignment-test"

  # Initialize git repository
  git init >/dev/null 2>&1
  git config user.email "test@example.com"
  git config user.name "Test User"

  # Create initial commit
  echo "test content" > test.txt
  git add test.txt
  git commit -m "Initial commit" >/dev/null 2>&1

  # Set test environment variables
  export TAG_ASSIGNMENT_MODE="${TAG_ASSIGNMENT_MODE:-EXECUTE}"
  export GITHUB_REPOSITORY="test-org/test-repo"
  export GITHUB_SERVER_URL="https://github.com"
  export CI_TEST_MODE="${CI_TEST_MODE:-EXECUTE}"
}

# Cleanup test environment
cleanup_test_environment() {
  cd - >/dev/null
  rm -rf "/tmp/tag-assignment-test"
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
          "-f")
            # Mock force tag creation/movement
            shift 2
            echo "Force created/moved tag: $*"
            ;;
          *)
            echo "git tag $*"
            ;;
        esac
        ;;
      "rev-parse")
        if [[ "$2" == "--git-dir" ]]; then
          echo ".git"
        elif [[ "$2" == "--verify" ]]; then
          # Return success for valid refs
          return 0
        else
          echo "abc123def456"
        fi
        ;;
      "show-ref")
        echo "abc123def456 refs/tags/v1.2.0"
        echo "def456abc123 refs/tags/production"
        echo "ghi789jkl012 refs/tags/staging"
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
        echo "--- a/.git/refs/tags/production"
        echo "+++ b/.git/refs/tags/production"
        ;;
      "push")
        echo "Pushed tags to origin: ${*:2}"
        ;;
      "fetch")
        echo "Fetched from origin"
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

Describe "Tag Assignment Script"
  BeforeEach "setup_test_environment"
  BeforeEach "mock_git_commands"
  BeforeEach "mock_logging_functions"
  AfterEach "cleanup_test_environment"

  Describe "tag type validation"
    Context "when validating version tags"
      It "should accept valid semantic versions"
        When call validate_version_tag "v1.2.3"
        The status should be success

        When call validate_version_tag "v10.20.30"
        The status should be success
      End

      It "should accept semantic versions with prerelease"
        When call validate_version_tag "v1.2.3-alpha.1"
        The status should be success

        When call validate_version_tag "v1.2.3-beta.2"
        The status should be success
      End

      It "should accept semantic versions with build metadata"
        When call validate_version_tag "v1.2.3+build.123"
        The status should be success
      End

      It "should reject invalid version tags"
        When call validate_version_tag "1.2.3"  # Missing v prefix
        The status should be failure

        When call validate_version_tag "v1.2"     # Missing patch
        The status should be failure

        When call validate_version_tag "vinvalid"  # Invalid format
        The status should be failure
      End
    End

    Context "when validating environment tags"
      It "should accept standard environment names"
        When call validate_environment_tag "production"
        The status should be success

        When call validate_environment_tag "staging"
        The status should be success

        When call validate_environment_tag "development"
        The status should be success
      End

      It "should reject invalid environment names"
        When call validate_environment_tag "prod"    # Not full name
        The status should be failure

        When call validate_environment_tag "stag"    # Not full name
        The status should be failure

        When call validate_environment_tag "invalid-env"  # Unknown environment
        The status should be failure
      End
    End

    Context "when validating state tags"
      It "should accept valid state names"
        When call validate_state_tag "testing"
        The status should be success

        When call validate_state_tag "stable"
        The status should be success

        When call validate_state_tag "unstable"
        The status should be success

        When call validate_state_tag "deprecated"
        The status should be success

        When call validate_state_tag "maintenance"
        The status should be success
      End

      It "should reject invalid state names"
        When call validate_state_tag "test"     # Not full name
        The status should be failure

        When call validate_state_tag "deployed" # Not a valid state
        The status should = failure

        When call validate_state_tag "invalid-state"  # Unknown state
        The status should be failure
      End
    End
  End

  Describe "tag creation operations"
    Context "when creating version tags"
      It "should create new version tag"
        When call create_version_tag "v2.0.0" "abc123def456"
        The output should include "Created version tag: v2.0.0"
        The output should include "Commit: abc123def456"
      End

      It "should reject creating existing version tag"
        When call create_version_tag "v1.2.0" "abc123def456"
        The status should be failure
        The output should include "Version tag v1.2.0 already exists"
      End

      It "should create version tag with force option"
        When call create_version_tag "v1.2.0" "abc123def456" "true"
        The output should include "Force created version tag: v1.2.0"
      End
    End

    Context "when creating environment tags"
      It "should create new environment tag"
        When call create_environment_tag "production" "abc123def456"
        The output should include "Created environment tag: production"
        The output should include "Commit: abc123def456"
      End

      It "should move existing environment tag"
        When call create_environment_tag "production" "abc123def456"
        The output should include "Moved environment tag: production"
        The output should include "Old commit: def456abc123"
        The output should include "New commit: abc123def456"
      End

      It "should force move environment tag"
        When call create_environment_tag "staging" "abc123def456" "true"
        The output should include "Force moved environment tag: staging"
      End
    End

    Context "when creating state tags"
      It "should create new state tag"
        When call create_state_tag "stable" "v2.0.0" "abc123def456"
        The output should include "Created state tag: v2.0.0-stable"
        The output should include "Version: v2.0.0"
        The output should include "State: stable"
      End

      It "should create state tag with existing version"
        When call create_state_tag "testing" "v1.2.0" "abc123def456"
        The output should include "Created state tag: v1.2.0-testing"
        The output should include "Version: v1.2.0"
      End

      It "should reject creating existing state tag"
        When call create_state_tag "testing" "v1.2.0" "abc123def456"
        The status should be failure
        The output should include "State tag v1.2.0-testing already exists"
      End
    End
  End

  Describe "tag operations with behavior modes"
    Context "when in EXECUTE mode"
      BeforeEach "export TAG_ASSIGNMENT_MODE=EXECUTE"

      It "should perform actual tag operations"
        When call assign_tag "version" "v2.0.0" "" "abc123def456" "false"
        The output should include "Tag assignment completed"
      End
    End

    Context "when in DRY_RUN mode"
      BeforeEach "export TAG_ASSIGNMENT_MODE=DRY_RUN"

      It "should simulate tag operations without creating tags"
        When call assign_tag "version" "v2.0.0" "" "abc123def456" "false"
        The output should include "DRY RUN: Would create version tag v2.0.0"
        The output should include "No actual changes made"
      End
    End

    Context "when in FAIL mode"
      BeforeEach "export TAG_ASSIGNMENT_MODE=FAIL"

      It "should simulate tag operation failure"
        When call assign_tag "version" "v2.0.0" "" "abc123def456" "false"
        The status should be failure
        The output should include "FAIL MODE: Simulating tag assignment failure"
      End
    End
  End

  Describe "subproject tag handling"
    Context "when working with subprojects"
      It "should include subproject in tag name"
        When call create_version_tag "v2.0.0" "abc123def456" "false" "api"
        The output should include "Created version tag: v2.0.0-api"
      End

      It "should include subproject in state tag"
        When call create_state_tag "stable" "v2.0.0" "abc123def456" "false" "frontend"
        The output should include "Created state tag: v2.0.0-frontend-stable"
      End

      It "should validate subproject names"
        When call validate_subproject "api"
        The status should be success

        When call validate_subproject "frontend"
        The status should be success

        When call validate_subproject "backend"
        The status should be success

        When call validate_subproject "invalid@subproject"
        The status should be failure
      End
    End
  End

  Describe "tag validation and conflict resolution"
    Context "when checking for tag conflicts"
      It "should detect version tag conflicts"
        When call check_tag_conflict "version" "v1.2.0"
        The status should be success
        The output should include "Version tag v1.2.0 exists"
      End

      It "should detect environment tag conflicts"
        When call check_tag_conflict "environment" "production"
        The status should be success
        The output should include "Environment tag production exists"
      End

      It "should report no conflict for non-existent tags"
        When call check_tag_conflict "version" "v9.9.9"
        The status should be failure
        The output should include "Tag v9.9.9 does not exist"
      End
    End

    Context "when resolving tag conflicts"
      It "should refuse to move immutable version tags without force"
        When call resolve_tag_conflict "version" "v1.2.0" "false"
        The status should be failure
        The output should include "Version tag v1.2.0 is immutable"
      End

      It "should allow moving version tags with force"
        When call resolve_tag_conflict "version" "v1.2.0" "true"
        The status should be success
        The output should include "Force moving version tag v1.2.0"
      End

      It "should allow moving environment tags without force"
        When call resolve_tag_conflict "environment" "production" "false"
        The status should be success
        The output should include "Moving environment tag production"
      End
    End
  End

  Describe "tag listing and information"
    Context "when listing tags"
      It "should list version tags"
        When call list_tags "version"
        The output should include "v1.0.0"
        The output should include "v1.1.0"
        The output should not include "production"
      End

      It "should list environment tags"
        When call list_tags "environment"
        The output should include "production"
        The output should include "staging"
        The output should not include "v1.0.0"
      End

      It "should list state tags"
        When call list_tags "state"
        The output should include "v1.2.0-testing"
        The output should not include "production"
      End

      It "should list all tags"
        When call list_tags "all"
        The output should include "v1.0.0"
        The output should include "v1.1.0"
        The output should include "v1.2.0-testing"
        The output should include "production"
        The output should include "staging"
      End
    End

    Context "when getting tag information"
      It "should retrieve tag details"
        When call get_tag_info "v1.2.0"
        The output should include "Tag: v1.2.0"
        The output should include "Commit: abc123def456"
        The output should include "Type: version"
      End

      It "should handle non-existent tags"
        When call get_tag_info "non-existent-tag"
        The status should be failure
        The output should include "Tag non-existent-tag not found"
      End
    End
  End

  Describe "integration with GitHub Actions"
    Context "when processing GitHub Actions inputs"
      It "should parse standard inputs"
        When call parse_github_inputs "version" "v2.0.0" "" "testing" "api" "abc123def456" "false"
        The status should be success
      End

      It "should validate required inputs"
        When call parse_github_inputs "version" "" "" "" "" "" ""
        The status should be failure
        The output should include "Version is required for version tag type"
      End

      It "should handle state tag inputs"
        When call parse_github_inputs "state" "v2.0.0" "stable" "" "api" "abc123def456" "false"
        The status should be success
        The output should include "Parsed state tag: v2.0.0-stable"
      End

      It "should handle environment tag inputs"
        When call parse_github_inputs "environment" "" "production" "" "" "abc123def456" "false"
        The status should be success
        The output should include "Parsed environment tag: production"
      End
    End
  End

  Describe "tag synchronization and remote operations"
    Context "when syncing with remote"
      It "should push new tags to remote"
        When call sync_tags_to_remote "v2.0.0" "v2.0.0-api-stable"
        The output should include "Pushed tags to origin: v2.0.0 v2.0.0-api-stable"
      End

      It "should fetch remote tags"
        When call fetch_remote_tags
        The output should include "Fetched from origin"
      End

      It "should handle sync failures gracefully"
        When call sync_tags_to_remote "non-existent-tag"
        The output should include "Failed to push some tags"
        The status should be success  # Should not fail the entire operation
      End
    End
  End
End