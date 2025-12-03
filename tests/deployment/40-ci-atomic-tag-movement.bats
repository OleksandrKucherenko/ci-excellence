#!/usr/bin/env bats

# Load deployment test helper
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
    git tag v1.0.0
}

teardown() {
    # Cleanup test environment
    cleanup_deployment_test_project
}

@test "atomic tag script validates version tag format correctly" {
    # GIVEN: Valid version tag formats
    local valid_tags=("v1.0.0" "v2.1.3" "v10.20.30" "v1.0.0-alpha" "v1.0.0-beta.1")

    # WHEN: Validating each tag
    for tag in "${valid_tags[@]}"; do
        run bash -c "
            source '${TEST_DEPLOYMENT_DIR}/40-ci-atomic-tag-movement.sh'
            validate_tag_name '$tag' 'version'
        "

        # THEN: Each tag is valid
        assert_success
    done
}

@test "atomic tag script rejects invalid version tag formats" {
    # GIVEN: Invalid version tag formats
    local invalid_tags=("1.0.0" "v1.0" "v1.0.0.0" "v1.0.0-" "v1.0.0-" "v-1.0.0" "vv1.0.0")

    # WHEN: Validating each invalid tag
    for tag in "${invalid_tags[@]}"; do
        run bash -c "
            source '${TEST_DEPLOYMENT_DIR}/40-ci-atomic-tag-movement.sh'
            validate_tag_name '$tag' 'version'
        "

        # THEN: Each tag is rejected
        assert_failure
        assert_output --partial "Invalid version tag format: $tag"
    done
}

@test "atomic tag script validates environment tag format correctly" {
    # GIVEN: Valid environment tag formats
    local valid_tags=("env/staging" "env/production" "env/development" "env/test-env")

    # WHEN: Validating each tag
    for tag in "${valid_tags[@]}"; do
        run bash -c "
            source '${TEST_DEPLOYMENT_DIR}/40-ci-atomic-tag-movement.sh'
            validate_tag_name '$tag' 'environment'
        "

        # THEN: Each tag is valid
        assert_success
    done
}

@test "atomic tag script rejects invalid environment tag formats" {
    # GIVEN: Invalid environment tag formats
    local invalid_tags=("staging" "env/" "env//staging" "env/staging/extra" "ENV/staging" "env/Staging")

    # WHEN: Validating each invalid tag
    for tag in "${invalid_tags[@]}"; do
        run bash -c "
            source '${TEST_DEPLOYMENT_DIR}/40-ci-atomic-tag-movement.sh'
            validate_tag_name '$tag' 'environment'
        "

        # THEN: Each tag is rejected
        assert_failure
        assert_output --partial "Invalid environment tag format: $tag"
    done
}

@test "atomic tag script validates state tag format correctly" {
    # GIVEN: Valid state tag formats
    local valid_tags=("state/success" "state/failed" "state/rolling_back" "state/emergency")

    # WHEN: Validating each tag
    for tag in "${valid_tags[@]}"; do
        run bash -c "
            source '${TEST_DEPLOYMENT_DIR}/40-ci-atomic-tag-movement.sh'
            validate_tag_name '$tag' 'state'
        "

        # THEN: Each tag is valid
        assert_success
    done
}

@test "atomic tag script validates deployment tag format correctly" {
    # GIVEN: Valid deployment tag formats
    local valid_tags=("deploy/2024-01-01-deploy-123" "deploy/2024-12-31-release-456" "deploy/2025-03-15-hotfix-789")

    # WHEN: Validating each tag
    for tag in "${valid_tags[@]}"; do
        run bash -c "
            source '${TEST_DEPLOYMENT_DIR}/40-ci-atomic-tag-movement.sh'
            validate_tag_name '$tag' 'deployment'
        "

        # THEN: Each tag is valid
        assert_success
    done
}

@test "atomic tag script rejects invalid deployment tag formats" {
    # GIVEN: Invalid deployment tag formats
    local invalid_tags=("deploy/deploy-123" "deploy/2024-13-01-deploy-123" "deploy/2024-01-32-deploy-123" "deploy/2024-1-1-deploy-123")

    # WHEN: Validating each invalid tag
    for tag in "${invalid_tags[@]}"; do
        run bash -c "
            source '${TEST_DEPLOYMENT_DIR}/40-ci-atomic-tag-movement.sh'
            validate_tag_name '$tag' 'deployment'
        "

        # THEN: Each tag is rejected
        assert_failure
        assert_output --partial "Invalid deployment tag format: $tag"
    done
}

@test "atomic tag script checks tag existence correctly" {
    # GIVEN: Existing and non-existing tags
    git tag v1.0.1

    # WHEN: Checking tag existence
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/40-ci-atomic-tag-movement.sh'
        tag_exists 'v1.0.0' && echo 'v1.0.0 exists' || echo 'v1.0.0 does not exist'
        tag_exists 'v1.0.1' && echo 'v1.0.1 exists' || echo 'v1.0.1 does not exist'
        tag_exists 'v2.0.0' && echo 'v2.0.0 exists' || echo 'v2.0.0 does not exist'
    "

    # THEN: Tag existence is correctly identified
    assert_success
    assert_line "v1.0.0 exists"
    assert_line "v1.0.1 exists"
    assert_line "v2.0.0 does not exist"
}

@test "atomic tag script creates immutable version tags" {
    # GIVEN: A new version tag to create
    # WHEN: Creating a version tag
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/40-ci-atomic-tag-movement.sh'
        create_immutable_tag 'v1.1.0' 'HEAD' 'Release version 1.1.0'
    "

    # THEN: Version tag is created
    assert_success
    assert_output --partial "Created immutable tag: v1.1.0"

    # Verify tag actually exists
    run git rev-parse --verify "refs/tags/v1.1.0"
    assert_success
}

@test "atomic tag script prevents overwriting immutable version tags" {
    # GIVEN: An existing version tag
    git tag v1.2.0

    # WHEN: Attempting to recreate the same tag
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/40-ci-atomic-tag-movement.sh'
        create_immutable_tag 'v1.2.0' 'HEAD' 'Attempt to overwrite'
    "

    # THEN: Tag creation is prevented
    assert_failure
    assert_output --partial "Cannot overwrite immutable tag: v1.2.0"
}

@test "atomic tag script creates and moves environment tags" {
    # GIVEN: An environment tag to create/move
    # WHEN: Creating environment tag
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/40-ci-atomic-tag-movement.sh'
        create_environment_tag 'env/staging' 'HEAD'
    "

    # THEN: Environment tag is created
    assert_success
    assert_output --partial "Created environment tag: env/staging"

    # WHEN: Moving the environment tag
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/40-ci-atomic-tag-movement.sh'
        move_environment_tag 'env/staging' 'HEAD'
    "

    # THEN: Environment tag is moved
    assert_success
    assert_output --partial "Moved environment tag: env/staging"
}

@test "atomic tag script creates state tags" {
    # GIVEN: A state tag to create
    # WHEN: Creating state tag
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/40-ci-atomic-tag-movement.sh'
        create_state_tag 'state/success' 'HEAD' 'Deployment successful'
    "

    # THEN: State tag is created
    assert_success
    assert_output --partial "Created state tag: state/success"
}

@test "atomic tag script creates deployment tags" {
    # GIVEN: A deployment tag to create
    # WHEN: Creating deployment tag
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/40-ci-atomic-tag-movement.sh'
        create_deployment_tag 'deploy/2024-01-01-deploy-123' 'HEAD' 'Deployment 123'
    "

    # THEN: Deployment tag is created
    assert_success
    assert_output --partial "Created deployment tag: deploy/2024-01-01-deploy-123"
}

@test "atomic tag script validates tag type" {
    # GIVEN: Valid and invalid tag types
    # WHEN: Validating tag types
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/40-ci-atomic-tag-movement.sh'
        validate_tag_type 'version' && echo 'version valid' || echo 'version invalid'
        validate_tag_type 'environment' && echo 'environment valid' || echo 'environment invalid'
        validate_tag_type 'state' && echo 'state valid' || echo 'state invalid'
        validate_tag_type 'deployment' && echo 'deployment valid' || echo 'deployment invalid'
        validate_tag_type 'invalid' && echo 'invalid valid' || echo 'invalid invalid'
    "

    # THEN: Tag types are correctly validated
    assert_success
    assert_line "version valid"
    assert_line "environment valid"
    assert_line "state valid"
    assert_line "deployment valid"
    assert_line "invalid invalid"
}

@test "atomic tag script moves environment tags atomically" {
    # GIVEN: An environment tag exists
    git tag env/staging HEAD~1

    # WHEN: Moving the tag atomically
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/40-ci-atomic-tag-movement.sh'
        move_tag_atomically 'env/staging' 'HEAD' 'environment'
    "

    # THEN: Tag is moved atomically
    assert_success
    assert_output --partial "Moved tag atomically: env/staging"
}

@test "atomic tag script validates tag naming conventions" {
    # GIVEN: Tag naming conventions
    # WHEN: Checking tag prefixes
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/40-ci-atomic-tag-movement.sh'
        echo \"VERSION_TAG_PREFIX: \$VERSION_TAG_PREFIX\"
        echo \"ENVIRONMENT_TAG_PREFIX: \$ENVIRONMENT_TAG_PREFIX\"
        echo \"STATE_TAG_PREFIX: \$STATE_TAG_PREFIX\"
        echo \"DEPLOYMENT_TAG_PREFIX: \$DEPLOYMENT_TAG_PREFIX\"
    "

    # THEN: Correct prefixes are defined
    assert_success
    assert_line "VERSION_TAG_PREFIX: v"
    assert_line "ENVIRONMENT_TAG_PREFIX: env/"
    assert_line "STATE_TAG_PREFIX: state/"
    assert_line "DEPLOYMENT_TAG_PREFIX: deploy/"
}

@test "atomic tag script supports environment tag configurations" {
    # GIVEN: Environment tag configurations
    # WHEN: Listing environment tags
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/40-ci-atomic-tag-movement.sh'
        for tag_config in \"\${ENVIRONMENT_TAGS[@]}\"; do
            echo \"\$tag_config\"
        done
    "

    # THEN: Environment tag configurations are listed
    assert_success
    assert_line --partial "env/staging:"
    assert_line --partial "env/production:"
    assert_line --partial "env/rollback-staging:"
    assert_line --partial "env/rollback-production:"
    assert_line --partial "env/candidate:"
}

@test "atomic tag script supports state tag configurations" {
    # GIVEN: State tag configurations
    # WHEN: Listing state tags
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/40-ci-atomic-tag-movement.sh'
        for tag_config in \"\${STATE_TAGS[@]}\"; do
            echo \"\$tag_config\"
        done
    "

    # THEN: State tag configurations are listed
    assert_success
    assert_line --partial "state/staging-success:"
    assert_line --partial "state/production-success:"
    assert_line --partial "state/staging-failed:"
    assert_line --partial "state/production-failed:"
    assert_line --partial "state/rollback-initiated:"
    assert_line --partial "state/emergency:"
}

@test "atomic tag script supports tag type definitions" {
    # GIVEN: Tag type definitions
    # WHEN: Listing tag types
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/40-ci-atomic-tag-movement.sh'
        for tag_type in \"\${TAG_TYPES[@]}\"; do
            echo \"\$tag_type\"
        done
    "

    # THEN: Tag types are defined with properties
    assert_success
    assert_line --partial "version:immutable:"
    assert_line --partial "environment:movable:"
    assert_line --partial "state:immutable:"
    assert_line --partial "deployment:immutable:"
}

@test "atomic tag script handles tag creation with commit reference" {
    # GIVEN: Specific commit reference
    local commit_sha=$(git rev-parse HEAD)

    # WHEN: Creating tag with specific commit
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/40-ci-atomic-tag-movement.sh'
        create_immutable_tag 'v1.3.0' '$commit_sha' 'Tag specific commit'
    "

    # THEN: Tag is created at specific commit
    assert_success
    assert_output --partial "Created immutable tag: v1.3.0"

    # Verify tag points to correct commit
    run git rev-parse v1.3.0
    assert_output "$commit_sha"
}

@test "atomic tag script handles tag deletion" {
    # GIVEN: A tag to delete
    git tag temp-tag HEAD

    # WHEN: Deleting the tag
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/40-ci-atomic-tag-movement.sh'
        delete_tag 'temp-tag'
    "

    # THEN: Tag is deleted
    assert_success
    assert_output --partial "Deleted tag: temp-tag"

    # Verify tag no longer exists
    run git rev-parse --verify "refs/tags/temp-tag"
    assert_failure
}

@test "atomic tag script validates tag before operations" {
    # GIVEN: Invalid tag name
    # WHEN: Attempting operations with invalid tag
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/40-ci-atomic-tag-movement.sh'
        create_immutable_tag 'invalid-tag' 'HEAD' 'Test'
    "

    # THEN: Operation is rejected
    assert_failure
    assert_output --partial "Invalid tag format"
}

@test "atomic tag script provides comprehensive tag management" {
    # GIVEN: Complete tag management scenario
    # WHEN: Performing tag operations
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/40-ci-atomic-tag-movement.sh'

        # Create version tag
        create_immutable_tag 'v2.0.0' 'HEAD' 'Version 2.0.0'

        # Create environment tag
        create_environment_tag 'env/production' 'HEAD'

        # Create state tag
        create_state_tag 'state/success' 'HEAD' 'Success'

        # Move environment tag
        move_environment_tag 'env/production' 'HEAD'
    "

    # THEN: All operations succeed
    assert_success
    assert_output --partial "Created immutable tag: v2.0.0"
    assert_output --partial "Created environment tag: env/production"
    assert_output --partial "Created state tag: state/success"
    assert_output --partial "Moved environment tag: env/production"
}

@test "atomic tag script handles error conditions gracefully" {
    # GIVEN: Error conditions
    # WHEN: Attempting operations on non-existent references
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/40-ci-atomic-tag-movement.sh'
        create_immutable_tag 'v3.0.0' 'non-existent-ref' 'Test'
    "

    # THEN: Error is handled gracefully
    assert_failure
}

@test "atomic tag script includes proper version tracking" {
    # GIVEN: Script version
    # WHEN: Checking script version
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/40-ci-atomic-tag-movement.sh'
        echo \"Script version: \$SCRIPT_VERSION\"
    "

    # THEN: Version is available
    assert_success
    assert_output "Script version: 1.0.0"
}

@test "atomic tag script uses strict error handling" {
    # GIVEN: Script should use strict error handling
    # WHEN: Checking for strict mode
    run grep -E "set -euo pipefail" "${TEST_DEPLOYMENT_DIR}/40-ci-atomic-tag-movement.sh"

    # THEN: Strict mode is enabled
    assert_success
    assert_output "set -euo pipefail"
}