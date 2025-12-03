#!/usr/bin/env bats

# Example refactored security tools test using the new mock system
# This demonstrates how to use the extracted security tool mock libraries

# Load the mock loader system
load "${BATS_TEST_DIRNAME}/../mocks/mock-loader.bash"
load "${BATS_TEST_DIRNAME}/../test_helper.bash"

setup() {
    # GIVEN: Setup mocks for security scanning
    bats_setup_with_mocks "security"

    # Create test project with files
    mkdir -p "$BATS_TEST_TMPDIR/project"
    cd "$BATS_TEST_TMPDIR/project"

    # Create files with and without secrets
    cat > clean_file.txt << 'EOF'
This file contains no secrets
Just regular configuration
EOF

    cat > secrets_file.txt << 'EOF'
This file contains secrets
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
DATABASE_PASSWORD=super-secret-password
GITHUB_TOKEN=ghp_1234567890abcdef1234567890abcdef123456
EOF
}

teardown() {
    # Clean up mocks and test environment
    bats_teardown_with_mocks
}

@test "gitleaks scan finds no secrets in clean files" {
    # WHEN: Running gitleaks scan on clean files
    run gitleaks detect --repo .

    # THEN: Should report no secrets found
    assert_success
    assert_output --partial "No secrets found"
}

@test "gitleaks scan detects secrets" {
    # GIVEN: Configure gitleaks to find secrets
    set_security_tool_mocks_has_secrets

    # WHEN: Running gitleaks scan
    run gitleaks detect --repo .

    # THEN: Should detect secrets
    assert_failure
    assert_output --partial "Secrets found: 3"
}

@test "trufflehog filesystem scan works correctly" {
    # WHEN: Running trufflehog filesystem scan
    run trufflehog filesystem .

    # THEN: Should complete scan
    assert_success
    assert_output --partial "No secrets found"
}

@test "trufflehog filesystem scan detects secrets" {
    # GIVEN: Configure trufflehog to find secrets
    set_security_tool_mocks_has_secrets

    # WHEN: Running trufflehog filesystem scan
    run trufflehog filesystem .

    # THEN: Should detect secrets
    assert_failure
    assert_output --partial "Found credentials"
}

@test "shellcheck passes clean bash files" {
    # GIVEN: Create a clean bash file
    cat > clean_script.sh << 'EOF'
#!/bin/bash
# Clean script with no issues
echo "Hello, world!"
if [[ "$1" == "test" ]]; then
    echo "Test mode"
fi
EOF

    # WHEN: Running shellcheck
    run shellcheck clean_script.sh

    # THEN: Should pass without issues
    assert_success
    assert_output --partial "All files passed shellcheck analysis"
}

@test "shellcheck detects issues in problematic files" {
    # GIVEN: Configure shellcheck to fail
    set_shellcheck_for_strict_linting

    # WHEN: Running shellcheck on secrets file (will have issues)
    run shellcheck secrets_file.txt

    # THEN: Should detect issues
    assert_failure
}

@test "detect-secrets scan works correctly" {
    # WHEN: Running detect-secrets scan
    run detect-secrets scan .

    # THEN: Should complete scan
    assert_success
    assert_output --partial "No secrets detected"
}

@test "detect-secrets scan detects secrets" {
    # GIVEN: Configure detect-secrets to find secrets
    set_security_tool_mocks_has_secrets

    # WHEN: Running detect-secrets scan
    run detect-secrets scan .

    # THEN: Should detect secrets
    assert_failure
    assert_output --partial "Potential secrets detected"
}

@test "comprehensive security scan uses all tools" {
    # WHEN: Running comprehensive security scan
    run run_secrets_scan "all" .

    # THEN: Should complete all scans
    assert_success
}

@test "security scan failure mode works correctly" {
    # GIVEN: Set security tools to failure mode
    set_security_tool_mocks_scan_failure

    # WHEN: Running gitleaks scan
    run gitleaks detect --repo .

    # THEN: Should fail with error
    assert_failure
}

@test "mock configuration can be customized" {
    # GIVEN: Configure specific tool versions
    configure_mock "gitleaks_version" "v9.0.0"
    configure_mock "trufflehog_version" "4.0.0"

    # WHEN: Checking tool versions
    run gitleaks --version
    assert_output "v9.0.0"

    run trufflehog --version
    assert_output "4.0.0"
}

@test "security tools can scan specific files" {
    # WHEN: Running gitleaks on specific file
    run gitleaks detect secrets_file.txt

    # THEN: Should complete scan
    assert_success
}

@test "shellcheck can use different severity levels" {
    # WHEN: Running shellcheck with error severity
    run shellcheck -S error clean_script.sh

    # THEN: Should complete
    assert_success
}