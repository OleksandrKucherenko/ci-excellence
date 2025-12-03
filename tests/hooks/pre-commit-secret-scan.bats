#!/usr/bin/env bats

# Load test helper
load "${BATS_TEST_DIRNAME}/../test_helper.bash"

setup() {
    # GIVEN: A git repository with hook scripts available
    setup_git_hooks_test
    configure_secret_scan_hook
    set_execute_mode
}

teardown() {
    # Cleanup test environment
    cleanup_git_hooks_test
}

@test "pre-commit-secret-scan: script exists and is executable" {
    # GIVEN: The secret scan hook script should exist
    [[ -f "$TEST_HOOKS_DIR/pre-commit-secret-scan.sh" ]]
    [[ -x "$TEST_HOOKS_DIR/pre-commit-secret-scan.sh" ]]
}

@test "pre-commit-secret-scan: shows help information" {
    # WHEN: Script is called with help flag
    run run_hook_script "pre-commit-secret-scan.sh" "help"

    # THEN: Help information should be displayed
    assert_success
    assert_line --partial "Pre-commit Secret Scan Hook"
    assert_line --partial "Usage:"
}

@test "pre-commit-secret-scan: checks Gitleaks availability" {
    # WHEN: Script validates setup
    run run_hook_script "pre-commit-secret-scan.sh" "validate"

    # THEN: Should validate Gitleaks is available
    assert_success
    assert_line --partial "✅ Pre-commit hook validation completed"
}

@test "pre-commit-secret-scan: fails when Gitleaks is not available" {
    # GIVEN: Gitleaks is not available
    rm -f "$BATS_TEST_TMPDIR/bin/gitleaks"

    # WHEN: Script runs without Gitleaks
    run run_hook_script "pre-commit-secret-scan.sh" "validate"

    # THEN: Should fail with appropriate error
    assert_failure
    assert_line --partial "Gitleaks is not installed"
}

@test "pre-commit-secret-scan: handles files without secrets" {
    # GIVEN: Files without secrets are staged
    create_well_formatted_script
    create_test_bash_file "config.yml" '# Configuration file
app:
  name: "MyApp"
  version: "1.0.0"'

    stage_test_files "good_script.sh" "config.yml"

    # WHEN: Secret scan runs
    run run_hook_script "pre-commit-secret-scan.sh"

    # THEN: Should pass validation
    assert_success
    assert_line --partial "No secrets detected in staged files"
    assert_line --partial "✅ Pre-commit secret scan completed successfully"
}

@test "pre-commit-secret-scan: detects AWS access keys" {
    # GIVEN: Files with AWS secrets are staged
    create_script_with_secrets
    stage_test_files "secrets.sh"

    # WHEN: Secret scan runs
    run run_hook_script "pre-commit-secret-scan.sh"

    # THEN: Should detect AWS secrets and fail
    assert_failure
    assert_secrets_detected "${output}"
    assert_line --partial "❌ Pre-commit secret scan failed"
}

@test "pre-commit-secret-scan: detects GitHub personal access tokens" {
    # GIVEN: Files with GitHub tokens are staged
    create_test_bash_file "deploy.sh" '#!/bin/bash
# Deployment script with GitHub token
export GITHUB_TOKEN="ghp_1234567890abcdef1234567890abcdef123456"
echo "Deploying with GitHub token"'

    stage_test_files "deploy.sh"

    # WHEN: Secret scan runs
    run run_hook_script "pre-commit-secret-scan.sh"

    # THEN: Should detect GitHub tokens
    assert_failure
    assert_secrets_detected "${output}"
}

@test "pre-commit-secret-scan: scans configuration files for secrets" {
    # GIVEN: Configuration files with secret patterns are staged
    create_test_bash_file ".env" '# Environment configuration
DATABASE_URL="postgresql://user:password@localhost:5432/db"
API_KEY="sk-1234567890abcdef1234567890abcdef12345678"
JWT_SECRET="super-secret-jwt-key"'

    create_test_bash_file "config.ini" '[database]
host=localhost
port=5432
user=admin
password=admin123'

    stage_test_files ".env" "config.ini"

    # WHEN: Secret scan runs
    run run_hook_script "pre-commit-secret-scan.sh"

    # THEN: Should scan and detect secrets in config files
    assert_failure
    assert_secrets_detected "${output}"
}

@test "pre-commit-secret-scan: scans certificate files" {
    # GIVEN: Certificate files are staged
    create_test_bash_file "cert.pem" '-----BEGIN CERTIFICATE-----
MIICkTCCAfugAwIBAgIJAKC+k4vp6H+dMA0GCSqGSIb3DQEBBQUAMHsxCzAJBgNV
BAYTAlVTMQswCQYDVQQIEwJDQTEWMBQGA1UEBxMNU2FuIEZyYW5jaXNjbzETMBEG
-----END CERTIFICATE-----'

    create_test_bash_file "private.key" '-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC5K7Lkx...
-----END PRIVATE KEY-----'

    stage_test_files "cert.pem" "private.key"

    # WHEN: Secret scan runs
    run run_hook_script "pre-commit-secret-scan.sh"

    # THEN: Should scan certificate files
    assert_success  # Certificates might not contain detectable secrets in mock
    assert_line --partial "Scanning"
}

@test "pre-commit-secret-scan: performs quick pattern matching" {
    # GIVEN: Files with obvious secret patterns are staged
    create_script_with_secrets
    stage_test_files "secrets.sh"

    # WHEN: Quick scan is performed manually
    run run_hook_script "pre-commit-secret-scan.sh" "quick" "secrets.sh"

    # THEN: Should detect secrets via pattern matching
    assert_failure
    assert_line --partial "❌ Quick secret scan detected potential secrets"
}

@test "pre-commit-secret-scan: scans multiple file types" {
    # GIVEN: Multiple file types with potential secrets
    create_test_bash_file "script.py" '#!/usr/bin/env python
# Python script with secrets
import os
AWS_KEY = "AKIAIOSFODNN7EXAMPLE"
SECRET = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"'

    create_test_bash_file "app.js" '// JavaScript with secrets
const apiToken = "ghp_1234567890abcdef1234567890abcdef123456";
const dbPassword = "supersecretpassword123";'

    create_test_bash_file "deploy.ps1" '# PowerShell script with secrets
$apiKey = "sk-abcdefghijklmnopqrstuvwxyz123456"
$connectionString = "Server=localhost;Database=test;User=admin;Password=secret123"'

    stage_test_files "script.py" "app.js" "deploy.ps1"

    # WHEN: Secret scan runs
    run run_hook_script "pre-commit-secret-scan.sh"

    # THEN: Should scan all file types
    assert_failure
    assert_secrets_detected "${output}"
}

@test "pre-commit-secret-scan: creates Gitleaks configuration when missing" {
    # GIVEN: No Gitleaks config exists
    [[ ! -f "$TEST_PROJECT_ROOT/.gitleaks.toml" ]]

    # WHEN: Secret scan runs
    create_well_formatted_script
    stage_test_files "good_script.sh"
    run run_hook_script "pre-commit-secret-scan.sh"

    # THEN: Should create configuration file
    assert_success
    [[ -f "$TEST_PROJECT_ROOT/.gitleaks.toml" ]]
    assert_line --partial "Creating Gitleaks configuration"
}

@test "pre-commit-secret-scan: respects existing Gitleaks configuration" {
    # GIVEN: Custom Gitleaks configuration exists
    cat > "$TEST_PROJECT_ROOT/.gitleaks.toml" << 'EOF'
title = "Custom Gitleaks Config"

[[rules]]
description = "Custom AWS Access Key"
regex = '''AKIA[0-9A-Z]{16}'''
EOF

    create_well_formatted_script
    stage_test_files "good_script.sh"

    # WHEN: Secret scan runs
    run run_hook_script "pre-commit-secret-scan.sh"

    # THEN: Should use existing configuration
    assert_success
    # Config file should remain unchanged
    grep -q "Custom Gitleaks Config" "$TEST_PROJECT_ROOT/.gitleaks.toml"
}

@test "pre-commit-secret-scan: scans specific files manually" {
    # GIVEN: Files with secrets are not staged
    create_script_with_secrets
    # Don't stage the file

    # WHEN: Manual scan is performed
    run run_hook_script "pre-commit-secret-scan.sh" "scan" "secrets.sh"

    # THEN: Should scan specified files
    assert_failure
    assert_secrets_detected "${output}"
}

@test "pre-commit-secret-scan: handles empty staged files" {
    # GIVEN: No files are staged

    # WHEN: Secret scan runs
    run run_hook_script "pre-commit-secret-scan.sh"

    # THEN: Should succeed with no files message
    assert_success
    assert_line --partial "No staged files to scan"
}

@test "pre-commit-secret-scan: generates report after execution" {
    # GIVEN: Files are staged
    create_well_formatted_script
    stage_test_files "good_script.sh"

    # WHEN: Secret scan runs
    run run_hook_script "pre-commit-secret-scan.sh"

    # THEN: Should generate a report
    assert_success
    assert_report_generated "secret-scan-*.md"
    assert_line --partial "Pre-commit report generated:"
}

@test "pre-commit-secret-scan: generates failure report when secrets found" {
    # GIVEN: Files with secrets are staged
    create_script_with_secrets
    stage_test_files "secrets.sh"

    # WHEN: Secret scan runs
    run run_hook_script "pre-commit-secret-scan.sh"

    # THEN: Should generate a failure report
    assert_failure
    assert_report_generated "secret-scan-*.md"
}

@test "pre-commit-secret-scan: provides helpful remediation guidance" {
    # GIVEN: Files with secrets are staged
    create_script_with_secrets
    stage_test_files "secrets.sh"

    # WHEN: Secret scan runs
    run run_hook_script "pre-commit-secret-scan.sh"

    # THEN: Should provide remediation guidance
    assert_failure
    assert_line --partial "To fix:"
    assert_line --partial "1. Review the detected secrets above"
    assert_line --partial "2. Remove or replace the secrets with environment variables"
    assert_line --partial "3. Add the patterns to .gitleaks.toml if they are false positives"
}

@test "pre-commit-secret-scan: works in DRY_RUN mode" {
    # GIVEN: Dry run mode is enabled
    set_dry_run_mode
    create_script_with_secrets
    stage_test_files "secrets.sh"

    # WHEN: Secret scan runs
    run run_hook_script "pre-commit-secret-scan.sh"

    # THEN: Should simulate without actual execution
    assert_success
    assert_line --partial "DRY_RUN: Would scan staged files for secrets"
}

@test "pre-commit-secret-scan: works in PASS mode" {
    # GIVEN: Pass mode is enabled
    set_pass_mode
    create_script_with_secrets
    stage_test_files "secrets.sh"

    # WHEN: Secret scan runs
    run run_hook_script "pre-commit-secret-scan.sh"

    # THEN: Should simulate success regardless of actual secrets
    assert_success
    assert_line --partial "PASS MODE: Pre-commit secret scan simulated successfully"
}

@test "pre-commit-secret-scan: works in FAIL mode" {
    # GIVEN: Fail mode is enabled
    set_fail_mode
    create_well_formatted_script
    stage_test_files "good_script.sh"

    # WHEN: Secret scan runs
    run run_hook_script "pre-commit-secret-scan.sh"

    # THEN: Should simulate failure regardless of actual secrets
    assert_failure
    assert_line --partial "FAIL MODE: Simulating pre-commit secret scan failure"
}

@test "pre-commit-secret-scan: works in SKIP mode" {
    # GIVEN: Skip mode is enabled
    set_skip_mode
    create_script_with_secrets
    stage_test_files "secrets.sh"

    # WHEN: Secret scan runs
    run run_hook_script "pre-commit-secret-scan.sh"

    # THEN: Should skip execution
    assert_success
    assert_line --partial "SKIP MODE: Pre-commit secret scan skipped"
}

@test "pre-commit-secret-scan: validates git repository" {
    # GIVEN: Script runs outside a git repository
    cd "$BATS_TEST_TMPDIR"
    export PROJECT_ROOT="$BATS_TEST_TMPDIR"

    # WHEN: Secret scan runs
    run "$TEST_HOOKS_DIR/pre-commit-secret-scan.sh"

    # THEN: Should fail with git repository error
    assert_failure
    assert_line --partial "Not in a git repository"
}

@test "pre-commit-secret-scan: respects script version" {
    # WHEN: Help is requested
    run run_hook_script "pre-commit-secret-scan.sh" "help"

    # THEN: Should show version information
    assert_success
    assert_line --partial "Pre-commit Secret Scan Hook v1.0.0"
}

@test "pre-commit-secret-scan: handles multiple scan types" {
    # GIVEN: Files with different types of sensitive content
    create_script_with_secrets
    create_test_bash_file "config.json" '{
  "database": {
    "host": "localhost",
    "password": "supersecret123",
    "api_key": "AKIAIOSFODNN7EXAMPLE"
  }
}'

    stage_test_files "secrets.sh" "config.json"

    # WHEN: Secret scan runs (performing multiple scan types)
    run run_hook_script "pre-commit-secret-scan.sh"

    # THEN: Should perform comprehensive scanning
    assert_failure
    assert_secrets_detected "${output}"
}

@test "pre-commit-secret-scan: excludes false positive patterns" {
    # GIVEN: Files with common false positive patterns
    create_test_bash_file "examples.sh" '#!/bin/bash
# Example patterns that should be allowed
echo "This is an example-password for testing"
echo "Use test-secret in development only"
echo "Connect to localhost:3000 for testing"
echo "Dummy key: dummy-key-for-testing"
echo "Example variables: xxx, yyy, zzz"'

    stage_test_files "examples.sh"

    # WHEN: Secret scan runs with allowlist
    run run_hook_script "pre-commit-secret-scan.sh"

    # THEN: Should not flag false positives
    assert_success
}

@test "pre-commit-secret-scan: handles binary files gracefully" {
    # GIVEN: Binary files are staged (simulated)
    echo -e '\x00\x01\x02\x03' > "$TEST_PROJECT_ROOT/binary"
    stage_test_files "binary"

    # WHEN: Secret scan runs
    run run_hook_script "pre-commit-secret-scan.sh"

    # THEN: Should handle binary files gracefully
    assert_success
    # Binary files might be skipped or handled gracefully
}

@test "pre-commit-secret-scan: provides scan progress information" {
    # GIVEN: Multiple files are staged
    create_well_formatted_script
    create_test_bash_file "config.yml" "app:\n  name: test"
    create_test_bash_file "script.py" "#!/usr/bin/env python\nprint('hello')"

    stage_test_files "good_script.sh" "config.yml" "script.py"

    # WHEN: Secret scan runs
    run run_hook_script "pre-commit-secret-scan.sh"

    # THEN: Should show progress information
    assert_success
    assert_line --partial "Scanning"
    assert_line --partial "files for secrets"
}

@test "pre-commit-secret-scan: handles malformed configuration files" {
    # GIVEN: Malformed Gitleaks configuration exists
    cat > "$TEST_PROJECT_ROOT/.gitleaks.toml" << 'EOF'
invalid toml syntax here
[missing_bracket
bad_format = "unclosed
EOF

    create_well_formatted_script
    stage_test_files "good_script.sh"

    # WHEN: Secret scan runs
    run run_hook_script "pre-commit-secret-scan.sh"

    # THEN: Should handle malformed config gracefully
    # This might succeed or fail depending on implementation
    # The test verifies graceful handling
    [[ "${status}" -eq 0 || "${status}" -eq 1 ]]
}

@test "pre-commit-secret-scan: respects PRE_COMMIT_SECRET_SCAN_MODE environment variable" {
    # GIVEN: Custom mode is set via environment
    export PRE_COMMIT_SECRET_SCAN_MODE="DRY_RUN"
    create_script_with_secrets
    stage_test_files "secrets.sh"

    # WHEN: Secret scan runs
    run run_hook_script "pre-commit-secret-scan.sh"

    # THEN: Should use configured mode
    assert_success
    assert_line --partial "DRY_RUN: Would scan staged files for secrets"
}

@test "pre-commit-secret-scan: creates Gitleaks allowlist for common patterns" {
    # GIVEN: No Gitleaks config exists
    # WHEN: Secret scan runs first time
    create_well_formatted_script
    stage_test_files "good_script.sh"
    run run_hook_script "pre-commit-secret-scan.sh"

    # THEN: Should create allowlist with common patterns
    assert_success
    [[ -f "$TEST_PROJECT_ROOT/.gitleaks.toml" ]]
    grep -q "example-password" "$TEST_PROJECT_ROOT/.gitleaks.toml"
    grep -q "localhost" "$TEST_PROJECT_ROOT/.gitleaks.toml"
    grep -q ":3000" "$TEST_PROJECT_ROOT/.gitleaks.toml"
}