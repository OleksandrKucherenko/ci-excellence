#!/usr/bin/env bash
# Configuration Manager CLI
# Manages multi-environment configuration and secrets

set -euo pipefail

# Source shared utilities
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Source configuration utilities
# shellcheck source=../lib/config-utils.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/config-utils.sh"

# Script configuration
readonly SCRIPT_NAME="$(basename "$0" .sh)"
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_DESCRIPTION="Multi-environment configuration management CLI"

# Usage information
usage() {
  cat <<EOF
Usage: $SCRIPT_NAME <command> [OPTIONS] [ARGS]

Multi-environment configuration management with SOPS encryption support.

COMMANDS:
  init [ENV]               Initialize configuration environment
  load [ENV]               Load configuration and secrets for environment
  validate [ENV]           Validate configuration and secrets
  show [ENV]               Show environment configuration
  list                     List available environments
  compare ENV1 ENV2        Compare two environment configurations
  export-k8s [ENV] [DIR]   Export Kubernetes configuration for environment
  encrypt SECRETS_FILE     Encrypt secrets file with SOPS
  decrypt SECRETS_FILE     Decrypt secrets file
  clean-cache              Clean configuration and secrets cache
  get-value KEY [ENV]      Get configuration value
  get-secret KEY [ENV]      Get secret value

OPTIONS:
  -v, --verbose            Enable verbose output
  -q, --quiet              Suppress non-error output
  -t, --test-mode MODE     Test mode (DRY_RUN|SIMULATE|EXECUTE)
  -h, --help               Show this help message
  -V, --version            Show version information

EXAMPLES:
  $SCRIPT_NAME init production                # Initialize production environment
  $SCRIPT_NAME load staging                    # Load staging configuration
  $SCRIPT_NAME validate production            # Validate production config
  $SCRIPT_NAME show development               # Show development configuration
  $SCRIPT_NAME compare staging production     # Compare staging vs production
  $SCRIPT_NAME export-k8s production          # Export Kubernetes config
  $SCRIPT_NAME encrypt secrets/dev.yaml       # Encrypt development secrets
  $SCRIPT_NAME get-value ".application.log_level" staging  # Get log level

ENVIRONMENT VARIABLES:
  CI_TEST_MODE               Test mode override (DRY_RUN|SIMULATE|EXECUTE)
  CONFIG_ENVIRONMENT         Default environment to use
  CONFIG_CACHE_DIR           Configuration cache directory
  SECRETS_CACHE_DIR          Secrets cache directory

EXIT CODES:
  0     Success
  1     General error
  2     Configuration error
  3     Validation failed
  4     Invalid arguments
  5     Prerequisites not met

EOF
}

# Show version information
version() {
  echo "$SCRIPT_NAME version $SCRIPT_VERSION"
  echo "$SCRIPT_DESCRIPTION"
}

# Parse command line arguments
parse_args() {
  local opt_verbose=false
  local opt_quiet=false
  local opt_test_mode=""

  # Parse options
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -v|--verbose)
        opt_verbose=true
        shift
        ;;
      -q|--quiet)
        opt_quiet=true
        shift
        ;;
      -t|--test-mode)
        shift
        if [[ -z "$1" ]]; then
          log_error "Test mode cannot be empty"
          return 4
        fi
        case "$1" in
          DRY_RUN|SIMULATE|EXECUTE) ;;
          *)
            log_error "Invalid test mode: $1. Use DRY_RUN, SIMULATE, or EXECUTE"
            return 4
            ;;
        esac
        opt_test_mode="$1"
        shift
        ;;
      -h|--help)
        usage
        return 0
        ;;
      -V|--version)
        version
        return 0
        ;;
      -*)
        log_error "Unknown option: $1"
        usage
        return 4
        ;;
      *)
        # Stop parsing options, remaining args are command and args
        break
        ;;
    esac
  done

  # Set global variables
  export VERBOSE="$opt_verbose"
  export QUIET="$opt_quiet"

  # Resolve test mode
  if [[ -n "$opt_test_mode" ]]; then
    export TEST_MODE="$opt_test_mode"
  else
    local resolved_mode
    if ! resolved_mode=$(resolve_test_mode "$SCRIPT_NAME" "config" ""); then
      return 1
    fi
    export TEST_MODE="$resolved_mode"
  fi

  return 0
}

# Initialize environment command
cmd_init() {
  local environment="${1:-}"

  if [[ -z "$environment" ]]; then
    log_error "Environment name required for init command"
    return 4
  fi

  log_info "Initializing environment: $environment"

  case "$TEST_MODE" in
    "DRY_RUN")
      log_info "Would initialize environment: $environment"
      return 0
      ;;
    "SIMULATE")
      log_info "Simulating environment initialization: $environment"
      sleep 1
      return 0
      ;;
  esac

  init_config_environment "$environment"
  setup_configuration "$environment"

  log_success "✅ Environment initialized: $environment"
  return 0
}

# Load configuration command
cmd_load() {
  local environment="${1:-}"

  log_info "Loading configuration"

  if [[ -n "$environment" ]]; then
    init_config_environment "$environment"
  fi

  load_environment_config
  load_secrets

  log_success "✅ Configuration loaded"
  return 0
}

# Validate configuration command
cmd_validate() {
  local environment="${1:-}"

  log_info "Validating configuration"

  if [[ -n "$environment" ]]; then
    init_config_environment "$environment"
  fi

  if validate_configuration; then
    log_success "✅ Configuration validation passed"
    return 0
  else
    log_error "❌ Configuration validation failed"
    return 3
  fi
}

# Show configuration command
cmd_show() {
  local environment="${1:-}"

  if [[ -z "$environment" ]]; then
    log_error "Environment name required for show command"
    return 4
  fi

  if [[ ! -f "${ENVIRONMENTS_DIR}/${environment}.json" ]]; then
    log_error "Environment configuration not found: $environment"
    return 2
  fi

  show_environment "$environment"
  return 0
}

# List environments command
cmd_list() {
  log_info "Listing available environments"
  list_environments
  return 0
}

# Compare environments command
cmd_compare() {
  local env1="$1"
  local env2="$2"

  if [[ -z "$env1" || -z "$env2" ]]; then
    log_error "Two environment names required for compare command"
    return 4
  fi

  compare_environments "$env1" "$env2"
  return 0
}

# Export Kubernetes configuration command
cmd_export_k8s() {
  local environment="${1:-}"
  local output_dir="${2:-}"

  if [[ -z "$environment" ]]; then
    log_error "Environment name required for export-k8s command"
    return 4
  fi

  export_kubernetes_config "$environment" "$output_dir"
  return 0
}

# Encrypt secrets command
cmd_encrypt() {
  local secrets_file="$1"

  if [[ -z "$secrets_file" ]]; then
    log_error "Secrets file path required for encrypt command"
    return 4
  fi

  if [[ ! -f "$secrets_file" ]]; then
    log_error "Secrets file not found: $secrets_file"
    return 2
  fi

  log_info "Encrypting secrets file: $secrets_file"

  case "$TEST_MODE" in
    "DRY_RUN")
      log_info "Would encrypt: $secrets_file"
      return 0
      ;;
    "SIMULATE")
      log_info "Simulating encryption: $secrets_file"
      sleep 2
      return 0
      ;;
  esac

  if ! command -v sops >/dev/null 2>&1; then
    log_error "SOPS is required for encryption. Install with: brew install sops or go install github.com/getsops/sops/v3/cmd/sops@latest"
    return 5
  fi

  if sops --encrypt "$secrets_file" > "${secrets_file}.encrypted"; then
    mv "${secrets_file}.encrypted" "$secrets_file"
    log_success "✅ Secrets encrypted: $secrets_file"
  else
    log_error "❌ Failed to encrypt secrets: $secrets_file"
    return 2
  fi

  return 0
}

# Decrypt secrets command
cmd_decrypt() {
  local secrets_file="$1"

  if [[ -z "$secrets_file" ]]; then
    log_error "Secrets file path required for decrypt command"
    return 4
  fi

  if [[ ! -f "$secrets_file" ]]; then
    log_error "Secrets file not found: $secrets_file"
    return 2
  fi

  log_info "Decrypting secrets file: $secrets_file"

  case "$TEST_MODE" in
    "DRY_RUN")
      log_info "Would decrypt: $secrets_file"
      return 0
      ;;
    "SIMULATE")
      log_info "Simulating decryption: $secrets_file"
      sleep 1
      return 0
      ;;
  esac

  if ! command -v sops >/dev/null 2>&1; then
    log_error "SOPS is required for decryption. Install with: brew install sops or go install github.com/getsops/sops/v3/cmd/sops@latest"
    return 5
  fi

  local output_file="${secrets_file%.yaml}.decrypted.yaml"

  if sops --decrypt "$secrets_file" > "$output_file"; then
    log_success "✅ Secrets decrypted to: $output_file"
  else
    log_error "❌ Failed to decrypt secrets: $secrets_file"
    return 2
  fi

  return 0
}

# Clean cache command
cmd_clean_cache() {
  log_info "Cleaning cache"

  case "$TEST_MODE" in
    "DRY_RUN")
      log_info "Would clean configuration and secrets cache"
      return 0
      ;;
    "SIMULATE")
      log_info "Simulating cache cleanup"
      sleep 1
      return 0
      ;;
  esac

  clean_cache
  return 0
}

# Get configuration value command
cmd_get_value() {
  local key="$1"
  local environment="${2:-}"

  if [[ -z "$key" ]]; then
    log_error "Configuration key required for get-value command"
    return 4
  fi

  if [[ -n "$environment" ]]; then
    init_config_environment "$environment"
  fi

  local value
  if value=$(get_config_value "$key" "$environment" ""); then
    echo "$value"
    return 0
  else
    return 2
  fi
}

# Get secret value command
cmd_get_secret() {
  local key="$1"
  local environment="${2:-}"

  if [[ -z "$key" ]]; then
    log_error "Secret key required for get-secret command"
    return 4
  fi

  if [[ -n "$environment" ]]; then
    init_config_environment "$environment"
  fi

  local value
  if value=$(get_secret_value "$key" "$environment" ""); then
    echo "$value"
    return 0
  else
    return 2
  fi
}

# Main function
main() {
  # Parse command line arguments
  if ! parse_args "$@"; then
    return 1
  fi

  # Extract command and arguments
  if [[ $# -eq 0 ]]; then
    log_error "Command required"
    usage
    return 4
  fi

  local command="$1"
  shift

  log_info "🔧 Configuration Manager"
  log_info "Script version: $SCRIPT_VERSION"
  log_info "Command: $command"
  log_info "Test mode: $TEST_MODE"

  # Execute command
  case "$command" in
    "init")
      cmd_init "$@"
      ;;
    "load")
      cmd_load "$@"
      ;;
    "validate")
      cmd_validate "$@"
      ;;
    "show")
      cmd_show "$@"
      ;;
    "list")
      cmd_list "$@"
      ;;
    "compare")
      cmd_compare "$@"
      ;;
    "export-k8s")
      cmd_export_k8s "$@"
      ;;
    "encrypt")
      cmd_encrypt "$@"
      ;;
    "decrypt")
      cmd_decrypt "$@"
      ;;
    "clean-cache")
      cmd_clean_cache "$@"
      ;;
    "get-value")
      cmd_get_value "$@"
      ;;
    "get-secret")
      cmd_get_secret "$@"
      ;;
    *)
      log_error "Unknown command: $command"
      usage
      return 4
      ;;
  esac
}

# Error handling
trap 'log_error "Script failed with exit code $?"' ERR

# Execute main function with all arguments
main "$@"