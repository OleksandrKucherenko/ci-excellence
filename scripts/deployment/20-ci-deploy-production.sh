#!/bin/bash
# T102: Production deployment script with enhanced validation and security

set -euo pipefail

# Script configuration
SCRIPT_NAME="$(basename "$0" .sh)"
SCRIPT_VERSION="1.0.0"
SCRIPT_MODE="${CI_DEPLOY_PRODUCTION_MODE:-${CI_TEST_MODE:-default}}"
DEFAULT_REGION="us-east"
ENVIRONMENT="production"
LOG_LEVEL="${CI_LOG_LEVEL:-info}"

# Source libraries and utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/config.sh"
source "${SCRIPT_DIR}/../lib/logging.sh"
source "${SCRIPT_DIR}/../lib/environment.sh"
source "${SCRIPT_DIR}/../lib/validation.sh"
source "${SCRIPT_DIR}/../lib/deployment.sh"
source "${SCRIPT_DIR}/../lib/security.sh"

# Production deployment configuration
declare -A DEPLOYMENT_CONFIG=(
    ["environment"]="production"
    ["max_concurrent_deployments"]=1
    ["health_check_timeout"]=600
    ["require_approval"]=true
    ["allow_skip_tests"]=false
    ["rollback_on_failure"]=true
    ["create_backup"]=true
    ["deploy_regions"]="us-east,eu-west"
    ["default_region"]="us-east"
    ["require_staging_promotion"]=true
    ["blue_green_deployment"]=true
)

# Enhanced health check endpoints for production
declare -a HEALTH_CHECK_ENDPOINTS=(
    "/health"
    "/api/health"
    "/metrics/health"
    "/monitoring/status"
    "/system/health"
)

# Production rollback strategies
declare -a ROLLBACK_STRATEGIES=(
    "blue_green_switchback"
    "git_revert"
    "previous_tag"
    "emergency_rollback"
    "manual_intervention"
)

# Enhanced security configurations for production
declare -A SECURITY_CONFIG=(
    ["scan_secrets"]=true
    ["scan_dependencies"]=true
    ["scan_infrastructure"]=true
    ["require_security_approval"]=true
    ["allow_risk_acceptance"]=false
    ["require_penetration_test"]=false
    ["vulnerability_scan_threshold"]="medium"
)

# Production-specific validations
declare -a PRODUCTION_VALIDATIONS=(
    "staging_promotion_check"
    "security_scan_validation"
    "performance_benchmark_check"
    "compliance_validation"
    "infrastructure_health_check"
    "database_migration_validation"
    "feature_flag_validation"
)

# Compliance requirements for production
declare -a COMPLIANCE_REQUIREMENTS=(
    "SOC2"
    "GDPR"
    "PCI-DSS"
    "SOX"
    "HIPAA"
)

# Function to load production environment configuration
load_production_config() {
    local config_file="${PROJECT_ROOT}/environments/production/config.yml"
    local region="${1:-$DEFAULT_REGION}"

    log_info "Loading production environment configuration"

    if [[ ! -f "$config_file" ]]; then
        log_error "Production configuration file not found: $config_file"
        return 1
    fi

    # Parse YAML configuration using yq if available
    if command -v yq &> /dev/null; then
        log_debug "Parsing YAML configuration with yq"

        # Extract environment variables from config
        local env_vars
        env_vars=$(yq eval '.environment_variables | to_entries | .[] | "\(.key)=\(.value)"' "$config_file" 2>/dev/null || true)

        # Export extracted environment variables
        while IFS='=' read -r key value; do
            if [[ -n "$key" && -n "$value" ]]; then
                export "$key"="$value"
                log_debug "Exported $key from production config"
            fi
        done <<< "$env_vars"

        # Extract compliance requirements
        local compliance_reqs
        compliance_reqs=$(yq eval '.compliance.data_residency.regulations[]' "$config_file" 2>/dev/null | tr '\n' ',' | sed 's/,$//' || true)
        export PRODUCTION_COMPLIANCE_REQUIREMENTS="${compliance_reqs:-SOC2,GDPR,PCI-DSS,SOX}"

    else
        log_warn "yq not available, using basic config parsing"
        export PRODUCTION_COMPLIANCE_REQUIREMENTS="SOC2,GDPR,PCI-DSS,SOX"
    fi

    # Load region-specific configuration
    local region_config="${PROJECT_ROOT}/environments/production/regions/${region}/config.yml"
    if [[ -f "$region_config" ]]; then
        log_debug "Loading region-specific configuration for ${region}"

        if command -v yq &> /dev/null; then
            local region_env_vars
            region_env_vars=$(yq eval '.environment_variables | to_entries | .[] | "\(.key)=\(.value)"' "$region_config" 2>/dev/null || true)

            while IFS='=' read -r key value; do
                if [[ -n "$key" && -n "$value" ]]; then
                    export "$key"="$value"
                    log_debug "Exported $key from ${region} region config"
                fi
            done <<< "$region_env_vars"
        fi
    fi

    # Export production-specific variables
    export DEPLOYMENT_ENVIRONMENT="production"
    export DEPLOYMENT_REGION="$region"
    export CI_DEPLOYMENT_TARGET="production"
    export PRODUCTION_DEPLOYMENT="true"

    log_success "Production configuration loaded successfully"
}

# Function to validate production deployment prerequisites
validate_production_prerequisites() {
    log_info "Validating production deployment prerequisites"

    # Enhanced branch validation
    local current_branch
    current_branch=$(git branch --show-current)

    case "$current_branch" in
        main|master|release/*)
            log_debug "Branch $current_branch is acceptable for production deployment"
            ;;
        *)
            log_error "Branch $current_branch is not acceptable for production deployment"
            log_error "Production deployments must be from main/master or release branches"
            return 1
            ;;
    esac

    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        log_error "Working directory has uncommitted changes"
        return 1
    fi

    # Validate required environment variables
    local required_vars=(
        "AWS_REGION"
        "DEPLOYMENT_ENVIRONMENT"
        "CI_COMMIT_SHA"
        "CI_COMMIT_TAG"
    )

    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            log_error "Required environment variable $var is not set"
            return 1
        fi
    done

    # Validate that we have a version tag
    if [[ -z "${CI_COMMIT_TAG:-}" ]]; then
        log_error "Production deployments require a version tag"
        log_error "Current commit: $CI_COMMIT_SHA"
        return 1
    fi

    # Validate tag format (should be a version tag)
    if [[ ! "$CI_COMMIT_TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9]+)?$ ]]; then
        log_error "Invalid version tag format: $CI_COMMIT_TAG"
        log_error "Expected format: vX.Y.Z or vX.Y.Z-prerelease"
        return 1
    fi

    # Check for recent successful staging deployment
    log_info "Checking for recent successful staging deployment"
    check_staging_deployment_status "$CI_COMMIT_SHA" || {
        log_error "No successful staging deployment found for commit $CI_COMMIT_SHA"
        log_error "Production deployments must be promoted from successful staging deployments"
        return 1
    }

    # Validate test requirements (must be recent and comprehensive)
    log_info "Validating test requirements for production"
    validate_production_test_requirements || return 1

    # Security validations
    log_info "Running security validations for production"
    validate_production_security_requirements || return 1

    # Compliance validations
    log_info "Running compliance validations"
    validate_production_compliance_requirements || return 1

    # Infrastructure health check
    log_info "Running infrastructure health check"
    validate_infrastructure_health "production" "$DEFAULT_REGION" || return 1

    # Validate deployment configuration
    validate_deployment_config DEPLOYMENT_CONFIG || return 1

    log_success "Production prerequisites validation passed"
}

# Function to validate production test requirements
validate_production_test_requirements() {
    local last_test_file="${PROJECT_ROOT}/.last_production_test"
    local min_test_age_hours=2  # Tests must be within last 2 hours for production

    if [[ -f "$last_test_file" ]]; then
        local last_test_time
        last_test_time=$(stat -c %Y "$last_test_file" 2>/dev/null || stat -f %m "$last_test_file" 2>/dev/null || echo 0)
        local current_time
        current_time=$(date +%s)
        local diff_hours=$(( (current_time - last_test_time) / 3600 ))

        if [[ $diff_hours -gt $min_test_age_hours ]]; then
            log_error "Tests haven't been run in ${diff_hours} hours (max: ${min_test_age_hours})"
            return 1
        fi
    else
        log_error "No recent test record found"
        return 1
    fi

    # Check for comprehensive test results
    local test_results_file="${PROJECT_ROOT}/test_results.json"
    if [[ ! -f "$test_results_file" ]]; then
        log_error "No test results file found: $test_results_file"
        return 1
    fi

    # Validate test coverage (should be > 80% for production)
    if command -v jq &> /dev/null; then
        local coverage
        coverage=$(jq -r '.coverage.total // 0' "$test_results_file" 2>/dev/null || echo 0)
        if (( $(echo "$coverage < 80" | bc -l) )); then
            log_error "Test coverage ${coverage}% is below required 80% for production"
            return 1
        fi
        log_info "Test coverage: ${coverage}%"
    fi

    log_success "Production test requirements validated"
}

# Function to validate production security requirements
validate_production_security_requirements() {
    local security_report_file="${PROJECT_ROOT}/security_report.json"

    if [[ ! -f "$security_report_file" ]]; then
        log_error "No security report found: $security_report_file"
        return 1
    fi

    # Check for high severity vulnerabilities
    if command -v jq &> /dev/null; then
        local high_vulns
        high_vulns=$(jq -r '.vulnerabilities.high // 0' "$security_report_file" 2>/dev/null || echo 0)

        if [[ "$high_vulns" -gt 0 ]]; then
            log_error "$high_vulns high severity vulnerabilities found"
            return 1
        fi

        # Check for critical secrets
        local critical_secrets
        critical_secrets=$(jq -r '.secrets.critical // 0' "$security_report_file" 2>/dev/null || echo 0)

        if [[ "$critical_secrets" -gt 0 ]]; then
            log_error "$critical_secrets critical secrets found"
            return 1
        fi

        log_info "Security validation passed"
    else
        log_warn "jq not available, skipping detailed security validation"
    fi

    # Validate encryption requirements
    validate_encryption_requirements "production" || return 1

    log_success "Production security requirements validated"
}

# Function to validate production compliance requirements
validate_production_compliance_requirements() {
    local compliance_report_file="${PROJECT_ROOT}/compliance_report.json"

    # Check compliance for each required standard
    for standard in "${COMPLIANCE_REQUIREMENTS[@]}"; do
        log_info "Validating $standard compliance"

        case "$standard" in
            "GDPR")
                validate_gdpr_compliance || return 1
                ;;
            "SOC2")
                validate_soc2_compliance || return 1
                ;;
            "PCI-DSS")
                validate_pci_dss_compliance || return 1
                ;;
            "SOX")
                validate_sox_compliance || return 1
                ;;
            "HIPAA")
                validate_hipaa_compliance || return 1
                ;;
        esac
    done

    log_success "Production compliance requirements validated"
}

# Function to check staging deployment status
check_staging_deployment_status() {
    local commit_sha="$1"
    local staging_regions=("us-east" "eu-west")
    local successful_staging=false

    log_info "Checking staging deployment status for commit $commit_sha"

    for region in "${staging_regions[@]}"; do
        local staging_deployments
        staging_deployments=$(list_deployments_for_commit "staging" "$region" "$commit_sha" 2>/dev/null || true)

        if [[ -n "$staging_deployments" ]]; then
            local latest_deployment
            latest_deployment=$(echo "$staging_deployments" | head -n1 | cut -d',' -f1)

            if [[ -n "$latest_deployment" ]]; then
                local deployment_status
                deployment_status=$(get_deployment_status "$latest_deployment" 2>/dev/null || echo "unknown")

                if [[ "$deployment_status" == "success" ]]; then
                    log_info "Found successful staging deployment: $latest_deployment ($region)"
                    successful_staging=true
                    break
                else
                    log_warn "Staging deployment $latest_deployment ($region) status: $deployment_status"
                fi
            fi
        fi
    done

    if [[ "$successful_staging" == "false" ]]; then
        log_error "No successful staging deployment found for commit $commit_sha"
        return 1
    fi

    return 0
}

# Function to deploy to production environment
deploy_to_production() {
    local target_region="${1:-$DEFAULT_REGION}"
    local deployment_id="${2:-$(generate_deployment_id)}"

    log_info "Starting production deployment to ${target_region} region"
    log_info "Deployment ID: $deployment_id"
    log_info "Version: ${CI_COMMIT_TAG:-unknown}"

    # Production approval check
    if [[ "${DEPLOYMENT_CONFIG[require_approval]}" == "true" ]] && [[ "${PRODUCTION_APPROVED:-false}" != "true" ]]; then
        log_error "Production deployment requires explicit approval"
        log_info "Set PRODUCTION_APPROVED=true to proceed"
        return 1
    fi

    # Load production configuration
    load_production_config "$target_region"

    # Validate prerequisites
    validate_production_prerequisites

    # Create deployment record
    create_deployment_record "$deployment_id" "$ENVIRONMENT" "$target_region" "$CI_COMMIT_SHA"

    # Set deployment status
    set_deployment_status "$deployment_id" "in_progress" "Deploying to production"

    trap 'handle_production_deployment_failure "$deployment_id" "$ENVIRONMENT" "$target_region"' ERR

    # Pre-deployment checks
    log_info "Running comprehensive pre-deployment checks for production"
    run_production_pre_deployment_checks "$deployment_id" "$ENVIRONMENT" "$target_region"

    # Create backup before deployment
    if [[ "${DEPLOYMENT_CONFIG[create_backup]}" == "true" ]]; then
        log_info "Creating production backup"
        create_production_backup "$deployment_id" "$target_region"
    fi

    # Enhanced security scanning
    if [[ "${SECURITY_CONFIG[scan_secrets]}" == "true" ]]; then
        log_info "Running comprehensive security scanning for production"
        run_security_scans "production" "high" "all"
    fi

    # Run comprehensive tests
    log_info "Running comprehensive tests for production deployment"
    run_deployment_tests "production"

    # Update test timestamp
    touch "${PROJECT_ROOT}/.last_production_test"

    # Build application for production
    log_info "Building application for production"
    build_application_for_environment "production" "$target_region"

    # Deploy infrastructure with enhanced validation
    log_info "Deploying infrastructure for production"
    deploy_infrastructure_for_environment "production" "$target_region"

    # Blue-green deployment if enabled
    if [[ "${DEPLOYMENT_CONFIG[blue_green_deployment]}" == "true" ]]; then
        log_info "Performing blue-green deployment to production"
        deploy_blue_green_production "$deployment_id" "$target_region"
    else
        log_info "Deploying application to production (rolling update)"
        deploy_application_to_environment "production" "$target_region"
    fi

    # Comprehensive health checks
    log_info "Running comprehensive health checks on production deployment"
    run_production_health_checks "$ENVIRONMENT" "$target_region" "${HEALTH_CHECK_ENDPOINTS[@]}"

    # Performance validation
    log_info "Running performance validation on production"
    run_performance_validation "$ENVIRONMENT" "$target_region"

    # Comprehensive smoke tests
    log_info "Running comprehensive smoke tests on production"
    run_production_smoke_tests "$ENVIRONMENT" "$target_region"

    # Update production environment tags
    log_info "Updating production environment tags"
    update_environment_tags "$ENVIRONMENT" "$target_region" "$CI_COMMIT_TAG"

    # Set deployment status to success
    set_deployment_status "$deployment_id" "success" "Production deployment completed successfully"

    # Generate deployment report
    generate_production_deployment_report "$deployment_id" "$ENVIRONMENT" "$target_region" "success"

    log_success "Production deployment completed successfully"

    # Display production-specific information
    echo
    log_info "Production Environment Information:"
    echo "  - Region: $target_region"
    echo "  - Environment: production"
    echo "  - Version: ${CI_COMMIT_TAG:-unknown}"
    echo "  - Deployment ID: $deployment_id"
    echo "  - Commit: $CI_COMMIT_SHA"
    echo "  - Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    echo
    log_info "Production URLs:"
    echo "  - Web: https://${target_region}.example.com"
    echo "  - API: https://api.${target_region}.example.com"
    echo
    log_info "Monitoring and Alerting:"
    echo "  - Status Page: https://status.example.com"
    echo "  - Metrics: https://metrics.example.com"
    echo "  - Logs: https://logs.example.com"
    echo
    log_warn "Production deployment is live. Monitor closely for the next 30 minutes."
}

# Function to handle production deployment failure
handle_production_deployment_failure() {
    local deployment_id="$1"
    local environment="$2"
    local region="$3"

    log_error "Production deployment failed: $deployment_id"

    # Set deployment status to failed
    set_deployment_status "$deployment_id" "failed" "Production deployment failed"

    # Trigger automatic rollback if enabled
    if [[ "${DEPLOYMENT_CONFIG[rollback_on_failure]}" == "true" ]]; then
        log_warn "Triggering automatic rollback for production deployment"
        rollback_production_deployment "$deployment_id" "blue_green_switchback"
    fi

    # Send alert notifications
    send_production_deployment_alert "$deployment_id" "$environment" "$region" "failed"

    # Generate failure report
    generate_production_deployment_report "$deployment_id" "$environment" "$region" "failed"
}

# Function to show production deployment status
show_production_status() {
    local region="${1:-$DEFAULT_REGION}"

    log_info "Getting production deployment status for ${region} region"

    # Load production config to get endpoints
    load_production_config "$region"

    echo
    log_info "Production Deployment Status:"
    echo "  - Environment: production"
    echo "  - Region: $region"
    echo "  - AWS Region: ${AWS_REGION:-not set}"
    echo "  - Deployment Target: ${CI_DEPLOYMENT_TARGET:-not set}"
    echo "  - Compliance: ${PRODUCTION_COMPLIANCE_REQUIREMENTS:-not set}"
    echo

    if command -v aws &> /dev/null && [[ -n "${AWS_REGION:-}" ]]; then
        log_info "Checking AWS resources in production..."

        # Check ECS services
        local cluster_name="production-${region}"
        if aws ecs describe-clusters --clusters "$cluster_name" &> /dev/null; then
            echo "  - ECS Cluster: $cluster_name (active)"

            # List services with detailed status
            local services
            services=$(aws ecs list-services --cluster "$cluster_name" --query 'serviceArns[*]' --output text 2>/dev/null | tr '\t' '\n' || true)
            if [[ -n "$services" ]]; then
                echo "  - Services:"
                while IFS= read -r service; do
                    if [[ -n "$service" ]]; then
                        local service_name
                        service_name=$(basename "$service")
                        local service_status
                        service_status=$(aws ecs describe-services --cluster "$cluster_name" --services "$service_name" --query 'services[0].status' --output text 2>/dev/null || echo "unknown")
                        local desired_count
                        desired_count=$(aws ecs describe-services --cluster "$cluster_name" --services "$service_name" --query 'services[0].desiredCount' --output text 2>/dev/null || echo "0")
                        local running_count
                        running_count=$(aws ecs describe-services --cluster "$cluster_name" --services "$service_name" --query 'services[0].runningCount' --output text 2>/dev/null || echo "0")
                        echo "    - $service_name: $service_status ($running_count/$desired_count)"
                    fi
                done <<< "$services"
            fi
        else
            echo "  - ECS Cluster: $cluster_name (not found)"
        fi

        # Check S3 buckets
        local bucket_prefix="production-${region}"
        echo "  - S3 Buckets:"
        aws s3 ls | grep "$bucket_prefix" | sed 's/^/    - /' || echo "    - None found"

        # Check load balancers
        echo "  - Load Balancers:"
        aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `production-`)] | [*].[LoadBalancerName,State.Code]' --output text 2>/dev/null | sed 's/^/    - /' || echo "    - None found"
    fi

    echo
    log_info "Recent Deployments:"
    list_recent_deployments "production" 5 || echo "  - No recent deployments found"

    echo
    log_info "Production Health:"
    echo "  - Version Tag: $(git describe --tags --exact-match 2>/dev/null || echo 'none')"
    echo "  - Last Production Test: $(stat -c %y "${PROJECT_ROOT}/.last_production_test" 2>/dev/null || echo 'never')"
    echo "  - Security Report: $([ -f "${PROJECT_ROOT}/security_report.json" ] && echo 'present' || echo 'missing')"
    echo "  - Compliance Report: $([ -f "${PROJECT_ROOT}/compliance_report.json" ] && echo 'present' || echo 'missing')"
}

# Function to rollback production deployment
rollback_production() {
    local deployment_id="$1"
    local strategy="${2:-blue_green_switchback}"

    log_info "Rolling back production deployment: $deployment_id"

    if [[ -z "$deployment_id" ]]; then
        log_error "Deployment ID is required for rollback"
        return 1
    fi

    # Validate rollback strategy
    if [[ ! " ${ROLLBACK_STRATEGIES[*]} " =~ " $strategy " ]]; then
        log_error "Invalid rollback strategy: $strategy"
        log_info "Valid strategies: ${ROLLBACK_STRATEGIES[*]}"
        return 1
    fi

    # Check if deployment exists
    if ! deployment_exists "$deployment_id"; then
        log_error "Deployment $deployment_id not found"
        return 1
    fi

    # Production rollback requires explicit confirmation
    if [[ "${CONFIRM_PRODUCTION_ROLLBACK:-false}" != "true" ]]; then
        log_error "Production rollback requires explicit confirmation"
        log_info "Set CONFIRM_PRODUCTION_ROLLBACK=true to proceed"
        return 1
    fi

    # Set rollback status
    set_deployment_status "$deployment_id" "rolling_back" "Rolling back production deployment"

    trap 'log_error "Production rollback failed for deployment $deployment_id"' ERR

    case "$strategy" in
        "blue_green_switchback")
            log_info "Rolling back using blue-green switchback"
            rollback_production_blue_green "$deployment_id"
            ;;
        "git_revert")
            log_info "Rolling back using git revert"
            rollback_deployment_git_revert "$deployment_id"
            ;;
        "previous_tag")
            log_info "Rolling back to previous tag"
            rollback_deployment_previous_tag "$deployment_id"
            ;;
        "emergency_rollback")
            log_info "Triggering emergency rollback"
            trigger_emergency_rollback "$deployment_id"
            ;;
        "manual_intervention")
            log_info "Marking for manual intervention"
            set_deployment_status "$deployment_id" "manual_intervention" "Manual intervention required for production rollback"
            send_production_emergency_alert "$deployment_id" "manual_intervention_required"
            log_info "Emergency alert sent. Please investigate and resolve immediately."
            return 0
            ;;
    esac

    # Update deployment status
    set_deployment_status "$deployment_id" "rolled_back" "Production deployment rolled back successfully"

    # Send rollback notification
    send_production_deployment_alert "$deployment_id" "production" "$region" "rolled_back"

    log_success "Production rollback completed"
}

# Main function
main() {
    local command="${1:-deploy}"
    local region="${2:-$DEFAULT_REGION}"
    local deployment_id="${3:-}"

    # Initialize logging and configuration
    initialize_logging "$LOG_LEVEL" "ci-deploy-production"
    load_project_config

    # Production safety check
    if [[ "${CI_PRODUCTION_SAFE_MODE:-true}" == "true" ]] && [[ "${CI_TEST_MODE}" != "dry_run" ]]; then
        log_warn "Production safe mode is enabled"
        log_info "Set CI_PRODUCTION_SAFE_MODE=false to disable safety checks"
    fi

    case "$command" in
        "deploy")
            log_info "Starting production deployment"
            deploy_to_production "$region" "$deployment_id"
            ;;
        "status")
            show_production_status "$region"
            ;;
        "rollback")
            if [[ -z "$deployment_id" ]]; then
                log_error "Deployment ID is required for rollback"
                echo "Usage: $0 rollback <deployment_id> [strategy]"
                exit 1
            fi
            local strategy="${4:-blue_green_switchback}"
            rollback_production "$deployment_id" "$strategy"
            ;;
        "validate")
            log_info "Validating production deployment prerequisites"
            load_production_config "$region"
            validate_production_prerequisites
            ;;
        "config")
            log_info "Showing production configuration"
            load_production_config "$region"
            show_environment_config "production" "$region"
            ;;
        "check-staging")
            log_info "Checking staging deployment status"
            check_staging_deployment_status "${3:-$CI_COMMIT_SHA}"
            ;;
        *)
            log_error "Unknown command: $command"
            echo
            echo "Usage: $0 [command] [region] [deployment_id] [strategy]"
            echo
            echo "Commands:"
            echo "  deploy         Deploy to production (default)"
            echo "  status         Show production deployment status"
            echo "  rollback       Rollback production deployment"
            echo "  validate       Validate production deployment prerequisites"
            echo "  config         Show production configuration"
            echo "  check-staging  Check staging deployment for commit"
            echo
            echo "Regions: us-east, eu-west"
            echo "Strategies: blue_green_switchback, git_revert, previous_tag, emergency_rollback, manual_intervention"
            echo
            echo "Environment Variables:"
            echo "  PRODUCTION_APPROVED=true           Required for production deployment"
            echo "  CONFIRM_PRODUCTION_ROLLBACK=true    Required for production rollback"
            echo "  CI_PRODUCTION_SAFE_MODE=false       Disable safety checks"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"