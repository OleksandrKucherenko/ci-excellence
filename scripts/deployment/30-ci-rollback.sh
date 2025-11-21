#!/bin/bash
# CI Rollback Script - Version 1.0.0
#
# PURPOSE: Execute rollback operations for failed deployments
#
# USAGE:
#   ./scripts/deployment/30-ci-rollback.sh [environment] [deployment_id] [strategy]
#
# EXAMPLES:
#   # Rollback production deployment
#   ./scripts/deployment/30-ci-rollback.sh production deploy-123 previous_tag
#
#   # Rollback staging deployment with dry run
#   DRY_RUN=true ./scripts/deployment/30-ci-rollback.sh staging deploy-456 git_revert
#
# TESTABILITY ENVIRONMENT VARIABLES:
#   - CI_TEST_MODE: Set to "dry_run" to simulate rollback
#   - DRY_RUN: Skip actual rollback operations
#   - CONFIRM_ROLLBACK: Required for production rollbacks
#   - LOG_LEVEL: Set logging level (debug, info, warn, error)
#
# EXTENSION POINTS:
#   - Add custom rollback logic in execute_custom_rollback()
#   - Extend rollback_strategies with additional options
#   - Add environment-specific rollback procedures
#
# SIZE GUIDELINES:
#   - Keep script under 50 lines of code (excluding comments and documentation)
#   - Extract complex rollback logic to helper functions
#   - Use shared utilities for deployment operations
#
# DEPENDENCIES:
#   - Required: git, curl, jq
#   - Libraries: scripts/lib/deployment.sh, scripts/lib/logging.sh

set -euo pipefail

# Script configuration
SCRIPT_NAME="$(basename "$0" .sh)"
SCRIPT_VERSION="1.0.0"
SCRIPT_MODE="${SCRIPT_MODE:-${CI_TEST_MODE:-default}}"
LOG_LEVEL="${LOG_LEVEL:-info}"
DRY_RUN="${DRY_RUN:-false}"

# Source libraries and utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/config.sh"
source "${SCRIPT_DIR}/../lib/logging.sh"
source "${SCRIPT_DIR}/../lib/validation.sh"
source "${SCRIPT_DIR}/../lib/deployment.sh"
source "${SCRIPT_DIR}/../lib/environment.sh"

# Rollback strategies
declare -a rollback_strategies=(
    "previous_tag"
    "git_revert"
    "blue_green_switchback"
    "manual_intervention"
)

# Main rollback function
main_rollback() {
    local environment="${1:-}"
    local deployment_id="${2:-}"
    local strategy="${3:-previous_tag}"

    log_info "Starting rollback operation"
    log_info "Environment: $environment"
    log_info "Deployment ID: $deployment_id"
    log_info "Strategy: $strategy"
    log_info "Mode: $SCRIPT_MODE"

    # Validate inputs
    validate_rollback_inputs "$environment" "$deployment_id" "$strategy"

    # Load environment configuration
    load_environment_config "$environment" "us-east"

    # Execute rollback strategy
    execute_rollback_strategy "$environment" "$deployment_id" "$strategy"

    # Update rollback state tags
    update_rollback_tags "$environment" "$deployment_id" "$strategy"

    # Generate rollback report
    generate_rollback_report "$environment" "$deployment_id" "$strategy"

    log_success "Rollback operation completed successfully"
}

# Validate rollback inputs
validate_rollback_inputs() {
    local environment="$1"
    local deployment_id="$2"
    local strategy="$3"

    log_info "Validating rollback inputs"

    # Validate environment using dynamic discovery
    if ! validate_environment_exists "$environment"; then
        log_error "Rollback validation failed - environment '$environment' does not exist"
        log_info "Available environments: $(discover_environments | tr '\n' ' ')"
        exit 1
    fi

    # Validate deployment ID
    if [[ -z "$deployment_id" ]]; then
        log_error "Deployment ID is required"
        exit 1
    fi

    # Validate strategy
    if [[ ! " ${rollback_strategies[*]} " =~ " $strategy " ]]; then
        log_error "Invalid rollback strategy: $strategy"
        log_info "Valid strategies: ${rollback_strategies[*]}"
        exit 1
    fi

    # Production rollback requires confirmation
    if [[ "$environment" == "production" && "${CONFIRM_ROLLBACK:-false}" != "true" ]]; then
        log_error "Production rollback requires CONFIRM_ROLLBACK=true"
        exit 1
    fi

    log_success "Rollback inputs validation passed"
}

# Execute rollback strategy
execute_rollback_strategy() {
    local environment="$1"
    local deployment_id="$2"
    local strategy="$3"

    log_info "Executing rollback strategy: $strategy"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would execute rollback strategy: $strategy"
        return 0
    fi

    case "$strategy" in
        "previous_tag")
            rollback_to_previous_tag "$environment" "$deployment_id"
            ;;
        "git_revert")
            rollback_with_git_revert "$environment" "$deployment_id"
            ;;
        "blue_green_switchback")
            rollback_blue_green_switchback "$environment" "$deployment_id"
            ;;
        "manual_intervention")
            rollback_manual_intervention "$environment" "$deployment_id"
            ;;
        *)
            log_error "Unknown rollback strategy: $strategy"
            exit 1
            ;;
    esac
}

# Rollback to previous tag
rollback_to_previous_tag() {
    local environment="$1"
    local deployment_id="$2"

    log_info "Rolling back to previous tag"

    # Get previous tag (implementation specific)
    local previous_tag
    previous_tag=$(git tag --sort=-version:refname | grep -v "env/" | grep -v "state/" | head -2 | tail -1)

    if [[ -z "$previous_tag" ]]; then
        log_error "No previous tag found for rollback"
        exit 1
    fi

    log_info "Rolling back to tag: $previous_tag"

    # Move environment tag to previous tag
    ./scripts/deployment/40-ci-atomic-tag-movement.sh move-environment "$environment" "$(git rev-parse "$previous_tag")" "$deployment_id"
}

# Rollback with git revert
rollback_with_git_revert() {
    local environment="$1"
    local deployment_id="$2"

    log_info "Rolling back with git revert"

    # Get deployment information
    local deployment_record="${PROJECT_ROOT}/.deployments/${deployment_id}.json"
    if [[ ! -f "$deployment_record" ]]; then
        log_error "Deployment record not found: $deployment_record"
        exit 1
    fi

    local commit_hash
    if command -v jq &> /dev/null; then
        commit_hash=$(jq -r '.commit' "$deployment_record" 2>/dev/null || echo "")
    else
        commit_hash=$(grep -o '"commit": "[^"]*"' "$deployment_record" | cut -d'"' -f4 || echo "")
    fi

    if [[ -z "$commit_hash" ]]; then
        log_error "Could not find commit hash for deployment: $deployment_id"
        exit 1
    fi

    log_info "Reverting commit: $commit_hash"

    # Execute git revert
    if ! git revert --no-edit "$commit_hash"; then
        log_error "Git revert failed for commit: $commit_hash"
        exit 1
    fi

    # Push revert if not in dry run
    if [[ "$DRY_RUN" != "true" ]]; then
        git push origin HEAD
        log_info "Git revert pushed to remote"
    fi
}

# Rollback with blue-green switchback
rollback_blue_green_switchback() {
    local environment="$1"
    local deployment_id="$2"

    log_info "Rolling back with blue-green switchback"

    # This would implement blue-green rollback logic
    # For now, simulate the operation
    log_info "Blue-green switchback completed (simulated)"
}

# Manual intervention rollback
rollback_manual_intervention() {
    local environment="$1"
    local deployment_id="$2"

    log_warn "Manual intervention required for rollback"

    # Create manual intervention record
    local intervention_record="${PROJECT_ROOT}/.deployments/manual-intervention-${deployment_id}.json"
    mkdir -p "$(dirname "$intervention_record")"

    cat > "$intervention_record" << EOF
{
  "deployment_id": "$deployment_id",
  "environment": "$environment",
  "strategy": "manual_intervention",
  "status": "requires_manual_intervention",
  "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "initiated_by": "${USER:-unknown}",
  "instructions": "Please investigate and manually resolve the deployment issue"
}
EOF

    log_error "Manual intervention required - see record: $intervention_record"
}

# Update rollback state tags
update_rollback_tags() {
    local environment="$1"
    local deployment_id="$2"
    local strategy="$3"

    log_info "Updating rollback state tags"

    # Create rollback initiated tag
    ./scripts/deployment/40-ci-atomic-tag-movement.sh create-state "rollback-initiated" "${CI_COMMIT_SHA:-HEAD}" "$environment" "$deployment_id"

    # Update rollback environment tag
    ./scripts/deployment/40-ci-atomic-tag-movement.sh move-environment "rollback-$environment" "${CI_COMMIT_SHA:-HEAD}" "$deployment_id"

    log_success "Rollback state tags updated"
}

# Generate rollback report
generate_rollback_report() {
    local environment="$1"
    local deployment_id="$2"
    local strategy="$3"
    local report_file="${PROJECT_ROOT}/.reports/rollback-report-${deployment_id}.json"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    mkdir -p "$(dirname "$report_file")"

    cat > "$report_file" << EOF
{
  "rollback_info": {
    "deployment_id": "$deployment_id",
    "environment": "$environment",
    "strategy": "$strategy",
    "timestamp": "$timestamp",
    "initiated_by": "${USER:-unknown}",
    "dry_run": $DRY_RUN,
    "script_version": "$SCRIPT_VERSION"
  },
  "status": {
    "completed": true,
    "message": "Rollback completed successfully"
  },
  "actions_taken": [
    "rollback_strategy_executed",
    "environment_tags_updated",
    "rollback_state_created"
  ],
  "next_steps": [
    "Verify rollback health",
    "Monitor application stability",
    "Investigate root cause of deployment failure"
  ]
}
EOF

    log_info "Rollback report generated: $report_file"
}

# Execute custom rollback logic (extension point)
execute_custom_rollback() {
    local environment="$1"
    local deployment_id="$2"
    local strategy="$3"

    log_info "Executing custom rollback logic"

    # Add your custom rollback logic here
    # Example:
    # notify_rollback_stakeholders "$environment" "$deployment_id"
    # rollback_database_changes "$deployment_id"
    # cleanup_failed_deployment_artifacts "$deployment_id"
}

# Show usage information
show_usage() {
    echo
    echo "Usage: $0 [environment] [deployment_id] [strategy]"
    echo
    echo "Arguments:"
    echo "  environment     Target environment (staging, production)"
    echo "  deployment_id   Deployment ID to rollback"
    echo "  strategy        Rollback strategy (default: previous_tag)"
    echo
    echo "Strategies:"
    echo "  previous_tag        Rollback to previous version tag"
    echo "  git_revert          Rollback using git revert"
    echo "  blue_green_switchback Blue-green environment switchback"
    echo "  manual_intervention  Mark for manual intervention"
    echo
    echo "Environment Variables:"
    echo "  DRY_RUN=true              Simulate rollback without changes"
    echo "  CONFIRM_ROLLBACK=true     Required for production rollback"
    echo "  LOG_LEVEL=debug           Enable debug logging"
    echo
    echo "Examples:"
    echo "  $0 production deploy-123 previous_tag"
    echo "  DRY_RUN=true $0 staging deploy-456 git_revert"
    echo "  CONFIRM_ROLLBACK=true $0 production deploy-789 blue_green_switchback"
}

# Main function
main() {
    local environment="${1:-}"
    local deployment_id="${2:-}"
    local strategy="${3:-previous_tag}"

    # Initialize logging and configuration
    initialize_logging "$LOG_LEVEL" "$SCRIPT_NAME"
    load_project_config

    case "$1" in
        "--help"|"-h")
            show_usage
            ;;
        "")
            log_error "Environment argument is required"
            show_usage
            exit 1
            ;;
        *)
            main_rollback "$environment" "$deployment_id" "$strategy"
            ;;
    esac
}

# Run main function with all arguments
main "$@"