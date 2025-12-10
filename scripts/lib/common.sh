#!/bin/bash
# Common utilities for CI/CD scripts
# Provides shared functions for logging, error handling, and testability

set -euo pipefail

# Color definitions for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# Global configuration
readonly SCRIPT_VERSION="1.0.0"
readonly LOG_TIMESTAMP="${LOG_TIMESTAMP:-true}"

# Logging functions
log_with_timestamp() {
  local level="$1"
  local message="$2"
  local color="$3"

  if [[ "$LOG_TIMESTAMP" == "true" ]]; then
    printf "${color}[%s] [%s] %s${NC}\n" "$(date -u +"%Y-%m-%d %H:%M:%S UTC")" "$level" "$message" >&2
  else
    printf "${color}[%s] %s${NC}\n" "$level" "$message" >&2
  fi
}

log_debug() {
  if [[ "${DEBUG:-false}" == "true" ]]; then
    log_with_timestamp "DEBUG" "$1" "$CYAN"
  fi
}

log_info() {
  log_with_timestamp "INFO" "$1" "$BLUE"
}

log_success() {
  log_with_timestamp "SUCCESS" "$1" "$GREEN"
}

log_warn() {
  log_with_timestamp "WARN" "$1" "$YELLOW"
}

log_error() {
  log_with_timestamp "ERROR" "$1" "$RED"
}

log_critical() {
  log_with_timestamp "CRITICAL" "$1" "$PURPLE"
}

# Error handling
handle_error() {
  local exit_code=$?
  local line_number=$1
  local script_name="${BASH_SOURCE[1]:-unknown}"

  log_error "Script failed with exit code $exit_code at $script_name:$line_number"
  log_error "Command: ${BASH_COMMAND:-unknown}"

  # Cleanup function if defined
  if declare -f cleanup >/dev/null; then
    log_info "Running cleanup function..."
    cleanup
  fi

  exit $exit_code
}

# Set up error handling
setup_error_handling() {
  set -Ee
  trap 'handle_error $LINENO' ERR
}

# Testability utilities
get_script_behavior() {
  local script_name="$1"
  local default_behavior="$2"

  # Priority order: Pipeline-level > Script-specific > Global > Default
  local pipeline_var="PIPELINE_SCRIPT_${script_name^^}_BEHAVIOR"
  local script_var="CI_${script_name^^}_BEHAVIOR"

  if [[ -n "${!pipeline_var:-}" ]]; then
    echo "${!pipeline_var}"
  elif [[ -n "${!script_var:-}" ]]; then
    echo "${!script_var}"
  elif [[ -n "${CI_TEST_MODE:-}" ]]; then
    echo "$CI_TEST_MODE"
  else
    echo "$default_behavior"
  fi
}

# Validate behavior mode
validate_behavior() {
  local behavior="$1"
  local valid_modes=("EXECUTE" "DRY_RUN" "PASS" "FAIL" "SKIP" "TIMEOUT")

  for mode in "${valid_modes[@]}"; do
    if [[ "$behavior" == "$mode" ]]; then
      return 0
    fi
  done

  log_error "Invalid behavior mode: $behavior. Valid modes: ${valid_modes[*]}"
  return 1
}

# Environment variable utilities
get_env_var() {
  local var_name="$1"
  local default_value="${2:-}"

  local value="${!var_name:-$default_value}"
  echo "$value"
}

validate_required_env() {
  local var_name="$1"
  local description="${2:-environment variable}"

  if [[ -z "${!var_name:-}" ]]; then
    log_error "Required $description is not set: $var_name"
    return 1
  fi
}

# File and directory utilities
ensure_directory() {
  local dir_path="$1"
  local description="${2:-directory}"

  if [[ ! -d "$dir_path" ]]; then
    log_info "Creating $description: $dir_path"
    mkdir -p "$dir_path"
  fi
}

ensure_file_exists() {
  local file_path="$1"
  local description="${2:-file}"

  if [[ ! -f "$file_path" ]]; then
    log_error "$description not found: $file_path"
    return 1
  fi
}

safe_remove() {
  local path="$1"
  local description="${2:-path}"

  if [[ -e "$path" ]]; then
    log_info "Removing $description: $path"
    rm -rf "$path"
  fi
}

# Git utilities
get_git_info() {
  local info_type="$1"

  case "$info_type" in
    "branch")
      git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown"
      ;;
    "commit")
      git rev-parse HEAD 2>/dev/null || echo "unknown"
      ;;
    "remote")
      git config --get remote.origin.url 2>/dev/null || echo "unknown"
      ;;
    "tag")
      git describe --tags --exact-match 2>/dev/null || echo "none"
      ;;
    "is_clean")
      if git diff-index --quiet HEAD -- 2>/dev/null; then
        echo "true"
      else
        echo "false"
      fi
      ;;
    *)
      log_error "Unknown git info type: $info_type"
      return 1
      ;;
  esac
}

# String utilities
trim() {
  local var="$1"
  echo "${var#"${var%%[![:space:]]*}"}"
  echo "${var%"${var##*[![:space:]]}"}"
}

string_to_lower() {
  echo "$1" | tr '[:upper:]' '[:upper:]' '[:lower:]'
}

string_to_upper() {
  echo "$1" | tr '[:lower:]' '[:upper:]'
}

# Array utilities
array_contains() {
  local needle="$1"
  shift
  local haystack=("$@")

  for item in "${haystack[@]}"; do
    if [[ "$item" == "$needle" ]]; then
      return 0
    fi
  done

  return 1
}

# Time utilities
get_timestamp() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

get_duration_seconds() {
  local start_time="$1"
  local end_time="${2:-$(date +%s)}"

  echo $((end_time - start_time))
}

format_duration() {
  local seconds="$1"

  local hours=$((seconds / 3600))
  local minutes=$(((seconds % 3600) / 60))
  local secs=$((seconds % 60))

  if [[ $hours -gt 0 ]]; then
    printf "%dh %dm %ds" $hours $minutes $secs
  elif [[ $minutes -gt 0 ]]; then
    printf "%dm %ds" $minutes $secs
  else
    printf "%ds" $secs
  fi
}

# Validation utilities
validate_semver() {
  local version="$1"

  # Semantic versioning pattern: MAJOR.MINOR.PATCH(-PRERELEASE)(+BUILD)
  local semver_regex='^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$'

  if [[ $version =~ $semver_regex ]]; then
    return 0
  else
    return 1
  fi
}

validate_tag_format() {
  local tag="$1"
  local pattern="$2"

  case "$pattern" in
    "version")
      validate_semver "${tag#v}"  # Remove 'v' prefix if present
      ;;
    "environment")
      [[ $tag =~ ^(production|staging|canary|sandbox|performance)$ ]]
      ;;
    "state")
      [[ $tag =~ ^.*-(stable|unstable|deprecated)$ ]]
      ;;
    *)
      log_error "Unknown tag format pattern: $pattern"
      return 1
      ;;
  esac
}

# Security utilities
sanitize_input() {
  local input="$1"
  local type="${2:-string}"

  case "$type" in
    "alphanumeric")
      echo "$input" | tr -cd '[:alnum:]'
      ;;
    "filename")
      echo "$input" | tr -cd '[:alnum:]._\-/'
      ;;
    "url")
      echo "$input" | tr -cd '[:alnum:]._\-/~?=%&'
      ;;
    *)
      # Basic sanitization: remove control characters
      echo "$input" | tr -d '\000-\010\013\014\016-\037\177-\377'
      ;;
  esac
}

# HTTP utilities (basic, no external dependencies)
make_http_request() {
  local method="$1"
  local url="$2"
  local data="$3"
  local timeout="${4:-30}"

  if command -v curl >/dev/null 2>&1; then
    if [[ -n "$data" ]]; then
      curl -s -X "$method" -d "$data" --max-time "$timeout" "$url"
    else
      curl -s -X "$method" --max-time "$timeout" "$url"
    fi
  elif command -v wget >/dev/null 2>&1; then
    if [[ -n "$data" ]]; then
      wget -q -O - --timeout="$timeout" --method="$method" --body-data="$data" "$url"
    else
      wget -q -O - --timeout="$timeout" --method="$method" "$url"
    fi
  else
    log_error "Neither curl nor wget available for HTTP requests"
    return 1
  fi
}

# JSON utilities (basic, no jq dependency)
get_json_value() {
  local json="$1"
  local key="$2"

  # Basic JSON parsing - works for simple key-value pairs
  echo "$json" | grep -o "\"$key\"\s*:\s*\"[^\"]*\"" | cut -d'"' -f4
}

# Initialize common utilities
init_common() {
  log_debug "Initializing common utilities v$SCRIPT_VERSION"
  setup_error_handling

  # Validate environment
  if [[ -n "${CI:-}" ]]; then
    log_debug "Running in CI environment"
  else
    log_debug "Running in local environment"
  fi
}

# Auto-initialize when sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  init_common
fi