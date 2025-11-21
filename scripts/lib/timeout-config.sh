#!/usr/bin/env bash
# Timeout Configuration for CI Scripts
# Define timeout limits for all CI steps

set -euo pipefail

# ============================================================================
# Default Timeouts (in seconds)
# ============================================================================

# Setup timeouts
export TIMEOUT_INSTALL_TOOLS="${TIMEOUT_INSTALL_TOOLS:-300}"          # 5 minutes
export TIMEOUT_INSTALL_DEPENDENCIES="${TIMEOUT_INSTALL_DEPENDENCIES:-600}"  # 10 minutes

# Build timeouts
export TIMEOUT_COMPILE="${TIMEOUT_COMPILE:-900}"                      # 15 minutes
export TIMEOUT_LINT="${TIMEOUT_LINT:-300}"                            # 5 minutes
export TIMEOUT_SECURITY_SCAN="${TIMEOUT_SECURITY_SCAN:-600}"          # 10 minutes
export TIMEOUT_BUNDLE="${TIMEOUT_BUNDLE:-600}"                        # 10 minutes

# Test timeouts
export TIMEOUT_UNIT_TESTS="${TIMEOUT_UNIT_TESTS:-600}"                # 10 minutes
export TIMEOUT_INTEGRATION_TESTS="${TIMEOUT_INTEGRATION_TESTS:-1200}" # 20 minutes
export TIMEOUT_E2E_TESTS="${TIMEOUT_E2E_TESTS:-1800}"                 # 30 minutes
export TIMEOUT_SMOKE_TESTS="${TIMEOUT_SMOKE_TESTS:-300}"              # 5 minutes

# Release timeouts
export TIMEOUT_VERSION_UPDATE="${TIMEOUT_VERSION_UPDATE:-180}"        # 3 minutes
export TIMEOUT_PUBLISH_NPM="${TIMEOUT_PUBLISH_NPM:-300}"              # 5 minutes
export TIMEOUT_PUBLISH_GITHUB="${TIMEOUT_PUBLISH_GITHUB:-300}"        # 5 minutes
export TIMEOUT_PUBLISH_DOCKER="${TIMEOUT_PUBLISH_DOCKER:-900}"        # 15 minutes
export TIMEOUT_PUBLISH_DOCUMENTATION="${TIMEOUT_PUBLISH_DOCUMENTATION:-600}"  # 10 minutes

# Maintenance timeouts
export TIMEOUT_CLEANUP="${TIMEOUT_CLEANUP:-600}"                      # 10 minutes
export TIMEOUT_SYNC_FILES="${TIMEOUT_SYNC_FILES:-180}"                # 3 minutes
export TIMEOUT_SECURITY_AUDIT="${TIMEOUT_SECURITY_AUDIT:-600}"        # 10 minutes
export TIMEOUT_DEPENDENCY_UPDATE="${TIMEOUT_DEPENDENCY_UPDATE:-600}"  # 10 minutes

# Notification timeouts
export TIMEOUT_NOTIFICATIONS="${TIMEOUT_NOTIFICATIONS:-120}"          # 2 minutes

# ============================================================================
# Timeout Helper Functions
# ============================================================================

# Get timeout for current script
get_script_timeout() {
    local script_name
    script_name=$(basename "${BASH_SOURCE[1]}" .sh | tr '[:lower:]' '[:upper:]' | tr '-' '_')
    local timeout_var="TIMEOUT_${script_name}"

    # Check if specific timeout is set
    if [[ -n "${!timeout_var:-}" ]]; then
        echo "${!timeout_var}"
    else
        # Default to 10 minutes if not configured
        echo "600"
    fi
}

# Apply timeout to a command
# Usage: run_with_timeout <command> [args...]
run_with_timeout() {
    local timeout_duration
    timeout_duration=$(get_script_timeout)

    echo "⏱️  Running with timeout: ${timeout_duration}s" >&2

    if command -v timeout >/dev/null 2>&1; then
        timeout --kill-after=10s "${timeout_duration}s" "$@"
        return $?
    else
        # Fallback for systems without timeout command
        local pid
        "$@" &
        pid=$!

        (
            sleep "$timeout_duration"
            if kill -0 "$pid" 2>/dev/null; then
                echo "⚠️  Timeout reached (${timeout_duration}s), terminating process ${pid}" >&2
                kill -TERM "$pid" 2>/dev/null || true
                sleep 10
                kill -KILL "$pid" 2>/dev/null || true
            fi
        ) &
        local killer_pid=$!

        wait "$pid"
        local exit_code=$?
        kill "$killer_pid" 2>/dev/null || true

        if [[ $exit_code -eq 124 || $exit_code -eq 137 ]]; then
            echo "❌ Command timed out after ${timeout_duration}s" >&2
            return 124
        fi

        return $exit_code
    fi
}

# Print timeout configuration for debugging
print_timeout_config() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "⏱️  Timeout Configuration" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "  Current Script: $(basename "${BASH_SOURCE[1]}")" >&2
    echo "  Timeout: $(get_script_timeout)s" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
}

# Export functions
export -f get_script_timeout
export -f run_with_timeout
export -f print_timeout_config
