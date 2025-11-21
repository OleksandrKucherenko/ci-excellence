#!/usr/bin/env bash
# Common utility functions for CI/CD scripts
# Provides logging, error handling, and testability support

# Prevent double sourcing
if [[ "${CI_COMMON_SH_LOADED:-}" == "true" ]]; then
  return 0
fi
CI_COMMON_SH_LOADED=true

# Strict mode for CI scripts
set -euo pipefail

# Color codes for output
declare -A COLORS=(
  [RED]='\033[0;31m'
  [GREEN]='\033[0;32m'
  [YELLOW]='\033[1;33m'
  [BLUE]='\033[0;34m'
  [PURPLE]='\033[0;35m'
  [CYAN]='\033[0;36m'
  [WHITE]='\033[1;37m'
  [GRAY]='\033[0;37m'
  [NC]='\033[0m' # No Color
)

# Logging functions with colors and timestamps
log_timestamp() {
  date '+%Y-%m-%d %H:%M:%S'
}

log_info() {
  echo -e "${COLORS[BLUE]}[INFO]${COLORS[NC]} $(log_timestamp) $*" >&2
}

log_debug() {
  if [[ "${DEBUG:-false}" == "true" ]]; then
    echo -e "${COLORS[GRAY]}[DEBUG]${COLORS[NC]} $(log_timestamp) $*" >&2
  fi
}

log_success() {
  echo -e "${COLORS[GREEN]}[SUCCESS]${COLORS[NC]} $(log_timestamp) $*" >&2
}

log_warning() {
  echo -e "${COLORS[YELLOW]}[WARNING]${COLORS[NC]} $(log_timestamp) $*" >&2
}

log_error() {
  echo -e "${COLORS[RED]}[ERROR]${COLORS[NC]} $(log_timestamp) $*" >&2
}

log_command() {
  local cmd="$*"
  log_debug "Executing: $cmd"
  if [[ "${CI_TEST_MODE:-EXECUTE}" != "DRY_RUN" ]]; then
    eval "$cmd"
  else
    echo -e "${COLORS[YELLOW]}[DRY_RUN]${COLORS[NC]} Would execute: $cmd"
  fi
}

# Testability support functions
get_script_name() {
  local script_path="$1"
  basename "$script_path" | sed 's/^[0-9]*-ci-//; s/\.sh$//; s/-/_/g' | tr '[:lower:]' '[:upper:]'
}

get_pipeline_name() {
  local workflow_name="${GITHUB_WORKFLOW:-}"
  echo "$workflow_name" | tr '[:lower:]' '[:upper:]' | tr -c '[:alnum:]' '_' | sed 's/__*/_/g; s/^_//; s/_$//'
}

resolve_test_mode() {
  local script_name="$1"
  local pipeline_name="$2"

  # Hierarchical variable lookup (most specific wins)
  local mode_var="CI_TEST_${pipeline_name}_${script_name}_BEHAVIOR"
  local mode="${!mode_var:-}"

  if [[ -z "$mode" ]]; then
    mode_var="CI_TEST_${script_name}_BEHAVIOR"
    mode="${!mode_var:-}"
  fi

  if [[ -z "$mode" ]]; then
    mode="${CI_TEST_MODE:-EXECUTE}"
  fi

  echo "$mode"
}

log_test_mode_source() {
  local script_name="$1"
  local pipeline_name="$2"
  local mode="$3"

  local mode_var="CI_TEST_${pipeline_name}_${script_name}_BEHAVIOR"
  if [[ -n "${!mode_var:-}" ]]; then
    log_info "Test mode: $mode (from CI_TEST_${pipeline_name}_${script_name}_BEHAVIOR)"
  else
    mode_var="CI_TEST_${script_name}_BEHAVIOR"
    if [[ -n "${!mode_var:-}" ]]; then
      log_info "Test mode: $mode (from CI_TEST_${script_name}_BEHAVIOR)"
    elif [[ -n "${CI_TEST_MODE:-}" ]]; then
      log_info "Test mode: $mode (from CI_TEST_MODE)"
    else
      log_info "Test mode: $mode (default)"
    fi
  fi
}

# Execute command based on test mode
execute_with_testability() {
  local script_name="$1"
  local pipeline_name="$2"
  local command="$3"

  local mode
  mode=$(resolve_test_mode "$script_name" "$pipeline_name")

  log_test_mode_source "$script_name" "$pipeline_name" "$mode"

  case "$mode" in
    DRY_RUN)
      log_info "Dry run: would execute $command"
      return 0
      ;;
    PASS)
      log_info "Simulated success for $script_name"
      return 0
      ;;
    FAIL)
      log_error "Simulated failure for $script_name"
      return 1
      ;;
    SKIP)
      log_info "Skipping $script_name"
      return 0
      ;;
    TIMEOUT)
      log_warning "Simulating timeout for $script_name"
      sleep infinity
      return 124
      ;;
    EXECUTE)
      log_info "Executing $script_name"
      if [[ "${DEBUG:-false}" == "true" ]]; then
        log_debug "Command: $command"
      fi
      eval "$command"
      ;;
    *)
      log_error "Unknown test mode: $mode"
      return 1
      ;;
  esac
}

# Error handling and cleanup
cleanup_on_error() {
  local exit_code=$?
  if [[ $exit_code -ne 0 ]]; then
    log_error "Script failed with exit code $exit_code"
    log_error "Command: ${BASH_COMMAND:-unknown}"
    log_error "Line: ${BASH_LINENO:-unknown}"
  fi
}

# Set up error handling
setup_error_handling() {
  trap cleanup_on_error ERR
  trap cleanup_on_error EXIT
}

# Check if required tools are available
check_required_tools() {
  local missing_tools=()

  for tool in "$@"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      missing_tools+=("$tool")
    fi
  done

  if [[ ${#missing_tools[@]} -gt 0 ]]; then
    log_error "Missing required tools: ${missing_tools[*]}"
    log_error "Please install missing tools and try again"
    return 1
  fi

  log_success "All required tools are available: $*"
}

# Check if required environment variables are set
check_required_env_vars() {
  local missing_vars=()

  for var in "$@"; do
    if [[ -z "${!var:-}" ]]; then
      missing_vars+=("$var")
    fi
  done

  if [[ ${#missing_vars[@]} -gt 0 ]]; then
    log_error "Missing required environment variables: ${missing_vars[*]}"
    return 1
  fi

  log_debug "All required environment variables are set: $*"
}

# Validate configuration
validate_config() {
  local config_file="$1"

  if [[ ! -f "$config_file" ]]; then
    log_error "Configuration file not found: $config_file"
    return 1
  fi

  # Basic YAML validation (would need yq or similar for proper validation)
  if command -v yq >/dev/null 2>&1; then
    if ! yq eval '.' "$config_file" >/dev/null 2>&1; then
      log_error "Invalid YAML in configuration file: $config_file"
      return 1
    fi
  fi

  log_success "Configuration file is valid: $config_file"
}

# Retry mechanism with exponential backoff
retry() {
  local retries="$1"
  local delay="$2"
  local max_delay="$3"
  local command="${@:4}"

  local attempt=1
  local current_delay="$delay"

  while [[ $attempt -le $retries ]]; do
    log_info "Attempt $attempt of $retries: $command"

    if eval "$command"; then
      log_success "Command succeeded on attempt $attempt"
      return 0
    fi

    if [[ $attempt -eq $retries ]]; then
      log_error "Command failed after $retries attempts"
      return 1
    fi

    log_warning "Command failed, retrying in ${current_delay}s..."
    sleep "$current_delay"

    # Exponential backoff
    current_delay=$((current_delay * 2))
    if [[ $current_delay -gt $max_delay ]]; then
      current_delay=$max_delay
    fi

    ((attempt++))
  done
}

# Create temporary directory with cleanup
create_temp_dir() {
  local prefix="${1:-ci}"
  local temp_dir
  temp_dir=$(mktemp -d -t "${prefix}-XXXXXX")

  # Set up cleanup on exit
  trap "rm -rf '$temp_dir'" EXIT

  echo "$temp_dir"
}

# Check if running in GitHub Actions
is_github_actions() {
  [[ -n "${GITHUB_ACTIONS:-}" ]]
}

# Check if running in CI environment
is_ci_environment() {
  [[ -n "${CI:-}" ]] || is_github_actions
}

# Get environment-specific configuration path
get_env_config_path() {
  local environment="$1"
  local config_type="${2:-config}"

  echo "environments/${environment}/${config_type}.yml"
}

# Get secrets file path
get_secrets_path() {
  local environment="$1"
  echo "environments/${environment}/secrets.enc"
}

# Decrypt secrets using SOPS
decrypt_secrets() {
  local secrets_file="$1"
  local output_file="${2:-}"

  if [[ ! -f "$secrets_file" ]]; then
    log_error "Secrets file not found: $secrets_file"
    return 1
  fi

  if command -v sops >/dev/null 2>&1; then
    if [[ -n "$output_file" ]]; then
      sops --decrypt "$secrets_file" > "$output_file"
    else
      sops --decrypt "$secrets_file"
    fi
  else
    log_error "SOPS not available for decrypting secrets"
    return 1
  fi
}

# Format duration in seconds to human-readable format
format_duration() {
  local duration="$1"
  local hours=$((duration / 3600))
  local minutes=$(((duration % 3600) / 60))
  local seconds=$((duration % 60))

  if [[ $hours -gt 0 ]]; then
    printf "%dh %dm %ds" $hours $minutes $seconds
  elif [[ $minutes -gt 0 ]]; then
    printf "%dm %ds" $minutes $seconds
  else
    printf "%ds" $seconds
  fi
}

# Generate random string
generate_random_string() {
  local length="${1:-16}"
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -base64 "$length" | tr -d "=+/" | cut -c1-"$length"
  else
    # Fallback using /dev/urandom
    tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c "$length"
  fi
}

# Export functions for use in other scripts
export -f log_info log_debug log_success log_warning log_error log_command
export -f get_script_name get_pipeline_name resolve_test_mode log_test_mode_source
export -f execute_with_testability setup_error_handling
export -f check_required_tools check_required_env_vars validate_config
export -f retry create_temp_dir
export -f is_github_actions is_ci_environment
export -f get_env_config_path get_secrets_path decrypt_secrets
export -f format_duration generate_random_string