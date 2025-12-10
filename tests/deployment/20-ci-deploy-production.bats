#!/usr/bin/env bats

# Load deployment test helper
load "${BATS_TEST_DIRNAME}/../test_helper.bash"

setup() {
    # GIVEN: A clean test environment with deployment structure
    setup_deployment_test_project
    setup_production_deployment_scenario
    setup_git_branch "main"
}

teardown() {
    # Cleanup test environment
    cleanup_deployment_test_project
}

@test "production deployment script loads production configuration successfully" {
    # GIVEN: Production environment configuration exists
    # WHEN: The load_production_config function is called
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/20-ci-deploy-production.sh'
        load_production_config 'us-east'
    "

    # THEN: Configuration is loaded successfully
    assert_success
    assert_output --partial "Loading production environment configuration"
}

@test "production deployment script requires production configuration file" {
    # GIVEN: Production configuration file is missing
    rm -f "${TEST_PROJECT_ROOT}/environments/production/config.yml"

    # WHEN: Loading production configuration
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/20-ci-deploy-production.sh'
        load_production_config 'us-east'
    "

    # THEN: Loading fails with appropriate error
    assert_failure
    assert_output --partial "Production configuration file not found"
}

@test "production deployment script validates production-specific requirements" {
    # GIVEN: Production deployment prerequisites need validation
    # WHEN: Validating production prerequisites
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/20-ci-deploy-production.sh'
        validate_production_prerequisites
    "

    # THEN: Production-specific validations are performed
    assert_success
}

@test "production deployment script requires staging promotion validation" {
    # GIVEN: Production deployment requires staging promotion
    # WHEN: Checking staging promotion requirement
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/20-ci-deploy-production.sh'
        [[ \"\${DEPLOYMENT_CONFIG[require_staging_promotion]}\" == \"true\" ]]
    "

    # THEN: Staging promotion requirement is confirmed
    assert_success
}

@test "production deployment script enables blue-green deployment by default" {
    # GIVEN: Production deployment supports blue-green
    # WHEN: Checking blue-green configuration
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/20-ci-deploy-production.sh'
        [[ \"\${DEPLOYMENT_CONFIG[blue_green_deployment]}\" == \"true\" ]]
    "

    # THEN: Blue-green deployment is enabled
    assert_success
}

@test "production deployment script has enhanced security configurations" {
    # GIVEN: Production requires enhanced security
    # WHEN: Checking security configuration
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/20-ci-deploy-production.sh'
        [[ \"\${SECURITY_CONFIG[require_security_approval]}\" == \"true\" ]]
        [[ \"\${SECURITY_CONFIG[scan_infrastructure]}\" == \"true\" ]]
        [[ \"\${SECURITY_CONFIG[allow_risk_acceptance]}\" == \"false\" ]]
    "

    # THEN: Enhanced security is configured
    assert_success
}

@test "production deployment script includes compliance requirements" {
    # GIVEN: Production must meet compliance standards
    # WHEN: Checking compliance requirements
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/20-ci-deploy-production.sh'
        [[ \" \${COMPLIANCE_REQUIREMENTS[*]} \" =~ \" SOC2 \" ]]
        [[ \" \${COMPLIANCE_REQUIREMENTS[*]} \" =~ \" GDPR \" ]]
        [[ \" \${COMPLIANCE_REQUIREMENTS[*]} \" =~ \" PCI-DSS \" ]]
    "

    # THEN: Compliance requirements are defined
    assert_success
}

@test "production deployment script has enhanced health check endpoints" {
    # GIVEN: Production requires comprehensive health checks
    # WHEN: Checking health check endpoints
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/20-ci-deploy-production.sh'
        [[ \" \${HEALTH_CHECK_ENDPOINTS[*]} \" =~ \"/health\" ]]
        [[ \" \${HEALTH_CHECK_ENDPOINTS[*]} \" =~ \"/api/health\" ]]
        [[ \" \${HEALTH_CHECK_ENDPOINTS[*]} \" =~ \"/metrics/health\" ]]
        [[ \" \${HEALTH_CHECK_ENDPOINTS[*]} \" =~ \"/monitoring/status\" ]]
    "

    # THEN: Enhanced health checks are configured
    assert_success
}

@test "production deployment script supports blue-green rollback strategies" {
    # GIVEN: Production supports advanced rollback strategies
    # WHEN: Checking rollback strategies
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/20-ci-deploy-production.sh'
        [[ \" \${ROLLBACK_STRATEGIES[*]} \" =~ \"blue_green_switchback\" ]]
        [[ \" \${ROLLBACK_STRATEGIES[*]} \" =~ \"emergency_rollback\" ]]
    "

    # THEN: Advanced rollback strategies are available
    assert_success
}

@test "production deployment script creates backup by default" {
    # GIVEN: Production deployment should create backups
    # WHEN: Checking backup configuration
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/20-ci-deploy-production.sh'
        [[ \"\${DEPLOYMENT_CONFIG[create_backup]}\" == \"true\" ]]
    "

    # THEN: Backup creation is enabled
    assert_success
}

@test "production deployment script requires approval by default" {
    # GIVEN: Production deployment requires approval
    # WHEN: Checking approval configuration
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/20-ci-deploy-production.sh'
        [[ \"\${DEPLOYMENT_CONFIG[require_approval]}\" == \"true\" ]]
    "

    # THEN: Approval requirement is enabled
    assert_success
}

@test "production deployment script has longer health check timeout" {
    # GIVEN: Production requires longer health checks
    # WHEN: Checking timeout configuration
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/20-ci-deploy-production.sh'
        [[ \"\${DEPLOYMENT_CONFIG[health_check_timeout]}\" == \"600\" ]]
    "

    # THEN: Extended timeout is configured
    assert_success
}

@test "production deployment script runs production-specific validations" {
    # GIVEN: Production has specific validation requirements
    # WHEN: Checking production validations
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/20-ci-deploy-production.sh'
        [[ \" \${PRODUCTION_VALIDATIONS[*]} \" =~ \"staging_promotion_check\" ]]
        [[ \" \${PRODUCTION_VALIDATIONS[*]} \" =~ \"security_scan_validation\" ]]
        [[ \" \${PRODUCTION_VALIDATIONS[*]} \" =~ \"performance_benchmark_check\" ]]
        [[ \" \${PRODUCTION_VALIDATIONS[*]} \" =~ \"compliance_validation\" ]]
    "

    # THEN: Production-specific validations are defined
    assert_success
}

@test "production deployment script prevents test skipping" {
    # GIVEN: Production should not allow test skipping
    # WHEN: Checking test skip configuration
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/20-ci-deploy-production.sh'
        [[ \"\${DEPLOYMENT_CONFIG[allow_skip_tests]}\" == \"false\" ]]
    "

    # THEN: Test skipping is disabled
    assert_success
}

@test "production deployment script has longer deployment timeout" {
    # GIVEN: Production deployments may take longer
    # WHEN: Checking deployment timeout
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/20-ci-deploy-production.sh'
        [[ \"\${DEPLOYMENT_CONFIG[health_check_timeout]}\" -gt 300 ]]
    "

    # THEN: Extended timeout is configured
    assert_success
}

@test "production deployment script includes emergency rollback option" {
    # GIVEN: Production needs emergency rollback capability
    # WHEN: Checking rollback options
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/20-ci-deploy-production.sh'
        [[ \" \${ROLLBACK_STRATEGIES[*]} \" =~ \"emergency_rollback\" ]]
    "

    # THEN: Emergency rollback is available
    assert_success
}

@test "production deployment script supports multiple production regions" {
    # GIVEN: Production can deploy to multiple regions
    # WHEN: Checking region configuration
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/20-ci-deploy-production.sh'
        [[ \"\${DEPLOYMENT_CONFIG[deploy_regions]}\" == \"us-east,eu-west\" ]]
    "

    # THEN: Multiple regions are supported
    assert_success
}

@test "production deployment script handles deployment command with dry run" {
    # GIVEN: Dry run mode is enabled for safety
    export CI_DEPLOY_PRODUCTION_MODE="dry_run"

    # WHEN: Running production deployment command
    run bash -c "${TEST_DEPLOYMENT_DIR}/20-ci-deploy-production.sh deploy us-east test-prod-123"

    # THEN: Production deployment process executes safely
    assert_success
    assert_output --partial "Starting production deployment"
}

@test "production deployment script handles status command" {
    # WHEN: Running production status command
    run bash -c "${TEST_DEPLOYMENT_DIR}/20-ci-deploy-production.sh status us-east"

    # THEN: Production status is displayed
    assert_success
    assert_output --partial "Production deployment status"
}

@test "production deployment script handles rollback command" {
    # GIVEN: A production deployment exists
    local deployment_id="prod-deploy-123"
    bash -c "
        source '${TEST_DEPLOYMENT_DIR}/20-ci-deploy-production.sh'
        create_deployment_record '$deployment_id' 'production' 'us-east' 'abc123'
    "

    # WHEN: Running production rollback
    run bash -c "${TEST_DEPLOYMENT_DIR}/20-ci-deploy-production.sh rollback $deployment_id blue_green_switchback"

    # THEN: Production rollback is executed
    assert_success
    assert_output --partial "Rolling back production deployment"
}

@test "production deployment script validates input parameters" {
    # WHEN: Running rollback without deployment ID
    run bash -c "${TEST_DEPLOYMENT_DIR}/20-ci-deploy-production.sh rollback"

    # THEN: Command fails with usage information
    assert_failure
    assert_output --partial "Deployment ID is required for rollback"
}

@test "production deployment script supports emergency rollback" {
    # GIVEN: A production deployment exists
    local deployment_id="prod-deploy-123"
    bash -c "
        source '${TEST_DEPLOYMENT_DIR}/20-ci-deploy-production.sh'
        create_deployment_record '$deployment_id' 'production' 'us-east' 'abc123'
    "

    # WHEN: Running emergency rollback
    run bash -c "${TEST_DEPLOYMENT_DIR}/20-ci-deploy-production.sh rollback $deployment_id emergency_rollback"

    # THEN: Emergency rollback is executed
    assert_success
}

@test "production deployment script includes vulnerability scanning" {
    # GIVEN: Production requires vulnerability scanning
    # WHEN: Checking security configuration
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/20-ci-deploy-production.sh'
        [[ \"\${SECURITY_CONFIG[vulnerability_scan_threshold]}\" == \"medium\" ]]
    "

    # THEN: Vulnerability scanning threshold is set
    assert_success
}

@test "production deployment script requires uncommitted changes check" {
    # GIVEN: Production requires clean working directory
    # WHEN: Simulating uncommitted changes
    setup_git_uncommitted_changes

    # WHEN: Running pre-deployment checks
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/20-ci-deploy-production.sh'
        run_pre_deployment_checks 'test-deploy' 'production' 'us-east'
    "

    # THEN: Pre-deployment checks fail due to uncommitted changes
    assert_failure
    assert_output --partial "Working directory has uncommitted changes"
}

@test "production deployment script validates staging promotion" {
    # GIVEN: Production requires successful staging deployment
    # WHEN: Validating staging promotion
    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/20-ci-deploy-production.sh'
        validate_staging_promotion 'test-deploy'
    "

    # THEN: Staging promotion validation is performed
    assert_success
}

@test "production deployment script generates comprehensive deployment report" {
    # GIVEN: Production deployment reporting is required
    # WHEN: Generating production deployment report
    local deployment_id="prod-deploy-123"
    bash -c "
        source '${TEST_DEPLOYMENT_DIR}/20-ci-deploy-production.sh'
        create_deployment_record '$deployment_id' 'production' 'us-east' 'abc123'
    "

    run bash -c "
        source '${TEST_DEPLOYMENT_DIR}/20-ci-deploy-production.sh'
        generate_production_deployment_report '$deployment_id' 'production' 'us-east' 'success'
    "

    # THEN: Comprehensive report is generated
    assert_success
}

@test "production deployment script supports manual intervention rollback" {
    # GIVEN: Manual intervention may be required for production
    # WHEN: Running manual intervention rollback
    local deployment_id="prod-deploy-123"
    bash -c "
        source '${TEST_DEPLOYMENT_DIR}/20-ci-deploy-production.sh'
        create_deployment_record '$deployment_id' 'production' 'us-east' 'abc123'
    "

    run bash -c "${TEST_DEPLOYMENT_DIR}/20-ci-deploy-production.sh rollback $deployment_id manual_intervention"

    # THEN: Manual intervention is initiated
    assert_success
    assert_output --partial "Marking for manual intervention"
}