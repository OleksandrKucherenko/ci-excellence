#!/usr/bin/env bash
# Refactored Test Helper Functions for CI Excellence Test Suite
# Provides essential utilities and assertions - mock functionality moved to mock system

# Load BATS support libraries if available
load_bats_support() {
    # Try to load bats-support and bats-assert if they exist
    local tests_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # Try system paths first (these are most likely to exist)
    for lib in bats-support bats-assert; do
        for path in /home/linuxbrew/.linuxbrew/Cellar/bats-core/*/lib /usr/lib/bats /usr/local/lib/bats /opt/bats /usr/share/bats; do
            if [[ -f "$path/$lib/load.bash" ]]; then
                source "$path/$lib/load.bash"
                break 2
            fi
        done
    done

    # Try local test_helper directory as fallback
    if [[ -f "$tests_dir/test_helper/bats-support/load.bash" ]]; then
        source "$tests_dir/test_helper/bats-support/load.bash"
    fi
    if [[ -f "$tests_dir/test_helper/bats-assert/load.bash" ]]; then
        source "$tests_dir/test_helper/bats-assert/load.bash"
    fi
}

# Initialize test environment
load_bats_support

# Basic assertion functions for BATS testing
assert_success() {
    local status="${1:-$?}"
    local message="${2:-Expected command to succeed}"

    if [[ "$status" -eq 0 ]]; then
        return 0
    else
        echo "Assertion failed: $message (exit code: $status)" >&2
        return 1
    fi
}

assert_failure() {
    local status="${1:-$?}"
    local message="${2:-Expected command to fail}"

    if [[ "$status" -ne 0 ]]; then
        return 0
    else
        echo "Assertion failed: $message (exit code: $status)" >&2
        return 1
    fi
}

assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Expected '$expected' to equal '$actual'}"

    if [[ "$expected" == "$actual" ]]; then
        return 0
    else
        echo "Assertion failed: $message" >&2
        echo "  Expected: '$expected'" >&2
        echo "  Actual:   '$actual'" >&2
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-Expected '$haystack' to contain '$needle'}"

    if [[ "$haystack" == *"$needle"* ]]; then
        return 0
    else
        echo "Assertion failed: $message" >&2
        echo "  Haystack: '$haystack'" >&2
        echo "  Needle:   '$needle'" >&2
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local message="${2:-Expected file '$file' to exist}"

    if [[ -f "$file" ]]; then
        return 0
    else
        echo "Assertion failed: $message" >&2
        return 1
    fi
}

assert_file_not_exists() {
    local file="$1"
    local message="${2:-Expected file '$file' to not exist}"

    if [[ ! -f "$file" ]]; then
        return 0
    else
        echo "Assertion failed: $message" >&2
        return 1
    fi
}

assert_directory_exists() {
    local dir="$1"
    local message="${2:-Expected directory '$dir' to exist}"

    if [[ -d "$dir" ]]; then
        return 0
    else
        echo "Assertion failed: $message" >&2
        return 1
    fi
}

# Utility functions for test environment setup
setup_test_environment() {
    export PROJECT_ROOT="$BATS_TEST_TMPDIR/project"
    export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
    mkdir -p "$PROJECT_ROOT"
}

# Clean up test environment
cleanup_test_environment() {
    unset PROJECT_ROOT
}

# Helper to create temporary files
create_temp_file() {
    local prefix="${1:-test}"
    mktemp -t "${prefix}.XXXXXX"
}

# Helper to create temporary directories
create_temp_dir() {
    local prefix="${1:-test}"
    mktemp -d -t "${prefix}.XXXXXX"
}

# Helper to wait for background processes
wait_for_process() {
    local pid="$1"
    local timeout="${2:-30}"
    local count=0

    while kill -0 "$pid" 2>/dev/null; do
        if [[ $count -ge $timeout ]]; then
            kill "$pid" 2>/dev/null
            return 1
        fi
        sleep 1
        ((count++))
    done
    return 0
}