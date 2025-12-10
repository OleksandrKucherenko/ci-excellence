#!/bin/bash
# CI Deployment Summary Generator - Version 1.0.0
#
# PURPOSE: Generate deployment pipeline summaries with status and action links
#
# USAGE:
#   ./scripts/ci/reporting/25-ci-generate-deployment-summary.sh
#
# EXAMPLES:
#   # Generate summary with deployment results
#   ./scripts/ci/reporting/25-ci-generate-deployment-summary.sh
#
#   # With specific deployment info
#   DEPLOYMENT_ID="deploy-123" ENVIRONMENT="production" ./scripts/ci/reporting/25-ci-generate-deployment-summary.sh
#
# TESTABILITY ENVIRONMENT VARIABLES:
#   - CI_TEST_MODE: Set to "dry_run" to simulate report generation
#   - ENABLE_ACTION_LINKS: Enable/disable action links (default: true)
#
# EXTENSION POINTS:
#   - Add custom deployment metrics in generate_deployment_metrics()
#   - Extend action links in generate_deployment_actions()
#   - Customize formatting in format_deployment_summary()
#
# SIZE GUIDELINES:
#   - Keep script under 50 lines (excluding comments and documentation)
#   - Extract complex logic to helper functions
#   - Use templates for different deployment types
#
# DEPENDENCIES:
#   - Required: bash
#   - Optional: jq (for JSON formatting)

set -euo pipefail

# Script configuration
SCRIPT_NAME="$(basename "$0" .sh)"
SCRIPT_VERSION="1.0.0"
SCRIPT_MODE="${SCRIPT_MODE:-${CI_TEST_MODE:-default}}"

# Source libraries and utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/config.sh"
source "${SCRIPT_DIR}/../../lib/logging.sh"

# Deployment information
DEPLOYMENT_ID="${DEPLOYMENT_ID:-}"
ENVIRONMENT="${ENVIRONMENT:-unknown}"
SUBPROJECT="${SUBPROJECT:-root}"
DEPLOYMENT_STRATEGY="${DEPLOYMENT_STRATEGY:-rolling}"
COMMIT_SHA="${COMMIT_SHA:-unknown}"

# Pipeline results
VALIDATE_RESULT="${VALIDATE_RESULT:-unknown}"
PRE_DEPLOY_RESULT="${PRE_DEPLOY_RESULT:-unknown}"
DEPLOY_RESULT="${DEPLOY_RESULT:-unknown}"
POST_DEPLOY_RESULT="${POST_DEPLOY_RESULT:-unknown}"

# GitHub context
GITHUB_SERVER_URL="${GITHUB_SERVER_URL:-https://github.com}"
GITHUB_REPOSITORY="${GITHUB_REPOSITORY:-}"
GITHUB_RUN_ID="${GITHUB_RUN_ID:-}"
GITHUB_ACTOR="${GITHUB_ACTOR:-}"

# Report configuration
ENABLE_ACTION_LINKS="${ENABLE_ACTION_LINKS:-true}"

# Main deployment summary function
generate_deployment_summary() {
    log_info "Generating deployment pipeline summary"

    # Create summary file
    local summary_file="deployment-$DEPLOYMENT_ID-summary.txt"
    create_deployment_summary "$summary_file"

    # Output to GitHub Actions
    output_deployment_summary "$summary_file"

    # Save as artifact
    save_deployment_artifact "$summary_file"

    log_success "✅ Deployment summary generated successfully"
}

# Create deployment summary
create_deployment_summary() {
    local summary_file="$1"
    local overall_status
    local emoji

    # Determine overall status
    overall_status=$(get_overall_status)
    emoji=$(get_status_emoji "$overall_status")

    # Generate summary content
    cat > "$summary_file" << EOF
$emoji Deployment Summary

**Deployment ID**: $DEPLOYMENT_ID
**Environment**: $ENVIRONMENT
**Subproject**: $SUBPROJECT
**Strategy**: $DEPLOYMENT_STRATEGY
**Status**: $overall_status
**Commit**: $COMMIT_SHA
**Timestamp**: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

**Results**:
- Validation: $VALIDATE_RESULT
- Pre-deployment: $PRE_DEPLOY_RESULT
- Deployment: $DEPLOY_RESULT
- Post-deployment: $POST_DEPLOY_RESULT

**Actions**:
EOF

    # Add action links
    if [[ "$ENABLE_ACTION_LINKS" == "true" ]]; then
        add_deployment_actions "$summary_file" "$overall_status"
    fi

    # Add execution info
    cat >> "$summary_file" << EOF
**Deployment executed by**: @$GITHUB_ACTOR
EOF
}

# Get overall deployment status
get_overall_status() {
    local failed_jobs=0

    # Check each job result
    [[ "$VALIDATE_RESULT" != "success" ]] && ((failed_jobs++))
    [[ "$PRE_DEPLOY_RESULT" != "success" ]] && ((failed_jobs++))
    [[ "$DEPLOY_RESULT" != "success" ]] && ((failed_jobs++))
    [[ "$POST_DEPLOY_RESULT" != "success" ]] && ((failed_jobs++))

    if [[ $failed_jobs -eq 0 ]]; then
        echo "success"
    else
        echo "failure"
    fi
}

# Get status emoji
get_status_emoji() {
    local status="$1"
    case "$status" in
        "success") echo "✅" ;;
        "failure") echo "❌" ;;
        *) echo "❓" ;;
    esac
}

# Add deployment actions
add_deployment_actions() {
    local summary_file="$1"
    local status="$2"

    # Always show workflow link
    echo "- [View Workflow]($GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID)" >> "$summary_file"

    if [[ "$status" == "success" ]]; then
        # Success actions
        if [[ -n "${ENVIRONMENT_URL:-}" ]]; then
            echo "- [View Deployment]($ENVIRONMENT_URL)" >> "$summary_file"
        fi
    else
        # Failure actions
        if [[ -n "${ROLLBACK_TAG:-}" ]]; then
            echo "- [Rollback Available](https://github.com/$GITHUB_REPOSITORY/releases/tag/$ROLLBACK_TAG)" >> "$summary_file"
        fi
    fi

    # Management actions
    echo "- [View Deployment Details]($GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID)" >> "$summary_file"
}

# Output deployment summary to GitHub Actions
output_deployment_summary() {
    local summary_file="$1"

    # Convert to GitHub Actions markdown format
    local markdown_file="${summary_file%.txt}.md"

    # Convert text summary to markdown
    sed 's/\*\*\([^*]*\)\*\*/\*\*\1\*\*/g' "$summary_file" > "$markdown_file"
    sed 's/^-\s*\[\([^]]*\)\](\([^)]*\))/- [\1](\2)/g' "$markdown_file" >> "$markdown_file"

    # Output to GitHub Actions
    cat "$markdown_file" >> "$GITHUB_STEP_SUMMARY"
    log_info "Deployment summary output to GitHub Actions"
}

# Save deployment summary as artifact
save_deployment_artifact() {
    local summary_file="$1"

    mkdir -p deployment-summaries
    cp "$summary_file" "deployment-summaries/"
    log_info "Deployment summary saved as artifact"
}

# Custom deployment metrics extension point
generate_deployment_metrics() {
    # Override this function to add custom deployment metrics
    log_debug "Custom deployment metrics (no additional metrics defined)"
}

# Custom deployment actions extension point
generate_deployment_actions() {
    # Override this function to add custom deployment actions
    log_debug "Custom deployment actions (no additional actions defined)"
}

# Main function
main() {
    log_info "$SCRIPT_NAME v$SCRIPT_VERSION - Deployment Summary Generator"

    # Initialize project configuration
    load_project_config

    # Generate deployment summary
    generate_deployment_summary

    # Run custom extensions if defined
    if command -v generate_deployment_metrics >/dev/null 2>&1; then
        generate_deployment_metrics
    fi

    if command -v generate_deployment_actions >/dev/null 2>&1; then
        generate_deployment_actions
    fi

    log_success "✅ Deployment summary generation completed"
}

# Run main function with all arguments
main "$@"