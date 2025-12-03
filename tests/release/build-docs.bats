#!/usr/bin/env bats

# Load deployment test helper
load "${BATS_TEST_DIRNAME}/../test_helper.bash"

setup() {
    # GIVEN: A clean test environment
    setup_deployment_test_project
}

teardown() {
    # Cleanup test environment
    cleanup_deployment_test_project
}

@test "build docs script runs without errors" {
    # WHEN: Running the build-docs script
    run bash -c "${TEST_RELEASE_DIR}/build-docs.sh"

    # THEN: Script executes successfully
    assert_success
    assert_output --partial "Building Documentation"
    assert_output --partial "Documentation Built"
}

@test "build docs script provides clear output formatting" {
    # WHEN: Running the script
    run bash -c "${TEST_RELEASE_DIR}/build-docs.sh"

    # THEN: Output is properly formatted
    assert_success
    assert_line --partial "========================================="
    assert_line --partial "Building Documentation"
    assert_line --partial "Documentation Built"
    assert_line --partial "========================================="
}

@test "build docs script includes usage documentation" {
    # GIVEN: Script should document its purpose
    # WHEN: Checking script content
    run grep -E "# CI Pipeline Stub: Build Documentation" "${TEST_RELEASE_DIR}/build-docs.sh"

    # THEN: Documentation is present
    assert_success
    assert_output "# CI Pipeline Stub: Build Documentation"
}

@test "build docs script uses set -euo pipefail" {
    # GIVEN: Script should use strict error handling
    # WHEN: Checking script content
    run grep -E "set -euo pipefail" "${TEST_RELEASE_DIR}/build-docs.sh"

    # THEN: Strict mode is enabled
    assert_success
    assert_output "set -euo pipefail"
}

@test "build docs script includes proper shebang" {
    # GIVEN: Script should have proper shebang
    # WHEN: Checking script content
    run head -n 1 "${TEST_RELEASE_DIR}/build-docs.sh"

    # THEN: Shebang is present
    assert_success
    assert_output "#!/usr/bin/env bash"
}

@test "build docs script provides extensible structure" {
    # GIVEN: Script should be extensible
    # WHEN: Checking for customization points
    run grep -E "# Add your documentation build commands here" "${TEST_RELEASE_DIR}/build-docs.sh"

    # THEN: Customization point is present
    assert_success
}

@test "build docs script shows stub execution message" {
    # WHEN: Running the script
    run bash -c "${TEST_RELEASE_DIR}/build-docs.sh"

    # THEN: Stub execution message is shown
    assert_success
    assert_output --partial "✓ Documentation build stub executed"
    assert_output --partial "Customize this script in scripts/release/build-docs.sh"
}