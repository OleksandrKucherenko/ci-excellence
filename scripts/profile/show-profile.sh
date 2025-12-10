#!/bin/bash
# Profile Status Display
# Shows current deployment profile status and configuration

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/scripts/lib/common.sh" 2>/dev/null || {
  echo "Failed to source common utilities" >&2
  exit 1
}

# Configuration
readonly PROFILE_STATUS_VERSION="1.0.0"
readonly PROFILES_DIR="$PROJECT_ROOT/environments"
readonly SUPPORTED_PROFILES=("local" "staging" "production" "canary" "sandbox" "performance")

# Testability configuration
get_behavior_mode() {
  local script_name="profile_status"
  get_script_behavior "$script_name" "EXECUTE"
}

# Get current profile information
get_profile_info() {
  local profile="${1:-}"
  local region="${2:-}"

  # Use current profile if not specified
  if [[ -z "$profile" ]]; then
    profile=$(get_env_var "DEPLOYMENT_PROFILE" "local")
  fi

  # Use current region if not specified
  if [[ -z "$region" ]]; then
    region=$(get_env_var "DEPLOYMENT_REGION" "")
  fi

  echo "$profile:$region"
}

# Show comprehensive profile status
show_profile_status() {
  local profile="${1:-}"
  local region="${2:-}"
  local detailed="${3:-true}"

  local behavior
  behavior=$(get_behavior_mode)

  case "$behavior" in
  "DRY_RUN")
    echo "🔍 DRY RUN: Would show profile status"
    return 0
    ;;
  "PASS")
    log_success "PASS MODE: Profile status displayed successfully"
    return 0
    ;;
  "FAIL")
    log_error "FAIL MODE: Simulating profile status display failure"
    return 1
    ;;
  "SKIP")
    log_info "SKIP MODE: Profile status display skipped"
    return 0
    ;;
  "TIMEOUT")
    log_info "TIMEOUT MODE: Simulating profile status display timeout"
    sleep 3
    return 124
    ;;
  esac

  # EXECUTE mode - Show actual status
  local profile_info
  profile_info=$(get_profile_info "$profile" "$region")
  IFS=':' read -r current_profile current_region <<<"$profile_info"

  log_info "🔍 Deployment Profile Status"
  echo ""

  # Basic profile information
  echo "📋 Profile Information:"
  printf "  %-25s %s\n" "Current Profile:" "$current_profile"
  printf "  %-25s %s\n" "Environment Context:" "${ENVIRONMENT_CONTEXT:-unknown}"
  printf "  %-25s %s\n" "Deployment Region:" "${current_region:-default (global)}"
  printf "  %-25s %s\n" "Configuration Root:" "$PROFILES_DIR"
  echo ""

  # Profile directory status
  echo "📁 Directory Structure:"
  local profile_dir="$PROFILES_DIR/$current_profile"
  if [[ -d "$profile_dir" ]]; then
    printf "  %-25s %s\n" "Profile Directory:" "✅ $profile_dir"

    # List subdirectories
    local subdirs=()
    while IFS= read -r -d '' subdir; do
      subdirs+=("$(basename "$subdir")")
    done < <(find "$profile_dir" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null || true)

    if [[ ${#subdirs[@]} -gt 0 ]]; then
      printf "  %-25s %s\n" "Subdirectories:" "$(
        IFS=', '
        echo "${subdirs[*]}"
      )"
    fi
  else
    printf "  %-25s %s\n" "Profile Directory:" "❌ Not found: $profile_dir"
  fi
  echo ""

  # Configuration files
  echo "⚙️ Configuration Files:"
  local config_file="$profile_dir/config.yml"
  if [[ -f "$config_file" ]]; then
    printf "  %-25s %s\n" "Main Config:" "✅ $config_file"

    if [[ "$detailed" == "true" ]]; then
      echo "    Configuration Preview:"
      if command -v yq >/dev/null 2>&1; then
        yq '.' "$config_file" 2>/dev/null | head -15 | sed 's/^/      /' || echo "      Unable to parse YAML"
      else
        head -10 "$config_file" 2>/dev/null | sed 's/^/      /' || echo "      Unable to read file"
      fi
      echo ""
    fi
  else
    printf "  %-25s %s\n" "Main Config:" "❌ Not found"
  fi

  local secrets_file="$profile_dir/secrets.enc"
  if [[ -f "$secrets_file" ]]; then
    printf "  %-25s %s\n" "Secrets File:" "🔒 $secrets_file"

    if [[ "$detailed" == "true" ]]; then
      # Check if we can decrypt it
      if command -v sops >/dev/null 2>&1 && [[ -f "$PROJECT_ROOT/.secrets/mise-age.txt" ]]; then
        local secret_count
        secret_count=$(sops --decrypt "$secrets_file" 2>/dev/null | grep -c "^[A-Za-z_][A-Za-z0-9_]*=" || echo "unknown")
        printf "  %-25s %s\n" "Secret Entries:" "$secret_count"
      else
        printf "  %-25s %s\n" "Secret Status:" "Encrypted (key not available)"
      fi
    fi
  else
    printf "  %-25s %s\n" "Secrets File:" "❌ Not found"
  fi
  echo ""

  # Region configuration
  if [[ -n "$current_region" ]]; then
    echo "🌍 Region Configuration:"
    local region_dir="$profile_dir/regions/$current_region"
    if [[ -d "$region_dir" ]]; then
      printf "  %-25s %s\n" "Region Directory:" "✅ $region_dir"

      local region_config_file="$region_dir/config.yml"
      if [[ -f "$region_config_file" ]]; then
        printf "  %-25s %s\n" "Region Config:" "✅ $region_config_file"

        if [[ "$detailed" == "true" ]]; then
          echo "    Region Config Preview:"
          if command -v yq >/dev/null 2>&1; then
            yq '.' "$region_config_file" 2>/dev/null | head -10 | sed 's/^/      /' || echo "      Unable to parse YAML"
          else
            head -10 "$region_config_file" 2>/dev/null | sed 's/^/      /' || echo "      Unable to read file"
          fi
          echo ""
        fi
      else
        printf "  %-25s %s\n" "Region Config:" "❌ Not found"
      fi
    else
      printf "  %-25s %s\n" "Region Directory:" "❌ Not found: $region_dir"
    fi
    echo ""
  fi

  # Environment variables
  echo "🔧 Environment Variables:"
  local env_vars=("DEPLOYMENT_PROFILE" "DEPLOYMENT_REGION" "ENVIRONMENT_CONTEXT" "CI_JOB_TIMEOUT_MINUTES" "CI_TEST_MODE")
  for var in "${env_vars[@]}"; do
    local value="${!var:-}"
    if [[ -n "$value" ]]; then
      printf "  %-25s %s\n" "$var:" "$value"
    else
      printf "  %-25s %s\n" "$var:" "(not set)"
    fi
  done
  echo ""

  # Available regions for this profile
  if [[ "$detailed" == "true" && -d "$profile_dir/regions" ]]; then
    echo "🗺️ Available Regions:"
    local regions=()
    while IFS= read -r -d '' region_dir; do
      regions+=("$(basename "$region_dir")")
    done < <(find "$profile_dir/regions" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null || true)

    if [[ ${#regions[@]} -gt 0 ]]; then
      for region in "${regions[@]}"; do
        local region_config_file="$profile_dir/regions/$region/config.yml"
        local status="✓"
        [[ ! -f "$region_config_file" ]] && status="✗"
        printf "  %-3s %-20s %s\n" "$status" "$region" "$([[ -f "$region_config_file" ]] && echo "has config" || echo "no config")"
      done
    else
      echo "  No regions configured"
    fi
    echo ""
  fi

  # Quick actions
  echo "⚡ Quick Actions:"
  printf "  %-30s %s\n" "Switch profile:" "mise run switch-profile <profile>"
  printf "  %-30s %s\n" "Edit secrets:" "mise run edit-secrets"
  printf "  %-30s %s\n" "List profiles:" "mise run switch-profile list"
  printf "  %-30s %s\n" "Validate tools:" "mise run verify-tools"
  echo ""

  # Show shell integration if available
  if [[ -f "$PROJECT_ROOT/scripts/shell/mise-profile.plugin.zsh" ]]; then
    echo "🐚 Shell Integration:"
    echo "  ZSH plugin available: scripts/shell/mise-profile.plugin.zsh"
    echo "  Commands: mise_switch <profile>, mise_profile_status"
    echo ""
  fi
}

# Show summary status (compact)
show_summary_status() {
  local profile="${1:-}"
  local region="${2:-}"

  local profile_info
  profile_info=$(get_profile_info "$profile" "$region")
  IFS=':' read -r current_profile current_region <<<"$profile_info"

  # Build status line
  local status_line="["
  status_line+="$current_profile"

  if [[ -n "$current_region" ]]; then
    status_line+="|$current_region"
  fi

  status_line+="]"

  # Add environment context
  local context="${ENVIRONMENT_CONTEXT:-unknown}"
  status_line+=" ($context)"

  # Add file status indicators
  local profile_dir="$PROFILES_DIR/$current_profile"
  local config_status="✗"
  local secrets_status="✗"

  [[ -f "$profile_dir/config.yml" ]] && config_status="✓"
  [[ -f "$profile_dir/secrets.enc" ]] && secrets_status="🔒"

  status_line+=" Config:$config_status Secrets:$secrets_status"

  echo "$status_line"
}

# Validate profile configuration
validate_profile() {
  local profile="${1:-}"

  if [[ -z "$profile" ]]; then
    profile=$(get_env_var "DEPLOYMENT_PROFILE" "local")
  fi

  log_info "Validating profile configuration: $profile"

  local issues=0

  # Check if profile directory exists
  local profile_dir="$PROFILES_DIR/$profile"
  if [[ ! -d "$profile_dir" ]]; then
    log_error "Profile directory not found: $profile_dir"
    ((issues++))
  fi

  # Check config file
  local config_file="$profile_dir/config.yml"
  if [[ ! -f "$config_file" ]]; then
    log_error "Config file not found: $config_file"
    ((issues++))
  else
    # Validate YAML syntax
    if command -v yamllint >/dev/null 2>&1; then
      if ! yamllint -d relaxed "$config_file" >/dev/null 2>&1; then
        log_error "Config file has YAML syntax errors: $config_file"
        ((issues++))
      fi
    fi
  fi

  # Check secrets file
  local secrets_file="$profile_dir/secrets.enc"
  if [[ ! -f "$secrets_file" ]]; then
    log_warn "Secrets file not found: $secrets_file"
  fi

  # Check environment variables
  if [[ -z "${DEPLOYMENT_PROFILE:-}" ]]; then
    log_error "DEPLOYMENT_PROFILE environment variable not set"
    ((issues++))
  fi

  if [[ "$profile" != "local" && -z "${ENVIRONMENT_CONTEXT:-}" ]]; then
    log_error "ENVIRONMENT_CONTEXT environment variable not set"
    ((issues++))
  fi

  if [[ $issues -eq 0 ]]; then
    log_success "✅ Profile configuration is valid: $profile"
    return 0
  else
    log_error "❌ Profile configuration has $issues issues: $profile"
    return 1
  fi
}

# Main execution
main() {
  local action="${1:-status}"
  shift || true

  case "$action" in
  "status")
    show_profile_status "$@"
    ;;
  "summary")
    show_summary_status "$@"
    ;;
  "validate")
    validate_profile "$@"
    ;;
  "config")
    if [[ $# -lt 1 ]]; then
      log_error "Usage: $0 config <profile>"
      exit 1
    fi
    show_profile_status "$1" "${2:-}" "true"
    ;;
  "help" | "--help" | "-h")
    cat <<EOF
Profile Status Display v$PROFILE_STATUS_VERSION

Usage: $0 <action> [options]

Actions:
  status [profile] [region]              Show detailed profile status (default)
  summary [profile] [region]             Show compact profile summary
  validate [profile]                     Validate profile configuration
  config <profile> [region]              Show profile configuration only
  help                                   Show this help message

Examples:
  $0                                     # Show current status
  $0 status production                   # Show production status
  $0 summary                             # Show compact summary
  $0 validate staging                    # Validate staging profile
  $0 config production us-east           # Show production config with region

Testability Examples:
  CI_TEST_MODE=DRY_RUN $0 status
  CI_PROFILE_STATUS_BEHAVIOR=FAIL $0 validate
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
