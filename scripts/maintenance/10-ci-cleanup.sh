#!/bin/bash
# CI Cleanup Script - Version 1.0.0
#
# PURPOSE: Clean up old CI artifacts, logs, and temporary files to maintain system health
#
# USAGE:
#   ./scripts/maintenance/10-ci-cleanup.sh [options]
#
# EXAMPLES:
#   # Default cleanup
#   ./scripts/maintenance/10-ci-cleanup.sh
#
#   # Dry run mode
#   DRY_RUN=true ./scripts/maintenance/10-ci-cleanup.sh
#
#   # Clean specific directories
#   ./scripts/maintenance/10-ci-cleanup.sh --artifacts --logs
#
# TESTABILITY ENVIRONMENT VARIABLES:
#   - CI_TEST_MODE: Set to "dry_run" to simulate operations
#   - DRY_RUN: Skip actual file deletion operations
#   - CLEANUP_DAYS: Number of days to keep files (default: 30)
#   - LOG_LEVEL: Set logging level (debug, info, warn, error)
#
# EXTENSION POINTS:
#   - Add custom cleanup logic in cleanup_custom_directories()
#   - Extend cleanup_patterns with additional patterns
#   - Add environment-specific cleanup rules
#
# SIZE GUIDELINES:
#   - Keep script under 50 lines of code (excluding comments and documentation)
#   - Extract complex cleanup logic to helper functions
#   - Use shared utilities for file operations
#
# DEPENDENCIES:
#   - Required: find, rm, sort
#   - Optional: jq (for JSON processing), aws-cli (for AWS cleanup)

set -euo pipefail

# Script configuration
SCRIPT_NAME="$(basename "$0" .sh)"
SCRIPT_VERSION="1.0.0"
SCRIPT_MODE="${SCRIPT_MODE:-${CI_TEST_MODE:-default}}"
LOG_LEVEL="${LOG_LEVEL:-info}"
DRY_RUN="${DRY_RUN:-false}"
CLEANUP_DAYS="${CLEANUP_DAYS:-30}"

# Source libraries and utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/config.sh"
source "${SCRIPT_DIR}/../lib/logging.sh"

# Cleanup patterns
declare -a cleanup_patterns=(
    "*.tmp"
    "*.log"
    "*.bak"
    "*.swp"
    ".DS_Store"
    "Thumbs.db"
    "*.pid"
    "*.lock"
)

# Directories to clean
declare -a cleanup_directories=(
    ".logs"
    ".temp"
    ".cache"
    ".reports"
    ".artifacts"
    ".security"
    ".deployments"
    ".maintenance"
)

# Main cleanup function
main_cleanup() {
    log_info "Starting CI cleanup operations"
    log_info "Cleanup mode: $SCRIPT_MODE"
    log_info "Retention period: $CLEANUP_DAYS days"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_warn "Running in DRY RUN mode - no files will be deleted"
    fi

    # Clean temporary files
    cleanup_temp_files

    # Clean old logs
    cleanup_old_logs

    # Clean old reports
    cleanup_old_reports

    # Clean old deployment records
    cleanup_old_deployments

    # Clean custom directories
    cleanup_custom_directories

    # Generate cleanup report
    generate_cleanup_report

    log_success "CI cleanup completed successfully"
}

# Clean temporary files
cleanup_temp_files() {
    log_info "Cleaning up temporary files"

    local temp_files_deleted=0

    # Find and clean temporary files
    while IFS= read -r -d '' file; do
        if [[ -f "$file" ]]; then
            log_debug "Found temporary file: $file"

            if [[ "$DRY_RUN" != "true" ]]; then
                rm -f "$file"
                ((temp_files_deleted++))
                log_debug "Deleted temporary file: $file"
            else
                log_debug "[DRY RUN] Would delete temporary file: $file"
                ((temp_files_deleted++))
            fi
        fi
    done < <(find "${PROJECT_ROOT}" -type f \( \
        -name "*.tmp" -o \
        -name "*.bak" -o \
        -name "*.swp" -o \
        -name ".DS_Store" -o \
        -name "Thumbs.db" \
        \) -print0 2>/dev/null || true)

    log_info "Temporary files processed: $temp_files_deleted"
}

# Clean old logs
cleanup_old_logs() {
    log_info "Cleaning up old log files"

    local logs_deleted=0
    local cutoff_date
    cutoff_date=$(date -d "$CLEANUP_DAYS days ago" +%s 2>/dev/null || date -v-"$CLEANUP_DAYS"d +%s 2>/dev/null || echo "0")

    # Clean log directories
    for log_dir in ".logs" "logs" ".reports"; do
        if [[ -d "${PROJECT_ROOT}/$log_dir" ]]; then
            while IFS= read -r -d '' log_file; do
                local file_date
                file_date=$(stat -c %Y "$log_file" 2>/dev/null || stat -f %m "$log_file" 2>/dev/null || echo "0")

                if [[ $file_date -lt $cutoff_date ]]; then
                    if [[ "$DRY_RUN" != "true" ]]; then
                        rm -f "$log_file"
                        ((logs_deleted++))
                        log_debug "Deleted old log: $log_file"
                    else
                        log_debug "[DRY RUN] Would delete old log: $log_file"
                        ((logs_deleted++))
                    fi
                fi
            done < <(find "${PROJECT_ROOT}/$log_dir" -type f -name "*.log" -print0 2>/dev/null || true)
        fi
    done

    log_info "Old log files processed: $logs_deleted"
}

# Clean old reports
cleanup_old_reports() {
    log_info "Cleaning up old report files"

    local reports_deleted=0
    local cutoff_date
    cutoff_date=$(date -d "$CLEANUP_DAYS days ago" +%s 2>/dev/null || date -v-"$CLEANUP_DAYS"d +%s 2>/dev/null || echo "0")

    # Clean report directories
    for report_dir in ".reports" "reports"; do
        if [[ -d "${PROJECT_ROOT}/$report_dir" ]]; then
            while IFS= read -r -d '' report_file; do
                local file_date
                file_date=$(stat -c %Y "$report_file" 2>/dev/null || stat -f %m "$report_file" 2>/dev/null || echo "0")

                if [[ $file_date -lt $cutoff_date ]]; then
                    if [[ "$DRY_RUN" != "true" ]]; then
                        rm -f "$report_file"
                        ((reports_deleted++))
                        log_debug "Deleted old report: $report_file"
                    else
                        log_debug "[DRY RUN] Would delete old report: $report_file"
                        ((reports_deleted++))
                    fi
                fi
            done < <(find "${PROJECT_ROOT}/$report_dir" -type f \( -name "*.json" -o -name "*.xml" -o -name "*.html" \) -print0 2>/dev/null || true)
        fi
    done

    log_info "Old report files processed: $reports_deleted"
}

# Clean old deployment records
cleanup_old_deployments() {
    log_info "Cleaning up old deployment records"

    local deployments_deleted=0
    local cutoff_date
    cutoff_date=$(date -d "$CLEANUP_DAYS days ago" +%s 2>/dev/null || date -v-"$CLEANUP_DAYS"d +%s 2>/dev/null || echo "0")

    # Clean deployment directory
    if [[ -d "${PROJECT_ROOT}/.deployments" ]]; then
        while IFS= read -r -d '' deployment_file; do
            local file_date
            file_date=$(stat -c %Y "$deployment_file" 2>/dev/null || stat -f %m "$deployment_file" 2>/dev/null || echo "0")

            if [[ $file_date -lt $cutoff_date ]]; then
                if [[ "$DRY_RUN" != "true" ]]; then
                    rm -f "$deployment_file"
                    ((deployments_deleted++))
                    log_debug "Deleted old deployment record: $deployment_file"
                else
                    log_debug "[DRY RUN] Would delete old deployment record: $deployment_file"
                    ((deployments_deleted++))
                fi
            fi
        done < <(find "${PROJECT_ROOT}/.deployments" -type f -name "*.json" -print0 2>/dev/null || true)
    fi

    log_info "Old deployment records processed: $deployments_deleted"
}

# Clean custom directories (extension point)
cleanup_custom_directories() {
    log_info "Cleaning up custom directories"

    # Add your custom cleanup logic here
    # Example:
    # if [[ -d "${PROJECT_ROOT}/custom-temp" ]]; then
    #     log_info "Cleaning custom temp directory"
    # fi
}

# Generate cleanup report
generate_cleanup_report() {
    local report_file="${PROJECT_ROOT}/.maintenance/cleanup-report.json"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    mkdir -p "$(dirname "$report_file")"

    cat > "$report_file" << EOF
{
  "cleanup_info": {
    "timestamp": "$timestamp",
    "script_version": "$SCRIPT_VERSION",
    "dry_run": $DRY_RUN,
    "retention_days": $CLEANUP_DAYS,
    "initiated_by": "${USER:-unknown}"
  },
  "summary": {
    "status": "completed",
    "message": "CI cleanup completed successfully"
  },
  "directories_cleaned": [
    ".logs",
    ".reports",
    ".deployments",
    ".temp"
  ],
  "file_patterns": $(printf '%s\n' "${cleanup_patterns[@]}" | jq -R . | jq -s .)
}
EOF

    log_info "Cleanup report generated: $report_file"
}

# Show usage information
show_usage() {
    echo
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  --dry-run         Simulate cleanup without deleting files"
    echo "  --days N         Set retention period to N days (default: 30)"
    echo "  --artifacts      Clean only artifact files"
    echo "  --logs          Clean only log files"
    echo "  --reports       Clean only report files"
    echo "  --deployments  Clean only deployment records"
    echo
    echo "Environment Variables:"
    echo "  DRY_RUN=true    Run in dry-run mode"
    echo "  CLEANUP_DAYS=N  Set retention period"
    echo "  LOG_LEVEL=debug Enable debug logging"
    echo
    echo "Examples:"
    echo "  $0                    # Default cleanup"
    echo "  DRY_RUN=true $0       # Dry run mode"
    echo "  $0 --days 7           # Keep only 7 days of files"
}

# Main function
main() {
    local command="${1:-cleanup}"

    # Initialize logging and configuration
    initialize_logging "$LOG_LEVEL" "$SCRIPT_NAME"
    load_project_config

    case "$command" in
        "cleanup")
            main_cleanup
            ;;
        "dry-run")
            DRY_RUN=true
            main_cleanup
            ;;
        "--dry-run")
            DRY_RUN=true
            main_cleanup
            ;;
        "--help"|"-h")
            show_usage
            ;;
        *)
            log_error "Unknown option: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"