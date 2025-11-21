#!/usr/bin/env bash
# CI Dependencies Installation Script
# Installs project dependencies with testability support

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

# Get script and pipeline names for testability
SCRIPT_NAME=$(get_script_name "$0")
PIPELINE_NAME=$(get_pipeline_name)
MODE=$(resolve_test_mode "$SCRIPT_NAME" "$PIPELINE_NAME)

log_test_mode_source "$SCRIPT_NAME" "$PIPELINE_NAME" "$MODE"

# Execute based on test mode
case "$MODE" in
  DRY_RUN)
    log_info "Dry run: would install project dependencies"
    echo "[DRY_RUN] Would execute: mise install"
    echo "[DRY_RUN] Would execute: npm ci (if package.json exists)"
    echo "[DRY_RUN] Would execute: mise run install-hooks (if available)"
    exit 0
    ;;
  PASS)
    log_info "Simulated dependency installation success"
    exit 0
    ;;
  FAIL)
    log_error "Simulated dependency installation failure"
    exit 1
    ;;
  SKIP)
    log_info "Skipping dependency installation"
    exit 0
    ;;
  TIMEOUT)
    log_warning "Simulating dependency installation timeout"
    sleep infinity
    ;;
  EXECUTE)
    log_info "Installing project dependencies"
    ;;
  *)
    log_error "Unknown test mode: $MODE"
    exit 1
    ;;
esac

# Function to install MISE dependencies
install_mise_deps() {
  log_info "Installing MISE dependencies"

  if ! command -v mise >/dev/null 2>&1; then
    log_error "MISE is not available"
    return 1
  fi

  if mise install; then
    log_success "MISE dependencies installed successfully"
  else
    log_error "Failed to install MISE dependencies"
    return 1
  fi
}

# Function to install Node.js dependencies
install_node_deps() {
  local project_root="${1:-.}"

  if [[ ! -f "${project_root}/package.json" ]]; then
    log_info "No package.json found, skipping Node.js dependency installation"
    return 0
  fi

  log_info "Installing Node.js dependencies"

  # Check if npm lock file exists
  if [[ -f "${project_root}/package-lock.json" ]]; then
    log_command "npm ci"
  else
    log_warning "No package-lock.json found, using npm install"
    log_command "npm install"
  fi

  # Verify installation
  if [[ -d "${project_root}/node_modules" ]]; then
    local package_count
    package_count=$(find "${project_root}/node_modules" -maxdepth 1 -type d | wc -l)
    log_success "Node.js dependencies installed ($((package_count - 1)) packages)"
  else
    log_error "Node.js dependencies installation failed"
    return 1
  fi
}

# Function to install Python dependencies
install_python_deps() {
  local project_root="${1:-.}"

  if [[ -f "${project_root}/requirements.txt" ]]; then
    log_info "Installing Python dependencies from requirements.txt"
    log_command "pip install -r requirements.txt"
  elif [[ -f "${project_root}/pyproject.toml" ]]; then
    log_info "Installing Python dependencies from pyproject.toml"
    log_command "pip install ."
  else
    log_info "No Python dependency files found, skipping Python dependencies"
    return 0
  fi

  log_success "Python dependencies installed successfully"
}

# Function to install Go dependencies
install_go_deps() {
  local project_root="${1:-.}"

  if [[ -f "${project_root}/go.mod" ]]; then
    log_info "Installing Go dependencies"
    cd "$project_root"
    log_command "go mod download"
    log_command "go mod verify"
    cd - >/dev/null
    log_success "Go dependencies installed successfully"
  else
    log_info "No go.mod found, skipping Go dependencies"
    return 0
  fi
}

# Function to install Rust dependencies
install_rust_deps() {
  local project_root="${1:-.}"

  if [[ -f "${project_root}/Cargo.toml" ]]; then
    log_info "Installing Rust dependencies"
    cd "$project_root"
    log_command "cargo fetch"
    cd - >/dev/null
    log_success "Rust dependencies installed successfully"
  else
    log_info "No Cargo.toml found, skipping Rust dependencies"
    return 0
  fi
}

# Function to install git hooks
install_git_hooks() {
  log_info "Installing git hooks"

  if command -v mise >/dev/null 2>&1 && mise run --help | grep -q "install-hooks"; then
    log_command "mise run install-hooks"
  elif command -v lefthook >/dev/null 2>&1; then
    log_command "lefthook install"
  else
    log_warning "No git hook manager available, skipping hook installation"
    return 0
  fi

  log_success "Git hooks installed successfully"
}

# Function to validate environment
validate_environment() {
  log_info "Validating development environment"

  local validation_errors=0

  # Check required tools
  local required_tools=("git" "bash")
  for tool in "${required_tools[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      log_error "Required tool not found: $tool"
      ((validation_errors++))
    fi
  done

  # Check recommended tools
  local recommended_tools=("mise" "node" "npm")
  for tool in "${recommended_tools[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      log_warning "Recommended tool not found: $tool"
    fi
  done

  # Check git configuration
  if ! git config user.name >/dev/null 2>&1 || ! git config user.email >/dev/null 2>&1; then
    log_warning "Git user configuration not found"
    log_warning "Run: git config --global user.name 'Your Name' && git config --global user.email 'your.email@example.com'"
  fi

  if [[ $validation_errors -eq 0 ]]; then
    log_success "Environment validation passed"
  else
    log_error "Environment validation failed with $validation_errors error(s)"
    return 1
  fi
}

# Main installation process
main() {
  local start_time
  start_time=$(date +%s)

  log_info "Starting dependency installation"

  # Validate environment first
  validate_environment

  # Install MISE dependencies (includes tools like SOPS, shellcheck, etc.)
  install_mise_deps

  # Install language-specific dependencies
  install_node_deps
  install_python_deps
  install_go_deps
  install_rust_deps

  # Install git hooks
  install_git_hooks

  # Calculate installation time
  local end_time
  end_time=$(date +%s)
  local duration=$((end_time - start_time))

  log_success "Dependency installation completed in $(format_duration "$duration")"
}

# Execute main function
main