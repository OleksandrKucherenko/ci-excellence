#!/usr/bin/env bash
# ShellSpec tests for Tag Utilities Library
# Tests the version parsing, tag manipulation, and semver comparison functions

set -euo pipefail

# Load the library under test
# shellcheck disable=SC1090,SC1091
. "$(dirname "$0")/../../../scripts/lib/tag-utils.sh" 2>/dev/null || {
  echo "Failed to source tag-utils.sh" >&2
  exit 1
}

# Load common utilities for logging
# shellcheck disable=SC1090,SC1091
. "$(dirname "$0")/../../../scripts/lib/common.sh" 2>/dev/null || {
  echo "Failed to source common.sh" >&2
  exit 1
}

# Setup test environment
setup_test_environment() {
  export DEBUG="${DEBUG:-false}"
}

# Mock git commands for testing
mock_git_commands() {
  git() {
    case "$1" in
      "describe")
        case "$2" in
          "--tags"|"--abbrev=0")
            echo "v2.1.0"
            ;;
          "--dirty"|"--always")
            echo "v2.1.0-5-gabc123def"
            ;;
          *)
            echo "v2.1.0"
            ;;
        esac
        ;;
      "rev-list")
        case "$2" in
          "--count")
            echo "42"
            ;;
          "HEAD")
            echo "abc123def456"
            echo "def456abc123"
            echo "ghi789jkl012"
            ;;
          *)
            echo "abc123def456"
            ;;
        esac
        ;;
      "rev-parse")
        case "$2" in
          "HEAD")
            echo "abc123def456"
            ;;
          "--short=7"|"HEAD")
            echo "abc123d"
            ;;
          *)
            echo "abc123def456"
            ;;
        esac
        ;;
      "tag")
        case "$2" in
          "-l")
            echo "v1.0.0"
            echo "v1.1.0"
            echo "v1.2.0"
            echo "v2.0.0"
            echo "v2.1.0"
            echo "v1.2.0-alpha.1"
            echo "v1.2.0-beta.1"
            echo "v2.0.0-rc.1"
            echo "production"
            echo "staging"
            echo "v1.2.0-testing"
            echo "v1.1.0-stable"
            echo "v1.0.0-deprecated"
            ;;
          *)
            echo "git tag $*"
            ;;
        esac
        ;;
      "show-ref")
        echo "abc123def456 refs/tags/v1.2.0"
        echo "def456abc123 refs/tags/v2.0.0"
        echo "ghi789jkl012 refs/tags/production"
        ;;
      "log")
        case "$2" in
          "--pretty=format:%H"|"v1.2.0..HEAD")
            echo "abc123def456"
            echo "def456abc123"
            ;;
          *)
            echo "commit abc123def456"
            ;;
        esac
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

Describe "Tag Utilities Library"
  BeforeEach "setup_test_environment"
  BeforeEach "mock_git_commands"
  BeforeEach "mock_logging_functions"

  Describe "version parsing functions"
    Describe "parse_version"
      It "should parse simple semantic versions"
        When call parse_version "v1.2.3"
        The output should equal "1.2.3"
      End

      It "should parse semantic versions with prerelease"
        When call parse_version "v1.2.3-alpha.1"
        The output should equal "1.2.3-alpha.1"
      End

      It "should parse semantic versions with build metadata"
        When call parse_version "v1.2.3+build.123"
        The output should equal "1.2.3"
      End

      It "should parse semantic versions with both prerelease and build"
        When call parse_version "v1.2.3-alpha.1+build.123"
        The output should equal "1.2.3-alpha.1"
      End

      It "should handle major version only"
        When call parse_version "v1.0.0"
        The output should equal "1.0.0"
      End

      It "should reject invalid version formats"
        When call parse_version "invalid-version"
        The status should be failure

        When call parse_version "1.2.3"  # Missing v prefix
        The status should be failure
      End
    End

    Describe "get_version_parts"
      It "should extract major, minor, patch from simple version"
        When call get_version_parts "v1.2.3"
        The line 1 of output should equal "1"
        The line 2 of output should equal "2"
        The line 3 of output should equal "3"
      End

      It "should extract version parts from prerelease version"
        When call get_version_parts "v1.2.3-alpha.1"
        The line 1 of output should equal "1"
        The line 2 of output should equal "2"
        The line 3 of output should equal "3"
        The line 4 of output should equal "alpha.1"
      End

      It "should handle version with build metadata"
        When call get_version_parts "v1.2.3+build.123"
        The line 1 of output should equal "1"
        The line 2 of output should equal "2"
        The line 3 of output should equal "3"
        The output should not include "build.123"
      End
    End

    Describe "get_prerelease"
      It "should extract prerelease identifier"
        When call get_prerelease "v1.2.3-alpha.1"
        The output should equal "alpha.1"
      End

      It "should return empty for stable versions"
        When call get_prerelease "v1.2.3"
        The output should equal ""
      End

      It "should extract complex prerelease"
        When call get_prerelease "v1.2.3-beta.2+build.123"
        The output should equal "beta.2"
      End
    End
  End

  Describe "semantic version comparison"
    Describe "compare_versions"
      It "should compare equal versions"
        When call compare_versions "v1.2.3" "v1.2.3"
        The status should be success
        The output should equal "0"
      End

      It "should identify greater major version"
        When call compare_versions "v2.0.0" "v1.0.0"
        The status should be success
        The output should equal "1"
      End

      It "should identify lesser major version"
        When call compare_versions "v1.0.0" "v2.0.0"
        The status should be success
        The output should equal "-1"
      End

      It "should identify greater minor version"
        When call compare_versions "v1.3.0" "v1.2.0"
        The status should be success
        The output should equal "1"
      End

      It "should identify greater patch version"
        When call compare_versions "v1.2.4" "v1.2.3"
        The status should be success
        The output should equal "1"
      End

      It "should treat stable versions as greater than prerelease"
        When call compare_versions "v1.2.3" "v1.2.3-alpha.1"
        The status should be success
        The output should equal "1"
      End

      It "should compare prerelease versions correctly"
        When call compare_versions "v1.2.3-alpha.2" "v1.2.3-alpha.1"
        The status should be success
        The output should equal "1"
      End

      It "should compare prerelease vs beta correctly"
        When call compare_versions "v1.2.3-beta.1" "v1.2.3-alpha.1"
        The status should be success
        The output should equal "1"
      End
    End

    Describe "is_version_newer"
      It "should return true for newer version"
        When call is_version_newer "v2.0.0" "v1.0.0"
        The status should be success
      End

      It "should return false for older version"
        When call is_version_newer "v1.0.0" "v2.0.0"
        The status should be failure
      End

      It "should return false for equal versions"
        When call is_version_newer "v1.2.3" "v1.2.3"
        The status should be failure
      End
    End

    Describe "get_latest_version"
      It "should find latest version from list"
        When call get_latest_version "v1.0.0" "v1.1.0" "v1.2.0" "v2.0.0"
        The output should equal "v2.0.0"
      End

      It "should handle versions with prereleases"
        When call get_latest_version "v1.2.3-alpha.1" "v1.2.3-beta.1" "v1.2.3"
        The output should equal "v1.2.3"
      End

      It "should handle single version"
        When call get_latest_version "v1.0.0"
        The output should equal "v1.0.0"
      End

      It "should handle empty list"
        When call get_latest_version
        The status should be failure
      End
    End
  End

  Describe "tag type detection and validation"
    Describe "get_tag_type"
      It "should identify version tags"
        When call get_tag_type "v1.2.3"
        The output should equal "version"
      End

      It "should identify version tags with prerelease"
        When call get_tag_type "v1.2.3-alpha.1"
        The output should equal "version"
      End

      It "should identify environment tags"
        When call get_tag_type "production"
        The output should equal "environment"

        When call get_tag_type "staging"
        The output should equal "environment"

        When call get_tag_type "development"
        The output should equal "environment"
      End

      It "should identify state tags"
        When call get_tag_type "abc123-testing"
        The output should equal "state"

        When call get_tag_type "def456-stable"
        The output should equal "state"

        When call get_tag_type "ghi789-unstable"
        The output should equal "state"
      End

      It "should identify feature branch tags"
        When call get_tag_type "feature/new-feature"
        The output should equal "feature"

        When call get_tag_type "feature/branch-name"
        The output should equal "feature"
      End

      It "should identify hotfix tags"
        When call get_tag_type "hotfix/quick-fix"
        The output should equal "feature"
      End

      It "should return unknown for unrecognized patterns"
        When call get_tag_type "random-tag"
        The output should equal "unknown"

        When call get_tag_type "123456"
        The output should equal "unknown"
      End
    End

    Describe "is_valid_version_tag"
      It "should validate correct version tags"
        When call is_valid_version_tag "v1.2.3"
        The status should be success

        When call is_valid_version_tag "v10.20.30"
        The status should be success
      End

      It "should validate version tags with prerelease"
        When call is_valid_version_tag "v1.2.3-alpha.1"
        The status should be success

        When call is_valid_version_tag "v1.2.3-beta.2"
        The status should be success
      End

      It "should reject invalid version tags"
        When call is_valid_version_tag "1.2.3"  # Missing v
        The status should be failure

        When call is_valid_version_tag "v1.2"  # Missing patch
        The status should be failure

        When call is_valid_version_tag "vinvalid"  # Invalid format
        The status should = failure
      End
    End

    Describe "is_valid_environment_tag"
      It "should validate standard environment tags"
        When call is_valid_environment_tag "production"
        The status should be success

        When call is_valid_environment_tag "staging"
        The status should = success

        When call is_valid_environment_tag "development"
        The status should be success
      End

      It "should reject invalid environment tags"
        When call is_valid_environment_tag "prod"  # Short form
        The status should be failure

        When call is_valid_environment_tag "custom-env"  # Non-standard
        The status should be failure
      End
    End

    Describe "is_valid_state_tag"
      It "should validate state tags"
        When call is_valid_state_tag "abc123-testing"
        The status should be success

        When call is_valid_state_tag "def456-stable"
        The status should be success

        When call is_valid_state_tag "ghi789-unstable"
        The status should be success
      End

      It "should reject invalid state tags"
        When call is_valid_state_tag "123456"  # Just commit SHA
        The status should be failure

        When call is_valid_state_tag "abc123-testing"  # Wrong format for testing
        The status should be failure
      End
    End
  End

  Describe "tag generation and formatting"
    Describe "generate_version_tag"
      It "should generate version tag from components"
        When call generate_version_tag "1" "2" "3"
        The output should equal "v1.2.3"
      End

      It "should generate version tag with prerelease"
        When call generate_version_tag "1" "2" "3" "alpha.1"
        The output should equal "v1.2.3-alpha.1"
      End

      It "should generate version tag with build metadata"
        When call generate_version_tag "1" "2" "3" "" "build.123"
        The output should equal "v1.2.3+build.123"
      End

      It "should generate full version tag"
        When call generate_version_tag "1" "2" "3" "beta.2" "build.456"
        The output should equal "v1.2.3-beta.2+build.456"
      End
    End

    Describe "generate_state_tag"
      It "should generate state tag from version and state"
        When call generate_state_tag "v1.2.3" "testing"
        The output should equal "v1.2.3-testing"
      End

      It "should generate state tag with subproject"
        When call generate_state_tag "v1.2.3" "stable" "api"
        The output should equal "v1.2.3-api-stable"
      End

      It "should handle commit-based state tags"
        When call generate_state_tag "abc123def456" "unstable"
        The output should equal "abc123def456-unstable"
      End
    End

    Describe "format_tag_message"
      It "should format version tag message"
        When call format_tag_message "version" "v1.2.3" "Release version 1.2.3"
        The output should include "Release version 1.2.3"
        The output should include "Type: version"
        The output should include "Tag: v1.2.3"
      End

      It "should format environment tag message"
        When call format_tag_message "environment" "production" "Deploy to production"
        The output should include "Deploy to production"
        The output should include "Type: environment"
        The output should include "Tag: production"
      End

      It "should format state tag message"
        When call format_tag_message "state" "v1.2.3-testing" "Mark as testing"
        The output should include "Mark as testing"
        The output should include "Type: state"
        The output should include "Tag: v1.2.3-testing"
      End
    End
  End

  Describe "git integration functions"
    Describe "get_current_version"
      It "should get current version from git tags"
        When call get_current_version
        The output should equal "v2.1.0"
      End

      It "should handle no tags gracefully"
        BeforeEach "git() { echo 'No tags found'; }"

        When call get_current_version
        The status should be failure
      End
    End

    Describe "get_tags_since"
      It "should get tags since specified version"
        When call get_tags_since "v1.2.0"
        The output should include "v2.0.0"
        The output should include "v2.1.0"
        The output should not include "v1.2.0"
        The output should not include "v1.1.0"
      End

      It "should handle non-existent base version"
        When call get_tags_since "v9.9.9"
        The output should be empty
      End
    End

    Describe "get_tag_commit"
      It "should get commit SHA for tag"
        When call get_tag_commit "v1.2.0"
        The output should equal "abc123def456"
      End

      It "should handle non-existent tag"
        When call get_tag_commit "non-existent-tag"
        The status should be failure
        The output should include "Tag non-existent-tag not found"
      End
    End

    Describe "get_commits_since_tag"
      It "should get commits since specified tag"
        When call get_commits_since_tag "v1.2.0"
        The output should include "abc123def456"
        The output should include "def456abc123"
      End

      It "should handle non-existent tag"
        When call get_commits_since_tag "non-existent-tag"
        The output should be empty
      End
    End

    Describe "get_commit_count_since_tag"
      It "should count commits since tag"
        When call get_commit_count_since_tag "v1.2.0"
        The output should equal "2"
      End

      It "should handle non-existent tag"
        When call get_commit_count_since_tag "non-existent-tag"
        The output should equal "0"
      End
    End
  End

  Describe "tag filtering and searching"
    Describe "filter_tags_by_type"
      It "should filter version tags"
        When call filter_tags_by_type "version" "v1.0.0" "v1.1.0" "production" "v1.2.0-testing" "staging"
        The output should include "v1.0.0"
        The output should include "v1.1.0"
        The output should not include "production"
        The output should not include "v1.2.0-testing"
        The output should not include "staging"
      End

      It "should filter environment tags"
        When call filter_tags_by_type "environment" "v1.0.0" "production" "v1.1.0" "staging" "v1.2.0-testing"
        The output should include "production"
        The output should include "staging"
        The output should not include "v1.0.0"
        The output should not include "v1.1.0"
        The output should not include "v1.2.0-testing"
      End

      It "should filter state tags"
        When call filter_tags_by_type "state" "v1.0.0" "production" "v1.2.0-testing" "v1.1.0-stable" "v1.0.0-deprecated"
        The output should include "v1.2.0-testing"
        The output should include "v1.1.0-stable"
        The output should include "v1.0.0-deprecated"
        The output should not include "v1.0.0"
        The output should not include "production"
      End
    End

    Describe "find_tags_by_pattern"
      It "should find tags matching pattern"
        When call find_tags_by_pattern "v1.*"
        The output should include "v1.0.0"
        The output should include "v1.1.0"
        The output should include "v1.2.0"
        The output should not include "v2.0.0"
      End

      It "should find prerelease tags"
        When call find_tags_by_pattern "*-alpha.*"
        The output should include "v1.2.0-alpha.1"
        The output should not include "v1.2.0-beta.1"
        The output should not include "v2.0.0"
      End

      It "should handle no matches"
        When call find_tags_by_pattern "v9.*"
        The output should be empty
      End
    End
  End

  Describe "version increment functions"
    Describe "increment_version"
      It "should increment patch version"
        When call increment_version "v1.2.3" "patch"
        The output should equal "v1.2.4"
      End

      It "should increment minor version"
        When call increment_version "v1.2.3" "minor"
        The output should equal "v1.3.0"
      End

      It "should increment major version"
        When call increment_version "v1.2.3" "major"
        The output should equal "v2.0.0"
      End

      It "should handle prerelease versions"
        When call increment_version "v1.2.3-alpha.1" "patch"
        The output should equal "v1.2.3-alpha.2"
      End

      It "should reject invalid increment type"
        When call increment_version "v1.2.3" "invalid"
        The status should be failure
      End
    End

    Describe "suggest_next_version"
      It "should suggest next patch version"
        When call suggest_next_version "v1.2.3" "patch"
        The output should equal "v1.2.4"
      End

      It "should suggest next minor version"
        When call suggest_next_version "v1.2.3" "minor"
        The output should equal "v1.3.0"
      End

      It "should suggest next major version"
        When call suggest_next_version "v1.2.3" "major"
        The output should equal "v2.0.0"
      End

      It "should suggest based on existing tags"
        When call suggest_next_version "" "auto"
        The output should equal "v2.1.1"
      End
    End
  End
End