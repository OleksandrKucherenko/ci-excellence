#!/bin/bash
# T101: Staging deployment script with environment config loading and SOPS decryption

set -euo pipefail

# Script configuration
SCRIPT_NAME="$(basename "$0" .sh)"
SCRIPT_VERSION="1.0.0"
SCRIPT_MODE="${CI_DEPLOY_STAGING_MODE:-${CI_TEST_MODE:-default}}"
DEFAULT_REGION="us-east"
ENVIRONMENT="staging"
LOG_LEVEL="${CI_LOG_LEVEL:-info}"

# Source libraries and utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/config.sh"
source "${SCRIPT_DIR}/../lib/logging.sh"
source "${SCRIPT_DIR}/../lib/environment.sh"
source "${SCRIPT_DIR}/../lib/validation.sh"
source "${SCRIPT_DIR}/../lib/deployment.sh"

# Staging deployment configuration
declare -A DEPLOYMENT_CONFIG=(
    ["environment"]="staging"
    ["max_concurrent_deployments"]=1
    ["health_check_timeout"]=300
    ["require_approval"]=false
    ["allow_skip_tests"]=false
    ["rollback_on_failure"]=true
    ["create_backup"]=false
    ["deploy_regions"]="us-east,eu-west"
    ["default_region"]="us-east"
)

# Health check endpoints for staging
declare -a HEALTH_CHECK_ENDPOINTS=(
    "/health"
    "/api/health"
    "/metrics"
)

# Rollback strategies for staging
declare -a ROLLBACK_STRATEGIES=(
    "git_revert"
    "previous_tag"
    "manual_intervention"
)

# Security configurations for staging
declare -A SECURITY_CONFIG=(
    ["scan_secrets"]=true
    ["scan_dependencies"]=true
    ["scan_infrastructure"]=false
    ["require_security_approval"]=false
    ["allow_risk_acceptance"]=true
)

# Features available in staging
declare -a STAGING_FEATURES=(
    "feature_flags"
    "a_b_testing"
    "canary_deployments"
    "blue_green"
    "rolling_update"
)

# Function to load staging environment configuration
load_staging_config() {
    local config_file="${PROJECT_ROOT}/environments/staging/config.yml"
    local region="${1:-$DEFAULT_REGION}"

    log_info "Loading staging environment configuration"

    if [[ ! -f "$config_file" ]]; then
        log_error "Staging configuration file not found: $config_file"
        return 1
    fi

    # Parse YAML configuration using yq if available, otherwise fall back to grep
    if command -v yq &> /dev/null; then
        log_debug "Parsing YAML configuration with yq"

        # Extract environment variables from config
        local env_vars
        env_vars=$(yq eval '.environment_variables | to_entries | .[] | "\(.key)=\(.value)"' "$config_file" 2>/dev/null || true)

        # Export extracted environment variables
        while IFS='=' read -r key value; do
            if [[ -n "$key" && -n "$value" ]]; then
                export "$key"="$value"
                log_debug "Exported $key from staging config"
            fi
        done <<< "$env_vars"

    else
        log_warn "yq not available, using basic config parsing"
        # Fallback to basic environment variable loading
        export AWS_REGION="us-east-1"
        export DEPLOYMENT_ENVIRONMENT="staging"
    fi

    # Load region-specific configuration if it exists
    local region_config="${PROJECT_ROOT}/environments/staging/regions/${region}/config.yml"
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

    # Export staging-specific variables
    export DEPLOYMENT_ENVIRONMENT="staging"
    export DEPLOYMENT_REGION="$region"
    export CI_DEPLOYMENT_TARGET="staging"

    log_success "Staging configuration loaded successfully"
}

# Function to validate staging deployment prerequisites
validate_staging_prerequisites() {
    log_info "Validating staging deployment prerequisites"

    # Check if we're on the correct branch
    local current_branch
    current_branch=$(git branch --show-current)

    case "$current_branch" in
        main|master|develop|staging|feature/*|hotfix/*)
            log_debug "Branch $current_branch is acceptable for staging deployment"
            ;;
        *)
            log_warn "Branch $current_branch may not be suitable for staging deployment"
            if [[ "${FORCE_DEPLOY:-false}" != "true" ]]; then
                log_error "Use FORCE_DEPLOY=true to deploy from this branch"
                return 1
            fi
            ;;
    esac

    # Validate required environment variables
    local required_vars=(
        "AWS_REGION"
        "DEPLOYMENT_ENVIRONMENT"
        "CI_COMMIT_SHA"
    )

    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            log_error "Required environment variable $var is not set"
            return 1
        fi
    done

    # Check for staging-specific requirements
    if [[ "${SKIP_TESTS:-false}" != "true" ]]; then
        log_info "Validating test requirements for staging"

        # Check if tests have been run recently (within last 24 hours)
        local last_test_file="${PROJECT_ROOT}/.last_staging_test"
        if [[ -f "$last_test_file" ]]; then
            local last_test_time
            last_test_time=$(stat -c %Y "$last_test_file" 2>/dev/null || stat -f %m "$last_test_file" 2>/dev/null || echo 0)
            local current_time
            current_time=$(date +%s)
            local diff_hours=$(( (current_time - last_test_time) / 3600 ))

            if [[ $diff_hours -gt 24 ]]; then
                log_warn "Tests haven't been run in ${diff_hours} hours"
                if [[ "${FORCE_DEPLOY:-false}" != "true" ]]; then
                    log_error "Run tests first or use FORCE_DEPLOY=true"
                    return 1
                fi
            fi
        else
            log_warn "No recent test record found"
            if [[ "${FORCE_DEPLOY:-false}" != "true" ]]; then
                log_error "Run tests first or use FORCE_DEPLOY=true"
                return 1
            fi
        fi
    fi

    # Validate deployment configuration
    validate_deployment_config DEPLOYMENT_CONFIG || return 1

    log_success "Staging prerequisites validation passed"
}

# Function to deploy to staging environment
deploy_to_staging() {
    local target_region="${1:-$DEFAULT_REGION}"
    local deployment_id="${2:-$(generate_deployment_id)}"

    log_info "Starting staging deployment to ${target_region} region"
    log_info "Deployment ID: $deployment_id"

    # Load staging configuration
    load_staging_config "$target_region"

    # Validate prerequisites
    validate_staging_prerequisites

    # Create deployment record
    create_deployment_record "$deployment_id" "$ENVIRONMENT" "$target_region" "$CI_COMMIT_SHA"

    # Set deployment status
    set_deployment_status "$deployment_id" "in_progress" "Deploying to staging"

    trap 'handle_deployment_failure "$deployment_id" "$ENVIRONMENT" "$target_region"' ERR

    # Pre-deployment checks
    log_info "Running pre-deployment checks for staging"
    run_pre_deployment_checks "$deployment_id" "$ENVIRONMENT" "$target_region"

    # Security scanning (lighter for staging)
    if [[ "${SECURITY_CONFIG[scan_secrets]}" == "true" ]]; then
        log_info "Running security scanning for staging"
        run_security_scans "staging" "medium" "all"
    fi

    # Run tests if not skipped
    if [[ "${SKIP_TESTS:-false}" != "true" ]]; then
        log_info "Running tests for staging deployment"
        run_deployment_tests "staging"

        # Update test timestamp
        touch "${PROJECT_ROOT}/.last_staging_test"
    fi

    # Build application for staging
    log_info "Building application for staging"
    build_application_for_environment "staging" "$target_region"

    # Deploy infrastructure (if needed)
    log_info "Deploying infrastructure for staging"
    deploy_infrastructure_for_environment "staging" "$target_region"

    # Deploy application
    log_info "Deploying application to staging"
    deploy_application_to_environment "staging" "$target_region"

    # Run health checks
    log_info "Running health checks on staging deployment"
    run_deployment_health_checks "$ENVIRONMENT" "$target_region" "${HEALTH_CHECK_ENDPOINTS[@]}"

    # Run smoke tests
    log_info "Running smoke tests on staging"
    run_smoke_tests "$ENVIRONMENT" "$target_region"

    # Set deployment status to success
    set_deployment_status "$deployment_id" "success" "Staging deployment completed successfully"

    # Generate deployment report
    generate_deployment_report "$deployment_id" "$ENVIRONMENT" "$target_region" "success"

    log_success "Staging deployment completed successfully"

    # Display staging-specific information
    echo
    log_info "Staging Environment Information:"
    echo "  - Region: $target_region"
    echo "  - Environment: staging"
    echo "  - Deployment ID: $deployment_id"
    echo "  - Commit: $CI_COMMIT_SHA"
    echo "  - Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    echo
    log_info "Staging URLs (if applicable):"
    echo "  - Web: https://staging-${target_region}.example.com"
    echo "  - API: https://api-staging-${target_region}.example.com"
    echo
    log_info "Use './scripts/deployment/30-ci-promote-to-production.sh' to promote to production"
}

# Function to show staging deployment status
show_staging_status() {
    local region="${1:-$DEFAULT_REGION}"

    log_info "Getting staging deployment status for ${region} region"

    # Load staging config to get endpoints
    load_staging_config "$region"

    echo
    log_info "Staging Deployment Status:"
    echo "  - Environment: staging"
    echo "  - Region: $region"
    echo "  - AWS Region: ${AWS_REGION:-not set}"
    echo "  - Deployment Target: ${CI_DEPLOYMENT_TARGET:-not set}"
    echo

    if command -v aws &> /dev/null && [[ -n "${AWS_REGION:-}" ]]; then
        log_info "Checking AWS resources in staging..."

        # Check ECS services
        local cluster_name="staging-${region}"
        if aws ecs describe-clusters --clusters "$cluster_name" &> /dev/null; then
            echo "  - ECS Cluster: $cluster_name (active)"

            # List services
            local services
            services=$(aws ecs list-services --cluster "$cluster_name" --query 'serviceArns[*]' --output text 2>/dev/null | tr '\t' '\n' || true)
            if [[ -n "$services" ]]; then
                echo "  - Services:"
                while IFS= read -r service; do
                    if [[ -n "$service" ]]; then
                        local service_name
                        service_name=$(basename "$service")
                        echo "    - $service_name"
                    fi
                done <<< "$services"
            fi
        else
            echo "  - ECS Cluster: $cluster_name (not found)"
        fi

        # Check S3 buckets
        local bucket_prefix="staging-${region}"
        echo "  - S3 Buckets:"
        aws s3 ls | grep "$bucket_prefix" | sed 's/^/    - /' || echo "    - None found"
    fi

    echo
    log_info "Recent Deployments:"
    list_recent_deployments "staging" 5 || echo "  - No recent deployments found"
}

# Function to rollback staging deployment
rollback_staging() {
    local deployment_id="$1"
    local strategy="${2:-git_revert}"

    log_info "Rolling back staging deployment: $deployment_id"

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

    # Set rollback status
    set_deployment_status "$deployment_id" "rolling_back" "Rolling back staging deployment"

    trap 'log_error "Rollback failed for deployment $deployment_id"' ERR

    case "$strategy" in
        "git_revert")
            log_info "Rolling back using git revert"
            rollback_deployment_git_revert "$deployment_id"
            ;;
        "previous_tag")
            log_info "Rolling back to previous tag"
            rollback_deployment_previous_tag "$deployment_id"
            ;;
        "manual_intervention")
            log_info "Marking for manual intervention"
            set_deployment_status "$deployment_id" "manual_intervention" "Manual intervention required"
            log_info "Please investigate and resolve manually"
            return 0
            ;;
    esac

    # Update deployment status
    set_deployment_status "$deployment_id" "rolled_back" "Staging deployment rolled back successfully"

    log_success "Staging rollback completed"
}

# Main function
main() {
    local command="${1:-deploy}"
    local region="${2:-$DEFAULT_REGION}"
    local deployment_id="${3:-}"

    # Initialize logging and configuration
    initialize_logging "$LOG_LEVEL" "ci-deploy-staging"
    load_project_config

    case "$command" in
        "deploy")
            log_info "Starting staging deployment"
            deploy_to_staging "$region" "$deployment_id"
            ;;
        "status")
            show_staging_status "$region"
            ;;
        "rollback")
            if [[ -z "$deployment_id" ]]; then
                log_error "Deployment ID is required for rollback"
                echo "Usage: $0 rollback <deployment_id> [strategy]"
                exit 1
            fi
            local strategy="${4:-git_revert}"
            rollback_staging "$deployment_id" "$strategy"
            ;;
        "validate")
            log_info "Validating staging deployment prerequisites"
            load_staging_config "$region"
            validate_staging_prerequisites
            ;;
        "config")
            log_info "Showing staging configuration"
            load_staging_config "$region"
            show_environment_config "staging" "$region"
            ;;
        *)
            log_error "Unknown command: $command"
            echo
            echo "Usage: $0 [command] [region] [deployment_id] [strategy]"
            echo
            echo "Commands:"
            echo "  deploy    Deploy to staging (default)"
            echo "  status    Show staging deployment status"
            echo "  rollback  Rollback staging deployment"
            echo "  validate  Validate staging deployment prerequisites"
            echo "  config    Show staging configuration"
            echo
            echo "Regions: us-east, eu-west"
            echo "Strategies: git_revert, previous_tag, manual_intervention"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"