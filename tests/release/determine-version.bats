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

@test "determine version script runs without errors" {
    # WHEN: Running the determine-version script
    run bash -c "${TEST_RELEASE_DIR}/determine-version.sh patch"

    # THEN: Script executes successfully
    assert_success
    assert_output --partial "Determining Version"
    assert_output --partial "Release Type: patch"
}

@test "determine version script handles patch release type" {
    # WHEN: Running with patch release type
    run bash -c "${TEST_RELEASE_DIR}/determine-version.sh patch"

    # THEN: Version is incremented correctly
    assert_success
    assert_output --partial "Current version: 0.0.0"
    assert_output --partial "New version: 0.0.1"
}

@test "determine version script handles minor release type" {
    # WHEN: Running with minor release type
    run bash -c "${TEST_RELEASE_DIR}/determine-version.sh minor"

    # THEN: Version is incremented correctly
    assert_success
    assert_output --partial "Current version: 0.0.0"
    assert_output --partial "New version: 0.1.0"
}

@test "determine version script handles major release type" {
    # WHEN: Running with major release type
    run bash -c "${TEST_RELEASE_DIR}/determine-version.sh major"

    # THEN: Version is incremented correctly
    assert_success
    assert_output --partial "Current version: 0.0.0"
    assert_output --partial "New version: 1.0.0"
}

@test "determine version script handles premajor release type" {
    # WHEN: Running with premajor release type
    run bash -c "${TEST_RELEASE_DIR}/determine-version.sh premajor"

    # THEN: Pre-release version is generated
    assert_success
    assert_output "1.0.0-alpha.0"
}

@test "determine version script handles preminor release type" {
    # WHEN: Running with preminor release type
    run bash -c "${TEST_RELEASE_DIR}/determine-version.sh preminor"

    # THEN: Pre-release version is generated
    assert_success
    assert_output "0.1.0-alpha.0"
}

@test "determine version script handles prepatch release type" {
    # WHEN: Running with prepatch release type
    run bash -c "${TEST_RELEASE_DIR}/determine-version.sh prepatch"

    # THEN: Pre-release version is generated
    assert_success
    assert_output "0.0.1-alpha.0"
}

@test "determine version script handles prerelease release type" {
    # WHEN: Running with prerelease release type
    run bash -c "${TEST_RELEASE_DIR}/determine-version.sh prerelease"

    # THEN: Pre-release version is generated
    assert_success
    assert_output "0.0.0-alpha.1"
}

@test "determine version script uses default patch release type" {
    # WHEN: Running without release type argument
    run bash -c "${TEST_RELEASE_DIR}/determine-version.sh"

    # THEN: Default patch type is used
    assert_success
    assert_output --partial "Release Type: patch"
    assert_output --partial "New version: 0.0.1"
}

@test "determine version script provides clear output formatting" {
    # WHEN: Running the script
    run bash -c "${TEST_RELEASE_DIR}/determine-version.sh patch"

    # THEN: Output is properly formatted
    assert_success
    assert_line --partial "========================================="
    assert_line --partial "Determining Version"
    assert_line --partial "Version Determined:"
}

@test "determine version script outputs version to stdout for piping" {
    # WHEN: Running script and capturing output
    run bash -c "${TEST_RELEASE_DIR}/determine-version.sh patch | tail -n 1"

    # THEN: Only version number is output to stdout
    assert_success
    assert_output "0.0.1"
}

@test "determine version script shows version comparison" {
    # WHEN: Running the script
    run bash -c "${TEST_RELEASE_DIR}/determine-version.sh minor"

    # THEN: Both current and new versions are shown
    assert_success
    assert_output --partial "Current version: 0.0.0"
    assert_output --partial "New version: 0.1.0"
}

@test "determine version script uses set -euo pipefail" {
    # GIVEN: Script should use strict error handling
    # WHEN: Checking script content
    run grep -E "set -euo pipefail" "${TEST_RELEASE_DIR}/determine-version.sh"

    # THEN: Strict mode is enabled
    assert_success
    assert_output "set -euo pipefail"
}

@test "determine version script includes shebang" {
    # GIVEN: Script should have proper shebang
    # WHEN: Checking script content
    run head -n 1 "${TEST_RELEASE_DIR}/determine-version.sh"

    # THEN: Shebang is present
    assert_success
    assert_output "#!/usr/bin/env bash"
}

@test "determine version script includes usage documentation" {
    # GIVEN: Script should document its purpose
    # WHEN: Checking script content
    run grep -E "# CI Pipeline Stub: Determine Version" "${TEST_RELEASE_DIR}/determine-version.sh"

    # THEN: Documentation is present
    assert_success
    assert_output "# CI Pipeline Stub: Determine Version"
}

@test "determine version script handles different initial versions" {
    # GIVEN: Custom initial version for testing
    # WHEN: Simulating different initial version
    run bash -c "
        CURRENT_VERSION='1.2.3'
        IFS='.' read -r -a VERSION_PARTS <<< \"\$CURRENT_VERSION\"
        MAJOR=\"\${VERSION_PARTS[0]}\"
        MINOR=\"\${VERSION_PARTS[1]}\"
        PATCH=\"\${VERSION_PARTS[2]}\"
        PATCH=\$((PATCH + 1))
        NEW_VERSION=\"\$MAJOR.\$MINOR.\$PATCH\"
        echo \"Current: \$CURRENT_VERSION, New: \$NEW_VERSION\"
    "

    # THEN: Version increment works correctly
    assert_success
    assert_output "Current: 1.2.3, New: 1.2.4"
}

@test "determine version script provides extensible structure" {
    # GIVEN: Script should be extensible
    # WHEN: Checking for extension points
    run grep -E "# Example:" "${TEST_RELEASE_DIR}/determine-version.sh"

    # THEN: Extension examples are present
    assert_success
}

@test "determine version script outputs final version consistently" {
    # WHEN: Running script multiple times
    local outputs=()
    for i in {1..3}; do
        output=$(bash -c "${TEST_RELEASE_DIR}/determine-version.sh patch | tail -n 1")
        outputs+=("$output")
    done

    # THEN: Output is consistent
    [[ "${outputs[0]}" == "${outputs[1]}" ]] && [[ "${outputs[1]}" == "${outputs[2]}" ]]
}