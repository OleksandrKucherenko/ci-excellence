#!/bin/bash
# CI Post-Release Version Determination Script - Version 1.0.0
#
# PURPOSE: Determine version from GitHub event contexts (release or workflow_dispatch)
#
# USAGE:
#   ./scripts/ci/deployment/16-ci-determine-post-release-version.sh
#
# EXAMPLES:
#   # Determine version from release event
#   GITHUB_EVENT_NAME="release" GITHUB_EVENT_RELEASE_TAG_NAME="v1.2.3" ./scripts/ci/deployment/16-ci-determine-post-release-version.sh
#
#   # Determine version from workflow_dispatch input
#   GITHUB_EVENT_NAME="workflow_dispatch" GITHUB_EVENT_INPUTS_VERSION="v1.2.3" ./scripts/ci/deployment/16-ci-determine-post-release-version.sh
#
# TESTABILITY ENVIRONMENT VARIABLES:
#   - CI_TEST_MODE: Set to "dry_run" to simulate version determination
#   - GITHUB_EVENT_NAME: Override event type for testing
#   - GITHUB_EVENT_RELEASE_TAG_NAME: Override release tag for testing
#   - GITHUB_EVENT_INPUTS_VERSION: Override input version for testing
#
# EXTENSION POINTS:
#   - Add custom version logic in determine_custom_version()
#   - Extend version validation in validate_version()
#   - Customize version format in format_version()
#
# SIZE GUIDELINES:
#   - Keep script under 50 lines (excluding comments and documentation)
#   - Extract complex version logic to helper functions
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

# GitHub context (from environment variables)
GITHUB_EVENT_NAME="${GITHUB_EVENT_NAME:-}"
GITHUB_EVENT_RELEASE_TAG_NAME="${GITHUB_EVENT_RELEASE_TAG_NAME:-}"
GITHUB_EVENT_INPUTS_VERSION="${GITHUB_EVENT_INPUTS_VERSION:-}"

# Main version determination function
determine_post_release_version() {
    log_info "Determining post-release version from $GITHUB_EVENT_NAME event"

    local version
    version=$(extract_version_from_context)

    # Validate version
    validate_version "$version"

    # Output to GitHub Actions
    output_version "$version"

    log_success "✅ Version determined: $version"
}

# Extract version from event context
extract_version_from_context() {
    local version

    case "$GITHUB_EVENT_NAME" in
        "release")
            version="$GITHUB_EVENT_RELEASE_TAG_NAME"
            log_info "Version from release event: $version"
            ;;
        "workflow_dispatch")
            version="$GITHUB_EVENT_INPUTS_VERSION"
            log_info "Version from workflow_dispatch input: $version"
            ;;
        *)
            log_error "❌ Unsupported event type: $GITHUB_EVENT_NAME"
            exit 1
            ;;
    esac

    echo "$version"
}

# Validate version format
validate_version() {
    local version="$1"

    if [[ -z "$version" ]]; then
        log_error "❌ Version is empty"
        exit 1
    fi

    # Basic version validation - should start with 'v' or be semantic version
    if [[ ! "$version" =~ ^(v[0-9]+\.[0-9]+\.[0-9]+|[0-9]+\.[0-9]+\.[0-9]+.*)$ ]]; then
        log_error "❌ Invalid version format: $version"
        log_error "Expected format: v1.2.3 or 1.2.3 or 1.2.3-alpha"
        exit 1
    fi

    log_info "✅ Version validation passed: $version"
}

# Output version to GitHub Actions
output_version() {
    local version="$1"

    if [[ "$SCRIPT_MODE" == "dry_run" ]]; then
        echo "[DRY RUN] Would output version: $version"
        return 0
    fi

    echo "version=$version" >> "$GITHUB_OUTPUT"
    log_info "Version output to GitHub Actions: $version"
}

# Custom version determination extension point
determine_custom_version() {
    # Override this function to add custom version determination logic
    log_debug "Custom version determination (no additional logic defined)"
}

# Custom version validation extension point
validate_custom_version() {
    # Override this function to add custom version validation logic
    log_debug "Custom version validation (no additional validation defined)"
}

# Main function
main() {
    log_info "$SCRIPT_NAME v$SCRIPT_VERSION - Post-Release Version Determination"

    # Initialize project configuration
    load_project_config

    # Determine post-release version
    determine_post_release_version

    # Run custom extensions if defined
    if command -v determine_custom_version >/dev/null 2>&1; then
        determine_custom_version
    fi

    if command -v validate_custom_version >/dev/null 2>&1; then
        validate_custom_version
    fi

    log_success "✅ Post-release version determination completed"
}

# Run main function with all arguments
main "$@"