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

@test "update version script requires version argument" {
    # WHEN: Running script without version argument
    run bash -c "${TEST_RELEASE_DIR}/update-version.sh"

    # THEN: Script fails with missing version error
    assert_failure
    assert_output --partial "Version is required"
}

@test "update version script runs without errors with version" {
    # WHEN: Running script with version argument
    run bash -c "${TEST_RELEASE_DIR}/update-version.sh 1.2.3"

    # THEN: Script executes successfully
    assert_success
    assert_output --partial "Updating Version Files"
    assert_output --partial "Version: 1.2.3"
}

@test "update version script provides clear output formatting" {
    # WHEN: Running the script
    run bash -c "${TEST_RELEASE_DIR}/update-version.sh 2.0.0"

    # THEN: Output is properly formatted
    assert_success
    assert_line --partial "========================================="
    assert_line --partial "Updating Version Files"
    assert_line --partial "Version: 2.0.0"
    assert_line --partial "Version Files Updated"
    assert_line --partial "========================================="
}

@test "update version script shows stub execution message" {
    # WHEN: Running the script
    run bash -c "${TEST_RELEASE_DIR}/update-version.sh 1.0.0"

    # THEN: Stub execution message is shown
    assert_success
    assert_output --partial "✓ Version update stub executed"
    assert_output --partial "Customize this script in scripts/release/update-version.sh"
}

@test "update version script handles semantic version format" {
    # WHEN: Running with semantic version
    run bash -c "${TEST_RELEASE_DIR}/update-version.sh 1.2.3-alpha.1"

    # THEN: Script handles pre-release versions
    assert_success
    assert_output --partial "Version: 1.2.3-alpha.1"
}

@test "update version script handles major version increments" {
    # WHEN: Running with major version bump
    run bash -c "${TEST_RELEASE_DIR}/update-version.sh 2.0.0"

    # THEN: Script handles major version
    assert_success
    assert_output --partial "Version: 2.0.0"
}

@test "update version script handles minor version increments" {
    # WHEN: Running with minor version bump
    run bash -c "${TEST_RELEASE_DIR}/update-version.sh 1.3.0"

    # THEN: Script handles minor version
    assert_success
    assert_output --partial "Version: 1.3.0"
}

@test "update version script handles patch version increments" {
    # WHEN: Running with patch version bump
    run bash -c "${TEST_RELEASE_DIR}/update-version.sh 1.2.4"

    # THEN: Script handles patch version
    assert_success
    assert_output --partial "Version: 1.2.4"
}

@test "update version script includes examples for different package managers" {
    # GIVEN: Script should include examples
    # WHEN: Checking for package.json example
    run grep -E "# Example: Update package.json" "${TEST_RELEASE_DIR}/update-version.sh"

    # THEN: Example is present
    assert_success

    # WHEN: Checking for setup.py example
    run grep -E "# Example: Update setup.py" "${TEST_RELEASE_DIR}/update-version.sh"

    # THEN: Example is present
    assert_success

    # WHEN: Checking for Cargo.toml example
    run grep -E "# Example: Update Cargo.toml" "${TEST_RELEASE_DIR}/update-version.sh"

    # THEN: Example is present
    assert_success
}

@test "update version script includes pyproject.toml example" {
    # WHEN: Checking for pyproject.toml example
    run grep -E "# Example: Update pyproject.toml" "${TEST_RELEASE_DIR}/update-version.sh"

    # THEN: Example is present
    assert_success
}

@test "update version script includes VERSION file example" {
    # WHEN: Checking for VERSION file example
    run grep -E "# Example: Update version.txt or VERSION file" "${TEST_RELEASE_DIR}/update-version.sh"

    # THEN: Example is present
    assert_success
}

@test "update version script uses set -euo pipefail" {
    # GIVEN: Script should use strict error handling
    # WHEN: Checking script content
    run grep -E "set -euo pipefail" "${TEST_RELEASE_DIR}/update-version.sh"

    # THEN: Strict mode is enabled
    assert_success
    assert_output "set -euo pipefail"
}

@test "update version script includes proper shebang" {
    # GIVEN: Script should have proper shebang
    # WHEN: Checking script content
    run head -n 1 "${TEST_RELEASE_DIR}/update-version.sh"

    # THEN: Shebang is present
    assert_success
    assert_output "#!/usr/bin/env bash"
}

@test "update version script includes usage documentation" {
    # GIVEN: Script should document its purpose
    # WHEN: Checking script content
    run grep -E "# CI Pipeline Stub: Update Version Files" "${TEST_RELEASE_DIR}/update-version.sh"

    # THEN: Documentation is present
    assert_success
    assert_output "# CI Pipeline Stub: Update Version Files"
}

@test "update version script validates version parameter with error code" {
    # WHEN: Checking how script validates version parameter
    run grep -E 'VERSION="\$\{1:.*Version is required.*\}"' "${TEST_RELEASE_DIR}/update-version.sh"

    # THEN: Parameter validation is present
    assert_success
    assert_output 'VERSION="${1:?Version is required}"'
}

@test "update version script provides clear customization guidance" {
    # WHEN: Checking for customization instructions
    run grep -E "Add your version update commands here" "${TEST_RELEASE_DIR}/update-version.sh"

    # THEN: Customization guidance is present
    assert_success
}

@test "update version script handles edge case version formats" {
    # WHEN: Running with edge case versions
    run bash -c "${TEST_RELEASE_DIR}/update-version.sh 0.0.1"

    # THEN: Script handles edge cases
    assert_success
    assert_output --partial "Version: 0.0.1"
}

@test "update version script handles beta versions" {
    # WHEN: Running with beta version
    run bash -c "${TEST_RELEASE_DIR}/update-version.sh 1.0.0-beta.2"

    # THEN: Script handles beta versions
    assert_success
    assert_output --partial "Version: 1.0.0-beta.2"
}

@test "update version script maintains consistent success status" {
    # GIVEN: Multiple runs with valid versions
    local exit_codes=()
    local versions=("1.0.0" "2.1.3" "0.0.1" "10.20.30")

    # WHEN: Running script with different versions
    for version in "${versions[@]}"; do
        bash -c "${TEST_RELEASE_DIR}/update-version.sh $version" >/dev/null
        exit_codes+=($?)
    done

    # THEN: All runs succeed
    for code in "${exit_codes[@]}"; do
        [[ "$code" == "0" ]]
    fi
}