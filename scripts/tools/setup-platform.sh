#!/bin/bash
# Platform Setup Script
# Sets up cross-platform development environment

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_ROOT/../.." && pwd)"
source "$PROJECT_ROOT/scripts/lib/common.sh" 2>/dev/null || {
  echo "Failed to source common utilities" >&2
  exit 1
}

# Configuration
readonly PLATFORM_VERSION="1.0.0"

# Platform detection
detect_platform() {
  local os=""
  local arch=""
  local platform=""

  # Detect OS
  case "$(uname -s)" in
    Linux*)
      os="linux"
      ;;
    Darwin*)
      os="macos"
      ;;
    CYGWIN*|MINGW*|MSYS*)
      os="windows"
      ;;
    *)
      os="unknown"
      ;;
  esac

  # Detect architecture
  case "$(uname -m)" in
    x86_64|amd64)
      arch="x64"
      ;;
    arm64|aarch64)
      arch="arm64"
      ;;
    i386|i686)
      arch="x86"
      ;;
    *)
      arch="unknown"
      ;;
  esac

  platform="${os}-${arch}"
  echo "$platform"
}

# Testability configuration
get_behavior_mode() {
  local script_name="platform_setup"
  get_script_behavior "$script_name" "EXECUTE"
}

# Setup shell integration
setup_shell_integration() {
  local shell="${1:-auto}"
  local behavior
  behavior=$(get_behavior_mode)

  log_info "Setting up shell integration for: $shell"

  case "$behavior" in
    "DRY_RUN")
      echo "🔍 DRY RUN: Would set up shell integration"
      return 0
      ;;
    "PASS")
      log_success "PASS MODE: Shell integration setup simulated successfully"
      return 0
      ;;
    "FAIL")
      log_error "FAIL MODE: Simulating shell integration setup failure"
      return 1
      ;;
    "SKIP")
      log_info "SKIP MODE: Shell integration setup skipped"
      return 0
      ;;
    "TIMEOUT")
      log_info "TIMEOUT MODE: Simulating shell integration setup timeout"
      sleep 2
      return 124
      ;;
  esac

  # EXECUTE mode - Actual shell integration setup
  # Detect current shell if auto
  if [[ "$shell" == "auto" ]]; then
    shell="${SHELL##*/}"
  fi

  case "$shell" in
    "bash"|"zsh"|"fish")
      log_info "Setting up integration for $shell"
      ;;
    *)
      log_warn "Shell integration not supported for: $shell"
      return 0
      ;;
  esac

  # Create shell integration script
  local integration_script="$PROJECT_ROOT/scripts/shell/setup-shell-integration.sh"
  if [[ ! -f "$integration_script" ]]; then
    log_warn "Shell integration script not found: $integration_script"
    return 0
  fi

  # Make script executable
  chmod +x "$integration_script"

  # Add to shell configuration
  local shell_config=""
  local integration_line="source '$PROJECT_ROOT/scripts/shell/setup-shell-integration.sh'"

  case "$shell" in
    "bash")
      shell_config="$HOME/.bashrc"
      if [[ -f "$HOME/.bash_profile" ]]; then
        shell_config="$HOME/.bash_profile"
      fi
      ;;
    "zsh")
      shell_config="$HOME/.zshrc"
      ;;
    "fish")
      shell_config="$HOME/.config/fish/config.fish"
      ;;
  esac

  if [[ -n "$shell_config" && -f "$shell_config" ]]; then
    if ! grep -q "setup-shell-integration.sh" "$shell_config" 2>/dev/null; then
      echo "" >> "$shell_config"
      echo "# CI Pipeline Excellence shell integration" >> "$shell_config"
      echo "$integration_line" >> "$shell_config"
      log_success "✅ Added shell integration to: $shell_config"
    else
      log_info "Shell integration already configured in: $shell_config"
    fi
  fi

  log_success "✅ Shell integration completed"
}

# Setup platform-specific tools
setup_platform_tools() {
  local platform="$1"
  local behavior
  behavior=$(get_behavior_mode)

  log_info "Setting up platform-specific tools for: $platform"

  case "$behavior" in
    "DRY_RUN")
      echo "🔍 DRY RUN: Would set up platform tools for $platform"
      return 0
      ;;
    "PASS")
      log_success "PASS MODE: Platform tools setup simulated successfully"
      return 0
      ;;
    "FAIL")
      log_error "FAIL MODE: Simulating platform tools setup failure"
      return 1
      ;;
    "SKIP")
      log_info "SKIP MODE: Platform tools setup skipped"
      return 0
      ;;
    "TIMEOUT")
      log_info "TIMEOUT MODE: Simulating platform tools setup timeout"
      sleep 3
      return 124
      ;;
  esac

  # EXECUTE mode - Actual platform tools setup
  case "$platform" in
    "linux-x64"|"linux-arm64")
      setup_linux_tools
      ;;
    "macos-x64"|"macos-arm64")
      setup_macos_tools
      ;;
    "windows-x64")
      setup_windows_tools
      ;;
    *)
      log_warn "Unknown platform: $platform"
      return 0
      ;;
  esac

  log_success "✅ Platform tools setup completed"
}

# Setup Linux-specific tools
setup_linux_tools() {
  log_info "Setting up Linux-specific tools"

  # Check for common Linux package managers
  if command -v apt-get >/dev/null 2>&1; then
    log_info "Detected apt-get package manager"
    # Additional Linux-specific setup could go here
  elif command -v yum >/dev/null 2>&1; then
    log_info "Detected yum package manager"
  elif command -v pacman >/dev/null 2>&1; then
    log_info "Detected pacman package manager"
  else
    log_info "No recognized package manager found"
  fi

  # Setup file permissions for scripts
  find "$PROJECT_ROOT/scripts" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

  log_info "Linux setup completed"
}

# Setup macOS-specific tools
setup_macos_tools() {
  log_info "Setting up macOS-specific tools"

  # Check for Homebrew
  if command -v brew >/dev/null 2>&1; then
    log_info "Homebrew detected: $(brew --version | head -1)"
  else
    log_warn "Homebrew not found - consider installing for better tool management"
  fi

  # Setup file permissions for scripts
  find "$PROJECT_ROOT/scripts" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

  log_info "macOS setup completed"
}

# Setup Windows-specific tools
setup_windows_tools() {
  log_info "Setting up Windows-specific tools"

  # Check for Windows Subsystem for Linux
  if [[ -f "/proc/version" ]] && grep -q "Microsoft\|WSL" "/proc/version" 2>/dev/null; then
    log_info "Running under WSL - using Linux setup"
    setup_linux_tools
    return 0
  fi

  # Setup file permissions for scripts (may not work on native Windows)
  if command -v chmod >/dev/null 2>&1; then
    find "$PROJECT_ROOT/scripts" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
  fi

  log_info "Windows setup completed"
}

# Setup environment variables
setup_environment() {
  local behavior
  behavior=$(get_behavior_mode)

  log_info "Setting up environment variables"

  case "$behavior" in
    "DRY_RUN")
      echo "🔍 DRY RUN: Would set up environment variables"
      return 0
      ;;
    "PASS")
      log_success "PASS MODE: Environment setup simulated successfully"
      return 0
      ;;
    "FAIL")
      log_error "FAIL MODE: Simulating environment setup failure"
      return 1
      ;;
    "SKIP")
      log_info "SKIP MODE: Environment setup skipped"
      return 0
      ;;
    "TIMEOUT")
      log_info "TIMEOUT MODE: Simulating environment setup timeout"
      sleep 2
      return 124
      ;;
  esac

  # EXECUTE mode - Actual environment setup
  local env_file="$PROJECT_ROOT/config/.env.local"
  ensure_directory "$(dirname "$env_file")"

  # Create or update .env.local with required variables
  if [[ ! -f "$env_file" ]]; then
    cat > "$env_file" << EOF
# Local environment variables
# Generated by platform setup script
# Created: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

# MISE Configuration
MISE_SOPS_AGE_KEY_FILE=".secrets/mise-age.txt"
SOPS_AGE_KEY_FILE="\$MISE_SOPS_AGE_KEY_FILE"

# Development Environment
DEPLOYMENT_PROFILE="local"
DEPLOYMENT_REGION="us-east"
ENVIRONMENT_CONTEXT="development"

# CI/CD Configuration
CI_JOB_TIMEOUT_MINUTES="30"
CI_TEST_MODE="EXECUTE"

# Platform Detection
PLATFORM_DETECTED=$(detect_platform)
EOF
    log_success "✅ Created environment file: $env_file"
  else
    log_info "Environment file already exists: $env_file"
  fi

  # Set executable permissions on all scripts
  local script_count=0
  while IFS= read -r -d '' script_file; do
    chmod +x "$script_file"
    ((script_count++))
  done < <(find "$PROJECT_ROOT/scripts" -name "*.sh" -print0 2>/dev/null || true)

  log_success "✅ Set executable permissions on $script_count scripts"
}

# Setup git configuration
setup_git_config() {
  local behavior
  behavior=$(get_behavior_mode)

  log_info "Setting up git configuration"

  case "$behavior" in
    "DRY_RUN")
      echo "🔍 DRY RUN: Would set up git configuration"
      return 0
      ;;
    "PASS")
      log_success "PASS MODE: Git configuration simulated successfully"
      return 0
      ;;
    "FAIL")
      log_error "FAIL MODE: Simulating git configuration failure"
      return 1
      ;;
    "SKIP")
      log_info "SKIP MODE: Git configuration skipped"
      return 0
      ;;
    "TIMEOUT")
      log_info "TIMEOUT MODE: Simulating git configuration timeout"
      sleep 2
      return 124
      ;;
  esac

  # EXECUTE mode - Actual git configuration
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    log_warn "Not in a git repository, skipping git configuration"
    return 0
  fi

  # Set safe directory for git
  local project_root_safe
  project_root_safe=$(cd "$PROJECT_ROOT" && pwd)
  git config --global safe.directory "$project_root_safe" 2>/dev/null || true

  # Configure git attributes if not set
  if [[ ! -f "$PROJECT_ROOT/.gitattributes" ]]; then
    cat > "$PROJECT_ROOT/.gitattributes" << EOF
# Git attributes for CI/CD pipeline

# Handle line endings
* text=auto eol=lf
*.sh text eol=lf
*.yml text eol=lf
*.yaml text eol=lf
*.json text eol=lf
*.md text eol=lf

# Binary files
*.png binary
*.jpg binary
*.jpeg binary
*.gif binary
*.ico binary
*.zip binary
*.tar.gz binary

# No LFS tracking
*.enc filter=lfs diff=lfs merge=lfs -text
secrets.* filter=lfs diff=lfs merge=lfs -text
EOF
    log_success "✅ Created .gitattributes file"
  else
    log_info ".gitattributes already exists"
  fi

  log_success "✅ Git configuration completed"
}

# Validate platform setup
validate_setup() {
  log_info "Validating platform setup"

  local platform
  platform=$(detect_platform)
  log_info "Detected platform: $platform"

  # Check if scripts are executable
  local non_executable_count=0
  while IFS= read -r -d '' script_file; do
    if [[ ! -x "$script_file" ]]; then
      log_warn "Script not executable: $script_file"
      ((non_executable_count++))
    fi
  done < <(find "$PROJECT_ROOT/scripts" -name "*.sh" -print0 2>/dev/null || true)

  if [[ $non_executable_count -eq 0 ]]; then
    log_success "✅ All scripts have executable permissions"
  else
    log_error "❌ $non_executable_count scripts are not executable"
    return 1
  fi

  # Check environment file
  local env_file="$PROJECT_ROOT/config/.env.local"
  if [[ -f "$env_file" ]]; then
    log_success "✅ Environment file exists: $env_file"
  else
    log_warn "Environment file not found: $env_file"
  fi

  # Check git configuration
  if git rev-parse --git-dir >/dev/null 2>&1; then
    if [[ -f "$PROJECT_ROOT/.gitattributes" ]]; then
      log_success "✅ Git attributes configured"
    else
      log_warn "Git attributes not configured"
    fi
  fi

  log_success "✅ Platform setup validation completed"
}

# Main execution
main() {
  local scope="${1:-all}"

  log_info "Platform Setup Script v$PLATFORM_VERSION"

  # Detect platform
  local platform
  platform=$(detect_platform)
  log_info "Platform detected: $platform"

  case "$scope" in
    "tools")
      setup_platform_tools "$platform"
      ;;
    "shell")
      setup_shell_integration "auto"
      ;;
    "env")
      setup_environment
      ;;
    "git")
      setup_git_config
      ;;
    "validate")
      validate_setup
      ;;
    "all")
      setup_platform_tools "$platform"
      setup_shell_integration "auto"
      setup_environment
      setup_git_config
      validate_setup
      ;;
    "help"|"--help"|"-h")
      cat << EOF
Platform Setup Script v$PLATFORM_VERSION

Usage: $0 <scope>

Scopes:
  tools                                   Setup platform-specific tools
  shell                                  Setup shell integration
  env                                    Setup environment variables
  git                                    Setup git configuration
  validate                               Validate platform setup
  all                                    Setup everything (default)

Supported Platforms:
  - linux-x64, linux-arm64
  - macos-x64, macos-arm64
  - windows-x64 (via WSL)

Examples:
  $0                                     # Setup everything
  $0 tools                               # Setup platform tools only
  $0 shell                               # Setup shell integration only

Testability Examples:
  CI_TEST_MODE=DRY_RUN $0
  CI_PLATFORM_SETUP_BEHAVIOR=FAIL $0 tools
EOF
      exit 0
      ;;
    *)
      log_error "Unknown scope: $scope"
      echo "Use '$0 help' for usage information"
      exit 1
      ;;
  esac

  log_success "✅ Platform setup completed successfully"
  echo ""
  echo "Next steps:"
  echo "  • Install tools: mise install"
  echo "  • Generate age key: mise run generate-age-key"
  echo "  • Initialize secrets: mise run secrets-init local"
  echo "  • Verify setup: mise run verify-tools"
}

# CLI interface
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi