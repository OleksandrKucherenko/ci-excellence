#!/usr/bin/env bash
# ShellSpec tests for Security Scan Script
# Tests the Gitleaks and Trufflehog integration for secret detection

set -euo pipefail

# Load the script under test
# shellcheck disable=SC1090,SC1091
. "$(dirname "$0")/../../../scripts/build/30-ci-security-scan.sh" 2>/dev/null || {
  echo "Failed to source 30-ci-security-scan.sh" >&2
  exit 1
}

# Setup test environment
setup_test_environment() {
  # Create test directory
  mkdir -p "/tmp/security-scan-test"
  cd "/tmp/security-scan-test"

  # Initialize git repository
  git init >/dev/null 2>&1
  git config user.email "test@example.com"
  git config user.name "Test User"

  # Create test files with various content
  mkdir -p scripts config docs

  # Create safe files
  cat > scripts/test.sh << 'EOF'
#!/bin/bash
# Test script with no secrets
echo "This is a safe script"
echo "No secrets here"
EOF

  cat > config/app.json << 'EOF'
{
  "app_name": "test-application",
  "version": "1.0.0",
  "debug": true
}
EOF

  # Set test environment variables
  export SECURITY_SCAN_MODE="${SECURITY_SCAN_MODE:-EXECUTE}"
  export CI_TEST_MODE="${CI_TEST_MODE:-EXECUTE}"
}

# Cleanup test environment
cleanup_test_environment() {
  cd - >/dev/null
  rm -rf "/tmp/security-scan-test"
}

# Mock security scanning tools
mock_security_tools() {
  # Mock gitleaks
  gitleaks() {
    case "$1" in
      "protect")
        echo "Scanning for secrets..."
        echo "No secrets detected"
        return 0
        ;;
      "detect")
        echo "Scanning repository for secrets..."
        echo "Commits scanned: 10"
        echo "Secrets found: 0"
        echo "File scanned: 5"
        return 0
        ;;
      "--version")
        echo "gitleaks version v8.18.2"
        ;;
      *)
        echo "gitleaks $*"
        return 0
        ;;
    esac
  }

  # Mock trufflehog
  trufflehog() {
    case "$1" in
      "git")
        case "$2" in
          "--only-verified")
            echo "Scanning git history for verified secrets..."
            echo "Found 0 verified secrets"
            return 0
            ;;
          "--fail")
            echo "Scanning git history for secrets..."
            echo "Found 0 secrets"
            return 0
            ;;
          *)
            echo "trufflehog git $*"
            return 0
            ;;
        esac
        ;;
      "filesystem")
        echo "Scanning filesystem for secrets..."
        echo "Found 0 secrets in files"
        return 0
        ;;
      "--version")
        echo "trufflehog v3.66.0"
        ;;
      *)
        echo "trufflehog $*"
        return 0
        ;;
    esac
  }

  # Mock detect-secrets
  detect-secrets() {
    case "$1" in
      "scan")
        echo "Scanning for high-entropy strings..."
        echo "No secrets detected"
        return 0
        ;;
      "--version")
        echo "detect-secrets 1.4.0"
        ;;
      *)
        echo "detect-secrets $*"
        return 0
        ;;
    esac
  }

  # Mock shhgit
  shhgit() {
    echo "Scanning with shhgit..."
    echo "No secrets found"
    return 0
  }
}

# Mock tools with failures
mock_security_tools_failure() {
  # Mock gitleaks with failure
  gitleaks() {
    case "$1" in
      "protect")
        echo "Scanning for secrets..."
        echo "❌ SECRET DETECTED"
        echo "File: config/secrets.json"
        echo "Line: 3"
        echo "Secret: api_key='sk-1234567890abcdef'"
        return 1
        ;;
      *)
        echo "gitleaks $*"
        return 0
        ;;
    esac
  }

  # Mock trufflehog with failure
  trufflehog() {
    case "$1" in
      "git")
        case "$2" in
          "--fail")
            echo "❌ SECRET DETECTED"
            echo "Found AWS secret key in commit abc123"
            echo "AKIAIOSFODNN7EXAMPLE"
            return 1
            ;;
        esac
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

Describe "Security Scan Script"
  BeforeEach "setup_test_environment"
  BeforeEach "mock_security_tools"
  BeforeEach "mock_logging_functions"
  AfterEach "cleanup_test_environment"

  Describe "tool availability validation"
    Context "when all security tools are available"
      It "should validate gitleaks installation"
        When call check_gitleaks_available
        The status should be success
        The output should include "Gitleaks is available"
      End

      It "should validate trufflehog installation"
        When call check_trufflehog_available
        The status should be success
        The output should include "Trufflehog is available"
      End

      It "should validate detect-secrets installation"
        When call check_detect_secrets_available
        The status should be success
        The output should include "Detect-secrets is available"
      End

      It "should validate all tools are available"
        When call validate_security_tools
        The status should be success
        The output should include "All security tools are available"
      End
    End

    Context "when security tools are not available"
      BeforeEach "unset -f gitleaks trufflehog detect-secrets"

      It "should handle missing gitleaks"
        When call check_gitleaks_available
        The status should be failure
        The output should include "Gitleaks is not installed"
      End

      It "should handle missing trufflehog"
        When call check_trufflehog_available
        The status should be failure
        The output should include "Trufflehog is not installed"
      End

      It "should fail validation when tools are missing"
        When call validate_security_tools
        The status should be failure
        The output should include "Some security tools are missing"
      End
    End
  End

  Describe "git repository validation"
    Context "when in valid git repository"
      It "should validate git repository"
        When call validate_git_repository
        The status should be success
        The output should include "Git repository validation passed"
      End

      It "should get git information"
        When call get_git_info
        The output should include "Repository: /tmp/security-scan-test"
        The output should include "Current commit:"
      End
    End

    Context "when not in git repository"
      BeforeEach "cd /tmp"

      It "should fail git repository validation"
        When call validate_git_repository
        The status should be failure
        The output should include "Not in a git repository"
      End
    End
  End

  Describe "gitleaks scanning"
    Context "when scanning clean repository"
      It "should run gitleaks protect successfully"
        When call run_gitleaks_scan
        The status should be success
        The output should include "Gitleaks protect completed"
        The output should include "No secrets detected"
      End

      It "should run gitleaks detect successfully"
        When call run_gitleaks_detect
        The status should be success
        The output should include "Gitleaks detect completed"
        The output should include "Secrets found: 0"
      End

      It "should generate gitleaks report"
        When call generate_gitleaks_report
        The file "/tmp/security-scan-test/gitleaks-report.json" should exist
      End
    End

    Context "when gitleaks detects secrets"
      BeforeEach "mock_security_tools_failure"

      It "should handle gitleaks secrets detection"
        When call run_gitleaks_scan
        The status should be failure
        The output should include "❌ Gitleaks detected secrets"
      End
    End
  End

  Describe "trufflehog scanning"
    Context "when scanning clean repository"
      It "should run trufflehog git scan successfully"
        When call run_trufflehog_git_scan
        The status should be success
        The output should include "Trufflehog git scan completed"
        The output should include "Found 0 verified secrets"
      End

      It "should run trufflehog filesystem scan"
        When call run_trufflehog_filesystem_scan
        The status should be success
        The output should include "Trufflehog filesystem scan completed"
      End

      It "should generate trufflehog report"
        When call generate_trufflehog_report
        The file "/tmp/security-scan-test/trufflehog-report.json" should exist
      End
    End

    Context "when trufflehog detects secrets"
      BeforeEach "mock_security_tools_failure"

      It "should handle trufflehog secrets detection"
        When call run_trufflehog_git_scan
        The status should be failure
        The output should include "❌ Trufflehog detected secrets"
      End
    End
  End

  Describe "detect-secrets scanning"
    Context "when scanning clean repository"
      It "should run detect-secrets scan successfully"
        When call run_detect_secrets_scan
        The status should be success
        The output should include "Detect-secrets scan completed"
        The output should include "No high-entropy strings detected"
      End

      It "should generate detect-secrets baseline"
        When call create_detect_secrets_baseline
        The file "/tmp/security-scan-test/.secrets.baseline" should exist
      End
    End
  End

  Describe "shhgit scanning"
    Context "when scanning clean repository"
      It "should run shhgit scan successfully"
        When call run_shhgit_scan
        The status should be success
        The output should include "Shhgit scan completed"
        The output should include "No secrets found"
      End
    End
  End

  Describe "comprehensive security scan"
    Context "when running all security tools"
      It "should run complete security scan successfully"
        When call run_security_scan "all"
        The status should be success
        The output should include "Comprehensive security scan completed"
        The output should include "Gitleaks protect completed"
        The output should include "Trufflehog git scan completed"
        The output should include "Detect-secrets scan completed"
      End

      It "should generate all security reports"
        When call run_security_scan "all"
        The file "/tmp/security-scan-test/gitleaks-report.json" should exist
        The file "/tmp/security-scan-test/trufflehog-report.json" should exist
        The file "/tmp/security-scan-test/detect-secrets-report.json" should exist
      End
    End

    Context "when running specific tools"
      It "should run only gitleaks when specified"
        When call run_security_scan "gitleaks"
        The output should include "Gitleaks protect completed"
        The output should not include "Trufflehog"
        The output should not include "Detect-secrets"
      End

      It "should run only trufflehog when specified"
        When call run_security_scan "trufflehog"
        The output should include "Trufflehog git scan completed"
        The output should not include "Gitleaks"
        The output should not include "Detect-secrets"
      End

      It "should run only detect-secrets when specified"
        When call run_security_scan "detect-secrets"
        The output should include "Detect-secrets scan completed"
        The output should not include "Gitleaks"
        The output should not include "Trufflehog"
      End
    End
  End

  Describe "behavior modes"
    Context "when in EXECUTE mode"
      BeforeEach "export SECURITY_SCAN_MODE=EXECUTE"

      It "should execute actual security scans"
        When call run_security_scan "gitleaks"
        The status should be success
        The output should not include "DRY RUN"
      End
    End

    Context "when in DRY_RUN mode"
      BeforeEach "export SECURITY_SCAN_MODE=DRY_RUN"

      It "should simulate security scans without execution"
        When call run_security_scan "all"
        The output should include "🔍 DRY RUN: Would run security scan"
        The output should include "Would run: gitleaks protect"
        The output should include "Would run: trufflehog git"
        The output should include "Would run: detect-secrets scan"
      End
    End

    Context "when in FAIL mode"
      BeforeEach "export SECURITY_SCAN_MODE=FAIL"

      It "should simulate security scan failure"
        When call run_security_scan "all"
        The status should be failure
        The output should include "FAIL MODE: Simulating security scan failure"
      End
    End

    Context "when in SKIP mode"
      BeforeEach "export SECURITY_SCAN_MODE=SKIP"

      It "should skip security scan execution"
        When call run_security_scan "all"
        The status should be success
        The output should include "SKIP MODE: Security scan skipped"
      End
    End

    Context "when in TIMEOUT mode"
      BeforeEach "export SECURITY_SCAN_MODE=TIMEOUT"

      It "should simulate security scan timeout"
        When call run_security_scan "all"
        The status should equal 124  # TIMEOUT exit code
        The output should include "TIMEOUT MODE: Simulating security scan timeout"
      End
    End
  End

  Describe "report generation"
    Context "when generating security reports"
      It "should create comprehensive security summary"
        When call generate_security_summary "all"
        The file "/tmp/security-scan-test/security-summary.md" should exist
        The contents of file "/tmp/security-scan-test/security-summary.md" should include "# 🔒 Security Scan Summary"
        The contents of file "/tmp/security-scan-test/security-summary.md" should include "## Scan Results"
      End

      It "should include scan statistics in summary"
        When call generate_security_summary "all"
        The contents of file "/tmp/security-scan-test/security-summary.md" should include "Total Scans"
        The contents of file "/tmp/security-scan-test/security-summary.md" should include "Secrets Found"
      End

      It "should include tool versions in summary"
        When call generate_security_summary "all"
        The contents of file "/tmp/security-scan-test/security-summary.md" should include "## Tool Versions"
        The contents of file "/tmp/security-scan-test/security-summary.md" should include "Gitleaks"
        The contents of file "/tmp/security-scan-test/security-summary.md" should include "Trufflehog"
      End
    End
  End

  Describe "file pattern filtering"
    Context "when scanning specific file patterns"
      It "should scan only specified patterns"
        When call run_security_scan_with_patterns "scripts/*.sh" "*.json"
        The status should be success
        The output should include "Scanning patterns: scripts/*.sh *.json"
      End

      It "should handle empty pattern list"
        When call run_security_scan_with_patterns ""
        The status should be success
        The output should include "No specific patterns provided, scanning all files"
      End
    End
  End

  Describe "error handling and recovery"
    Context "when security tool fails"
      It "should continue with other tools when one fails"
        BeforeEach "mock_security_tools_failure"

        When call run_security_scan "all"
        The status should be failure
        The output should include "Some security scans failed"
        The output should include "Continuing with remaining tools"
      End

      It "should generate partial report on failure"
        BeforeEach "mock_security_tools_failure"

        When call generate_security_summary "all"
        The file "/tmp/security-scan-test/security-summary.md" should exist
        The contents of file "/tmp/security-scan-test/security-summary.md" should include "## Scan Failures"
      End
    End
  End
End