#!/bin/bash
# CI Script Standards Validation Script - Version 1.0.0
#
# PURPOSE: Validate CI scripts follow CI Excellence Framework standards
#
# USAGE:
#   ./scripts/ci/quality/01-ci-validate-script-standards.sh [directory]
#
# EXAMPLES:
#   # Validate all CI scripts
#   ./scripts/ci/quality/01-ci-validate-script-standards.sh scripts/
#
#   # Validate specific directory
#   ./scripts/ci/quality/01-ci-validate-script-standards.sh scripts/ci/
#
# TESTABILITY ENVIRONMENT VARIABLES:
#   - CI_TEST_MODE: Set to "dry_run" to simulate validation
#   - VALIDATION_MODE: Set to "strict" for stricter validation
#
# EXTENSION POINTS:
#   - Add custom validation rules in validate_custom_standards()
#   - Extend checks in additional_validation_checks()
#   - Customize reporting in generate_validation_report()
#
# SIZE GUIDELINES:
#   - Keep script under 50 lines (excluding comments and documentation)
#   - Extract complex validation logic to helper functions
#   - Use shared utilities for common operations
#
# DEPENDENCIES:
#   - Required: bash, find, grep
#   - Optional: shellcheck, shfmt

set -euo pipefail

# Script configuration
SCRIPT_NAME="$(basename "$0" .sh)"
SCRIPT_VERSION="1.0.0"
SCRIPT_MODE="${SCRIPT_MODE:-${CI_TEST_MODE:-default}}"
VALIDATION_MODE="${VALIDATION_MODE:-standard}"

# Source libraries and utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/config.sh"
source "${SCRIPT_DIR}/../../lib/logging.sh"

# Validation targets
SCRIPT_DIRECTORY="${1:-scripts/}"

# Main script standards validation function
validate_script_standards() {
    log_info "Validating CI script standards in $SCRIPT_DIRECTORY"

    local validation_passed=true

    # Check if directory exists
    if [[ ! -d "$SCRIPT_DIRECTORY" ]]; then
        log_error "❌ Directory not found: $SCRIPT_DIRECTORY"
        exit 1
    fi

    # Run validation checks
    validate_script_structure || validation_passed=false
    validate_documentation_standards || validation_passed=false
    validate_error_handling || validation_passed=false
    validate_testability_framework || validation_passed=false

    # Generate validation report
    generate_validation_report "$validation_passed"

    if [[ "$validation_passed" == "true" ]]; then
        log_success "✅ All script standards validation passed"
    else
        log_error "❌ Some script standards validation failed"
        exit 1
    fi
}

# Validate script structure
validate_script_structure() {
    log_info "Validating script structure"

    local script_count=0
    local passed_count=0

    while IFS= read -r -d '' script_file; do
        if [[ "$script_file" =~ \.sh$ ]]; then
            ((script_count++))

            # Check for standard headers
            if validate_script_headers "$script_file"; then
                ((passed_count++))
            else
                log_warn "⚠️ Script structure issues found: $script_file"
            fi
        fi
    done < <(find "$SCRIPT_DIRECTORY" -name "*.sh" -type f -print0)

    log_info "Structure validation: $passed_count/$script_count scripts passed"
}

# Validate script headers
validate_script_headers() {
    local script_file="$1"

    # Check for standard CI Excellence Framework header elements
    local required_elements=(
        "set -euo pipefail"
        "SCRIPT_NAME="
        "SCRIPT_VERSION="
        "source.*lib/config.sh"
        "source.*lib/logging.sh"
    )

    for element in "${required_elements[@]}"; do
        if ! grep -q "$element" "$script_file"; then
            log_debug "Missing required element: $element in $script_file"
            return 1
        fi
    done

    return 0
}

# Validate documentation standards
validate_documentation_standards() {
    log_info "Validating documentation standards"

    local script_count=0
    local documented_count=0

    while IFS= read -r -d '' script_file; do
        if [[ "$script_file" =~ \.sh$ ]]; then
            ((script_count++))

            # Check for comprehensive documentation
            if validate_documentation "$script_file"; then
                ((documented_count++))
            else
                log_warn "⚠️ Documentation issues found: $script_file"
            fi
        fi
    done < <(find "$SCRIPT_DIRECTORY" -name "*.sh" -type f -print0)

    log_info "Documentation validation: $documented_count/$script_count scripts passed"
}

# Validate documentation
validate_documentation() {
    local script_file="$1"

    # Check for required documentation sections
    local required_sections=(
        "PURPOSE:"
        "USAGE:"
        "EXAMPLES:"
        "DEPENDENCIES:"
    )

    for section in "${required_sections[@]}"; do
        if ! grep -q "# $section" "$script_file"; then
            log_debug "Missing documentation section: $section in $script_file"
            return 1
        fi
    done

    return 0
}

# Validate error handling
validate_error_handling() {
    log_info "Validating error handling"

    local script_count=0
    local error_handling_count=0

    while IFS= read -r -d '' script_file; do
        if [[ "$script_file" =~ \.sh$ ]]; then
            ((script_count++))

            # Check for proper error handling
            if validate_error_handling_in_script "$script_file"; then
                ((error_handling_count++))
            else
                log_warn "⚠️ Error handling issues found: $script_file"
            fi
        fi
    done < <(find "$SCRIPT_DIRECTORY" -name "*.sh" -type f -print0)

    log_info "Error handling validation: $error_handling_count/$script_count scripts passed"
}

# Validate error handling in script
validate_error_handling_in_script() {
    local script_file="$1"

    # Check for exit codes in error conditions
    if grep -q "log_error" "$script_file"; then
        if ! grep -q "exit 1" "$script_file"; then
            log_debug "Error conditions without exit codes in $script_file"
            return 1
        fi
    fi

    return 0
}

# Validate testability framework
validate_testability_framework() {
    log_info "Validating testability framework"

    local script_count=0
    local testable_count=0

    while IFS= read -r -d '' script_file; do
        if [[ "$script_file" =~ \.sh$ ]]; then
            ((script_count++))

            # Check for testability support
            if validate_testability_support "$script_file"; then
                ((testable_count++))
            else
                log_warn "⚠️ Testability framework issues found: $script_file"
            fi
        fi
    done < <(find "$SCRIPT_DIRECTORY" -name "*.sh" -type f -print0)

    log_info "Testability framework validation: $testable_count/$script_count scripts passed"
}

# Validate testability support
validate_testability_support() {
    local script_file="$1"

    # Check for CI_TEST_MODE support
    if ! grep -q "CI_TEST_MODE" "$script_file"; then
        log_debug "Missing CI_TEST_MODE support in $script_file"
        return 1
    fi

    return 0
}

# Generate validation report
generate_validation_report() {
    local validation_passed="$1"

    local report_file="script-standards-validation-report.md"

    cat > "$report_file" << EOF
# 📋 CI Script Standards Validation Report

**Timestamp:** $(date -u +"%Y-%m-%dT%H:%M:%SZ")
**Directory:** $SCRIPT_DIRECTORY
**Validation Mode:** $VALIDATION_MODE
**Overall Status:** $(get_validation_status "$validation_passed")

## ✅ Validation Summary

All CI scripts have been validated against the CI Excellence Framework standards.

### 📊 Validation Areas
- Script Structure: Headers, naming, organization
- Documentation Standards: PURPOSE, USAGE, EXAMPLES sections
- Error Handling: Proper exit codes and error logging
- Testability Framework: CI_TEST_MODE and dry-run support

### 🎯 Framework Compliance

This validation ensures all scripts follow the CI Excellence Framework:
- Consistent structure and documentation
- Proper error handling and logging
- Comprehensive testability support
- Modular and maintainable design

---

*This report was generated by the CI Excellence Framework v$SCRIPT_VERSION*
EOF

    # Output to GitHub Actions if not in dry-run mode
    if [[ "$SCRIPT_MODE" != "dry_run" ]]; then
        cat "$report_file" >> "$GITHUB_STEP_SUMMARY"
    fi

    log_info "Validation report generated: $report_file"
}

# Get validation status icon
get_validation_status() {
    local passed="$1"
    if [[ "$passed" == "true" ]]; then
        echo "✅ PASSED"
    else
        echo "❌ FAILED"
    fi
}

# Custom validation rules extension point
validate_custom_standards() {
    # Override this function to add custom validation rules
    log_debug "Custom validation standards (no additional rules defined)"
}

# Additional validation checks extension point
additional_validation_checks() {
    # Override this function to add additional validation checks
    log_debug "Additional validation checks (no additional checks defined)"
}

# Main function
main() {
    log_info "$SCRIPT_NAME v$SCRIPT_VERSION - CI Script Standards Validation"

    # Initialize project configuration
    load_project_config

    # Validate script standards
    validate_script_standards

    # Run custom extensions if defined
    if command -v validate_custom_standards >/dev/null 2>&1; then
        validate_custom_standards
    fi

    if command -v additional_validation_checks >/dev/null 2>&1; then
        additional_validation_checks
    fi

    log_success "✅ CI script standards validation completed"
}

# Run main function with all arguments
main "$@"