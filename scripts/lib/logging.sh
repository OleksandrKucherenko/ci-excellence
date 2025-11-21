#!/bin/bash
# Logging library for CI scripts

# Initialize logging
initialize_logging() {
    local log_level="${1:-info}"
    local script_name="${2:-ci-script}"

    # Set log level
    case "$log_level" in
        "debug"|"trace")
            export LOG_LEVEL=0
            ;;
        "info")
            export LOG_LEVEL=1
            ;;
        "warn"|"warning")
            export LOG_LEVEL=2
            ;;
        "error")
            export LOG_LEVEL=3
            ;;
        *)
            export LOG_LEVEL=1
            log_level="info"
            ;;
    esac

    export LOG_SCRIPT_NAME="$script_name"

    # Create log directory if it doesn't exist
    local log_dir="${PROJECT_ROOT}/.logs"
    mkdir -p "$log_dir"

    # Set log file path
    export LOG_FILE="${log_dir}/${script_name}-$(date -u +"%Y%m%d").log"
}

# Generic logging function
log_message() {
    local level="$1"
    local message="$2"
    local level_num="$3"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%d %H:%M:%S UTC")

    # Check if we should log this level
    if [[ $level_num -ge ${LOG_LEVEL:-1} ]]; then
        # Output to console with color
        case "$level" in
            "DEBUG")
                echo -e "\033[0;34m[$timestamp] [DEBUG] $message\033[0m"
                ;;
            "INFO")
                echo -e "\033[0;34m[$timestamp] [INFO] $message\033[0m"
                ;;
            "WARN")
                echo -e "\033[1;33m[$timestamp] [WARN] $message\033[0m"
                ;;
            "ERROR")
                echo -e "\033[0;31m[$timestamp] [ERROR] $message\033[0m"
                ;;
            "SUCCESS")
                echo -e "\033[0;32m[$timestamp] [SUCCESS] $message\033[0m"
                ;;
        esac

        # Also log to file
        if [[ -n "${LOG_FILE:-}" ]]; then
            echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
        fi
    fi
}

# Debug logging
log_debug() {
    log_message "DEBUG" "$1" 0
}

# Info logging
log_info() {
    log_message "INFO" "$1" 1
}

# Warning logging
log_warn() {
    log_message "WARN" "$1" 2
}

# Error logging
log_error() {
    log_message "ERROR" "$1" 3
}

# Success logging
log_success() {
    log_message "SUCCESS" "$1" 1
}

# Start a section
log_section() {
    local title="$1"
    local separator
    separator=$(printf '=%.0s' {1..50})

    echo
    log_info "$separator"
    log_info "$title"
    log_info "$separator"
    echo
}

# Log command execution
log_command() {
    local command="$1"
    log_info "Executing: $command"
}

# Log command result
log_result() {
    local exit_code="$1"
    local command="${2:-command}"

    if [[ $exit_code -eq 0 ]]; then
        log_success "$command completed successfully"
    else
        log_error "$command failed with exit code $exit_code"
    fi
}

# Create log report
create_log_report() {
    local title="$1"
    local status="$2"
    local details="$3"

    local report_file="${PROJECT_ROOT}/.reports/log-report-$(date -u +"%Y%m%d%H%M%S").json"
    mkdir -p "${PROJECT_ROOT}/.reports"

    cat > "$report_file" << EOF
{
  "title": "$title",
  "status": "$status",
  "details": "$details",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "script": "${LOG_SCRIPT_NAME:-unknown}",
  "log_file": "${LOG_FILE:-}"
}
EOF

    log_info "Log report created: $report_file"
}

# Cleanup old logs
cleanup_old_logs() {
    local days="${1:-30}"
    local log_dir="${PROJECT_ROOT}/.logs"

    if [[ -d "$log_dir" ]]; then
        find "$log_dir" -name "*.log" -type f -mtime +$days -delete 2>/dev/null || true
        log_debug "Cleaned up log files older than $days days"
    fi
}