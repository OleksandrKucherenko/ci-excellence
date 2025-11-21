#!/bin/bash
# Tool Verification Script
# Verifies that all required tools are installed and correctly configured

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$PROJECT_ROOT/scripts/lib/config.sh" 2>/dev/null || {
  echo "Failed to source configuration utilities" >&2
  exit 1
}

# Configuration
readonly TOOLS_VERSION="1.0.0"

# Define required tools with minimum versions
declare -A REQUIRED_TOOLS=(
  ["age"]="latest"
  ["sops"]="latest"
  ["gitleaks"]="latest"
  ["trufflehog"]="latest"
  ["lefthook"]="latest"
  ["commitizen"]="latest"
  ["shellspec"]="latest"
  ["shellcheck"]="latest"
  ["shfmt"]="latest"
  ["act"]="latest"
  ["bun"]="latest"
  ["node"]="lts/*"
)

# Testability configuration
get_behavior_mode() {
  local script_name="tools_verification"
  get_script_behavior "$script_name" "EXECUTE"
}

# Check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Get tool version
get_tool_version() {
  local tool="$1"
  local version_output=""

  case "$tool" in
    "age")
      version_output=$(age -version 2>/dev/null | head -1 || echo "unknown")
      ;;
    "sops")
      version_output=$(sops --version 2>/dev/null | head -1 || echo "unknown")
      ;;
    "gitleaks")
      version_output=$(gitleaks version 2>/dev/null | head -1 || echo "unknown")
      ;;
    "trufflehog")
      version_output=$(trufflehog --version 2>/dev/null | head -1 || echo "unknown")
      ;;
    "lefthook")
      version_output=$(lefthook version 2>/dev/null | head -1 || echo "unknown")
      ;;
    "commitizen")
      version_output=$(cz --version 2>/dev/null | head -1 || echo "unknown")
      ;;
    "shellspec")
      version_output=$(shellspec --version 2>/dev/null | head -1 || echo "unknown")
      ;;
    "shellcheck")
      version_output=$(shellcheck --version 2>/dev/null | head -1 || echo "unknown")
      ;;
    "shfmt")
      version_output=$(shfmt --version 2>/dev/null | head -1 || echo "unknown")
      ;;
    "act")
      version_output=$(act --version 2>/dev/null | head -1 || echo "unknown")
      ;;
    "bun")
      version_output=$(bun --version 2>/dev/null | head -1 || echo "unknown")
      ;;
    "node")
      version_output=$(node --version 2>/dev/null | head -1 || echo "unknown")
      ;;
    *)
      version_output=$(timeout 5 "$tool" --version 2>/dev/null | head -1 || echo "unknown")
      ;;
  esac

  echo "$version_output"
}

# Compare versions (simple comparison)
version_compare() {
  local installed="$1"
  local required="$2"

  # Handle "latest" requirement
  if [[ "$required" == "latest" ]]; then
    return 0  # Assume any version is acceptable for "latest"
  fi

  # Handle LTS requirements
  if [[ "$required" == "lts/*" ]]; then
    # Basic check if it looks like a Node.js LTS version
    if [[ "$installed" =~ v[0-9]+\.[0-9]+\.[0-9]+ ]]; then
      local major
      major=$(echo "$installed" | sed 's/^v//' | cut -d'.' -f1)
      # Node.js LTS versions are even numbers (18, 20, etc.)
      if [[ $((major % 2)) -eq 0 && $major -ge 18 ]]; then
        return 0
      fi
    fi
    return 1
  fi

  # For specific versions, do basic comparison
  # This is simplified - real implementation would use semantic versioning
  if [[ -n "$installed" && "$installed" != "unknown" ]]; then
    return 0
  else
    return 1
  fi
}

# Verify single tool
verify_tool() {
  local tool="$1"
  local required_version="${REQUIRED_TOOLS[$tool]}"
  local behavior
  behavior=$(get_behavior_mode)

  log_info "Verifying tool: $tool"

  case "$behavior" in
    "DRY_RUN")
      echo "🔍 DRY RUN: Would verify $tool"
      return 0
      ;;
    "PASS")
      log_success "PASS MODE: Tool verification simulated successfully"
      return 0
      ;;
    "FAIL")
      log_error "FAIL MODE: Simulating tool verification failure"
      return 1
      ;;
    "SKIP")
      log_info "SKIP MODE: Tool verification skipped"
      return 0
      ;;
    "TIMEOUT")
      log_info "TIMEOUT MODE: Simulating tool verification timeout"
      sleep 2
      return 124
      ;;
  esac

  # EXECUTE mode - Actual verification
  if ! command_exists "$tool"; then
    log_error "❌ Tool not found: $tool"
    return 1
  fi

  local installed_version
  installed_version=$(get_tool_version "$tool")

  if version_compare "$installed_version" "$required_version"; then
    log_success "✅ $tool: $installed_version"
    return 0
  else
    log_error "❌ $tool: $installed_version (required: $required_version)"
    return 1
  fi
}

# Verify all tools
verify_all_tools() {
  log_info "Verifying all required tools"

  local behavior
  behavior=$(get_behavior_mode)

  if [[ "$behavior" == "DRY_RUN" ]]; then
    echo "🔍 DRY RUN: Would verify all required tools"
    return 0
  fi

  local failed_count=0
  local total_count=${#REQUIRED_TOOLS[@]}

  echo ""
  echo "🔧 Tool Verification Report:"
  printf "%-15s %-20s %s\n" "Tool" "Version" "Status"
  printf "%-15s %-20s %s\n" "----" "-------" "------"

  for tool in "${!REQUIRED_TOOLS[@]}"; do
    local required_version="${REQUIRED_TOOLS[$tool]}"
    local status="❌"
    local version="Not found"

    if command_exists "$tool"; then
      version=$(get_tool_version "$tool")
      if version_compare "$version" "$required_version"; then
        status="✅"
        ((total_found++))
      else
        ((failed_count++))
      fi
    else
      ((failed_count++))
    fi

    printf "%-15s %-20s %s\n" "$tool" "$version" "$status"
  done

  echo ""

  if [[ $failed_count -eq 0 ]]; then
    log_success "✅ All required tools are installed and verified"
    return 0
  else
    log_error "❌ $failed_count tools failed verification"
    echo ""
    echo "To install missing tools:"
    echo "  mise install"
    echo ""
    echo "To update tools:"
    echo "  mise install tool@latest"
    return 1
  fi
}

# Verify configuration files
verify_configurations() {
  log_info "Verifying configuration files"

  local failed_count=0

  echo ""
  echo "📁 Configuration File Verification:"
  printf "%-30s %s\n" "Configuration File" "Status"
  printf "%-30s %s\n" "-------------------" "------"

  local configs=(
    "$PROJECT_ROOT/mise.toml:MISE configuration"
    "$PROJECT_ROOT/.sops.yaml:SOPS configuration"
    "$PROJECT_ROOT/.lefthook.yml:Lefthook configuration"
    "$PROJECT_ROOT/commitizen.json:Commitizen configuration"
    "$PROJECT_ROOT/.shellspec.toml:ShellSpec configuration"
    "$PROJECT_ROOT/.shfmt.toml:ShellFormat configuration"
    "$PROJECT_ROOT/.shellcheckrc:ShellCheck configuration"
  )

  for config_entry in "${configs[@]}"; do
    local config_file="${config_entry%:*}"
    local config_desc="${config_entry#*:}"
    local status="❌"

    if [[ -f "$config_file" ]]; then
      status="✅"
    else
      ((failed_count++))
    fi

    printf "%-30s %s\n" "$config_desc" "$status"
  done

  echo ""

  if [[ $failed_count -eq 0 ]]; then
    log_success "✅ All configuration files are present"
  else
    log_error "❌ $failed_count configuration files are missing"
    return 1
  fi
}

# Verify environment setup
verify_environment() {
  log_info "Verifying environment setup"

  local failed_count=0

  echo ""
  echo "🌍 Environment Verification:"
  printf "%-25s %s\n" "Environment Variable" "Status"
  printf "%-25s %s\n" "------------------" "------"

  local env_vars=(
    "MISE_SOPS_AGE_KEY_FILE"
    "SOPS_AGE_KEY_FILE"
    "DEPLOYMENT_PROFILE"
  )

  for var in "${env_vars[@]}"; do
    local status="❌"
    local value="${!var:-}"

    if [[ -n "$value" ]]; then
      status="✅"
    else
      ((failed_count++))
    fi

    printf "%-25s %s\n" "$var" "$status"
  done

  # Verify age key file
  local age_key_file
  age_key_file=$(get_age_key_file)
  local key_status="❌"

  if [[ -f "$age_key_file" ]]; then
    key_status="✅"
  else
    ((failed_count++))
  fi

  printf "%-25s %s\n" "Age Key File" "$key_status"

  echo ""

  if [[ $failed_count -eq 0 ]]; then
    log_success "✅ Environment setup is verified"
  else
    log_error "❌ $failed_count environment issues found"
    return 1
  fi
}

# Show tool recommendations
show_recommendations() {
  echo ""
  echo "💡 Recommendations:"
  echo ""
  echo "• Keep tools updated with: mise install tool@latest"
  echo "• Use mise run verify-tools for regular verification"
  echo "• Check tool documentation for best practices"
  echo "• Monitor tool versions for security updates"
  echo ""
  echo "Common issues and solutions:"
  echo "• Tool not found: Run 'mise install'"
  echo "• Version mismatch: Run 'mise install tool@latest'"
  echo "• Permission denied: Check tool installation and PATH"
  echo "• Configuration missing: Re-run project setup"
}

# Main execution
main() {
  local scope="${1:-all}"

  log_info "Tool Verification Script v$TOOLS_VERSION"

  case "$scope" in
    "tools")
      verify_all_tools
      ;;
    "config")
      verify_configurations
      ;;
    "env")
      verify_environment
      ;;
    "all")
      local overall_success=true

      if ! verify_all_tools; then
        overall_success=false
      fi

      if ! verify_configurations; then
        overall_success=false
      fi

      if ! verify_environment; then
        overall_success=false
      fi

      if [[ "$overall_success" == "true" ]]; then
        log_success "✅ All verifications passed successfully"
      else
        log_error "❌ Some verifications failed"
        return 1
      fi
      ;;
    "help"|"--help"|"-h")
      cat << EOF
Tool Verification Script v$TOOLS_VERSION

Usage: $0 <scope>

Scopes:
  tools                                   Verify required tools only
  config                                 Verify configuration files only
  env                                    Verify environment setup only
  all                                    Verify everything (default)

Required Tools:
${!REQUIRED_TOOLS[*]}

Configuration Files:
  - mise.toml
  - .sops.yaml
  - .lefthook.yml
  - commitizen.json
  - .shellspec.toml
  - .shfmt.toml
  - .shellcheckrc

Examples:
  $0                                     # Verify everything
  $0 tools                               # Verify tools only
  $0 config                              # Verify configuration only

Testability Examples:
  CI_TEST_MODE=DRY_RUN $0
  CI_TOOLS_VERIFICATION_BEHAVIOR=FAIL $0
EOF
      exit 0
      ;;
    *)
      log_error "Unknown scope: $scope"
      echo "Use '$0 help' for usage information"
      exit 1
      ;;
  esac

  # Show recommendations for all successful runs
  if [[ $? -eq 0 ]]; then
    show_recommendations
  fi
}

# CLI interface
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi