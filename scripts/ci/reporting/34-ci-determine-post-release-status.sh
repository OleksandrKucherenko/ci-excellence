#!/bin/bash
# CI Post-Release Status Determination Script - Version 1.0.0
#
# PURPOSE: Determine post-release action status and generate notification messages
#
# USAGE:
#   ./scripts/ci/reporting/34-ci-determine-post-release-status.sh
#
# EXAMPLES:
#   # Determine status from job results
#   ROLLBACK_RESULT="success" ./scripts/ci/reporting/34-ci-determine-post-release-status.sh
#
#   # With verify deployment success
#   VERIFY_DEPLOYMENT_RESULT="success" ./scripts/ci/reporting/34-ci-determine-post-release-status.sh
#
# TESTABILITY ENVIRONMENT VARIABLES:
#   - CI_TEST_MODE: Set to "dry_run" to simulate status determination
#   - VERSION: Override version for testing
#
# EXTENSION POINTS:
#   - Add custom status logic in determine_custom_status()
#   - Extend status mapping in map_status_to_message()
#   - Customize message formatting in format_notification_message()
#
# SIZE GUIDELINES:
#   - Keep script under 50 lines (excluding comments and documentation)
#   - Extract complex status logic to helper functions
#   - Use shared utilities for common operations
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

# Pipeline results (from GitHub Actions)
VERIFY_DEPLOYMENT_RESULT="${VERIFY_DEPLOYMENT_RESULT:-unknown}"
TAG_STABLE_RESULT="${TAG_STABLE_RESULT:-unknown}"
TAG_UNSTABLE_RESULT="${TAG_UNSTABLE_RESULT:-unknown}"
ROLLBACK_RESULT="${ROLLBACK_RESULT:-unknown}"

# Main post-release status determination function
determine_post_release_status() {
    log_info "Determining post-release action status"

    local action_type
    local status
    local message

    # Determine which action was performed
    action_type=$(determine_action_type)

    # Map action to status and message
    status=$(determine_status_for_action "$action_type")
    message=$(generate_message_for_action "$action_type" "$status")

    # Output to GitHub Actions
    output_post_release_status "$status" "$message"

    log_success "✅ Post-release status determined: $action_type -> $status"
}

# Determine which action was performed
determine_action_type() {
    if [[ "$ROLLBACK_RESULT" == "success" ]]; then
        echo "rollback"
    elif [[ "$ROLLBACK_RESULT" == "failure" ]]; then
        echo "rollback_failed"
    elif [[ "$TAG_STABLE_RESULT" == "success" ]]; then
        echo "tag_stable"
    elif [[ "$TAG_UNSTABLE_RESULT" == "success" ]]; then
        echo "tag_unstable"
    elif [[ "$VERIFY_DEPLOYMENT_RESULT" == "success" ]]; then
        echo "verify_deployment"
    else
        echo "completed"
    fi
}

# Determine status for specific action
determine_status_for_action() {
    local action_type="$1"

    case "$action_type" in
        "rollback") echo "warning" ;;
        "rollback_failed") echo "failure" ;;
        "tag_stable"|"tag_unstable"|"verify_deployment") echo "success" ;;
        *) echo "info" ;;
    esac
}

# Generate message for action
generate_message_for_action() {
    local action_type="$1"
    local status="$2"

    case "$action_type" in
        "rollback")
            echo "Rollback Completed ⚠️"
            ;;
        "rollback_failed")
            echo "Rollback Failed ❌"
            ;;
        "tag_stable")
            echo "Version Tagged as Stable ✅"
            ;;
        "tag_unstable")
            echo "Version Tagged as Unstable 🟡"
            ;;
        "verify_deployment")
            echo "Deployment Verified ✅"
            ;;
        *)
            echo "Post-Release Actions Completed ℹ️"
            ;;
    esac
}

# Output post-release status to GitHub Actions
output_post_release_status() {
    local status="$1"
    local message="$2"

    if [[ "$SCRIPT_MODE" == "dry_run" ]]; then
        echo "[DRY RUN] Would output post-release status:"
        echo "status=$status"
        echo "message=$message"
        return 0
    fi

    # Output to GitHub Actions
    echo "status=$status" >> "$GITHUB_OUTPUT"
    echo "message=$message" >> "$GITHUB_OUTPUT"

    log_info "Post-release status: $status"
    log_info "Message: $message"
}

# Custom status determination extension point
determine_custom_status() {
    # Override this function to add custom status determination logic
    log_debug "Custom post-release status determination (no additional logic defined)"
}

# Custom action type determination extension point
determine_custom_action_type() {
    # Override this function to add custom action type determination
    log_debug "Custom action type determination (no additional logic defined)"
}

# Main function
main() {
    log_info "$SCRIPT_NAME v$SCRIPT_VERSION - Post-Release Status Determination"

    # Initialize project configuration
    load_project_config

    # Determine post-release status
    determine_post_release_status

    # Run custom extensions if defined
    if command -v determine_custom_status >/dev/null 2>&1; then
        determine_custom_status
    fi

    if command -v determine_custom_action_type >/dev/null 2>&1; then
        determine_custom_action_type
    fi

    log_success "✅ Post-release status determination completed"
}

# Run main function with all arguments
main "$@"