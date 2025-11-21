#!/bin/bash
# CI Release Status Determination Script - Version 1.0.0
#
# PURPOSE: Determine overall release status and generate notification messages
#
# USAGE:
#   ./scripts/ci/reporting/30-ci-determine-release-status.sh
#
# EXAMPLES:
#   # Determine release status from job results
#   PREPARE_RESULT="success" PUBLISH_NPM_RESULT="success" ./scripts/ci/reporting/30-ci-determine-release-status.sh
#
#   # With failed publish job
#   PREPARE_RESULT="success" PUBLISH_NPM_RESULT="failure" ./scripts/ci/reporting/30-ci-determine-release-status.sh
#
# TESTABILITY ENVIRONMENT VARIABLES:
#   - CI_TEST_MODE: Set to "dry_run" to simulate status determination
#   - RELEASE_VERSION: Override version for testing
#
# EXTENSION POINTS:
#   - Add custom status logic in determine_custom_status()
#   - Extend failure conditions in check_failure_conditions()
#   - Customize message formatting in format_notification_message()
#
# SIZE GUIDELINES:
#   - Keep script under 50 lines (excluding comments and documentation)
#   - Extract complex status logic to helper functions
#   - use shared utilities for common operations
#
# DEPENDENCIES:
#   - Required: bash
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

# Release information
RELEASE_VERSION="${RELEASE_VERSION:-unknown}"

# Pipeline results (from GitHub Actions)
PREPARE_RESULT="${PREPARE_RESULT:-unknown}"
PUBLISH_NPM_RESULT="${PUBLISH_NPM_RESULT:-unknown}"
PUBLISH_GITHUB_RESULT="${PUBLISH_GITHUB_RESULT:-unknown}"
PUBLISH_DOCKER_RESULT="${PUBLISH_DOCKER_RESULT:-unknown}"
PUBLISH_DOCUMENTATION_RESULT="${PUBLISH_DOCUMENTATION_RESULT:-unknown}"

# Main status determination function
determine_release_status() {
    log_info "Determining release status for version $RELEASE_VERSION"

    local overall_status
    local message

    # Check failure conditions
    if check_failure_conditions; then
        overall_status="failure"
        message="Release $RELEASE_VERSION Failed ❌"
    else
        overall_status="success"
        message="Release $RELEASE_VERSION Published ✅"
    fi

    # Output to GitHub Actions
    output_release_status "$overall_status" "$message"

    log_success "✅ Release status determined: $overall_status"
}

# Check if any critical job failed
check_failure_conditions() {
    local failed_jobs=0

    # Check each critical job
    [[ "$PREPARE_RESULT" == "failure" ]] && ((failed_jobs++))
    [[ "$PUBLISH_NPM_RESULT" == "failure" ]] && ((failed_jobs++))
    [[ "$PUBLISH_GITHUB_RESULT" == "failure" ]] && ((failed_jobs++))
    [[ "$PUBLISH_DOCKER_RESULT" == "failure" ]] && ((failed_jobs++))

    # Consider skipped jobs as successful for status determination
    [[ $failed_jobs -gt 0 ]]
}

# Output release status to GitHub Actions
output_release_status() {
    local status="$1"
    local message="$2"

    if [[ "$SCRIPT_MODE" == "dry_run" ]]; then
        echo "[DRY RUN] Would output release status:"
        echo "status=$status"
        echo "message=$message"
        return 0
    fi

    # Output to GitHub Actions
    echo "status=$status" >> "$GITHUB_OUTPUT"
    echo "message=$message" >> "$GITHUB_OUTPUT"

    log_info "Release status: $status"
    log_info "Message: $message"
}

# Custom status determination extension point
determine_custom_status() {
    # Override this function to add custom status determination logic
    log_debug "Custom status determination (no additional logic defined)"
}

# Custom failure conditions extension point
check_failure_conditions() {
    # Override this function to add custom failure condition checks
    log_debug "Custom failure conditions (no additional conditions defined)"
}

# Main function
main() {
    log_info "$SCRIPT_NAME v$SCRIPT_VERSION - Release Status Determination"

    # Initialize project configuration
    load_project_config

    # Determine release status
    determine_release_status

    # Run custom extensions if defined
    if command -v determine_custom_status >/dev/null 2>&1; then
        determine_custom_status
    fi

    log_success "✅ Release status determination completed"
}

# Run main function with all arguments
main "$@"