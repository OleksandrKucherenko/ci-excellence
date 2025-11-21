#!/bin/bash
# CI Deployment Parameter Validation Script - Version 1.0.0
#
# PURPOSE: Validate and process deployment parameters from GitHub Actions triggers
#
# USAGE:
#   ./scripts/ci/deployment/15-ci-validate-deployment-params.sh
#
# EXAMPLES:
#   # Manual validation (workflow_dispatch)
#   ./scripts/ci/deployment/15-ci-validate-deployment-params.sh
#
#   # With trigger context
#   INPUT_TAG_NAME="v1.2.3" INPUT_ENVIRONMENT="production" ./scripts/ci/deployment/15-ci-validate-deployment-params.sh
#
# TESTABILITY ENVIRONMENT VARIABLES:
#   - CI_TEST_MODE: Set to "dry_run" to simulate validation
#   - TAG_NAME: Override tag name for testing
#   - ENVIRONMENT: Override environment for testing
#
# EXTENSION POINTS:
#   - Add custom parameter validation in validate_custom_parameters()
#   - Extend environment validation in validate_environment()
#   - Add additional output parameters in output_deployment_info()
#
# SIZE GUIDELINES:
#   - Keep script under 50 lines (excluding comments and documentation)
#   - Extract complex validation logic to helper functions
#   - Use shared utilities for common operations
#
# DEPENDENCIES:
#   - Required: bash, git
#   - Optional: jq (for JSON output)

set -euo pipefail

# Script configuration
SCRIPT_NAME="$(basename "$0" .sh)"
SCRIPT_VERSION="1.0.0"
SCRIPT_MODE="${SCRIPT_MODE:-${CI_TEST_MODE:-default}}"

# Source libraries and utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/config.sh"
source "${SCRIPT_DIR}/../../lib/logging.sh"
source "${SCRIPT_DIR}/../../lib/validation.sh"

# Input parameters (from GitHub Actions)
INPUT_TAG_NAME="${INPUT_TAG_NAME:-}"
INPUT_ENVIRONMENT="${INPUT_ENVIRONMENT:-}"
INPUT_SUBPROJECT="${INPUT_SUBPROJECT:-}"
INPUT_COMMIT_SHA="${INPUT_COMMIT_SHA:-}"
INPUT_DEPLOYMENT_STRATEGY="${INPUT_DEPLOYMENT_STRATEGY:-rolling}"
INPUT_ROLLBACK_ENABLED="${INPUT_ROLLBACK_ENABLED:-true}"

# Workflow run context (from automated triggers)
WORKFLOW_RUN_TAG_NAME="${WORKFLOW_RUN_TAG_NAME:-}"
WORKFLOW_RUN_ENVIRONMENT="${WORKFLOW_RUN_ENVIRONMENT:-}"
WORKFLOW_RUN_SUBPROJECT="${WORKFLOW_RUN_SUBPROJECT:-}"
WORKFLOW_RUN_COMMIT_SHA="${WORKFLOW_RUN_COMMIT_SHA:-}"

# Main validation function
validate_deployment_parameters() {
    log_info "Validating deployment parameters"

    # Handle different trigger contexts
    if [[ -n "${WORKFLOW_RUN_TAG_NAME}" ]]; then
        TAG_NAME="${WORKFLOW_RUN_TAG_NAME}"
        ENVIRONMENT="${WORKFLOW_RUN_ENVIRONMENT}"
        SUBPROJECT="${WORKFLOW_RUN_SUBPROJECT}"
        COMMIT_SHA="${WORKFLOW_RUN_COMMIT_SHA}"
        log_info "Using workflow_run trigger context"
    else
        TAG_NAME="${INPUT_TAG_NAME}"
        ENVIRONMENT="${INPUT_ENVIRONMENT}"
        SUBPROJECT="${INPUT_SUBPROJECT}"
        COMMIT_SHA="${INPUT_COMMIT_SHA}"
        log_info "Using workflow_dispatch trigger context"
    fi

    # Set defaults for empty values
    TAG_NAME="${TAG_NAME:-}"
    ENVIRONMENT="${ENVIRONMENT:-staging}"
    SUBPROJECT="${SUBPROJECT:-root}"
    COMMIT_SHA="${COMMIT_SHA:-}"

    # Core validation
    validate_tag_name
    validate_environment
    validate_deployment_strategy
    validate_commit_sha
    validate_rollback_settings

    log_success "✅ All deployment parameters validated"
}

# Validate tag name
validate_tag_name() {
    if [[ -z "$TAG_NAME" ]]; then
        log_error "❌ Tag name is required"
        exit 1
    fi

    if [[ "$SCRIPT_MODE" == "dry_run" ]]; then
        log_info "[DRY RUN] Would validate tag: $TAG_NAME"
        return 0
    fi

    if ! git show-ref --verify --quiet "refs/tags/$TAG_NAME" 2>/dev/null; then
        log_error "❌ Tag '$TAG_NAME' does not exist"
        exit 1
    fi

    log_info "✅ Tag '$TAG_NAME' validated"
}

# Validate environment
validate_environment() {
    local valid_environments=("staging" "production" "development" "testing" "uat")
    local is_valid=false

    for env in "${valid_environments[@]}"; do
        if [[ "$ENVIRONMENT" == "$env" ]]; then
            is_valid=true
            break
        fi
    done

    if [[ "$is_valid" != "true" ]]; then
        log_error "❌ Invalid environment: $ENVIRONMENT"
        log_error "Valid environments: ${valid_environments[*]}"
        exit 1
    fi

    log_info "✅ Environment '$ENVIRONMENT' validated"
}

# Validate deployment strategy
validate_deployment_strategy() {
    local valid_strategies=("rolling" "blue-green" "canary")
    local is_valid=false

    for strategy in "${valid_strategies[@]}"; do
        if [[ "$INPUT_DEPLOYMENT_STRATEGY" == "$strategy" ]]; then
            is_valid=true
            break
        fi
    done

    if [[ "$is_valid" != "true" ]]; then
        log_error "❌ Invalid deployment strategy: $INPUT_DEPLOYMENT_STRATEGY"
        log_error "Valid strategies: ${valid_strategies[*]}"
        exit 1
    fi

    log_info "✅ Deployment strategy '$INPUT_DEPLOYMENT_STRATEGY' validated"
}

# Validate commit SHA
validate_commit_sha() {
    if [[ -n "$COMMIT_SHA" ]]; then
        if [[ "$SCRIPT_MODE" != "dry_run" ]] && ! git rev-parse --verify "$COMMIT_SHA" >/dev/null 2>&1; then
            log_error "❌ Invalid commit SHA: $COMMIT_SHA"
            exit 1
        fi
        log_info "✅ Commit SHA '$COMMIT_SHA' validated"
    else
        # Get commit SHA from tag if not provided
        if [[ "$SCRIPT_MODE" != "dry_run" ]]; then
            COMMIT_SHA=$(git rev-list -n 1 "$TAG_NAME")
            log_info "✅ Commit SHA from tag: $COMMIT_SHA"
        fi
    fi
}

# Validate rollback settings
validate_rollback_settings() {
    if [[ "$INPUT_ROLLBACK_ENABLED" != "true" && "$INPUT_ROLLBACK_ENABLED" != "false" ]]; then
        log_error "❌ Invalid rollback enabled setting: $INPUT_ROLLBACK_ENABLED"
        exit 1
    fi

    log_info "✅ Rollback settings validated"
}

# Output deployment information for GitHub Actions
output_deployment_info() {
    # Generate unique deployment ID
    local deployment_id
    if [[ "$SCRIPT_MODE" == "dry_run" ]]; then
        deployment_id="deploy-dry-run-$(date +%s)"
    else
        deployment_id="deploy-$(date +%s)-$(git rev-parse --short=7 HEAD)"
    fi

    # Output to GitHub Actions
    if [[ "$SCRIPT_MODE" == "dry_run" ]]; then
        echo "[DRY RUN] Would output deployment information to GitHub Actions"
    else
        echo "deployment_id=$deployment_id" >> "$GITHUB_OUTPUT"
        echo "tag_name=$TAG_NAME" >> "$GITHUB_OUTPUT"
        echo "environment=$ENVIRONMENT" >> "$GITHUB_OUTPUT"
        echo "subproject=$SUBPROJECT" >> "$GITHUB_OUTPUT"
        echo "commit_sha=$COMMIT_SHA" >> "$GITHUB_OUTPUT"
        echo "deployment_strategy=$INPUT_DEPLOYMENT_STRATEGY" >> "$GITHUB_OUTPUT"
        echo "should_rollback=$INPUT_ROLLBACK_ENABLED" >> "$GITHUB_OUTPUT"

        # Generate rollback tag name
        local rollback_tag="rollback-$(date +%Y%m%d-%H%M%S)-$ENVIRONMENT"
        echo "rollback_tag=$rollback_tag" >> "$GITHUB_OUTPUT"

        # Generate environment URL
        local environment_url="https://$ENVIRONMENT.example.com"
        if [[ "$SUBPROJECT" != "root" ]]; then
            environment_url="https://$SUBPROJECT-$ENVIRONMENT.example.com"
        fi
        echo "environment_url=$environment_url" >> "$GITHUB_OUTPUT"
    fi

    if [[ "$SCRIPT_MODE" == "dry_run" ]]; then
        echo "=== [DRY RUN] Deployment Information ==="
        echo "Deployment ID: $deployment_id"
        echo "Tag: $TAG_NAME"
        echo "Environment: $ENVIRONMENT"
        echo "Subproject: $SUBPROJECT"
        echo "Commit: $COMMIT_SHA"
        echo "Strategy: $INPUT_DEPLOYMENT_STRATEGY"
        echo "Rollback Enabled: $INPUT_ROLLBACK_ENABLED"
        echo "Environment URL: $environment_url"
        echo "Rollback Tag: $rollback_tag"
    else
        log_info "Deployment information generated: $deployment_id"
        log_info "Environment: $ENVIRONMENT"
        log_info "Tag: $TAG_NAME"
    fi
}

# Custom validation extension point
validate_custom_parameters() {
    # Override this function to add custom parameter validation
    log_debug "Custom parameter validation (no additional validation defined)"
}

# Main function
main() {
    log_info "$SCRIPT_NAME v$SCRIPT_VERSION - Deployment Parameter Validation"

    # Initialize project configuration
    load_project_config

    # Validate deployment parameters
    validate_deployment_parameters

    # Run custom validation if defined
    if command -v validate_custom_parameters >/dev/null 2>&1; then
        validate_custom_parameters
    fi

    # Output deployment information
    output_deployment_info

    log_success "✅ Deployment parameter validation completed successfully"
}

# Run main function with all arguments
main "$@"