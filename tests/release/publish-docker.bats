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

@test "publish docker script runs without errors" {
    # GIVEN: Version argument
    local version="1.2.3"

    # WHEN: Running the publish-docker script
    run bash -c "${TEST_RELEASE_DIR}/publish-docker.sh $version"

    # THEN: Script executes successfully
    assert_success
    assert_output --partial "Publishing Docker Image"
    assert_output --partial "Version: $version"
    assert_output --partial "Docker Image Published"
}

@test "publish docker script requires version argument" {
    # WHEN: Running script without version argument
    run bash -c "${TEST_RELEASE_DIR}/publish-docker.sh"

    # THEN: Script fails with missing version error
    assert_failure
    assert_output --partial "Version is required"
}

@test "publish docker script provides clear output formatting" {
    # GIVEN: Version argument
    local version="2.0.0"

    # WHEN: Running the script
    run bash -c "${TEST_RELEASE_DIR}/publish-docker.sh $version"

    # THEN: Output is properly formatted
    assert_success
    assert_line --partial "========================================="
    assert_line --partial "Publishing Docker Image"
    assert_line --partial "Version: $version"
    assert_line --partial "Docker Image Published"
    assert_line --partial "========================================="
}

@test "publish docker script handles semantic versions" {
    # GIVEN: Semantic version with pre-release
    local version="1.2.3-alpha.1"

    # WHEN: Running with semantic version
    run bash -c "${TEST_RELEASE_DIR}/publish-docker.sh $version"

    # THEN: Script handles pre-release versions
    assert_success
    assert_output --partial "Version: $version"
}

@test "publish docker script validates version parameter" {
    # WHEN: Checking how script validates version parameter
    run grep -E 'VERSION="\$\{1:.*Version is required.*\}"' "${TEST_RELEASE_DIR}/publish-docker.sh"

    # THEN: Parameter validation is present
    assert_success
    assert_output 'VERSION="${1:?Version is required}"'
}

@test "publish docker script uses set -euo pipefail" {
    # GIVEN: Script should use strict error handling
    # WHEN: Checking script content
    run grep -E "set -euo pipefail" "${TEST_RELEASE_DIR}/publish-docker.sh"

    # THEN: Strict mode is enabled
    assert_success
    assert_output "set -euo pipefail"
}

@test "publish docker script includes proper shebang" {
    # GIVEN: Script should have proper shebang
    # WHEN: Checking script content
    run head -n 1 "${TEST_RELEASE_DIR}/publish-docker.sh"

    # THEN: Shebang is present
    assert_success
    assert_output "#!/usr/bin/env bash"
}

@test "publish docker script shows stub execution message" {
    # GIVEN: Version argument
    local version="1.0.0"

    # WHEN: Running the script
    run bash -c "${TEST_RELEASE_DIR}/publish-docker.sh $version"

    # THEN: Stub execution message is shown
    assert_success
    assert_output --partial "✓ Docker publish stub executed"
    assert_output --partial "Customize this script in scripts/release/publish-docker.sh"
}