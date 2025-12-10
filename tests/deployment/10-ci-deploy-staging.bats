#!/usr/bin/env bats

# Load deployment test helper
load "${BATS_TEST_DIRNAME}/../test_helper.bash"

setup() {
    # GIVEN: A clean test environment with deployment structure
    setup_deployment_test_project
    setup_successful_deployment_scenario
    setup_git_branch "main"
}

teardown() {
    # Cleanup test environment
    cleanup_deployment_test_project
}

@test "staging deployment script loads staging configuration successfully" {
    # GIVEN: Staging environment configuration exists
    # WHEN: The load_staging_config function is called
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/10-ci-deploy-staging.sh'
        load_staging_config 'us-east'
    "

    # THEN: Configuration is loaded successfully
    assert_success
    assert_output --partial "Loading staging environment configuration"
    assert_output --partial "Staging configuration loaded successfully"
}

@test "staging deployment script validates branch prerequisites correctly" {
    # GIVEN: Current branch is main (allowed for staging)
    # WHEN: Validating staging prerequisites
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/10-ci-deploy-staging.sh'
        validate_staging_prerequisites
    "

    # THEN: Validation passes
    assert_success
    assert_output --partial "Branch main is acceptable for staging deployment"
}

@test "staging deployment script rejects disallowed branches without force flag" {
    # GIVEN: Current branch is feature/test (not standard)
    setup_git_branch "feature/test"

    # WHEN: Validating staging prerequisites without force flag
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/10-ci-deploy-staging.sh'
        validate_staging_prerequisites
    "

    # THEN: Validation fails with appropriate error
    assert_failure
    assert_output --partial "Branch feature/test may not be suitable for staging deployment"
    assert_output --partial "Use FORCE_DEPLOY=true to deploy from this branch"
}

@test "staging deployment script allows disallowed branches with force flag" {
    # GIVEN: Current branch is feature/test (not standard)
    setup_git_branch "feature/test"
    export FORCE_DEPLOY="true"

    # WHEN: Validating staging prerequisites with force flag
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/10-ci-deploy-staging.sh'
        validate_staging_prerequisites
    "

    # THEN: Validation passes
    assert_success
}

@test "staging deployment script validates required environment variables" {
    # GIVEN: Required environment variables are not set
    unset AWS_REGION DEPLOYMENT_ENVIRONMENT CI_COMMIT_SHA

    # WHEN: Validating staging prerequisites
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/10-ci-deploy-staging.sh'
        validate_staging_prerequisites
    "

    # THEN: Validation fails with missing variable error
    assert_failure
    assert_output --partial "Required environment variable AWS_REGION is not set"
}

@test "staging deployment script checks test recency correctly" {
    # GIVEN: No recent test record exists
    rm -f "${TEST_PROJECT_ROOT}/.last_staging_test"

    # WHEN: Validating staging prerequisites without force flag
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/10-ci-deploy-staging.sh'
        validate_staging_prerequisites
    "

    # THEN: Validation fails due to missing test record
    assert_failure
    assert_output --partial "No recent test record found"
    assert_output --partial "Run tests first or use FORCE_DEPLOY=true"
}

@test "staging deployment script allows deployment with recent test record" {
    # GIVEN: Recent test record exists (created by setup)
    # WHEN: Validating staging prerequisites
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/10-ci-deploy-staging.sh'
        validate_staging_prerequisites
    "

    # THEN: Validation passes
    assert_success
}

@test "staging deployment script allows skipping tests with SKIP_TESTS flag" {
    # GIVEN: No recent test record exists but tests are skipped
    rm -f "${TEST_PROJECT_ROOT}/.last_staging_test"
    export SKIP_TESTS="true"

    # WHEN: Validating staging prerequisites
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/10-ci-deploy-staging.sh'
        validate_staging_prerequisites
    "

    # THEN: Validation passes
    assert_success
}

@test "staging deployment script creates deployment record successfully" {
    # GIVEN: A deployment ID and environment details
    local deployment_id="test-deploy-123"
    local environment="staging"
    local region="us-east"
    local commit_sha="abc123def456"

    # WHEN: Creating deployment record
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/10-ci-deploy-staging.sh'
        create_deployment_record '$deployment_id' '$environment' '$region' '$commit_sha'
    "

    # THEN: Deployment record is created
    assert_success
    assert_deployment_record_exists "$deployment_id"
}

@test "staging deployment script sets deployment status correctly" {
    # GIVEN: A deployment record exists
    local deployment_id="test-deploy-123"
    bash -c "
        source '${TEST_DEPLOYMENT_DIR}/10-ci-deploy-staging.sh'
        create_deployment_record '$deployment_id' 'staging' 'us-east' 'abc123'
    "

    # WHEN: Setting deployment status
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/10-ci-deploy-staging.sh'
        set_deployment_status '$deployment_id' 'in_progress' 'Deploying to staging'
    "

    # THEN: Status is updated correctly
    assert_success
    assert_deployment_status "$deployment_id" "in_progress"
}

@test "staging deployment script generates deployment report" {
    # GIVEN: A deployment record exists
    local deployment_id="test-deploy-123"
    bash -c "
        source '${TEST_DEPLOYMENT_DIR}/10-ci-deploy-staging.sh'
        create_deployment_record '$deployment_id' 'staging' 'us-east' 'abc123'
    "

    # WHEN: Generating deployment report
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/10-ci-deploy-staging.sh'
        generate_deployment_report '$deployment_id' 'staging' 'us-east' 'success'
    "

    # THEN: Report is generated with correct information
    assert_success
    assert_deployment_report_generated "$deployment_id" "staging" "us-east"
}

@test "staging deployment script runs full deployment flow in dry run mode" {
    # GIVEN: Dry run mode is enabled
    export CI_DEPLOY_STAGING_MODE="dry_run"

    # WHEN: Running the deployment command
    run bash -c "${TEST_DEPLOYMENT_DIR}/10-ci-deploy-staging.sh deploy us-east test-deploy-123"

    # THEN: Deployment process executes through all stages
    assert_success
    assert_output --partial "Starting staging deployment"
    assert_output --partial "Loading staging environment configuration"
    assert_output --partial "Validating staging deployment prerequisites"
    assert_output --partial "Staging deployment completed successfully"
}

@test "staging deployment script handles status command correctly" {
    # WHEN: Running status command
    run bash -c "${TEST_DEPLOYMENT_DIR}/10-ci-deploy-staging.sh status us-east"

    # THEN: Status information is displayed
    assert_success
    assert_output --partial "Getting staging deployment status"
    assert_output --partial "Staging Deployment Status:"
    assert_output --partial "Environment: staging"
    assert_output --partial "Region: us-east"
}

@test "staging deployment script handles config command correctly" {
    # WHEN: Running config command
    run bash -c "${TEST_DEPLOYMENT_DIR}/10-ci-deploy-staging.sh config us-east"

    # THEN: Configuration is displayed
    assert_success
    assert_output --partial "Showing staging configuration"
    assert_output --partial "Loading staging environment configuration"
}

@test "staging deployment script handles validate command correctly" {
    # WHEN: Running validate command
    run bash -c "${TEST_DEPLOYMENT_DIR}/10-ci-deploy-staging.sh validate us-east"

    # THEN: Validation is performed
    assert_success
    assert_output --partial "Validating staging deployment prerequisites"
}

@test "staging deployment script handles rollback command correctly" {
    # GIVEN: A deployment record exists
    local deployment_id="test-deploy-123"
    bash -c "
        source '${TEST_DEPLOYMENT_DIR}/10-ci-deploy-staging.sh'
        create_deployment_record '$deployment_id' 'staging' 'us-east' 'abc123'
    "

    # WHEN: Running rollback command
    run bash -c "${TEST_DEPLOYMENT_DIR}/10-ci-deploy-staging.sh rollback $deployment_id git_revert"

    # THEN: Rollback is executed
    assert_success
    assert_output --partial "Rolling back staging deployment: $deployment_id"
}

@test "staging deployment script rejects invalid rollback strategies" {
    # GIVEN: A deployment record exists
    local deployment_id="test-deploy-123"
    bash -c "
        source '${TEST_DEPLOYMENT_DIR}/10-ci-deploy-staging.sh'
        create_deployment_record '$deployment_id' 'staging' 'us-east' 'abc123'
    "

    # WHEN: Running rollback with invalid strategy
    run bash -c "${TEST_DEPLOYMENT_DIR}/10-ci-deploy-staging.sh rollback $deployment_id invalid_strategy"

    # THEN: Rollback is rejected
    assert_failure
    assert_output --partial "Invalid rollback strategy: invalid_strategy"
    assert_output --partial "Valid strategies:"
}

@test "staging deployment script handles rollback without deployment ID" {
    # WHEN: Running rollback without deployment ID
    run bash -c "${TEST_DEPLOYMENT_DIR}/10-ci-deploy-staging.sh rollback"

    # THEN: Command fails with usage information
    assert_failure
    assert_output --partial "Deployment ID is required for rollback"
    assert_output --partial "Usage:"
}

@test "staging deployment script handles unknown commands" {
    # WHEN: Running unknown command
    run bash -c "${TEST_DEPLOYMENT_DIR}/10-ci-deploy-staging.sh unknown_command"

    # THEN: Command fails with usage information
    assert_failure
    assert_output --partial "Unknown command: unknown_command"
    assert_output --partial "Usage:"
    assert_output --partial "Commands:"
}

@test "staging deployment script handles manual intervention rollback" {
    # GIVEN: A deployment record exists
    local deployment_id="test-deploy-123"
    bash -c "
        source '${TEST_DEPLOYMENT_DIR}/10-ci-deploy-staging.sh'
        create_deployment_record '$deployment_id' 'staging' 'us-east' 'abc123'
    "

    # WHEN: Running rollback with manual intervention strategy
    run bash -c "${TEST_DEPLOYMENT_DIR}/10-ci-deploy-staging.sh rollback $deployment_id manual_intervention"

    # THEN: Manual intervention is marked
    assert_success
    assert_output --partial "Marking for manual intervention"
    assert_output --partial "Please investigate and resolve manually"
}

@test "staging deployment script supports different regions" {
    # WHEN: Running deployment for eu-west region
    run bash -c "${TEST_DEPLOYMENT_DIR}/10-ci-deploy-staging.sh status eu-west"

    # THEN: Status shows correct region
    assert_success
    assert_output --partial "Region: eu-west"
}

@test "staging deployment script accepts custom deployment ID" {
    # GIVEN: Custom deployment ID
    local custom_deployment_id="custom-deploy-456"

    # WHEN: Running deployment with custom ID
    run bash -c "${TEST_DEPLOYMENT_DIR}/10-ci-deploy-staging.sh deploy us-east $custom_deployment_id"

    # THEN: Custom ID is used in the process
    assert_success
    assert_output --partial "Deployment ID: $custom_deployment_id"
}

@test "staging deployment script provides helpful usage information" {
    # WHEN: Running script without arguments (shows usage)
    run bash -c "${TEST_DEPLOYMENT_DIR}/10-ci-deploy-staging.sh"

    # THEN: Default deploy command is executed
    assert_success
    assert_output --partial "Starting staging deployment"
}