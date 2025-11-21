#!/usr/bin/env bash
# CI Environment Validation Script
# Validates environment configuration and prerequisites with testability support

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

# shellcheck source=../lib/secret-utils.sh
source "${SCRIPT_DIR}/../lib/secret-utils.sh"

# Get script and pipeline names for testability
SCRIPT_NAME=$(get_script_name "$0")
PIPELINE_NAME=$(get_pipeline_name)
MODE=$(resolve_test_mode "$SCRIPT_NAME" "$PIPELINE_NAME")

log_test_mode_source "$SCRIPT_NAME" "$PIPELINE_NAME" "$MODE"

# Execute based on test mode
case "$MODE" in
  DRY_RUN)
    log_info "Dry run: would validate environment configuration"
    echo "[DRY_RUN] Would execute: validate_environment_config staging"
    echo "[DRY_RUN] Would execute: check_sops_age_key"
    echo "[DRY_RUN] Would execute: validate_git_configuration"
    exit 0
    ;;
  PASS)
    log_info "Simulated environment validation success"
    exit 0
    ;;
  FAIL)
    log_error "Simulated environment validation failure"
    exit 1
    ;;
  SKIP)
    log_info "Skipping environment validation"
    exit 0
    ;;
  TIMEOUT)
    log_warning "Simulating environment validation timeout"
    sleep infinity
    ;;
  EXECUTE)
    log_info "Validating environment configuration"
    ;;
  *)
    log_error "Unknown test mode: $MODE"
    exit 1
    ;;
esac

# Function to validate environment configuration
validate_environment_config() {
  local environment="${1:-staging}"

  log_info "Validating environment configuration for: $environment"

  if validate_environment_config "$environment"; then
    log_success "Environment configuration is valid: $environment"
  else
    log_error "Environment configuration validation failed: $environment"
    return 1
  fi
}

# Function to validate SOPS and age key setup
validate_sops_setup() {
  log_info "Validating SOPS and age key setup"

  if check_sops_age_key; then
    log_success "SOPS age key validation passed"
  else
    log_error "SOPS age key validation failed"
    return 1
  fi

  # Test SOPS functionality
  local test_content="test: value"
  local test_file="/tmp/sops-test.yml"

  echo "$test_content" > "$test_file"

  if command -v sops >/dev/null 2>&1; then
    if sops --encrypt --input-type yaml --output-type yaml "$test_file" > /dev/null 2>&1; then
      log_success "SOPS encryption test passed"
    else
      log_error "SOPS encryption test failed"
      rm -f "$test_file"
      return 1
    fi
  else
    log_error "SOPS not available"
    rm -f "$test_file"
    return 1
  fi

  rm -f "$test_file"
}

# Function to validate git configuration
validate_git_configuration() {
  log_info "Validating git configuration"

  local validation_errors=0

  # Check if we're in a git repository
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    log_error "Not in a git repository"
    ((validation_errors++))
  fi

  # Check git user configuration
  if ! git config user.name >/dev/null 2>&1; then
    log_error "Git user.name not configured"
    ((validation_errors++))
  fi

  if ! git config user.email >/dev/null 2>&1; then
    log_error "Git user.email not configured"
    ((validation_errors++))
  fi

  # Check for proper git remotes
  local remote_count
  remote_count=$(git remote | wc -l)
  if [[ $remote_count -eq 0 ]]; then
    log_warning "No git remotes configured"
  fi

  # Check git hooks
  local hooks_dir
  hooks_dir=$(git rev-parse --git-dir)/hooks
  if [[ -d "$hooks_dir" ]]; then
    local hook_count
    hook_count=$(find "$hooks_dir" -type f -executable | wc -l)
    log_info "Found $hook_count git hooks"
  fi

  if [[ $validation_errors -eq 0 ]]; then
    log_success "Git configuration validation passed"
  else
    log_error "Git configuration validation failed with $validation_errors error(s)"
    return 1
  fi
}

# Function to validate required tools
validate_required_tools() {
  log_info "Validating required tools"

  # Core tools
  local core_tools=("git" "bash" "curl" "wget")
  # CI/CD tools
  local ci_tools=("mise" "sops" "age")
  # Security tools
  local security_tools=("gitleaks" "trufflehog")
  # Formatting tools
  local format_tools=("shfmt" "shellcheck")

  local all_tools=("${core_tools[@]}" "${ci_tools[@]}" "${security_tools[@]}" "${format_tools[@]}")
  local missing_tools=()
  local available_tools=()

  for tool in "${all_tools[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
      available_tools+=("$tool")
    else
      missing_tools+=("$tool")
    fi
  done

  if [[ ${#available_tools[@]} -gt 0 ]]; then
    log_success "Available tools: ${available_tools[*]}"
  fi

  if [[ ${#missing_tools[@]} -gt 0 ]]; then
    log_warning "Missing tools: ${missing_tools[*]}"
    log_info "Run 'mise install' to install missing tools"
  fi

  # Check critical tools that must be present
  local critical_tools=("git" "bash")
  for tool in "${critical_tools[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      log_error "Critical tool missing: $tool"
      return 1
    fi
  done

  log_success "Required tools validation completed"
}

# Function to validate project structure
validate_project_structure() {
  log_info "Validating project structure"

  local required_dirs=(
    "scripts"
    "scripts/setup"
    "scripts/ci"
    "scripts/lib"
    "environments"
    ".github"
  )

  local missing_dirs=()
  for dir in "${required_dirs[@]}"; do
    if [[ ! -d "$dir" ]]; then
      missing_dirs+=("$dir")
    fi
  done

  if [[ ${#missing_dirs[@]} -gt 0 ]]; then
    log_warning "Missing directories: ${missing_dirs[*]}"
  fi

  # Check for required files
  local required_files=(
    "mise.toml"
    ".sops.yaml"
    "commitizen.json"
    "scripts/lib/common.sh"
  )

  local missing_files=()
  for file in "${required_files[@]}"; do
    if [[ ! -f "$file" ]]; then
      missing_files+=("$file")
    fi
  done

  if [[ ${#missing_files[@]} -gt 0 ]]; then
    log_warning "Missing files: ${missing_files[*]}"
  fi

  # Check environment directories
  local environments=("staging" "production")
  for env in "${environments[@]}"; do
    local env_dir="environments/$env"
    if [[ -d "$env_dir" ]]; then
      log_info "Environment directory found: $env_dir"

      # Check for config file
      local config_file="${env_dir}/config.yml"
      if [[ -f "$config_file" ]]; then
        log_info "Config file found: $config_file"
      else
        log_warning "Config file missing: $config_file"
      fi

      # Check for secrets file (optional)
      local secrets_file="${env_dir}/secrets.enc"
      if [[ -f "$secrets_file" ]]; then
        log_info "Secrets file found: $secrets_file"
      else
        log_info "Secrets file not found: $secrets_file (optional)"
      fi
    fi
  done

  log_success "Project structure validation completed"
}

# Function to validate GitHub Actions environment
validate_github_actions_environment() {
  log_info "Validating GitHub Actions environment"

  # Check if running in GitHub Actions
  if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
    log_info "Running in GitHub Actions environment"

    # Check required GitHub environment variables
    local github_vars=(
      "GITHUB_REPOSITORY"
      "GITHUB_REF_NAME"
      "GITHUB_SHA"
      "GITHUB_WORKFLOW"
      "GITHUB_RUN_ID"
    )

    local missing_vars=()
    for var in "${github_vars[@]}"; do
      if [[ -z "${!var:-}" ]]; then
        missing_vars+=("$var")
      fi
    done

    if [[ ${#missing_vars[@]} -gt 0 ]]; then
      log_warning "Missing GitHub variables: ${missing_vars[*]}"
    fi

    # Check GitHub token availability
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
      log_info "GitHub token available"
    else
      log_warning "GitHub token not available (may limit some functionality)"
    fi

    # Check for workspace
    if [[ -n "${GITHUB_WORKSPACE:-}" && -d "$GITHUB_WORKSPACE" ]]; then
      log_info "GitHub workspace available: $GITHUB_WORKSPACE"
    fi

    log_success "GitHub Actions environment validation completed"
  else
    log_info "Not running in GitHub Actions environment"
  fi
}

# Function to validate secret rotation
validate_secret_rotation() {
  local environment="${1:-staging}"
  local dry_run="${2:-true}"

  log_info "Validating secret rotation for: $environment"

  if validate_secret_rotation "$environment" "$dry_run"; then
    log_success "Secret rotation validation passed: $environment"
  else
    log_warning "Secret rotation validation failed: $environment"
    # Don't fail the validation for secret rotation issues
  fi
}

# Function to generate validation report
generate_validation_report() {
  local report_file="/tmp/validation-report.json"

  log_info "Generating validation report"

  cat > "$report_file" <<EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "environment": "${ENVIRONMENT:-unknown}",
  "git_repository": "${GITHUB_REPOSITORY:-unknown}",
  "workflow": "${GITHUB_WORKFLOW:-unknown}",
  "run_id": "${GITHUB_RUN_ID:-unknown}",
  "validation_status": "completed"
}
EOF

  log_success "Validation report generated: $report_file"

  # Add to GitHub Actions summary if available
  if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    echo "## Environment Validation Report" >> "$GITHUB_STEP_SUMMARY"
    echo "" >> "$GITHUB_STEP_SUMMARY"
    echo "**Environment:** ${ENVIRONMENT:-unknown}" >> "$GITHUB_STEP_SUMMARY"
    echo "**Repository:** ${GITHUB_REPOSITORY:-unknown}" >> "$GITHUB_STEP_SUMMARY"
    echo "**Workflow:** ${GITHUB_WORKFLOW:-unknown}" >> "$GITHUB_STEP_SUMMARY"
    echo "**Run ID:** ${GITHUB_RUN_ID:-unknown}" >> "$GITHUB_STEP_SUMMARY"
    echo "**Status:** ✅ Completed" >> "$GITHUB_STEP_SUMMARY"
  fi
}

# Main validation process
main() {
  local start_time
  start_time=$(date +%s)

  local environment="${1:-staging}"

  log_info "Starting environment validation"

  # Run all validations
  validate_required_tools
  validate_git_configuration
  validate_project_structure
  validate_sops_setup
  validate_environment_config "$environment"
  validate_github_actions_environment
  validate_secret_rotation "$environment" "true"

  # Generate report
  generate_validation_report

  # Calculate validation time
  local end_time
  end_time=$(date +%s)
  local duration=$((end_time - start_time))

  log_success "Environment validation completed in $(format_duration "$duration")"
}

# Execute main function with environment parameter
main "${1:-staging}"