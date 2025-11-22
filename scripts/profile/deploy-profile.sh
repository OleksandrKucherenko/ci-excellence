#!/bin/bash
# MISE Profile Switcher
# Switches active deployment profile for environment context

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/scripts/lib/common.sh" 2>/dev/null || {
  echo "Failed to source common utilities" >&2
  exit 1
}

# Configuration
readonly PROFILE_VERSION="1.0.0"
readonly PROFILES_DIR="$PROJECT_ROOT/environments"
readonly SUPPORTED_PROFILES=("local" "staging" "production" "canary" "sandbox" "performance")

# Testability configuration
get_behavior_mode() {
  local script_name="profile_switcher"
  get_script_behavior "$script_name" "EXECUTE"
}

# Validate profile
validate_profile() {
  local profile="$1"

  # Check if profile is in supported list OR exists as a directory
  local is_valid=false
  if array_contains "$profile" "${SUPPORTED_PROFILES[@]}"; then
    is_valid=true
  elif [[ -d "$PROFILES_DIR/$profile" ]]; then
    is_valid=true
  fi

  if [[ "$is_valid" == "false" ]]; then
    log_error "Invalid profile: $profile"

    # Get list of all available profiles (supported + directories)
    local available_profiles=("${SUPPORTED_PROFILES[@]}")
    if [[ -d "$PROFILES_DIR" ]]; then
      while IFS= read -r -d '' dir; do
        local dirname
        dirname=$(basename "$dir")
        if ! array_contains "$dirname" "${SUPPORTED_PROFILES[@]}"; then
          available_profiles+=("$dirname")
        fi
      done < <(find "$PROFILES_DIR" -mindepth 1 -maxdepth 1 -type d -not -name "global" -not -name "default*" -print0)
    fi

    log_info "Available profiles: ${available_profiles[*]}"
    return 1
  fi

  if [[ "$profile" != "local" && ! -d "$PROFILES_DIR/$profile" ]]; then
    log_warn "Profile directory not found: $PROFILES_DIR/$profile"
    log_info "Profile configuration may be incomplete"
  fi

  return 0
}

# Get current profile
get_current_profile() {
  local current_profile
  current_profile=$(get_env_var "DEPLOYMENT_PROFILE" "local")
  echo "$current_profile"
}

# Set environment variables for profile
set_profile_env() {
  local profile="$1"
  local region="${2:-}"

  # Set deployment profile
  export DEPLOYMENT_PROFILE="$profile"

  # Set region if provided
  if [[ -n "$region" ]]; then
    export DEPLOYMENT_REGION="$region"
  fi

  # Set profile-specific environment file
  local env_file="$PROJECT_ROOT/config/.env.$profile"
  if [[ -f "$env_file" ]]; then
    log_info "Loading profile environment file: $env_file"
    set -a
    source "$env_file"
    set +a
    # Keep DEPLOYMENT_PROFILE as the source of truth, overriding anything in the env file
    export DEPLOYMENT_PROFILE="$profile"
  fi

  log_success "✅ Profile environment configured: $profile"
}

# Update shell prompt (optional)
update_shell_prompt() {
  local profile="$1"
  local update_prompt="${UPDATE_SHELL_PROMPT:-true}"

  if [[ "$update_prompt" != "true" ]]; then
    return 0
  fi

  # Prompt update is handled by the shell plugin via MISE environment reload
  return 0
}

# Save profile preference
save_profile_preference() {
  local profile="$1"
  local region="${2:-}"
  local env_local="$PROJECT_ROOT/.env.local"

  # Ensure .env.local exists
  if [[ ! -f "$env_local" ]]; then
    touch "$env_local"
    echo "# Local environment overrides" >"$env_local"
  fi

  # Update DEPLOYMENT_PROFILE
  if grep -q "^DEPLOYMENT_PROFILE=" "$env_local"; then
    # Use a temp file to avoid issues with sed on some systems
    local temp_file
    temp_file=$(mktemp)
    sed "s|^DEPLOYMENT_PROFILE=.*|DEPLOYMENT_PROFILE=\"$profile\"|" "$env_local" >"$temp_file"
    mv "$temp_file" "$env_local"
  else
    echo "DEPLOYMENT_PROFILE=\"$profile\"" >>"$env_local"
  fi

  # Update DEPLOYMENT_REGION
  if grep -q "^DEPLOYMENT_REGION=" "$env_local"; then
    local temp_file
    temp_file=$(mktemp)
    sed "s|^DEPLOYMENT_REGION=.*|DEPLOYMENT_REGION=\"$region\"|" "$env_local" >"$temp_file"
    mv "$temp_file" "$env_local"
  else
    echo "DEPLOYMENT_REGION=\"$region\"" >>"$env_local"
  fi

  log_debug "Profile preference saved to: $env_local"
}

# Load profile preference
load_profile_preference() {
  # Rely on MISE loading .env.local
  local env_local="$PROJECT_ROOT/.env.local"

  if [[ -f "$env_local" ]]; then
    if grep -q "DEPLOYMENT_PROFILE" "$env_local"; then
      return 0
    fi
  fi

  return 1
}

# Show profile status
show_profile_status() {
  local profile="${1:-$(get_current_profile)}"
  local region="${DEPLOYMENT_REGION:-}"

  log_info "Current Profile Status:"
  echo "  Profile: $profile"
  echo "  Region: ${region:-default}"
  echo "  Configuration Directory: $PROFILES_DIR/$profile"

  # Show environment-specific configuration if it exists
  local config_file="$PROFILES_DIR/$profile/config.yml"
  if [[ -f "$config_file" ]]; then
    echo "  Config File: $config_file"
    if command -v yq >/dev/null 2>&1; then
      echo "  Config Preview:"
      # Disable pipefail to avoid SIGPIPE error when head closes the pipe early
      (
        set +o pipefail
        yq '.' "$config_file" 2>/dev/null | head -10 | sed 's/^/    /'
      )
    fi
  fi

  # Show secrets file status
  local secrets_file="$PROFILES_DIR/$profile/secrets.enc"
  if [[ -f "$secrets_file" ]]; then
    echo "  Secrets File: $secrets_file (encrypted)"
  else
    echo "  Secrets File: Not found"
  fi

  # Show region configuration
  if [[ -n "$region" ]]; then
    local region_config_file="$PROFILES_DIR/$profile/regions/$region/config.yml"
    if [[ -f "$region_config_file" ]]; then
      echo "  Region Config: $region_config_file"
    fi
  fi
}

# Switch profile
switch_profile() {
  local profile="$1"
  local region="${2:-}"
  local behavior
  behavior=$(get_behavior_mode)

  log_info "Switching to profile: $profile${region:+ (region: $region)} (mode: $behavior)"

  case "$behavior" in
  "DRY_RUN")
    echo "🔍 DRY RUN: Would switch to profile: $profile"
    return 0
    ;;
  "PASS")
    log_success "PASS MODE: Profile switch simulated successfully"
    return 0
    ;;
  "FAIL")
    log_error "FAIL MODE: Simulating profile switch failure"
    return 1
    ;;
  "SKIP")
    log_info "SKIP MODE: Profile switch skipped"
    return 0
    ;;
  "TIMEOUT")
    log_info "TIMEOUT MODE: Simulating profile switch timeout"
    sleep 3
    return 124
    ;;
  esac

  # EXECUTE mode - Actual profile switch
  # Validate profile
  if ! validate_profile "$profile"; then
    return 1
  fi

  local current_profile
  current_profile=$(get_current_profile)

  if [[ "$current_profile" == "$profile" && -z "${region:-}" ]]; then
    log_info "Already on profile: $profile"
    return 0
  fi

  log_info "Switching from '$current_profile' to '$profile'"

  # Set environment variables
  set_profile_env "$profile" "$region"

  # Update shell prompt
  update_shell_prompt "$profile"

  # Save preference
  save_profile_preference "$profile" "$region"

  log_success "✅ Successfully switched to profile: $profile"
  show_profile_status "$profile" "$region"

  # Show next steps
  echo ""
  echo "Next steps:"
  echo "  • View environment config: cat $PROFILES_DIR/$profile/config.yml"
  echo "  • Edit secrets: mise run edit-secrets"
  echo "  • Switch back: mise run switch-profile $current_profile"
}

# List available profiles
list_profiles() {
  log_info "Available Profiles:"

  for profile in "${SUPPORTED_PROFILES[@]}"; do
    local current_profile
    current_profile=$(get_current_profile)

    local status="  "
    if [[ "$current_profile" == "$profile" ]]; then
      status="* "
    fi

    local config_status="✓"
    if [[ ! -f "$PROFILES_DIR/$profile/config.yml" ]]; then
      config_status="✗"
    fi

    printf "%s%-12s %s Config: %s\n" "$status" "$profile" "$config_status"

    # List regions if they exist
    local regions_dir="$PROFILES_DIR/$profile/regions"
    if [[ -d "$regions_dir" ]]; then
      while IFS= read -r -d '' region_dir; do
        local region_name
        region_name=$(basename "$region_dir")
        printf "    %-12s Region: $region_name\n" ""
      done < <(find "$regions_dir" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null || true)
    fi
  done
}

# Initialize profile system
init_profile_system() {
  log_info "Initializing profile system"

  # Load existing preference
  if ! load_profile_preference; then
    log_debug "No existing profile preference found"
    export DEPLOYMENT_PROFILE="local"
    export ENVIRONMENT_CONTEXT="development"
  fi

  # Validate current profile
  local current_profile
  current_profile=$(get_current_profile)
  if ! validate_profile "$current_profile"; then
    log_warn "Current profile '$current_profile' is invalid, resetting to local"
    export DEPLOYMENT_PROFILE="local"
    export ENVIRONMENT_CONTEXT="development"
  fi

  log_debug "Profile system initialized"
}

# Main execution
main() {
  local action="${1:-switch}"

  # Check if the first argument is a known action
  if [[ "$action" == "status" || "$action" == "list" || "$action" == "current" || "$action" == "validate" || "$action" == "init" || "$action" == "help" || "$action" == "--help" || "$action" == "-h" || "$action" == "switch" ]]; then
    shift || true
  else
    # If not a known action, assume it's a profile name implies 'switch' action
    # But only if we actually have arguments, otherwise default to 'switch' (which will show usage)
    if [[ -n "$action" ]]; then
      action="switch"
      # Do not shift here, so the profile name remains as $1
    fi
  fi

  # Initialize profile system
  init_profile_system

  case "$action" in
  "switch")
    if [[ $# -lt 1 ]]; then
      log_error "Usage: $0 switch <profile> [region]"
      exit 1
    fi
    switch_profile "$@"
    ;;
  "status")
    show_profile_status "$@"
    ;;
  "list")
    list_profiles
    ;;
  "current")
    get_current_profile
    ;;
  "validate")
    if [[ $# -lt 1 ]]; then
      log_error "Usage: $0 validate <profile>"
      exit 1
    fi
    validate_profile "$1"
    ;;
  "init")
    init_profile_system
    log_success "✅ Profile system initialized"
    ;;
  "help" | "--help" | "-h")
    cat <<EOF
MISE Profile Switcher v$PROFILE_VERSION

Usage: $0 <action> [options]

Actions:
  switch <profile> [region]              Switch to specified profile
  status [profile] [region]              Show current profile status
  list                                   List available profiles
  current                                Get current profile name
  validate <profile>                     Validate profile configuration
  init                                   Initialize profile system
  help                                   Show this help message

Supported Profiles:
  ${SUPPORTED_PROFILES[*]}

Environment Variables:
  DEPLOYMENT_PROFILE                     Current deployment profile
  DEPLOYMENT_REGION                      Current deployment region
  ENVIRONMENT_CONTEXT                    Environment context (development, staging, production)
  UPDATE_SHELL_PROMPT                    Update shell prompt with profile (default: true)

Examples:
  $0 switch staging                       # Switch to staging profile
  $0 switch production us-east           # Switch to production with us-east region
  $0 status                              # Show current status
  $0 list                                # List all profiles
  $0 validate production                 # Validate production profile

Testability Examples:
  CI_TEST_MODE=DRY_RUN $0 switch staging
  CI_PROFILE_SWITCHER_BEHAVIOR=FAIL $0 switch production
EOF
    exit 0
    ;;
  *)
    log_error "Unknown action: $action"
    echo "Use '$0 help' for usage information"
    exit 1
    ;;
  esac
}

# CLI interface
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
