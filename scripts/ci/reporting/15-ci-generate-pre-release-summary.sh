#!/bin/bash
# CI Pre-Release Summary Generator - Version 1.0.0
#
# PURPOSE: Generate comprehensive pre-release pipeline summaries with action links
#
# USAGE:
#   ./scripts/ci/reporting/15-ci-generate-pre-release-summary.sh
#
# EXAMPLES:
#   # Generate summary with all pipeline results
#   ./scripts/ci/reporting/15-ci-generate-pre-release-summary.sh
#
#   # With specific results
#   SETUP_RESULT="success" COMPILE_RESULT="success" ./scripts/ci/reporting/15-ci-generate-pre-release-summary.sh
#
# TESTABILITY ENVIRONMENT VARIABLES:
#   - CI_TEST_MODE: Set to "dry_run" to simulate report generation
#   - ENABLE_ACTION_LINKS: Enable/disable action links (default: true)
#   - PIPELINE_TYPE: Type of pipeline (pre-release, release, deployment)
#
# EXTENSION POINTS:
#   - Add custom action links in generate_custom_actions()
#   - Extend report sections in generate_additional_sections()
#   - Customize formatting in format_summary()
#
# SIZE GUIDELINES:
#   - Keep script under 50 lines (excluding comments and documentation)
#   - Extract report generation logic to helper functions
#   - Use templates for different report types
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
SETUP_RESULT="${SETUP_RESULT:-unknown}"
COMPILE_RESULT="${COMPILE_RESULT:-unknown}"
LINT_RESULT="${LINT_RESULT:-unknown}"
UNIT_TESTS_RESULT="${UNIT_TESTS_RESULT:-unknown}"
INTEGRATION_TESTS_RESULT="${INTEGRATION_TESTS_RESULT:-unknown}"
E2E_TESTS_RESULT="${E2E_TESTS_RESULT:-unknown}"
SECURITY_SCAN_RESULT="${SECURITY_SCAN_RESULT:-unknown}"
ENHANCED_SECURITY_GATES_RESULT="${ENHANCED_SECURITY_GATES_RESULT:-unknown}"
BUNDLE_RESULT="${BUNDLE_RESULT:-unknown}"

# GitHub context
GITHUB_SERVER_URL="${GITHUB_SERVER_URL:-https://github.com}"
GITHUB_REPOSITORY="${GITHUB_REPOSITORY:-}"
GITHUB_RUN_ID="${GITHUB_RUN_ID:-}"
GITHUB_SHA="${GITHUB_SHA:-}"
GITHUB_REF_NAME="${GITHUB_REF_NAME:-}"

# Report configuration
PIPELINE_TYPE="${PIPELINE_TYPE:-pre-release}"
ENABLE_ACTION_LINKS="${ENABLE_ACTION_LINKS:-true}"

# Main summary generation function
generate_pre_release_summary() {
    log_info "Generating $PIPELINE_TYPE pipeline summary"

    # Create summary file
    local summary_file="pipeline-summary.md"
    create_summary_header "$summary_file"
    create_results_table "$summary_file"
    create_action_links "$summary_file"
    create_environment_info "$summary_file"
    create_footer "$summary_file"

    # Output to GitHub Actions
    output_to_github_actions "$summary_file"

    # Save as artifact
    save_summary_artifact "$summary_file"

    log_success "✅ Pipeline summary generated successfully"
}

# Create summary header
create_summary_header() {
    local summary_file="$1"

    cat > "$summary_file" << EOF
# 🚀 $PIPELINE_TYPE Pipeline Summary

EOF
}

# Create results table
create_results_table() {
    local summary_file="$1"

    cat >> "$summary_file" << EOF
## 📊 Pipeline Results

| Job | Status | Details |
|-----|--------|---------|
| Setup | $(get_status_icon "$SETUP_RESULT") | Environment validation and dependency installation |
| Compile | $(get_status_icon "$COMPILE_RESULT") | Project compilation and build |
| Lint | $(get_status_icon "$LINT_RESULT") | Code quality and style checks |
| Unit Tests | $(get_status_icon "$UNIT_TESTS_RESULT") | Unit test execution |
| Integration Tests | $(get_status_icon "$INTEGRATION_TESTS_RESULT") | Integration test execution |
| E2E Tests | $(get_status_icon "$E2E_TESTS_RESULT") | End-to-end test execution |
| Security Scan | $(get_status_icon "$SECURITY_SCAN_RESULT") | Basic security vulnerability scanning |
| Enhanced Security Gates | $(get_status_icon "$ENHANCED_SECURITY_GATES_RESULT") | Advanced security and quality gate validation |
| Bundle | $(get_status_icon "$BUNDLE_RESULT") | Package bundling and artifact creation |

EOF
}

# Get status icon for results
get_status_icon() {
    local result="$1"
    case "$result" in
        "success") echo "✅ Success" ;;
        "skipped") echo "⏭️ Skipped" ;;
        "failure") echo "❌ Failed" ;;
        "cancelled") echo "🚫 Cancelled" ;;
        *) echo "❓ Unknown" ;;
    esac
}

# Create action links section
create_action_links() {
    local summary_file="$1"

    if [[ "$ENABLE_ACTION_LINKS" != "true" ]]; then
        return 0
    fi

    cat >> "$summary_file" << EOF
## 🎯 Quick Actions

### 📋 If Pipeline Successful:

- [🚀 **Promote to Release**]($GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/workflows/release.yml/dispatch) - Trigger release workflow
- [🏷️ **Create Release Tag**]($GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/workflows/tag-assignment.yml/dispatch) - Assign version tag
- [🔍 **View Detailed Logs**]($GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID) - Full pipeline logs
- [📊 **Download Artifacts**]($GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID) - Build artifacts and reports

### 🛠️ If Issues Detected:

- [🔧 **Auto-Fix Issues**]($GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/workflows/auto-fix.yml/dispatch) - Run automated fixes
- [🔄 **Re-run Pipeline**]($GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID/rerun) - Re-run failed jobs
- [🐛 **Debug Issues**]($GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID) - Investigate failures

### 📋 Management Actions:

- [🧹 **Run Maintenance**]($GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/workflows/maintenance.yml/dispatch) - System maintenance tasks
- [📈 **View Pipeline Reports**]($GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/workflows/post-release.yml/dispatch) - Generate reports

EOF
}

# Create environment information section
create_environment_info() {
    local summary_file="$1"

    cat >> "$summary_file" << EOF
## 📋 Environment Information

- **Commit**: [$GITHUB_SHA]($GITHUB_SERVER_URL/$GITHUB_REPOSITORY/commit/$GITHUB_SHA)
- **Branch**: $GITHUB_REF_NAME
- **Workflow**: [#$GITHUB_RUN_ID]($GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID)
- **Generated**: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

EOF
}

# Create footer
create_footer() {
    local summary_file="$1"

    cat >> "$summary_file" << EOF
---

*This summary was generated by the CI Excellence Framework v$SCRIPT_VERSION*
EOF
}

# Output to GitHub Actions
output_to_github_actions() {
    local summary_file="$1"

    cat "$summary_file" >> "$GITHUB_STEP_SUMMARY"
    log_info "Summary output to GitHub Actions"
}

# Save summary as artifact
save_summary_artifact() {
    local summary_file="$1"

    mkdir -p summaries
    cp "$summary_file" "summaries/$PIPELINE_TYPE-summary.md"
    log_info "Summary saved as artifact"
}

# Custom action links extension point
generate_custom_actions() {
    # Override this function to add custom action links
    log_debug "Custom action links (no additional actions defined)"
}

# Additional report sections extension point
generate_additional_sections() {
    # Override this function to add custom report sections
    log_debug "Additional report sections (no additional sections defined)"
}

# Main function
main() {
    log_info "$SCRIPT_NAME v$SCRIPT_VERSION - $PIPELINE_TYPE Summary Generator"

    # Initialize project configuration
    load_project_config

    # Generate pre-release summary
    generate_pre_release_summary

    # Run custom extensions if defined
    if command -v generate_custom_actions >/dev/null 2>&1; then
        generate_custom_actions
    fi

    if command -v generate_additional_sections >/dev/null 2>&1; then
        generate_additional_sections
    fi

    log_success "✅ $PIPELINE_TYPE summary generation completed"
}

# Run main function with all arguments
main "$@"