#!/usr/bin/env bats

load '../build_helper'

setup() {
    setup_build_test
    setup_security_mocks
}

teardown() {
    teardown_build_test
}

@test "security-scan.sh executes successfully with mise available" {
    # GIVEN: Security scan script and mock mise command
    set_mock_mode "mise" "success"
    set_mock_output "mise" "mise version 2024.1.1"

    # WHEN: Running the security scan script
    cd "$FAKE_PROJECT_ROOT"
    run bash "$PROJECT_ROOT/scripts/build/security-scan.sh"

    # THEN: Script should execute successfully
    assert_success
    assert_output --partial "Running Security Scans"
}

@test "security-scan.sh fails when mise is not available" {
    # GIVEN: Security scan script without mise
    remove_mock "mise"

    # WHEN: Running the security scan script
    cd "$FAKE_PROJECT_ROOT"
    run bash "$PROJECT_ROOT/scripts/build/security-scan.sh"

    # THEN: Script should fail with mise error
    assert_failure
    assert_output --partial "mise not found"
    assert_output --partial "Please run setup script first"
}

@test "security-scan.sh runs gitleaks when available" {
    # GIVEN: Mock mise and gitleaks commands
    set_mock_output "mise" "mise version 2024.1.1"
    set_mock_output "gitleaks" "gitleaks version 8.18.0"
    set_mock_mode "gitleaks" "success"

    # WHEN: Running the security scan script
    cd "$FAKE_PROJECT_ROOT"
    run bash "$PROJECT_ROOT/scripts/build/security-scan.sh"

    # THEN: Script should run gitleaks
    assert_success
    assert_output --partial "Running gitleaks secret detection"
    assert_output --partial "No secrets detected by gitleaks"
}

@test "security-scan.sh runs trufflehog when available" {
    # GIVEN: Mock mise and trufflehog commands
    set_mock_output "mise" "mise version 2024.1.1"
    set_mock_output "trufflehog" "trufflehog version 3.81.0"
    set_mock_mode "trufflehog" "success"

    # WHEN: Running the security scan script
    cd "$FAKE_PROJECT_ROOT"
    run bash "$PROJECT_ROOT/scripts/build/security-scan.sh"

    # THEN: Script should run trufflehog
    assert_success
    assert_output --partial "Running trufflehog credential scan"
    assert_output --partial "No leaked credentials detected by trufflehog"
}

@test "security-scan.sh generates SARIF output" {
    # GIVEN: Mock mise and gitleaks commands
    set_mock_output "mise" "mise version 2024.1.1"
    set_mock_mode "gitleaks" "success"
    set_mock_mode "trufflehog" "success"

    # WHEN: Running the security scan script
    cd "$FAKE_PROJECT_ROOT"
    run bash "$PROJECT_ROOT/scripts/build/security-scan.sh"

    # THEN: Script should create SARIF file
    assert_success
    assert_output --partial "Security Scan Complete"

    # Check that SARIF file was created
    assert_file_exists "${FAKE_PROJECT_ROOT}/security-results.sarif"
}

@test "security-scan.sh handles gitleaks findings" {
    # GIVEN: Mock mise and gitleaks with findings
    set_mock_output "mise" "mise version 2024.1.1"
    set_mock_mode "gitleaks" "fail"
    set_mock_exit_code "gitleaks" "1"
    set_mock_output "gitleaks" "Secrets found!"

    # WHEN: Running the security scan script
    cd "$FAKE_PROJECT_ROOT"
    run bash "$PROJECT_ROOT/scripts/build/security-scan.sh"

    # THEN: Script should detect gitleaks findings and fail
    assert_failure
    assert_output --partial "Gitleaks found potential secrets"
}

@test "security-scan.sh handles trufflehog findings" {
    # GIVEN: Mock mise with gitleaks success and trufflehog findings
    set_mock_output "mise" "mise version 2024.1.1"
    set_mock_mode "gitleaks" "success"
    set_mock_mode "trufflehog" "fail"
    set_mock_exit_code "trufflehog" "1"
    set_mock_output "trufflehog" "Leaked credentials found!"

    # WHEN: Running the security scan script
    cd "$FAKE_PROJECT_ROOT"
    run bash "$PROJECT_ROOT/scripts/build/security-scan.sh"

    # THEN: Script should detect trufflehog findings and fail
    assert_failure
    assert_output --partial "Trufflehog found leaked credentials"
}

@test "security-scan.sh creates gitleaks and trufflehog reports" {
    # GIVEN: Mock mise and security tools
    set_mock_output "mise" "mise version 2024.1.1"
    set_mock_mode "gitleaks" "success"
    set_mock_mode "trufflehog" "success"

    # Mock file creation for reports
    mkdir -p "${FAKE_PROJECT_ROOT}"
    echo '{"summary": {"secretsFound": 0}}' > "${FAKE_PROJECT_ROOT}/gitleaks-report.json"
    echo '[]' > "${FAKE_PROJECT_ROOT}/trufflehog-report.json"

    # WHEN: Running the security scan script
    cd "$FAKE_PROJECT_ROOT"
    run bash "$PROJECT_ROOT/scripts/build/security-scan.sh"

    # THEN: Script should complete successfully
    assert_success
    assert_output --partial "Security Scan Complete"
}

@test "security-scan.sh contains commented examples for additional scanners" {
    # GIVEN: Security scan script is available
    run cat "$PROJECT_ROOT/scripts/build/security-scan.sh"

    # THEN: Script should contain examples for additional security tools
    assert_output --partial "NPM audit"
    assert_output --partial "Snyk scan"
    assert_output --partial "Python safety check"
    assert_output --partial "Trivy for container scanning"
    assert_output --partial "OWASP Dependency Check"
}

@test "security-scan.sh has proper error handling and exit codes" {
    # GIVEN: Security scan script exists
    run cat "$PROJECT_ROOT/scripts/build/security-scan.sh"

    # THEN: Script should have proper structure
    assert_line --partial "#!/usr/bin/env bash"
    assert_line --partial "set -euo pipefail"
    assert_line --partial "EXIT_CODE=0"
}

@test "security-scan.sh purpose and documentation is clear" {
    # GIVEN: Security scan script is available
    run cat "$PROJECT_ROOT/scripts/build/security-scan.sh"

    # THEN: Script should have clear documentation
    assert_output --partial "CI Pipeline Stub: Security Scan"
    assert_output --partial "Purpose: Run security vulnerability scans"
    assert_output --partial "Customize this script based on your project's security tools"
}

@test "security-scan.sh displays proper section headers" {
    # GIVEN: Security scan script is available
    run cat "$PROJECT_ROOT/scripts/build/security-scan.sh"

    # THEN: Script should contain proper section headers
    assert_line --partial "========================================="
    assert_line --partial "Running Security Scans"
    assert_line --partial "Security Scan Complete"
}