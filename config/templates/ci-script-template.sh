#!/bin/bash
# CI Script Template - Version 1.0.0
#
# PURPOSE: Brief one-sentence description of what this script does
#
# USAGE:
#   ./scripts/path/to/script.sh [command] [options]
#
# EXAMPLES:
#   # Default usage
#   ./scripts/path/to/script.sh
#
#   # With specific command
#   ./scripts/path/to/script.sh deploy production
#
#   # Dry run mode
#   DRY_RUN=true ./scripts/path/to/script.sh validate
#
# TESTABILITY ENVIRONMENT VARIABLES:
#   - CI_TEST_MODE: Set to "dry_run" to simulate operations without making changes
#   - SCRIPT_MODE: Override default script behavior (dry_run, verbose, quiet)
#   - FORCE_MODE: Skip safety checks and validations
#   - LOG_LEVEL: Set logging level (debug, info, warn, error)
#
# EXTENSION POINTS:
#   - Add custom validation logic in validate_custom_rules() function
#   - Extend execute_operation() with additional commands
#   - Add environment-specific logic in configure_environment()
#
# SIZE GUIDELINES:
#   - Keep script under 50 lines of code (excluding comments and documentation)
#   - Extract helper functions to lib/ directory if script grows larger
#   - Use shared libraries for common operations (see scripts/lib/)
#
# DEPENDENCIES:
#   - Required: git, curl, jq (if JSON processing needed)
#   - Optional: yq (for YAML processing), aws-cli (for cloud operations)
#   - Libraries: scripts/lib/config.sh, scripts/lib/logging.sh, scripts/lib/validation.sh

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

# Configuration variables - customize these for your specific needs
DEFAULT_COMMAND="validate"
DEFAULT_TIMEOUT=30
MAX_RETRIES=3

# Example: Node.js/TypeScript implementation
# Uncomment and modify for your project type
#
# run_nodejs_build() {
#     if [[ "$DRY_RUN" != "true" ]]; then
#         log_info "Building Node.js application"
#         npm run build
#         log_success "Node.js build completed"
#     else
#         log_info "[DRY RUN] Would build Node.js application"
#     fi
# }

# Example: Python implementation
# Uncomment and modify for your project type
#
# run_python_build() {
#     if [[ "$DRY_RUN" != "true" ]]; then
#         log_info "Building Python application"
#         python -m build
#         log_success "Python build completed"
#     else
#         log_info "[DRY RUN] Would build Python application"
#     fi
# }

# Example: Go implementation
# Uncomment and modify for your project type
#
# run_go_build() {
#     if [[ "$DRY_RUN" != "true" ]]; then
#         log_info "Building Go application"
#         go build -o bin/app ./cmd/main.go
#         log_success "Go build completed"
#     else
#         log_info "[DRY RUN] Would build Go application"
#     fi
# }

# Main operation function - extend this with your specific logic
execute_operation() {
    local command="$1"
    local target="${2:-default}"

    case "$command" in
        "validate")
            validate_prerequisites
            ;;
        "process")
            process_target "$target"
            ;;
        "cleanup")
            cleanup_resources
            ;;
        *)
            log_error "Unknown command: $command"
            show_usage
            return 1
            ;;
    esac
}

# Validation function - extend with custom rules
validate_prerequisites() {
    log_info "Validating prerequisites"

    # Check required tools
    local required_tools=("git" "curl")
    if ! validate_required_tools "${required_tools[@]}"; then
        return 1
    fi

    # Add your custom validation logic here
    # validate_custom_rules

    log_success "Prerequisites validation passed"
}

# Custom validation function - add your specific rules here
validate_custom_rules() {
    # Example: Check if required files exist
    local required_files=("package.json" ".env.example")
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            log_error "Required file not found: $file"
            return 1
        fi
    done

    # Example: Validate environment variables
    local required_vars=("NODE_ENV" "API_URL")
    if ! validate_environment_variables "${required_vars[@]}"; then
        return 1
    fi

    return 0
}

# Process target function - implement your main logic here
process_target() {
    local target="$1"

    log_info "Processing target: $target"

    # Add your specific processing logic here
    case "$target" in
        "nodejs")
            # run_nodejs_build
            log_info "Node.js processing (implement in run_nodejs_build)"
            ;;
        "python")
            # run_python_build
            log_info "Python processing (implement in run_python_build)"
            ;;
        "go")
            # run_go_build
            log_info "Go processing (implement in run_go_build)"
            ;;
        *)
            log_error "Unknown target: $target"
            return 1
            ;;
    esac

    log_success "Target processing completed"
}

# Cleanup function - implement resource cleanup
cleanup_resources() {
    log_info "Cleaning up resources"

    # Add your cleanup logic here
    # Example: Remove temporary files
    if [[ -d "${PROJECT_ROOT}/.temp" ]]; then
        rm -rf "${PROJECT_ROOT}/.temp"
        log_info "Temporary files cleaned up"
    fi

    log_success "Cleanup completed"
}

# Show usage information
show_usage() {
    echo
    echo "Usage: $0 [command] [target] [options]"
    echo
    echo "Commands:"
    echo "  validate    Validate prerequisites and environment"
    echo "  process     Process specified target"
    echo "  cleanup     Clean up resources and temporary files"
    echo
    echo "Targets:"
    echo "  nodejs      Process Node.js/TypeScript project"
    echo "  python      Process Python project"
    echo "  go          Process Go project"
    echo "  default     Use default processing logic"
    echo
    echo "Options:"
    echo "  DRY_RUN=true     Run in dry-run mode (no actual changes)"
    echo "  LOG_LEVEL=debug  Enable debug logging"
    echo "  FORCE_MODE=true  Skip safety checks"
    echo
    echo "Examples:"
    echo "  $0 validate                    # Validate prerequisites"
    echo "  $0 process nodejs              # Process Node.js project"
    echo "  DRY_RUN=true $0 process python # Dry run for Python project"
}

# Environment configuration function
configure_environment() {
    # Set up environment-specific configuration
    case "${DEPLOYMENT_ENVIRONMENT:-development}" in
        "production")
            export NODE_ENV="production"
            export LOG_LEVEL="warn"
            ;;
        "staging")
            export NODE_ENV="staging"
            export LOG_LEVEL="info"
            ;;
        *)
            export NODE_ENV="development"
            export LOG_LEVEL="debug"
            ;;
    esac
}

# Error handling function
handle_error() {
    local exit_code=$?
    local line_number=$1

    log_error "Script failed at line $line_number with exit code $exit_code"

    # Add cleanup logic here
    cleanup_resources

    exit $exit_code
}

# Set up error handling
trap 'handle_error $LINENO' ERR

# Main function
main() {
    local command="${1:-$DEFAULT_COMMAND}"
    local target="${2:-default}"

    # Initialize logging and configuration
    initialize_logging "$LOG_LEVEL" "$SCRIPT_NAME"
    load_project_config
    configure_environment

    # Log script start
    log_info "Starting $SCRIPT_NAME v$SCRIPT_VERSION"
    log_info "Command: $command, Target: $target, Mode: $SCRIPT_MODE"

    # Check if running in dry-run mode
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warn "Running in dry-run mode - no actual changes will be made"
    fi

    # Execute the main operation
    execute_operation "$command" "$target"

    log_success "$SCRIPT_NAME completed successfully"
}

# Run main function with all arguments
main "$@"