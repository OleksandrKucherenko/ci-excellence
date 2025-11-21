#!/usr/bin/env bash
# Mock Framework for CI Testing
# This library provides utilities to mock script execution states for local testing

set -euo pipefail

# ============================================================================
# Mock State Configuration
# ============================================================================
# Environment variables to control mock behavior:
#   MOCK_MODE=<ok|failed|stuck|random>   - Simulate different execution states
#   MOCK_DELAY=<seconds>                 - Add delay before completion (default: 0)
#   MOCK_STUCK_DURATION=<seconds>        - How long to stay stuck (default: 300)
#   MOCK_RANDOM_SEED=<number>            - Seed for random mode
#   MOCK_EXIT_CODE=<number>              - Specific exit code for failed mode (default: 1)
#   MOCK_VERBOSE=<true|false>            - Verbose mock output (default: false)

# ============================================================================
# Mock State Functions
# ============================================================================

# Get the mock mode for this script
# Priority: MOCK_MODE_<SCRIPT_NAME> > MOCK_MODE > "ok"
get_mock_mode() {
    local script_name
    script_name=$(basename "${BASH_SOURCE[1]}" .sh | tr '[:lower:]' '[:upper:]' | tr '-' '_')
    local specific_var="MOCK_MODE_${script_name}"

    if [[ -n "${!specific_var:-}" ]]; then
        echo "${!specific_var}"
    elif [[ -n "${MOCK_MODE:-}" ]]; then
        echo "${MOCK_MODE}"
    else
        echo "ok"
    fi
}

# Get the mock delay for this script
get_mock_delay() {
    local script_name
    script_name=$(basename "${BASH_SOURCE[1]}" .sh | tr '[:lower:]' '[:upper:]' | tr '-' '_')
    local specific_var="MOCK_DELAY_${script_name}"

    if [[ -n "${!specific_var:-}" ]]; then
        echo "${!specific_var}"
    elif [[ -n "${MOCK_DELAY:-}" ]]; then
        echo "${MOCK_DELAY}"
    else
        echo "0"
    fi
}

# Log mock message
mock_log() {
    if [[ "${MOCK_VERBOSE:-false}" == "true" ]]; then
        echo "[MOCK] $*" >&2
    fi
}

# Generate random outcome
random_outcome() {
    local seed="${MOCK_RANDOM_SEED:-$RANDOM}"
    local outcomes=("ok" "failed" "stuck")
    local index=$((seed % 3))
    echo "${outcomes[$index]}"
}

# Apply mock delay
apply_mock_delay() {
    local delay
    delay=$(get_mock_delay)

    if [[ "$delay" -gt 0 ]]; then
        mock_log "Applying delay of ${delay} seconds..."
        local elapsed=0
        while [[ $elapsed -lt $delay ]]; do
            sleep 1
            elapsed=$((elapsed + 1))
            if [[ $((elapsed % 10)) -eq 0 ]]; then
                mock_log "Progress: ${elapsed}/${delay} seconds"
            fi
        done
    fi
}

# Simulate stuck state
simulate_stuck() {
    local duration="${MOCK_STUCK_DURATION:-300}"
    mock_log "Entering STUCK state for ${duration} seconds (or until killed)..."

    # Create a progress indicator
    local elapsed=0
    while [[ $elapsed -lt $duration ]]; do
        if [[ $((elapsed % 30)) -eq 0 ]]; then
            echo "Still running... (${elapsed}s elapsed)" >&2
        fi
        sleep 5
        elapsed=$((elapsed + 5))
    done

    mock_log "STUCK timeout reached, exiting with timeout error"
    exit 124  # Standard timeout exit code
}

# ============================================================================
# Main Mock Handler
# ============================================================================

# Call this at the beginning of your script to enable mock behavior
# Usage: mock_handler "Script Name" || exit $?
mock_handler() {
    local script_description="$1"
    local mode
    mode=$(get_mock_mode)

    # Only act if in mock mode
    if [[ "${MOCK_ENABLED:-false}" != "true" ]]; then
        return 0
    fi

    mock_log "Mock mode enabled for: ${script_description}"
    mock_log "Mock mode: ${mode}"

    # Apply delay if configured
    apply_mock_delay

    # Handle different mock modes
    case "$mode" in
        ok)
            mock_log "Simulating OK state"
            echo "✅ [MOCK] ${script_description} completed successfully"
            return 0
            ;;
        failed)
            local exit_code="${MOCK_EXIT_CODE:-1}"
            mock_log "Simulating FAILED state with exit code ${exit_code}"
            echo "❌ [MOCK] ${script_description} failed (simulated)" >&2
            return "$exit_code"
            ;;
        stuck)
            mock_log "Simulating STUCK state"
            echo "⏳ [MOCK] ${script_description} is stuck..." >&2
            simulate_stuck
            ;;
        random)
            local outcome
            outcome=$(random_outcome)
            mock_log "Random mode selected: ${outcome}"
            MOCK_MODE="$outcome" mock_handler "$script_description"
            return $?
            ;;
        *)
            echo "⚠️  Unknown mock mode: ${mode}, defaulting to OK" >&2
            return 0
            ;;
    esac
}

# ============================================================================
# Timeout Wrapper
# ============================================================================

# Execute a command with timeout
# Usage: with_timeout <seconds> <command> [args...]
with_timeout() {
    local timeout_duration="$1"
    shift

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
                echo "⚠️  Timeout reached (${timeout_duration}s), killing process ${pid}" >&2
                kill -TERM "$pid" 2>/dev/null || true
                sleep 5
                kill -KILL "$pid" 2>/dev/null || true
            fi
        ) &
        local killer_pid=$!

        wait "$pid"
        local exit_code=$?
        kill "$killer_pid" 2>/dev/null || true

        return $exit_code
    fi
}

# ============================================================================
# Progress Reporting
# ============================================================================

# Start a progress reporter for long-running operations
# Usage: start_progress "Operation description" <timeout_seconds>
start_progress() {
    local description="$1"
    local timeout="${2:-300}"

    (
        local elapsed=0
        local interval=15
        while [[ $elapsed -lt $timeout ]]; do
            sleep $interval
            elapsed=$((elapsed + interval))
            echo "⏳ ${description}... (${elapsed}s elapsed)" >&2
        done
    ) &
    echo $!  # Return the PID of the progress reporter
}

# Stop a progress reporter
# Usage: stop_progress <pid>
stop_progress() {
    local pid="$1"
    kill "$pid" 2>/dev/null || true
}

# ============================================================================
# Test Utilities
# ============================================================================

# Check if running in mock mode
is_mock_mode() {
    [[ "${MOCK_ENABLED:-false}" == "true" ]]
}

# Execute real command or mock based on mode
mock_or_execute() {
    local description="$1"
    shift

    if is_mock_mode; then
        mock_handler "$description"
        return $?
    else
        "$@"
        return $?
    fi
}

# Print mock configuration summary
print_mock_config() {
    if is_mock_mode; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
        echo "🎭 MOCK MODE ENABLED" >&2
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
        echo "  Mode: $(get_mock_mode)" >&2
        echo "  Delay: $(get_mock_delay)s" >&2
        echo "  Verbose: ${MOCK_VERBOSE:-false}" >&2
        if [[ "$(get_mock_mode)" == "stuck" ]]; then
            echo "  Stuck Duration: ${MOCK_STUCK_DURATION:-300}s" >&2
        fi
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    fi
}

# ============================================================================
# Export functions for use in other scripts
# ============================================================================

export -f get_mock_mode
export -f get_mock_delay
export -f mock_log
export -f mock_handler
export -f with_timeout
export -f start_progress
export -f stop_progress
export -f is_mock_mode
export -f mock_or_execute
export -f print_mock_config
