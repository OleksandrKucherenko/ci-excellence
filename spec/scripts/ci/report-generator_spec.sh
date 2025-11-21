#!/usr/bin/env bash
# ShellSpec tests for CI Report Generator
# Tests the report-generator.sh script functionality

set -euo pipefail

# Load the script under test
# shellcheck disable=SC1090,SC1091
. "$(dirname "$0")/../../../scripts/ci/report-generator.sh" 2>/dev/null || {
  echo "Failed to source report-generator.sh" >&2
  exit 1
}

# Mock common functions for testing
mock_common_functions() {
  # Override functions that would normally exit or make external calls
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

  # Mock git functions
  get_git_info() {
    case "$1" in
      "commit") echo "abc123def456" ;;
      "branch") echo "main" ;;
      *) echo "mock" ;;
    esac
  }

  # Mock environment variables
  export GITHUB_STEP_SUMMARY="/tmp/test-report.md"
  export GITHUB_REPOSITORY="test/repo"
  export GITHUB_SERVER_URL="https://github.com"
}

# Setup test environment
setup_test_environment() {
  # Create test directory
  mkdir -p "/tmp/ci-test"

  # Set test environment variables
  export CI_REPORT_GENERATOR_BEHAVIOR="${CI_REPORT_GENERATOR_BEHAVIOR:-EXECUTE}"
  export CI_TEST_MODE="${CI_TEST_MODE:-EXECUTE}"

  # Mock common functions
  mock_common_functions
}

# Cleanup test environment
cleanup_test_environment() {
  rm -rf "/tmp/ci-test"
  rm -f "/tmp/test-report.md"
}

Describe "CI Report Generator"
  BeforeEach "setup_test_environment"
  AfterEach "cleanup_test_environment"

  Describe "behavior mode handling"
    Context "when CI_TEST_MODE is DRY_RUN"
      BeforeEach "export CI_TEST_MODE=DRY_RUN"

      It "should run in dry run mode"
        When call generate_report "PRE_RELEASE" "SUCCESS" "120" "v1.2.3" "api" "staging"
        The output should include "🔍 DRY RUN: Would generate pipeline report"
      End
    End

    Context "when CI_TEST_MODE is PASS"
      BeforeEach "export CI_TEST_MODE=PASS"

      It "should simulate successful report generation"
        When call generate_report "PRE_RELEASE" "SUCCESS" "120" "v1.2.3" "api" "staging"
        The output should include "PASS MODE: Report generation simulated successfully"
      End
    End

    Context "when CI_TEST_MODE is FAIL"
      BeforeEach "export CI_TEST_MODE=FAIL"

      It "should simulate report generation failure"
        When call generate_report "PRE_RELEASE" "SUCCESS" "120" "v1.2.3" "api" "staging"
        The output should include "FAIL MODE: Simulating report generation failure"
        The status should be failure
      End
    End

    Context "when CI_TEST_MODE is SKIP"
      BeforeEach "export CI_TEST_MODE=SKIP"

      It "should skip report generation"
        When call generate_report "PRE_RELEASE" "SUCCESS" "120" "v1.2.3" "api" "staging"
        The output should include "SKIP MODE: Report generation skipped"
      End
    End

    Context "when CI_TEST_MODE is TIMEOUT"
      BeforeEach "export CI_TEST_MODE=TIMEOUT"

      It "should simulate timeout"
        When run timeout 10s generate_report "PRE_RELEASE" "SUCCESS" "120" "v1.2.3" "api" "staging"
        The output should include "TIMEOUT MODE: Simulating report generation timeout"
        The status should be timeout
      End
    End
  End

  Describe "EXECUTE mode functionality"
    BeforeEach "export CI_TEST_MODE=EXECUTE"

    Context "when generating a successful pre-release report"
      It "should create a complete markdown report"
        When call generate_report "PRE_RELEASE" "SUCCESS" "120" "v1.2.3" "api" "staging"

        The file "/tmp/test-report.md" should exist
        The contents of file "/tmp/test-report.md" should include "# 🚀 Pipeline Completion Report"
        The contents of file "/tmp/test-report.md" should include "PRE_RELEASE"
        The contents of file "/tmp/test-report.md" should include "✅ SUCCESS"
        The contents of file "/tmp/test-report.md" should include "v1.2.3"
        The contents of file "/tmp/test-report.md" should include "api"
        The contents of file "/tmp/test-report.md" should include "staging"
      End
    End

    Context "when generating a failed release report"
      It "should create a report with failure status"
        When call generate_report "RELEASE" "FAILURE" "300" "v2.0.0" "" "production"

        The file "/tmp/test-report.md" should exist
        The contents of file "/tmp/test-report.md" should include "❌ FAILURE"
        The contents of file "/tmp/test-report.md" should include "v2.0.0"
        The contents of file "/tmp/test-report.md" should include "production"
        The contents of file "/tmp/test-report.md" should not include "🎯 Quick Actions"  # No actions for failed reports
      End
    End

    Context "when generating a report without version"
      It "should handle missing version gracefully"
        When call generate_report "MAINTENANCE" "SUCCESS" "45" "" "" ""

        The file "/tmp/test-report.md" should exist
        The contents of file "/tmp/test-report.md" should include "MAINTENANCE"
        The contents of file "/tmp/test-report.md" should include "N/A" for version
      End
    End
  End

  Describe "action links generation"
    BeforeEach "export CI_TEST_MODE=EXECUTE"

    Context "when generating a successful pre-release report"
      It "should include contextual action links"
        When call generate_report "PRE_RELEASE" "SUCCESS" "120" "v1.2.3" "api" "staging"

        The contents of file "/tmp/test-report.md" should include "## 🎯 Quick Actions"
        The contents of file "/tmp/test-report.md" should include "### 🚀 Promote to Release"
        The contents of file "/tmp/test-report.md" should include "promote-to-release"
        The contents of file "/tmp/test-report.md" should include "### 🏷️ State Assignment"
        The contents of file "/tmp/test-report.md" should include "state-assignment"
        The contents of file "/tmp/test-report.md" should include "### 🔧 Maintenance Task"
        The contents of file "/tmp/test-report.md" should include "security-scan"
      End
    End

    Context "when generating a successful release report"
      It "should include release-specific action links"
        When call generate_report "RELEASE" "SUCCESS" "200" "v1.3.0" "frontend" "production"

        The contents of file "/tmp/test-report.md" should include "### 🚀 Promote to Release"
        The contents of file "/tmp/test-report.md" should include "### 🏷️ State Assignment"
        The contents of file "/tmp/test-report.md" should include "\"state\": \"stable\""
        The contents of file "/tmp/test-report.md" should include "### 🔄 Rollback Action"
        The contents of file "/tmp/test-report.md" should include "rollback"
      End
    End

    Context "when generating for production environment"
      It "should include rollback links with proper payload"
        When call generate_report "RELEASE" "SUCCESS" "250" "v2.1.0" "api" "production"

        The contents of file "/tmp/test-report.md" should include "### 🔄 Rollback Action"
        The contents of file "/tmp/test-report.md" should include "\"from_commit\":"
        The contents of file "/tmp/test-report.md" should include "\"to_commit\":"
        The contents of file "/tmp/test-report.md" should include "\"environment\": \"production\""
      End
    End

    Context "when generating post-release report"
      It "should include post-release maintenance tasks"
        When call generate_report "POST_RELEASE" "SUCCESS" "100" "v1.4.0" "backend" "production"

        The contents of file "/tmp/test-report.md" should include "### 🔧 Maintenance Task"
        The contents of file "/tmp/test-report.md" should include "cleanup-artifacts"
        The contents of file "/tmp/test-report.md" should include "update-dependencies"
        The contents of file "/tmp/test-report.md" should include "performance-monitoring"
      End
    End

    Context "when generating maintenance report"
      It "should include maintenance-specific tasks"
        When call generate_report "MAINTENANCE" "SUCCESS" "60" "" "" ""

        The contents of file "/tmp/test-report.md" should include "### 🔧 Maintenance Task"
        The contents of file "/tmp/test-report.md" should include "reconcile-security"
        The contents of file "/tmp/test-report.md" should include "validate-configuration"
        The contents of file "/tmp/test-report.md" should include "backup-secrets"
      End
    End

    Context "when generating hotfix report"
      It "should include hotfix-specific actions"
        When call generate_report "HOTFIX" "SUCCESS" "80" "v1.2.4" "api" "production"

        The contents of file "/tmp/test-report.md" should include "### 🏷️ State Assignment"
        The contents of file "/tmp/test-report.md" should include "\"state\": \"unstable\""
        The contents of file "/tmp/test-report.md" should include "### 🔧 Maintenance Task"
        The contents of file "/tmp/test-report.md" should include "security-scan"
        The contents of file "/tmp/test-report.md" should include "regression-test"
        The contents of file "/tmp/test-report.md" should include "### 🔄 Rollback Action"
      End
    End

    Context "when WEBHOOK_ENDPOINT is set"
      BeforeEach "export WEBHOOK_ENDPOINT='https://hooks.example.com/ci'"

      It "should include webhook action links"
        When call generate_report "PRE_RELEASE" "SUCCESS" "100" "v1.0.0" "api" "staging"

        The contents of file "/tmp/test-report.md" should include "### 🔗 Webhook Actions"
        The contents of file "/tmp/test-report.md" should include "Trigger Webhook"
      End
    End
  End

  Describe "individual action link functions"
    BeforeEach "export CI_TEST_MODE=EXECUTE"

    Describe "generate_promote_link"
      It "should generate promote to release link with curl command"
        When call generate_promote_link "abc123" "production" "v1.2.3"

        The output should include "### 🚀 Promote to Release"
        The output should include "promote-to-release"
        The output should include "abc123"
        The output should include "v1.2.3"
        The output should include "curl -X POST"
        The output should include "Authorization: Bearer"
      End
    End

    Describe "generate_rollback_link"
      It "should generate rollback link with curl command"
        When call generate_rollback_link "abc123" "def456" "production"

        The output should include "### 🔄 Rollback Action"
        The output should include "rollback"
        The output should include "\"from_commit\": \"abc123\""
        The output should include "\"to_commit\": \"def456\""
        The output should include "\"environment\": \"production\""
        The output should include "curl -X POST"
      End
    End

    Describe "generate_state_link"
      It "should generate state assignment link"
        When call generate_state_link "abc123" "stable" "v1.2.3"

        The output should include "### 🏷️ State Assignment"
        The output should include "state-assignment"
        The output should include "\"commit_ish\": \"abc123\""
        The output should include "\"state\": \"stable\""
        The output should include "\"version\": \"v1.2.3\""
        The output should include "curl -X POST"
      End
    End

    Describe "generate_maintenance_link"
      It "should generate maintenance task link"
        When call generate_maintenance_link "security-scan" "abc123" "production"

        The output should include "### 🔧 Maintenance Task"
        The output should include "maintenance"
        The output should include "\"action\": \"security-scan\""
        The output should include "\"commit_ish\": \"abc123\""
        The output should include "\"environment\": \"production\""
        The output should include "curl -X POST"
      End

      It "should handle maintenance link without environment"
        When call generate_maintenance_link "cleanup-artifacts" "abc123"

        The output should include "### 🔧 Maintenance Task"
        The output should include "\"action\": \"cleanup-artifacts\""
        The output should include "\"commit_ish\": \"abc123\""
        The output should not include "\"environment\""
      End
    End

    Describe "auto_set_state_tags"
      It "should accept valid states"
        When call auto_set_state_tags "abc123" "stable"
        The output should include "Valid state: stable"
        The output should include "State tag set: abc123-stable"

        When call auto_set_state_tags "def456" "unstable"
        The output should include "Valid state: unstable"
        The output should include "State tag set: def456-unstable"

        When call auto_set_state_tags "ghi789" "testing"
        The output should include "Valid state: testing"
        The output should include "State tag set: ghi789-testing"

        When call auto_set_state_tags "jkl012" "deprecated"
        The output should include "Valid state: deprecated"
        The output should include "State tag set: jkl012-deprecated"

        When call auto_set_state_tags "mno345" "maintenance"
        The output should include "Valid state: maintenance"
        The output should include "State tag set: mno345-maintenance"
      End

      It "should reject invalid states"
        When call auto_set_state_tags "abc123" "invalid-state"
        The output should include "Invalid state: invalid-state"
        The status should be failure
      End
    End
  End

  Describe "performance metrics"
    BeforeEach "export CI_TEST_MODE=EXECUTE"

    Context "when pipeline duration is excellent"
      It "should show excellent performance assessment"
        When call generate_report "PRE_RELEASE" "SUCCESS" "30" "v1.0.0" "api" "staging"

        The contents of file "/tmp/test-report.md" should include "✅ Excellent"
      End
    End

    Context "when pipeline duration is moderate"
      It "should show moderate performance assessment"
        When call generate_report "PRE_RELEASE" "SUCCESS" "180" "v1.0.0" "api" "staging"

        The contents of file "/tmp/test-report.md" should include "⚠️ Moderate"
      End
    End

    Context "when pipeline duration is slow"
      It "should show slow performance assessment and recommendations"
        When call generate_report "PRE_RELEASE" "SUCCESS" "400" "v1.0.0" "api" "staging"

        The contents of file "/tmp/test-report.md" should include "❌ Slow"
        The contents of file "/tmp/test-report.md" should include "⚠️ Performance Recommendations"
      End
    End
  End

  Describe "next steps generation"
    BeforeEach "export CI_TEST_MODE=EXECUTE"

    Context "when pre-release pipeline succeeds"
      It "should show pre-release next steps"
        When call generate_report "PRE_RELEASE" "SUCCESS" "120" "v1.2.3" "api" "staging"

        The contents of file "/tmp/test-report.md" should include "✅ **Ready for release consideration**"
        The contents of file "/tmp/test-report.md" should include "Review test results and coverage reports"
        The contents of file "/tmp/test-report.md" should include "Create release tag"
      End
    End

    Context "when pre-release pipeline fails"
      It "should show failure next steps"
        When call generate_report "PRE_RELEASE" "FAILURE" "60" "v1.2.3" "api" "staging"

        The contents of file "/tmp/test-report.md" should include "❌ **Fix issues before proceeding**"
        The contents of file "/tmp/test-report.md" should include "Review failed job logs"
      End
    End

    Context "when release pipeline succeeds"
      It "should show release completion steps"
        When call generate_report "RELEASE" "SUCCESS" "250" "v2.0.0" "api" "production"

        The contents of file "/tmp/test-report.md" should include "🚀 **Release completed successfully**"
        The contents of file "/tmp/test-report.md" should include "Deploy to production"
      End
    End
  End

  Describe "get_behavior_mode function"
    Context "with CI_TEST_MODE set"
      BeforeEach "export CI_TEST_MODE=DRY_RUN"

      It "should return CI_TEST_MODE value"
        When call get_behavior_mode "any_script" "EXECUTE"
        The output should equal "DRY_RUN"
      End
    End

    Context "with script-specific behavior set"
      BeforeEach "export CI_REPORT_GENERATOR_BEHAVIOR=PASS"

      It "should return script-specific behavior"
        When call get_behavior_mode "report_generator" "EXECUTE"
        The output should equal "PASS"
      End
    End

    Context "with pipeline-level behavior set"
      BeforeEach "export PIPELINE_SCRIPT_REPORT_GENERATOR_BEHAVIOR=FAIL"

      It "should return pipeline-level behavior"
        When call get_behavior_mode "report_generator" "EXECUTE"
        The output should equal "FAIL"
      End
    End

    Context "with no behavior set"
      It "should return default behavior"
        When call get_behavior_mode "report_generator" "EXECUTE"
        The output should equal "EXECUTE"
      End
    End
  End
End