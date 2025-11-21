#!/usr/bin/env bash
# ShellSpec Integration Tests for User Story 1: Pipeline Reports with Action Links
# Tests the complete integration of report generator with pre-release workflow

set -euo pipefail

# Load scripts under test
# shellcheck disable=SC1090,SC1091
. "$(dirname "$0")/../../../scripts/ci/report-generator.sh" 2>/dev/null || {
  echo "Failed to source report-generator.sh" >&2
  exit 1
}

. "$(dirname "$0")/../../../scripts/lib/common.sh" 2>/dev/null || {
  echo "Failed to source common.sh" >&2
  exit 1
}

. "$(dirname "$0")/../../../scripts/ci/build/ci-05-summary-pre-release.sh" 2>/dev/null || {
  echo "Failed to source ci-05-summary-pre-release.sh" >&2
  exit 1
}

# Mock GitHub environment
setup_github_environment() {
  export GITHUB_STEP_SUMMARY="/tmp/integration-test-summary.md"
  export GITHUB_SERVER_URL="https://github.com"
  export GITHUB_REPOSITORY="test-org/test-repo"
  export GITHUB_SHA="abc123def456"
  export GITHUB_REF_NAME="main"
  export GITHUB_ACTOR="test-user"
  export GITHUB_RUN_NUMBER="123"
  export GITHUB_RUN_ID="456"

  # Create summary file
  touch "$GITHUB_STEP_SUMMARY"
}

# Mock common functions
mock_common_functions() {
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

# Cleanup test environment
cleanup_test_environment() {
  rm -f "/tmp/integration-test-summary.md"
  rm -f "/tmp/pipeline-report.md"
}

Describe "User Story 1 Integration: Pipeline Reports with Action Links"
  BeforeEach "setup_github_environment"
  BeforeEach "mock_common_functions"
  AfterEach "cleanup_test_environment"

  Describe "Complete pre-release pipeline integration"
    Context "when all jobs succeed"
      BeforeEach "export ENABLE_COMPILE=true ENABLE_LINT=true ENABLE_UNIT_TESTS=true"

      It "should generate comprehensive pre-release report with action links"
        When run ci-05-summary-pre-release.sh "success" "success" "success" "success" "skipped" "skipped" "success" "success"

        The file "/tmp/integration-test-summary.md" should exist
        The contents of file "/tmp/integration-test-summary.md" should include "🚀 Pipeline Completion Report"
        The contents of file "/tmp/integration-test-summary.md" should include "## 🎯 Quick Actions"
        The contents of file "/tmp/integration-test-summary.md" should include "### 🚀 Promote to Release"
        The contents of file "/tmp/integration-test-summary.md" should include "promote-to-release"
        The contents of file "/tmp/integration-test-summary.md" should include "### 🏷️ State Assignment"
        The contents of file "/tmp/integration-test-summary.md" should include "state-assignment"
        The contents of file "/tmp/integration-test-summary.md" should include "### 🔧 Maintenance Task"
        The contents of file "/tmp/integration-test-summary.md" should include "## 📊 Pre-Release Job Details"
        The contents of file "/tmp/integration-test-summary.md" should include "## 📦 Generated Artifacts"
      End

      It "should auto-set testing state for successful pipeline"
        When run ci-05-summary-pre-release.sh "success" "success" "success" "success" "skipped" "skipped" "success" "success"

        The output should include "Auto-setting state tags: testing on abc123def456"
        The output should include "State tag set: abc123def456-testing"
      End
    End

    Context "when some jobs fail"
      BeforeEach "export ENABLE_COMPILE=true ENABLE_LINT=true ENABLE_UNIT_TESTS=true"

      It "should generate report with rollback and maintenance links"
        When run ci-05-summary-pre-release.sh "success" "failure" "success" "success" "skipped" "skipped" "success" "success"

        The file "/tmp/integration-test-summary.md" should exist
        The contents of file "/tmp/integration-test-summary.md" should include "❌ Pipeline Completion Report"
        The contents of file "/tmp/integration-test-summary.md" should include "## 🎯 Quick Actions"
        The contents of file "/tmp/integration-test-summary.md" should include "### 🔧 Maintenance Task"
        The contents of file "/tmp/integration-test-summary.md" should include "validate-configuration"
      End

      It "should auto-set unstable state for failed pipeline"
        When run ci-05-summary-pre-release.sh "success" "failure" "success" "success" "skipped" "skipped" "success" "success"

        The output should include "Auto-setting state tags: unstable on abc123def456"
        The output should include "State tag set: abc123def456-unstable"
      End
    End
  End

  Describe "Action links functionality"
    Context "pre-release pipeline specific actions"
      It "should include promote to staging links"
        When run ci-05-summary-pre-release.sh "success" "success" "success" "success" "skipped" "skipped" "success" "success"

        The contents of file "/tmp/integration-test-summary.md" should include "Promote latest to staging"
        The contents of file "/tmp/integration-test-summary.md" should include "\"environment\": \"staging\""
        The contents of file "/tmp/integration-test-summary.md" should include "curl -X POST"
        The contents of file "/tmp/integration-test-summary.md" should include "Authorization: Bearer"
      End

      It "should include state assignment to testing"
        When run ci-05-summary-pre-release.sh "success" "success" "success" "success" "skipped" "skipped" "success" "success"

        The contents of file "/tmp/integration-test-summary.md" should include "Mark abc123def456 as testing"
        The contents of file "/tmp/integration-test-summary.md" should include "\"state\": \"testing\""
        The contents of file "/tmp/integration-test-summary.md" should include "state-assignment"
      End

      It "should include security scan maintenance task"
        When run ci-05-summary-pre-release.sh "success" "success" "success" "success" "skipped" "skipped" "success" "success"

        The contents of file "/tmp/integration-test-summary.md" should include "### 🔧 Maintenance Task"
        The contents of file "/tmp/integration-test-summary.md" should include "security-scan"
        The contents of file "/tmp/integration-test-summary.md" should include "\"action\": \"security-scan\""
        The contents of file "/tmp/integration-test-summary.md" should include "maintenance"
      End
    End

    Context "curl command generation"
      It "should generate properly formatted curl commands"
        When call generate_promote_link "abc123" "production" "v1.2.3"

        The output should match pattern "curl -X POST \\\\"
        The output should include "-H 'Authorization: Bearer \$GH_TOKEN'"
        The output should include "-H 'Accept: application/vnd.github.eagle-preview+json'"
        The output should include "-H 'Content-Type: application/json'"
        The output should include "'https://github.com/test-org/test-repo/actions/dispatches'"
      End
    End
  End

  Describe "Report structure and content"
    Context "markdown structure validation"
      It "should include all required report sections"
        When run ci-05-summary-pre-release.sh "success" "success" "success" "success" "skipped" "skipped" "success" "success"

        # Main report sections
        The contents of file "/tmp/integration-test-summary.md" should include "🚀 Pipeline Completion Report"
        The contents of file "/tmp/integration-test-summary.md" should include "## 📊 Execution Summary"
        The contents of file "/tmp/integration-test-summary.md" should include "## 🎯 Quick Actions"
        The contents of file "/tmp/integration-test-summary.md" should include "## 📈 Performance Metrics"
        The contents of file "/tmp/integration-test-summary.md" should include "## 📋 Next Steps"

        # Pre-release specific sections
        The contents of file "/tmp/integration-test-summary.md" should include "## 📊 Pre-Release Job Details"
        The contents of file "/tmp/integration-test-summary.md" should include "## 📦 Generated Artifacts"
      End

      It "should include proper metadata in execution summary"
        When run ci-05-summary-pre-release.sh "success" "success" "success" "success" "skipped" "skipped" "success" "success"

        The contents of file "/tmp/integration-test-summary.md" should include "| Commit | \\`abc123def456\\` |"
        The contents of file "/tmp/integration-test-summary.md" should include "| Pipeline Type | PRE_RELEASE |"
        The contents of file "/tmp/integration-test-summary.md" should include "| Status | ✅ SUCCESS |"
      End
    End
  End

  Describe "Error handling and edge cases"
    Context "when GitHub environment variables are missing"
      BeforeEach "unset GITHUB_STEP_SUMMARY"

      It "should fall back to temporary file"
        When run ci-05-summary-pre-release.sh "success" "success" "success" "success" "skipped" "skipped" "success" "success"

        The file "/tmp/pipeline-report.md" should exist
        The output should include "GITHUB_STEP_SUMMARY not found"
      End
    End

    Context "when no version tag is available"
      It "should handle missing version gracefully"
        When run ci-05-summary-pre-release.sh "success" "success" "success" "success" "skipped" "skipped" "success" "success"

        The contents of file "/tmp/integration-test-summary.md" should include "| Version | latest |"
      End
    End

    Context "when all jobs are disabled"
      BeforeEach "export ENABLE_COMPILE=false ENABLE_LINT=false ENABLE_UNIT_TESTS=false"

      It "should generate minimal report with only setup job"
        When run ci-05-summary-pre-release.sh "success" "skipped" "skipped" "skipped" "skipped" "skipped" "success" "skipped"

        The contents of file "/tmp/integration-test-summary.md" should include "| Setup | success | Always |"
        The contents of file "/tmp/integration-test-summary.md" should include "| Compile | skipped | ❌ |"
        The contents of file "/tmp/integration-test-summary.md" should include "| Lint | skipped | ❌ |"
      End
    End
  End

  Describe "Behavior modes integration"
    Context "when running in DRY_RUN mode"
      BeforeEach "export CI_TEST_MODE=DRY_RUN"

      It "should simulate report generation without creating files"
        When run ci-05-summary-pre-release.sh "success" "success" "success" "success" "skipped" "skipped" "success" "success"

        The output should include "DRY RUN: Would generate pipeline report"
        The output should include "🔍 DRY RUN: Would set state tag"
      End
    End

    Context "when running in FAIL mode"
      BeforeEach "export CI_TEST_MODE=FAIL"

      It "should simulate report generation failure"
        When run ci-05-summary-pre-release.sh "success" "success" "success" "success" "skipped" "skipped" "success" "success"

        The output should include "FAIL MODE: Simulating report generation failure"
        The status should be failure
      End
    End
  End
End