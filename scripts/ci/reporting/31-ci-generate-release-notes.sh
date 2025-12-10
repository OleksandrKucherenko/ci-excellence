#!/bin/bash
# CI Release Notes Generator Script - Version 1.0.0
#
# PURPOSE: Generate release notes and output to GitHub Actions
#
# USAGE:
#   ./scripts/ci/reporting/31-ci-generate-release-notes.sh [version]
#
# EXAMPLES:
#   # Generate release notes for version 1.2.3
#   ./scripts/ci/reporting/31-ci-generate-release-notes.sh "1.2.3"
#
#   # With test mode
#   CI_TEST_MODE="dry_run" ./scripts/ci/reporting/31-ci-generate-release-notes.sh "1.2.3"
#
# TESTABILITY ENVIRONMENT VARIABLES:
#   - CI_TEST_MODE: Set to "dry_run" to simulate notes generation
#   - RELEASE_VERSION: Override version for testing
#
# EXTENSION POINTS:
#   - Add custom notes formatting in format_release_notes()
#   - Extend notes content in generate_additional_content()
#   - Customize output format in output_notes()
#
# SIZE GUIDELINES:
#   - Keep script under 50 lines (excluding comments and documentation)
#   - Extract complex formatting logic to helper functions
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

# Release information
RELEASE_VERSION="${RELEASE_VERSION:-${1:-}}"

# Main release notes generation function
generate_release_notes() {
    if [[ -z "$RELEASE_VERSION" ]]; then
        log_error "❌ Release version is required"
        exit 1
    fi

    log_info "Generating release notes for version $RELEASE_VERSION"

    # Generate release notes content
    local notes
    notes=$(create_release_notes_content)

    # Output to GitHub Actions
    output_release_notes "$notes"

    log_success "✅ Release notes generated for version $RELEASE_VERSION"
}

# Create release notes content
create_release_notes_content() {
    if [[ "$SCRIPT_MODE" == "dry_run" ]]; then
        echo "[DRY RUN] Would generate release notes for $RELEASE_VERSION"
        echo "## Release Notes v$RELEASE_VERSION"
        echo ""
        echo "### Changes"
        echo "- Feature additions"
        echo "- Bug fixes"
        echo "- Documentation updates"
        return 0
    fi

    # Generate actual release notes using the release script
    chmod +x scripts/release/*.sh
    local notes
    notes=$(./scripts/release/generate-release-notes.sh "$RELEASE_VERSION")

    # Add custom formatting if needed
    format_release_notes "$notes"
}

# Format release notes with custom styling
format_release_notes() {
    local notes="$1"

    # Add header if not present
    if [[ ! "$notes" =~ ^##.*Release.*Notes ]]; then
        echo "## Release Notes v$RELEASE_VERSION"
        echo ""
        echo "$notes"
    else
        echo "$notes"
    fi
}

# Output release notes to GitHub Actions
output_release_notes() {
    local notes="$1"

    if [[ "$SCRIPT_MODE" == "dry_run" ]]; then
        echo "[DRY RUN] Would output release notes to GitHub Actions"
        echo "Content: $(echo "$notes" | wc -l) lines"
        return 0
    fi

    # Output to GitHub Actions with proper format
    echo "notes<<EOF" >> "$GITHUB_OUTPUT"
    echo "$notes" >> "$GITHUB_OUTPUT"
    echo "EOF" >> "$GITHUB_OUTPUT"

    log_info "Release notes output to GitHub Actions"
}

# Custom notes content extension point
generate_additional_content() {
    # Override this function to add custom release notes content
    log_debug "Additional release notes content (no additional content defined)"
}

# Main function
main() {
    log_info "$SCRIPT_NAME v$SCRIPT_VERSION - Release Notes Generator"

    # Initialize project configuration
    load_project_config

    # Generate release notes
    generate_release_notes

    # Run custom extensions if defined
    if command -v generate_additional_content >/dev/null 2>&1; then
        generate_additional_content
    fi

    log_success "✅ Release notes generation completed"
}

# Run main function with all arguments
main "$@"