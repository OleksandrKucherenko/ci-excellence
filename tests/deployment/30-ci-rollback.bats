#!/usr/bin/env bats

# Load deployment test helper
load "${BATS_TEST_DIRNAME}/../test_helper.bash"

setup() {
    # GIVEN: A clean test environment with deployment structure
    setup_deployment_test_project
    setup_successful_deployment_scenario
}

teardown() {
    # Cleanup test environment
    cleanup_deployment_test_project
}

@test "rollback script validates rollback inputs correctly" {
    # GIVEN: Valid rollback parameters
    # WHEN: Validating rollback inputs
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/30-ci-rollback.sh'
        validate_rollback_inputs 'staging' 'deploy-123' 'previous_tag'
    "

    # THEN: Validation succeeds
    assert_success
    assert_output --partial "Validating rollback inputs"
}

@test "rollback script rejects invalid environment" {
    # GIVEN: Invalid environment parameter
    # WHEN: Validating rollback inputs
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/30-ci-rollback.sh'
        validate_rollback_inputs 'invalid-env' 'deploy-123' 'previous_tag'
    "

    # THEN: Validation fails
    assert_failure
    assert_output --partial "Invalid environment"
}

@test "rollback script rejects empty deployment ID" {
    # GIVEN: Empty deployment ID
    # WHEN: Validating rollback inputs
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/30-ci-rollback.sh'
        validate_rollback_inputs 'staging' '' 'previous_tag'
    "

    # THEN: Validation fails
    assert_failure
    assert_output --partial "Deployment ID is required"
}

@test "rollback script rejects invalid rollback strategy" {
    # GIVEN: Invalid rollback strategy
    # WHEN: Validating rollback inputs
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/30-ci-rollback.sh'
        validate_rollback_inputs 'staging' 'deploy-123' 'invalid_strategy'
    "

    # THEN: Validation fails
    assert_failure
    assert_output --partial "Invalid rollback strategy"
}

@test "rollback script supports all valid rollback strategies" {
    # GIVEN: List of valid rollback strategies
    local valid_strategies=("previous_tag" "git_revert" "blue_green_switchback" "manual_intervention")

    # WHEN: Testing each strategy
    for strategy in "${valid_strategies[@]}"; do
        run bash -c "
            source '${TEST_DEPLOYMENT_DIR}/30-ci-rollback.sh'
            validate_rollback_inputs 'staging' 'deploy-123' '$strategy'
        "

        # THEN: Each strategy is valid
        assert_success
        assert_output --partial "Valid rollback strategy: $strategy"
    done
}

@test "rollback script loads environment configuration" {
    # GIVEN: Environment configuration exists
    # WHEN: Loading environment configuration
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/30-ci-rollback.sh'
        load_environment_config 'staging' 'us-east'
    "

    # THEN: Configuration is loaded
    assert_success
}

@test "rollback script executes previous tag strategy" {
    # GIVEN: A deployment record exists
    local deployment_id="rollback-test-123"
    bash -c "
        source '${TEST_DEPLOYMENT_DIR}/30-ci-rollback.sh'
        create_deployment_record '$deployment_id' 'staging' 'us-east' 'abc123'
    "

    # WHEN: Executing previous tag rollback
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/30-ci-rollback.sh'
        execute_rollback_strategy 'staging' '$deployment_id' 'previous_tag'
    "

    # THEN: Previous tag rollback is executed
    assert_success
    assert_output --partial "Executing previous tag rollback"
}

@test "rollback script executes git revert strategy" {
    # GIVEN: A deployment record exists
    local deployment_id="rollback-test-123"
    bash -c "
        source '${TEST_DEPLOYMENT_DIR}/30-ci-rollback.sh'
        create_deployment_record '$deployment_id' 'staging' 'us-east' 'abc123'
    "

    # WHEN: Executing git revert rollback
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/30-ci-rollback.sh'
        execute_rollback_strategy 'staging' '$deployment_id' 'git_revert'
    "

    # THEN: Git revert rollback is executed
    assert_success
    assert_output --partial "Executing git revert rollback"
}

@test "rollback script executes blue-green switchback strategy" {
    # GIVEN: A deployment record exists
    local deployment_id="rollback-test-123"
    bash -c "
        source '${TEST_DEPLOYMENT_DIR}/30-ci-rollback.sh'
        create_deployment_record '$deployment_id' 'production' 'us-east' 'abc123'
    "

    # WHEN: Executing blue-green switchback
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/30-ci-rollback.sh'
        execute_rollback_strategy 'production' '$deployment_id' 'blue_green_switchback'
    "

    # THEN: Blue-green switchback is executed
    assert_success
    assert_output --partial "Executing blue-green switchback"
}

@test "rollback script executes manual intervention strategy" {
    # GIVEN: A deployment record exists
    local deployment_id="rollback-test-123"
    bash -c "
        source '${TEST_DEPLOYMENT_DIR}/30-ci-rollback.sh'
        create_deployment_record '$deployment_id' 'staging' 'us-east' 'abc123'
    "

    # WHEN: Executing manual intervention rollback
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/30-ci-rollback.sh'
        execute_rollback_strategy 'staging' '$deployment_id' 'manual_intervention'
    "

    # THEN: Manual intervention is initiated
    assert_success
    assert_output --partial "Initiating manual intervention"
}

@test "rollback script updates rollback tags" {
    # GIVEN: A rollback operation is complete
    local deployment_id="rollback-test-123"
    bash -c "
        source '${TEST_DEPLOYMENT_DIR}/30-ci-rollback.sh'
        create_deployment_record '$deployment_id' 'staging' 'us-east' 'abc123'
    "

    # WHEN: Updating rollback tags
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/30-ci-rollback.sh'
        update_rollback_tags 'staging' '$deployment_id' 'previous_tag'
    "

    # THEN: Tags are updated
    assert_success
    assert_output --partial "Updated rollback tags"
}

@test "rollback script generates rollback report" {
    # GIVEN: A rollback operation is complete
    local deployment_id="rollback-test-123"
    bash -c "
        source '${TEST_DEPLOYMENT_DIR}/30-ci-rollback.sh'
        create_deployment_record '$deployment_id' 'staging' 'us-east' 'abc123'
    "

    # WHEN: Generating rollback report
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/30-ci-rollback.sh'
        generate_rollback_report 'staging' '$deployment_id' 'previous_tag'
    "

    # THEN: Report is generated
    assert_success
    assert_output --partial "Generated rollback report"
}

@test "rollback script runs main rollback function successfully" {
    # GIVEN: Valid rollback parameters
    # WHEN: Running main rollback function
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/30-ci-rollback.sh'
        main_rollback 'staging' 'deploy-123' 'previous_tag'
    "

    # THEN: Rollback completes successfully
    assert_success
    assert_output --partial "Starting rollback operation"
    assert_output --partial "Rollback operation completed successfully"
}

@test "rollback script supports dry run mode" {
    # GIVEN: Dry run mode is enabled
    export CI_TEST_MODE="dry_run"

    # WHEN: Running rollback in dry run mode
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/30-ci-rollback.sh'
        main_rollback 'staging' 'deploy-123' 'previous_tag'
    "

    # THEN: Rollback runs in dry run mode
    assert_success
    assert_output --partial "Mode: dry_run"
}

@test "rollback script respects DRY_RUN environment variable" {
    # GIVEN: DRY_RUN flag is set
    export DRY_RUN="true"

    # WHEN: Running rollback with dry run
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/30-ci-rollback.sh'
        main_rollback 'staging' 'deploy-123' 'previous_tag'
    "

    # THEN: Rollback is skipped
    assert_success
    assert_output --partial "DRY RUN: Skipping actual rollback operations"
}

@test "rollback script handles production environment" {
    # GIVEN: Production rollback parameters
    # WHEN: Running production rollback
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/30-ci-rollback.sh'
        main_rollback 'production' 'prod-deploy-123' 'blue_green_switchback'
    "

    # THEN: Production rollback is executed
    assert_success
    assert_output --partial "Environment: production"
}

@test "rollback script handles development environment" {
    # GIVEN: Development rollback parameters
    # WHEN: Running development rollback
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/30-ci-rollback.sh'
        main_rollback 'development' 'dev-deploy-123' 'git_revert'
    "

    # THEN: Development rollback is executed
    assert_success
    assert_output --partial "Environment: development"
}

@test "rollback script logs rollback progress" {
    # GIVEN: Rollback operation in progress
    # WHEN: Running rollback
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/30-ci-rollback.sh'
        main_rollback 'staging' 'deploy-123' 'previous_tag'
    "

    # THEN: Progress is logged
    assert_success
    assert_output --partial "Starting rollback operation"
    assert_output --partial "Environment: staging"
    assert_output --partial "Deployment ID: deploy-123"
    assert_output --partial "Strategy: previous_tag"
}

@test "rollback script validates deployment exists before rollback" {
    # GIVEN: Non-existent deployment ID
    # WHEN: Attempting rollback
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/30-ci-rollback.sh'
        validate_deployment_exists 'non-existent-deploy'
    "

    # THEN: Validation fails
    assert_failure
    assert_output --partial "Deployment non-existent-deploy not found"
}

@test "rollback script supports different log levels" {
    # GIVEN: Different log levels
    local log_levels=("debug" "info" "warn" "error")

    # WHEN: Testing each log level
    for level in "${log_levels[@]}"; do
        export LOG_LEVEL="$level"
        run bash -c "
            source '${TEST_DEPLOYMENT_DIR}/30-ci-rollback.sh'
            main_rollback 'staging' 'deploy-123' 'previous_tag'
        "

        # THEN: Rollback works with each log level
        assert_success
    done
}

@test "rollback script provides clear error messages" {
    # GIVEN: Invalid parameters
    # WHEN: Running rollback with invalid parameters
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/30-ci-rollback.sh'
        validate_rollback_inputs '' '' ''
    "

    # THEN: Clear error messages are provided
    assert_failure
    assert_output --partial "Validating rollback inputs"
}

@test "rollback script supports script version tracking" {
    # GIVEN: Script version is defined
    # WHEN: Checking script version
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/30-ci-rollback.sh'
        echo \"\$SCRIPT_VERSION\"
    "

    # THEN: Version is available
    assert_success
    assert_output "1.0.0"
}

@test "rollback script uses pipefail and strict mode" {
    # GIVEN: Script should use strict error handling
    # WHEN: Checking script content for strict mode
    run grep -E "set -euo pipefail" "${TEST_DEPLOYMENT_DIR}/30-ci-rollback.sh"

    # THEN: Strict mode is enabled
    assert_success
    assert_output "set -euo pipefail"
}

@test "rollback script maintains deployment state during rollback" {
    # GIVEN: A deployment with specific state
    local deployment_id="state-test-123"
    bash -c "
        source '${TEST_DEPLOYMENT_DIR}/30-ci-rollback.sh'
        create_deployment_record '$deployment_id' 'staging' 'us-east' 'abc123'
        set_deployment_status '$deployment_id' 'rolling_back' 'Starting rollback'
    "

    # WHEN: Executing rollback
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/30-ci-rollback.sh'
        main_rollback 'staging' '$deployment_id' 'previous_tag'
    "

    # THEN: Deployment state is properly maintained
    assert_success
    assert_deployment_status "$deployment_id" "rolled_back"
}

@test "rollback script handles rollback failure gracefully" {
    # GIVEN: Rollback operation might fail
    # WHEN: Simulating rollback failure
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/30-ci-rollback.sh'
        execute_rollback_with_failure 'staging' 'deploy-123' 'previous_tag'
    "

    # THEN: Failure is handled gracefully
    assert_failure
    assert_output --partial "Rollback failed"
}