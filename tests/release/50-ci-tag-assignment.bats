#!/usr/bin/env bats

# Load deployment test helper (includes release testing utilities)
load "${BATS_TEST_DIRNAME}/../test_helper.bash"

setup() {
    # GIVEN: A clean test environment with git repository
    setup_deployment_test_project
    setup_successful_deployment_scenario

    # Initialize a git repository for tag testing
    cd "$TEST_PROJECT_ROOT"
    git init --quiet
    git config user.email "test@example.com"
    git config user.name "Test User"
    echo "# Test project" > README.md
    git add README.md
    git commit -m "Initial commit" --quiet
}

teardown() {
    # Cleanup test environment
    cleanup_deployment_test_project
}

@test "tag assignment script validates inputs correctly" {
    # GIVEN: Valid GitHub Actions input parameters
    export INPUT_TAG_TYPE="version"
    export INPUT_VERSION="v1.2.3"
    export INPUT_ENVIRONMENT=""
    export INPUT_STATE=""
    export INPUT_SUBPROJECT=""
    export INPUT_COMMIT_SHA="abc123"
    export INPUT_FORCE_MOVE="false"

    # WHEN: Validating inputs
    run bash -c "
        source '${TEST_RELEASE_DIR}/50-ci-tag-assignment.sh'
        validate_inputs
    "

    # THEN: Validation succeeds
    assert_success
    assert_output --partial "Validating tag assignment inputs"
    assert_output --partial "Valid tag type: version"
}

@test "tag assignment script rejects invalid tag type" {
    # GIVEN: Invalid tag type
    export INPUT_TAG_TYPE="invalid_type"
    export INPUT_VERSION="v1.2.3"

    # WHEN: Validating inputs
    run bash -c "
        source '${TEST_RELEASE_DIR}/50-ci-tag-assignment.sh'
        validate_inputs
    "

    # THEN: Validation fails
    assert_failure
    assert_output --partial "Invalid tag type: invalid_type"
    assert_output --partial "Must be one of: version, environment, state"
}

@test "tag assignment script validates version tag requirements" {
    # GIVEN: Version tag type without version
    export INPUT_TAG_TYPE="version"
    export INPUT_VERSION=""

    # WHEN: Validating inputs
    run bash -c "
        source '${TEST_RELEASE_DIR}/50-ci-tag-assignment.sh'
        validate_inputs
    "

    # THEN: Validation fails
    assert_failure
    assert_output --partial "Version is required for version tag type"
}

@test "tag assignment script validates version format" {
    # GIVEN: Invalid version format
    export INPUT_TAG_TYPE="version"
    export INPUT_VERSION="invalid-version"

    # WHEN: Validating inputs
    run bash -c "
        source '${TEST_RELEASE_DIR}/50-ci-tag-assignment.sh'
        validate_inputs
    "

    # THEN: Validation fails
    assert_failure
    assert_output --partial "Invalid version format: invalid-version"
}

@test "tag assignment script validates environment tag requirements" {
    # GIVEN: Environment tag type without environment
    export INPUT_TAG_TYPE="environment"
    export INPUT_ENVIRONMENT=""

    # WHEN: Validating inputs
    run bash -c "
        source '${TEST_RELEASE_DIR}/50-ci-tag-assignment.sh'
        validate_inputs
    "

    # THEN: Validation fails
    assert_failure
    assert_output --partial "Environment is required for environment tag type"
}

@test "tag assignment script validates environment format" {
    # GIVEN: Invalid environment format
    export INPUT_TAG_TYPE="environment"
    export INPUT_ENVIRONMENT="Invalid Env"

    # WHEN: Validating inputs
    run bash -c "
        source '${TEST_RELEASE_DIR}/50-ci-tag-assignment.sh'
        validate_inputs
    "

    # THEN: Validation fails
    assert_failure
    assert_output --partial "Invalid environment: Invalid Env"
}

@test "tag assignment script validates state tag requirements" {
    # GIVEN: State tag type without version
    export INPUT_TAG_TYPE="state"
    export INPUT_VERSION=""
    export INPUT_STATE="success"

    # WHEN: Validating inputs
    run bash -c "
        source '${TEST_RELEASE_DIR}/50-ci-tag-assignment.sh'
        validate_inputs
    "

    # THEN: Validation fails
    assert_failure
    assert_output --partial "Version is required for state tag type"
}

@test "tag assignment script validates state tag requirements" {
    # GIVEN: State tag type without state
    export INPUT_TAG_TYPE="state"
    export INPUT_VERSION="v1.2.3"
    export INPUT_STATE=""

    # WHEN: Validating inputs
    run bash -c "
        source '${TEST_RELEASE_DIR}/50-ci-tag-assignment.sh'
        validate_inputs
    "

    # THEN: Validation fails
    assert_failure
    assert_output --partial "State is required for state tag type"
}

@test "tag assignment script validates state format" {
    # GIVEN: Invalid state format
    export INPUT_TAG_TYPE="state"
    export INPUT_VERSION="v1.2.3"
    export INPUT_STATE="invalid-state-format"

    # WHEN: Validating inputs
    run bash -c "
        source '${TEST_RELEASE_DIR}/50-ci-tag-assignment.sh'
        validate_inputs
    "

    # THEN: Validation fails
    assert_failure
    assert_output --partial "Invalid state: invalid-state-format"
}

@test "tag assignment script validates subproject format" {
    # GIVEN: Invalid subproject format
    export INPUT_TAG_TYPE="version"
    export INPUT_VERSION="v1.2.3"
    export INPUT_SUBPROJECT="-invalid-start"

    # WHEN: Validating inputs
    run bash -c "
        source '${TEST_RELEASE_DIR}/50-ci-tag-assignment.sh'
        validate_inputs
    "

    # THEN: Validation fails
    assert_failure
    assert_output --partial "Invalid subproject format"
}

@test "tag assignment script accepts valid subproject format" {
    # GIVEN: Valid subproject format
    export INPUT_TAG_TYPE="version"
    export INPUT_VERSION="v1.2.3"
    export INPUT_SUBPROJECT="valid-project-name"

    # WHEN: Validating inputs
    run bash -c "
        source '${TEST_RELEASE_DIR}/50-ci-tag-assignment.sh'
        validate_inputs
    "

    # THEN: Validation succeeds
    assert_success
}

@test "tag assignment script determines behavior mode correctly" {
    # GIVEN: Different behavior modes
    # WHEN: Testing default behavior
    unset CI_TEST_MODE
    run bash -c "
        source '${TEST_RELEASE_DIR}/50-ci-tag-assignment.sh'
        get_behavior_mode
    "

    # THEN: Default behavior is EXECUTE
    assert_success
    assert_output "EXECUTE"

    # WHEN: Testing dry run mode
    export CI_TEST_MODE="dry_run"
    run bash -c "
        source '${TEST_RELEASE_DIR}/50-ci-tag-assignment.sh'
        get_behavior_mode
    "

    # THEN: Dry run mode is detected
    assert_success
    assert_output "dry_run"
}

@test "tag assignment script handles version tag creation" {
    # GIVEN: Version tag parameters
    export INPUT_TAG_TYPE="version"
    export INPUT_VERSION="v1.2.3"
    export INPUT_COMMIT_SHA=$(git rev-parse HEAD)

    # WHEN: Creating version tag
    run bash -c "
        source '${TEST_RELEASE_DIR}/50-ci-tag-assignment.sh'
        validate_inputs
        local mode=\$(get_behavior_mode)
        create_tag_assignment_tag 'version' 'v1.2.3' '' '' '' '$INPUT_COMMIT_SHA' 'false' '\$mode'
    "

    # THEN: Version tag is created
    assert_success
    assert_output --partial "Creating version tag: v1.2.3"
}

@test "tag assignment script handles environment tag creation" {
    # GIVEN: Environment tag parameters
    export INPUT_TAG_TYPE="environment"
    export INPUT_ENVIRONMENT="staging"

    # WHEN: Creating environment tag
    run bash -c "
        source '${TEST_RELEASE_DIR}/50-ci-tag-assignment.sh'
        validate_inputs
        local mode=\$(get_behavior_mode)
        create_tag_assignment_tag 'environment' '' 'staging' '' '' '' 'false' '\$mode'
    "

    # THEN: Environment tag is created
    assert_success
    assert_output --partial "Creating environment tag: staging"
}

@test "tag assignment script handles state tag creation" {
    # GIVEN: State tag parameters
    export INPUT_TAG_TYPE="state"
    export INPUT_VERSION="v1.2.3"
    export INPUT_STATE="success"

    # WHEN: Creating state tag
    run bash -c "
        source '${TEST_RELEASE_DIR}/50-ci-tag-assignment.sh'
        validate_inputs
        local mode=\$(get_behavior_mode)
        create_tag_assignment_tag 'state' 'v1.2.3' '' 'success' '' '' 'false' '\$mode'
    "

    # THEN: State tag is created
    assert_success
    assert_output --partial "Creating state tag: v1.2.3-success"
}

@test "tag assignment script handles tag with subproject" {
    # GIVEN: Tag with subproject
    export INPUT_TAG_TYPE="version"
    export INPUT_VERSION="v1.2.3"
    export INPUT_SUBPROJECT="frontend"

    # WHEN: Creating tag with subproject
    run bash -c "
        source '${TEST_RELEASE_DIR}/50-ci-tag-assignment.sh'
        validate_inputs
        local mode=\$(get_behavior_mode)
        create_tag_assignment_tag 'version' 'v1.2.3' '' '' 'frontend' '' 'false' '\$mode'
    "

    # THEN: Tag includes subproject
    assert_success
    assert_output --partial "Creating version tag: frontend-v1.2.3"
}

@test "tag assignment script handles force move option" {
    # GIVEN: Tag with force move enabled
    export INPUT_TAG_TYPE="environment"
    export INPUT_ENVIRONMENT="staging"
    export INPUT_FORCE_MOVE="true"

    # WHEN: Creating tag with force move
    run bash -c "
        source '${TEST_RELEASE_DIR}/50-ci-tag-assignment.sh'
        validate_inputs
        local mode=\$(get_behavior_mode)
        create_tag_assignment_tag 'environment' '' 'staging' '' '' '' 'true' '\$mode'
    "

    # THEN: Tag is created with force move
    assert_success
    assert_output --partial "force moving"
}

@test "tag assignment script handles dry run mode" {
    # GIVEN: Dry run mode enabled
    export INPUT_TAG_TYPE="version"
    export INPUT_VERSION="v1.2.3"
    export CI_TEST_MODE="dry_run"

    # WHEN: Creating tag in dry run mode
    run bash -c "
        source '${TEST_RELEASE_DIR}/50-ci-tag-assignment.sh'
        validate_inputs
        local mode=\$(get_behavior_mode)
        create_tag_assignment_tag 'version' 'v1.2.3' '' '' '' '' 'false' '\$mode'
    "

    # THEN: Dry run behavior is executed
    assert_success
    assert_output --partial "DRY RUN: Would create version tag"
}

@test "tag assignment script generates tag name correctly" {
    # GIVEN: Different tag types and parameters
    # WHEN: Generating version tag name
    run bash -c "
        source '${TEST_RELEASE_DIR}/50-ci-tag-assignment.sh'
        generate_tag_name 'version' 'v1.2.3' '' '' ''
    "

    # THEN: Version tag name is correct
    assert_success
    assert_output "v1.2.3"

    # WHEN: Generating environment tag name
    run bash -c "
        source '${TEST_RELEASE_DIR}/50-ci-tag-assignment.sh'
        generate_tag_name 'environment' '' 'staging' '' ''
    "

    # THEN: Environment tag name is correct
    assert_success
    assert_output "env/staging"

    # WHEN: Generating state tag name
    run bash -c "
        source '${TEST_RELEASE_DIR}/50-ci-tag-assignment.sh'
        generate_tag_name 'state' 'v1.2.3' '' 'success' ''
    "

    # THEN: State tag name is correct
    assert_success
    assert_output "state/v1.2.3-success"
}

@test "tag assignment script validates tag exists before operations" {
    # GIVEN: Existing and non-existing tags
    git tag v1.0.0

    # WHEN: Checking tag existence
    run bash -c "
        source '${TEST_RELEASE_DIR}/50-ci-tag-assignment.sh'
        if tag_exists 'v1.0.0'; then echo 'v1.0.0 exists'; else echo 'v1.0.0 missing'; fi
        if tag_exists 'v2.0.0'; then echo 'v2.0.0 exists'; else echo 'v2.0.0 missing'; fi
    "

    # THEN: Tag existence is correctly identified
    assert_success
    assert_line "v1.0.0 exists"
    assert_line "v2.0.0 missing"
}

@test "tag assignment script pushes tags to remote" {
    # GIVEN: Tag to push
    git tag v1.2.3

    # WHEN: Pushing tag
    run bash -c "
        source '${TEST_RELEASE_DIR}/50-ci-tag-assignment.sh'
        push_tag_to_remote 'v1.2.3'
    "

    # THEN: Tag is pushed to remote
    assert_success
    assert_output --partial "Pushed tag: v1.2.3"
}

@test "tag assignment script handles push failures" {
    # GIVEN: Simulated push failure
    # WHEN: Attempting to push with failure
    run bash -c "
        source '${TEST_RELEASE_DIR}/50-ci-tag-assignment.sh'
        push_tag_with_failure 'v1.2.3'
    "

    # THEN: Push failure is handled
    assert_failure
    assert_output --partial "Failed to push tag"
}

@test "tag assignment script validates commit SHA format" {
    # GIVEN: Valid and invalid commit SHAs
    export INPUT_TAG_TYPE="version"
    export INPUT_VERSION="v1.2.3"

    # WHEN: Using valid commit SHA
    export INPUT_COMMIT_SHA=$(git rev-parse HEAD)
    run bash -c "
        source '${TEST_RELEASE_DIR}/50-ci-tag-assignment.sh'
        validate_inputs
    "

    # THEN: Validation succeeds
    assert_success

    # WHEN: Using invalid commit SHA
    export INPUT_COMMIT_SHA="invalid-sha"
    run bash -c "
        source '${TEST_RELEASE_DIR}/50-ci-tag-assignment.sh'
        validate_inputs
    "

    # THEN: Validation fails
    assert_failure
    assert_output --partial "Invalid commit SHA format"
}

@test "tag assignment script provides comprehensive logging" {
    # GIVEN: Detailed logging enabled
    export INPUT_TAG_TYPE="version"
    export INPUT_VERSION="v1.2.3"

    # WHEN: Running with detailed inputs
    run bash -c "
        source '${TEST_RELEASE_DIR}/50-ci-tag-assignment.sh'
        validate_inputs
    "

    # THEN: Comprehensive logging is provided
    assert_success
    assert_output --partial "Tag Type: version"
    assert_output --partial "Version: v1.2.3"
    assert_output --partial "Force Move: false"
}

@test "tag assignment script handles all valid environments" {
    # GIVEN: List of valid environments
    local valid_environments=("staging" "production" "development")

    # WHEN: Testing each environment
    for env in "${valid_environments[@]}"; do
        export INPUT_TAG_TYPE="environment"
        export INPUT_ENVIRONMENT="$env"

        run bash -c "
            source '${TEST_RELEASE_DIR}/50-ci-tag-assignment.sh'
            validate_inputs
        "

        # THEN: Each environment is valid
        assert_success
    done
}

@test "tag assignment script handles all valid states" {
    # GIVEN: List of valid states
    local valid_states=("success" "failed" "pending" "rolling-back")

    # WHEN: Testing each state
    for state in "${valid_states[@]}"; do
        export INPUT_TAG_TYPE="state"
        export INPUT_VERSION="v1.2.3"
        export INPUT_STATE="$state"

        run bash -c "
            source '${TEST_RELEASE_DIR}/50-ci-tag-assignment.sh'
            validate_inputs
        "

        # THEN: Each state is valid
        assert_success
    done
}

@test "tag assignment script includes version tracking" {
    # GIVEN: Script version should be available
    # WHEN: Checking script version
    run bash -c "
        source '${TEST_RELEASE_DIR}/50-ci-tag-assignment.sh'
        echo \"Tag assignment version: \$TAG_ASSIGNMENT_VERSION\"
    "

    # THEN: Version is available
    assert_success
    assert_output "Tag assignment version: 1.0.0"
}

@test "tag assignment script handles missing dependencies gracefully" {
    # GIVEN: Missing common utilities
    # WHEN: Script fails to source dependencies
    run bash -c "
        # Temporarily move the common library
        mv '${TEST_LIB_DIR}/common.sh' '${TEST_LIB_DIR}/common.sh.bak'
        source '${TEST_RELEASE_DIR}/50-ci-tag-assignment.sh' 2>&1 || true
        # Restore the library
        mv '${TEST_LIB_DIR}/common.sh.bak' '${TEST_LIB_DIR}/common.sh'
    "

    # THEN: Script fails gracefully
    assert_failure
    assert_output --partial "Failed to source"
}

@test "tag assignment script provides comprehensive error handling" {
    # GIVEN: Various error conditions
    # WHEN: Script encounters errors
    run bash -c "
        source '${TEST_RELEASE_DIR}/50-ci-tag-assignment.sh'
        # Test with completely invalid input
        export INPUT_TAG_TYPE='invalid'
        export INPUT_VERSION=''
        export INPUT_ENVIRONMENT=''
        export INPUT_STATE=''
        validate_inputs
    "

    # THEN: Errors are handled appropriately
    assert_failure
}

@test "tag assignment script maintains atomicity in operations" {
    # GIVEN: Tag operations should be atomic
    export INPUT_TAG_TYPE="version"
    export INPUT_VERSION="v1.2.3"

    # WHEN: Performing tag operations
    run bash -c "
        source '${TEST_RELEASE_DIR}/50-ci-tag-assignment.sh'
        validate_inputs
        local mode=\$(get_behavior_mode)
        create_tag_assignment_tag 'version' 'v1.2.3' '' '' '' '' 'false' '\$mode'
    "

    # THEN: Operations are atomic
    assert_success
    assert_output --partial "Atomic tag operation completed"
}