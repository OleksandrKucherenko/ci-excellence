#!/usr/bin/env bats

load '../build_helper'

setup() {
    setup_build_test
    setup_security_mocks
    # Create mock common library in the expected location
    mkdir -p "${FAKE_PROJECT_ROOT}/scripts/lib"
    cp "${TEST_TEMP_DIR}/lib/common.sh" "${FAKE_PROJECT_ROOT}/scripts/lib/common.sh"

    # Initialize git repository for security scan tests
    cd "$FAKE_PROJECT_ROOT" || exit 1
    git init >/dev/null 2>&1 || true
    git config user.email "test@example.com"
    git config user.name "Test User"
    echo "test" > test.txt
    git add test.txt
    git commit -m "Initial commit" >/dev/null 2>&1 || true
}

teardown() {
    teardown_build_test
}

@test "30-ci-security-scan.sh exists and is executable" {
    # GIVEN: CI security scan script should exist
    # THEN: Script file should exist and be executable
    assert_file_exists "$PROJECT_ROOT/scripts/build/30-ci-security-scan.sh"
    assert_file_executable "$PROJECT_ROOT/scripts/build/30-ci-security-scan.sh"
}

@test "30-ci-security-scan.sh has proper shebang and error handling" {
    # GIVEN: CI security scan script is available
    run cat "$PROJECT_ROOT/scripts/build/30-ci-security-scan.sh"

    # THEN: Script should have proper structure
    assert_line --partial "#!/bin/bash"
    assert_line --partial "set -euo pipefail"
}

@test "30-ci-security-scan.sh sources common utilities correctly" {
    # GIVEN: CI security scan script sources common utilities
    run grep -n "source.*common.sh" "$PROJECT_ROOT/scripts/build/30-ci-security-scan.sh"

    # THEN: Script should source common utilities
    assert_success
    assert_output --partial "scripts/lib/common.sh"
}

@test "30-ci-security-scan.sh validates security tools availability" {
    # GIVEN: Mock security tools are available
    set_mock_output "gitleaks" "gitleaks version 8.18.0"
    set_mock_output "trufflehog" "trufflehog version 3.81.0"
    set_mock_output "detect-secrets" "detect-secrets 1.0.0"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running security scan script in validate mode
    run bash "$PROJECT_ROOT/scripts/build/30-ci-security-scan.sh" validate gitleaks

    # THEN: Should validate tools successfully
    assert_success
    assert_output --partial "Available security tools"
}

@test "30-ci-security-scan.sh handles missing security tools gracefully" {
    # GIVEN: Some security tools are missing
    remove_mock "gitleaks"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running security scan script
    run bash "$PROJECT_ROOT/scripts/build/30-ci-security-scan.sh" gitleaks

    # THEN: Should handle missing tools gracefully
    assert_failure
    assert_output --partial "No security tools are available"
}

@test "30-ci-security-scan.sh handles DRY_RUN mode correctly" {
    # GIVEN: Test environment with DRY_RUN mode
    export CI_TEST_MODE="DRY_RUN"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running security scan script
    run bash "$PROJECT_ROOT/scripts/build/30-ci-security-scan.sh" all

    # THEN: Should perform dry run
    assert_success
    assert_output --partial "DRY RUN"
    assert_output --partial "Would run security scan"
}

@test "30-ci-security-scan.sh handles PASS mode correctly" {
    # GIVEN: Test environment with PASS mode
    export CI_TEST_MODE="PASS"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running security scan script
    run bash "$PROJECT_ROOT/scripts/build/30-ci-security-scan.sh" all

    # THEN: Should simulate success
    assert_success
    assert_output --partial "PASS MODE"
    assert_output --partial "simulated successfully"
}

@test "30-ci-security-scan.sh handles FAIL mode correctly" {
    # GIVEN: Test environment with FAIL mode
    export CI_TEST_MODE="FAIL"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running security scan script
    run bash "$PROJECT_ROOT/scripts/build/30-ci-security-scan.sh" all

    # THEN: Should simulate failure
    assert_failure
    assert_output --partial "FAIL MODE"
    assert_output --partial "Simulating security scan failure"
}

@test "30-ci-security-scan.sh handles SKIP mode correctly" {
    # GIVEN: Test environment with SKIP mode
    export CI_TEST_MODE="SKIP"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running security scan script
    run bash "$PROJECT_ROOT/scripts/build/30-ci-security-scan.sh" all

    # THEN: Should skip security scan
    assert_success
    assert_output --partial "SKIP MODE"
    assert_output --partial "Security scan skipped"
}

@test "30-ci-security-scan.sh runs gitleaks protect scan" {
    # GIVEN: Mock gitleaks available
    set_mock_output "gitleaks" "gitleaks version 8.18.0"
    set_mock_mode "gitleaks" "success"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running security scan script
    run bash "$PROJECT_ROOT/scripts/build/30-ci-security-scan.sh" all

    # THEN: Should run gitleaks protect
    assert_success
    assert_output --partial "Running Gitleaks protect scan"
    assert_output --partial "Gitleaks protect completed"
}

@test "30-ci-security-scan.sh runs gitleaks detect scan" {
    # GIVEN: Mock gitleaks available
    set_mock_output "gitleaks" "gitleaks version 8.18.0"
    set_mock_mode "gitleaks" "success"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running security scan script
    run bash "$PROJECT_ROOT/scripts/build/30-ci-security-scan.sh" all

    # THEN: Should run gitleaks detect
    assert_success
    assert_output --partial "Running Gitleaks detect scan"
    assert_output --partial "Gitleaks detect completed"
}

@test "30-ci-security-scan.sh runs trufflehog git scan" {
    # GIVEN: Mock trufflehog available
    set_mock_output "trufflehog" "trufflehog version 3.81.0"
    set_mock_mode "trufflehog" "success"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running security scan script
    run bash "$PROJECT_ROOT/scripts/build/30-ci-security-scan.sh" all

    # THEN: Should run trufflehog git scan
    assert_success
    assert_output --partial "Running Trufflehog git scan"
    assert_output --partial "Trufflehog git scan completed"
}

@test "30-ci-security-scan.sh runs trufflehog filesystem scan" {
    # GIVEN: Mock trufflehog available and project files
    set_mock_output "trufflehog" "trufflehog version 3.81.0"
    set_mock_mode "trufflehog" "success"
    mkdir -p "${FAKE_PROJECT_ROOT}/scripts"
    echo "#!/bin/bash" > "${FAKE_PROJECT_ROOT}/scripts/test.sh"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running security scan script
    run bash "$PROJECT_ROOT/scripts/build/30-ci-security-scan.sh" all

    # THEN: Should run trufflehog filesystem scan
    assert_success
    assert_output --partial "Running Trufflehog filesystem scan"
}

@test "30-ci-security-scan.sh runs detect-secrets scan" {
    # GIVEN: Mock detect-secrets available
    set_mock_output "detect-secrets" "detect-secrets 1.0.0"
    set_mock_mode "detect-secrets" "success"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running security scan script
    run bash "$PROJECT_ROOT/scripts/build/30-ci-security-scan.sh" all

    # THEN: Should run detect-secrets scan
    assert_success
    assert_output --partial "Running detect-secrets scan"
    assert_output --partial "Detect-secrets scan completed"
}

@test "30-ci-security-scan.sh handles gitleaks findings" {
    # GIVEN: Mock gitleaks with findings
    set_mock_mode "gitleaks" "fail"
    set_mock_exit_code "gitleaks" "1"
    set_mock_output "gitleaks" "Secrets found!"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running security scan script
    run bash "$PROJECT_ROOT/scripts/build/30-ci-security-scan.sh" all

    # THEN: Should detect gitleaks findings and fail
    assert_failure
    assert_output --partial "Security scan completed with issues"
}

@test "30-ci-security-scan.sh handles trufflehog findings" {
    # GIVEN: Mock trufflehog with findings
    set_mock_mode "trufflehog" "fail"
    set_mock_exit_code "trufflehog" "1"
    set_mock_output "trufflehog" "Leaked credentials found!"
    set_mock_mode "gitleaks" "success"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running security scan script
    run bash "$PROJECT_ROOT/scripts/build/30-ci-security-scan.sh" all

    # THEN: Should detect trufflehog findings and fail
    assert_failure
    assert_output --partial "Security scan completed with issues"
}

@test "30-ci-security-scan.sh supports scanner-specific scopes" {
    # GIVEN: Mock gitleaks available
    set_mock_output "gitleaks" "gitleaks version 8.18.0"
    set_mock_mode "gitleaks" "success"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running security scan script with gitleaks scope
    run bash "$PROJECT_ROOT/scripts/build/30-ci-security-scan.sh" gitleaks

    # THEN: Should run only gitleaks scans
    assert_success
    assert_output --partial "Running Gitleaks protect scan"
    assert_output --partial "Running Gitleaks detect scan"
}

@test "30-ci-security-scan.sh supports trufflehog-specific scope" {
    # GIVEN: Mock trufflehog available
    set_mock_output "trufflehog" "trufflehog version 3.81.0"
    set_mock_mode "trufflehog" "success"
    set_mock_mode "gitleaks" "success"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running security scan script with trufflehog scope
    run bash "$PROJECT_ROOT/scripts/build/30-ci-security-scan.sh" trufflehog

    # THEN: Should run only trufflehog scans
    assert_success
    assert_output --partial "Running Trufflehog git scan"
    assert_output --partial "Running Trufflehog filesystem scan"
}

@test "30-ci-security-scan.sh supports detect-secrets-specific scope" {
    # GIVEN: Mock detect-secrets available
    set_mock_output "detect-secrets" "detect-secrets 1.0.0"
    set_mock_mode "detect-secrets" "success"
    set_mock_mode "gitleaks" "success"
    set_mock_mode "trufflehog" "success"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running security scan script with detect-secrets scope
    run bash "$PROJECT_ROOT/scripts/build/30-ci-security-scan.sh" detect-secrets

    # THEN: Should run only detect-secrets scan
    assert_success
    assert_output --partial "Running detect-secrets scan"
}

@test "30-ci-security-scan.sh creates security reports directory" {
    # GIVEN: Mock security tools available
    set_mock_output "gitleaks" "gitleaks version 8.18.0"
    set_mock_output "trufflehog" "trufflehog version 3.81.0"
    set_mock_mode "gitleaks" "success"
    set_mock_mode "trufflehog" "success"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running security scan script
    run bash "$PROJECT_ROOT/scripts/build/30-ci-security-scan.sh" all

    # THEN: Should create security reports directory
    assert_success
    assert_dir_exists "${FAKE_PROJECT_ROOT}/.github/security-reports"
}

@test "30-ci-security-scan.sh generates security summary" {
    # GIVEN: Mock security tools available
    set_mock_output "gitleaks" "gitleaks version 8.18.0"
    set_mock_output "trufflehog" "trufflehog version 3.81.0"
    set_mock_output "jq" "jq-1.6"
    set_mock_mode "gitleaks" "success"
    set_mock_mode "trufflehog" "success"
    set_mock_mode "jq" "success"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running security scan script
    run bash "$PROJECT_ROOT/scripts/build/30-ci-security-scan.sh" all

    # THEN: Should generate security summary
    assert_success
    assert_output --partial "Generating security scan summary"
    assert_output --partial "Security scan completed successfully"
}

@test "30-ci-security-scan.sh shows help information" {
    # GIVEN: CI security scan script
    # WHEN: Running with help flag
    run bash "$PROJECT_ROOT/scripts/build/30-ci-security-scan.sh" help

    # THEN: Should show help information
    assert_success
    assert_output --partial "CI Security Scan Script"
    assert_output --partial "Usage:"
    assert_output --partial "Arguments:"
    assert_output --partial "Options:"
    assert_output --partial "Environment Variables:"
}

@test "30-ci-security-scan.sh supports environment-based tool control" {
    # GIVEN: Environment variable to disable gitleaks
    export ENABLE_GITLEAKS="false"
    set_mock_output "trufflehog" "trufflehog version 3.81.0"
    set_mock_mode "trufflehog" "success"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running security scan script
    run bash "$PROJECT_ROOT/scripts/build/30-ci-security-scan.sh" all

    # THEN: Should skip gitleaks and run other tools
    assert_success
    assert_output --partial "Gitleaks is disabled"
    assert_output --partial "Running Trufflehog git scan"
}

@test "30-ci-security-scan.sh validates git repository" {
    # GIVEN: Mock security tools available
    set_mock_output "gitleaks" "gitleaks version 8.18.0"
    set_mock_mode "gitleaks" "success"

    # Create non-git directory
    local non_git_dir="${BATS_TMPDIR}/non-git-project"
    mkdir -p "$non_git_dir"
    cd "$non_git_dir"

    # WHEN: Running security scan script
    run bash "$PROJECT_ROOT/scripts/build/30-ci-security-scan.sh" all

    # THEN: Should fail due to non-git repository
    assert_failure
    assert_output --partial "Git repository validation failed"
}

@test "30-ci-security-scan.sh provides comprehensive scan results summary" {
    # GIVEN: Mock security tools available
    set_mock_output "gitleaks" "gitleaks version 8.18.0"
    set_mock_output "trufflehog" "trufflehog version 3.81.0"
    set_mock_output "detect-secrets" "detect-secrets 1.0.0"
    set_mock_mode "gitleaks" "success"
    set_mock_mode "trufflehog" "success"
    set_mock_mode "detect-secrets" "success"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running security scan script
    run bash "$PROJECT_ROOT/scripts/build/30-ci-security-scan.sh" all

    # THEN: Should provide comprehensive scan results
    assert_success
    assert_output --partial "Security Scan Results:"
    assert_output --partial "gitleaks-protect: success"
    assert_output --partial "gitleaks-detect: success"
    assert_output --partial "trufflehog-git: success"
    assert_output --partial "trufflehog-filesystem: success"
    assert_output --partial "detect-secrets: success"
}