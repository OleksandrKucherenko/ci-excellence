#!/bin/bash
# CI Environment Validation Script
# Validates environment configuration and required variables

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_ROOT/../.." && pwd)"
source "$PROJECT_ROOT/scripts/lib/common.sh" 2>/dev/null || {
  echo "Failed to source common utilities" >&2
  exit 1
}

# Configuration
readonly VALIDATE_ENV_VERSION="1.0.0"

# Testability configuration
get_behavior_mode() {
  local script_name="ci_validate_env"
  get_script_behavior "$script_name" "EXECUTE"
}

# Validate required environment variable
validate_required_var() {
  local var_name="$1"
  local description="${2:-environment variable}"
  local required="${3:-true}"

  local value="${!var_name:-}"

  if [[ "$required" == "true" && -z "$value" ]]; then
    log_error "❌ Required $description not set: $var_name"
    return 1
  fi

  if [[ -n "$value" ]]; then
    log_success "✅ $description is set: $var_name"
  else
    log_info "ℹ️ Optional $description not set: $var_name"
  fi

  return 0
}

# Validate environment file exists
validate_env_file() {
  local env_file="$1"
  local description="${2:-environment file}"

  if [[ -f "$env_file" ]]; then
    log_success "✅ $description exists: $env_file"
    return 0
  else
    log_warn "⚠️ $description not found: $env_file"
    return 0
  fi
}

# Validate environment file format
validate_env_file_format() {
  local env_file="$1"
  local format="${2:-dotenv}"

  if [[ ! -f "$env_file" ]]; then
    return 0
  fi

  local validation_failed=false

  case "$format" in
    "dotenv")
      # Check for common dotenv file issues
      if grep -q "^[^#][^A-Z_][A-Z0-9_]*=" "$env_file" 2>/dev/null; then
        log_error "❌ $env_file has invalid variable format (should start with letter or underscore)"
        validation_failed=true
      fi

      if grep -q "^[A-Z_][A-Z0-9_]*=.*#.*$" "$env_file" 2>/dev/null; then
        log_warn "⚠️ $env_file has comments after variable assignments (may cause issues)"
      fi
      ;;
    "json")
      # Basic JSON validation using Python or node if available
      if command -v python3 >/dev/null 2>&1; then
        if ! python3 -m json.tool "$env_file" >/dev/null 2>&1; then
          log_error "❌ $env_file has invalid JSON format"
          validation_failed=true
        fi
      elif command -v node >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
        if ! node -e "try { JSON.parse(require('fs').readFileSync('$env_file', 'utf8')); console.log('JSON valid'); } catch(e) { process.exit(1); }" >/dev/null 2>&1; then
          log_error "❌ $env_file has invalid JSON format"
          validation_failed=true
        fi
      fi
      ;;
    "yaml")
      # Basic YAML validation using yq if available
      if command -v yq >/dev/null 2>&1; then
        if ! yq '.' "$env_file" >/dev/null 2>&1; then
          log_error "❌ $env_file has invalid YAML format"
          validation_failed=true
        fi
      else
        log_warn "⚠️ YAML validation tool not available, skipping format check"
      fi
      ;;
    *)
      log_info "ℹ️ No format validation available for: $format"
      ;;
  esac

  if [[ "$validation_failed" == "true" ]]; then
    return 1
  else
    log_success "✅ $env_file has valid format"
    return 0
  fi
}

# Validate Node.js environment
validate_node_env() {
  log_info "Validating Node.js environment"

  local validation_failed=false

  # Check Node.js installation
  if command -v node >/dev/null 2>&1; then
    local node_version
    node_version=$(node --version 2>/dev/null | head -1)
    log_success "✅ Node.js is installed: $node_version"
  else
    log_error "❌ Node.js is not installed"
    validation_failed=true
  fi

  # Check npm installation
  if command -v npm >/dev/null 2>&1; then
    local npm_version
    npm_version=$(npm --version 2>/dev/null | head -1)
    log_success "✅ npm is installed: $npm_version"
  else
    log_error "❌ npm is not installed"
    validation_failed=true
  fi

  # Check package.json if it exists
  if [[ -f "package.json" ]]; then
    log_success "✅ package.json exists"
    if command -v jq >/dev/null 2>&1; then
      local package_name
      package_name=$(jq -r '.name // "unknown"' package.json 2>/dev/null)
      local package_version
      package_version=$(jq -r '.version // "unknown"' package.json 2>/dev/null)
      log_info "   Project: $package_name v$package_version"
    fi
  else
    log_info "ℹ️ No package.json found (not a Node.js project)"
  fi

  # Check for lock files
  local lock_files=("package-lock.json" "yarn.lock" "pnpm-lock.yaml" "bun.lockb")
  local found_lock=false

  for lock_file in "${lock_files[@]}"; do
    if [[ -f "$lock_file" ]]; then
      log_success "✅ Lock file found: $lock_file"
      found_lock=true
    fi
  done

  if [[ "$found_lock" == "false" ]]; then
    log_warn "⚠️ No lock file found"
  fi

  if [[ "$validation_failed" == "true" ]]; then
    return 1
  fi

  return 0
}

# Validate Python environment
validate_python_env() {
  log_info "Validating Python environment"

  local validation_failed=false

  # Check Python installation
  if command -v python3 >/dev/null 2>&1; then
    local python_version
    python_version=$(python3 --version 2>/dev/null | head -1)
    log_success "✅ Python 3 is installed: $python_version"
  elif command -v python >/dev/null 2>&1; then
    local python_version
    python_version=$(python --version 2>/dev/null | head -1)
    log_success "✅ Python is installed: $python_version"
    log_warn "⚠️ Python 3 not detected, consider using python3"
  else
    log_error "❌ Python is not installed"
    validation_failed=true
  fi

  # Check pip installation
  local pip_cmd="pip"
  if command -v pip3 >/dev/null 2>&1; then
    pip_cmd="pip3"
  elif command -v pip >/dev/null 2>&1; then
    pip_cmd="pip"
  else
    log_error "❌ pip is not installed"
    validation_failed=true
  fi

  if [[ "$validation_failed" == "false" ]]; then
    local pip_version
    pip_version=$($pip_cmd --version 2>/dev/null | head -1)
    log_success "✅ $pip_cmd is installed: $pip_version"
  fi

  # Check requirements.txt if it exists
  if [[ -f "requirements.txt" ]]; then
    log_success "✅ requirements.txt exists"
    local req_count
    req_count=$(wc -l < requirements.txt 2>/dev/null || echo "0")
    log_info "   $req_count requirements found"
  fi

  # Check for virtual environment
  local venv_indicators=("venv" ".venv" "env" "environment")
  local found_venv=false

  for indicator in "${venv_indicators[@]}"; do
    if [[ -d "$indicator" ]]; then
      log_success "✅ Virtual environment found: $indicator"
      found_venv=true
      break
    fi
  done

  if [[ "$found_venv" == "false" ]]; then
    log_info "ℹ️ No virtual environment detected"
  fi

  if [[ "$validation_failed" == "true" ]]; then
    return 1
  fi

  return 0
}

# Validate Go environment
validate_go_env() {
  log_info "Validating Go environment"

  local validation_failed=false

  # Check Go installation
  if command -v go >/dev/null 2>&1; then
    local go_version
    go_version=$(go version 2>/dev/null | head -1)
    log_success "✅ Go is installed: $go_version"
  else
    log_error "❌ Go is not installed"
    validation_failed=true
  fi

  # Check go.mod if it exists
  if [[ -f "go.mod" ]]; then
    log_success "✅ go.mod exists"
    if command -v grep >/dev/null 2>&1; then
      local module_name
      module_name=$(grep "^module " go.mod | cut -d' ' -f2)
      log_info "   Module: $module_name"
    fi
  else
    log_info "ℹ️ No go.mod found (not a Go project)"
  fi

  # Check GOPATH
  local gopath="${GOPATH:-}"
  if [[ -n "$gopath" ]]; then
    log_success "✅ GOPATH is set: $gopath"
  else
    log_info "ℹ️ GOPATH not set (using Go modules)"
  fi

  if [[ "$validation_failed" == "true" ]]; then
    return 1
  fi

  return 0
}

# Validate Rust environment
validate_rust_env() {
  log_info "Validating Rust environment"

  local validation_failed=false

  # Check Rust installation
  if command -v rustc >/dev/null 2>&1; then
    local rust_version
    rust_version=$(rustc --version 2>/dev/null | head -1)
    log_success "✅ Rust is installed: $rust_version"
  else
    log_error "❌ Rust is not installed"
    validation_failed=true
  fi

  # Check Cargo installation
  if command -v cargo >/dev/null 2>&1; then
    local cargo_version
    cargo_version=$(cargo --version 2>/dev/null | head -1)
    log_success "✅ Cargo is installed: $cargo_version"
  else
    log_error "❌ Cargo is not installed"
    validation_failed=true
  fi

  # Check Cargo.toml if it exists
  if [[ -f "Cargo.toml" ]]; then
    log_success "✅ Cargo.toml exists"
    if command -v grep >/dev/null 2>&1; then
      local package_name
      package_name=$(grep "^name = " Cargo.toml | cut -d'"' -f2)
      local package_version
      package_version=$(grep "^version = " Cargo.toml | cut -d'"' -f2)
      log_info "   Package: $package_name v$package_version"
    fi
  else
    log_info "ℹ️ No Cargo.toml found (not a Rust project)"
  fi

  if [[ "$validation_failed" == "true" ]]; then
    return 1
  fi

  return 0
}

# Validate MISE environment
validate_mise_env() {
  log_info "Validating MISE environment"

  local validation_failed=false

  # Check MISE installation
  if command -v mise >/dev/null 2>&1; then
    local mise_version
    mise_version=$(mise --version 2>/dev/null | head -1)
    log_success "✅ MISE is installed: $mise_version"
  else
    log_error "❌ MISE is not installed"
    validation_failed=true
  fi

  # Check mise.toml if it exists
  if [[ -f "mise.toml" ]]; then
    log_success "✅ mise.toml exists"
  else
    log_info "ℹ️ No mise.toml found in current directory"
  fi

  # Check project mise.toml
  local project_mise="$PROJECT_ROOT/mise.toml"
  if [[ -f "$project_mise" ]]; then
    log_success "✅ Project mise.toml exists"
  else
    log_warn "⚠️ Project mise.toml not found: $project_mise"
  fi

  if [[ "$validation_failed" == "true" ]]; then
    return 1
  fi

  return 0
}

# Validate SOPS environment
validate_sops_env() {
  log_info "Validating SOPS environment"

  local validation_failed=false

  # Check SOPS installation
  if command -v sops >/dev/null 2>&1; then
    local sops_version
    sops_version=$(sops --version 2>/dev/null | head -1)
    log_success "✅ SOPS is installed: $sops_version"
  else
    log_error "❌ SOPS is not installed"
    validation_failed=true
  fi

  # Check age installation
  if command -v age >/dev/null 2>&1; then
    local age_version
    age_version=$(age --version 2>/dev/null | head -1)
    log_success "✅ Age is installed: $age_version"
  else
    log_error "❌ Age is not installed"
    validation_failed=true
  fi

  # Check SOPS configuration
  local sops_config="$PROJECT_ROOT/.sops.yaml"
  if [[ -f "$sops_config" ]]; then
    log_success "✅ SOPS configuration exists: $sops_config"
  else
    log_warn "⚠️ SOPS configuration not found: $sops_config"
  fi

  # Check age key file
  local age_key_file
  age_key_file=$(get_age_key_file)
  if [[ -f "$age_key_file" ]]; then
    log_success "✅ Age key file exists: $age_key_file"
  else
    log_error "❌ Age key file not found: $age_key_file"
    log_info "Generate one with: mise run generate-age-key"
    validation_failed=true
  fi

  if [[ "$validation_failed" == "true" ]]; then
    return 1
  fi

  return 0
}

# Validate Git environment
validate_git_env() {
  log_info "Validating Git environment"

  local validation_failed=false

  # Check Git installation
  if command -v git >/dev/null 2>&1; then
    local git_version
    git_version=$(git --version 2>/dev/null | head -1)
    log_success "✅ Git is installed: $git_version"
  else
    log_error "❌ Git is not installed"
    validation_failed=true
  fi

  # Check if we're in a git repository
  if git rev-parse --git-dir >/dev/null 2>&1; then
    log_success "✅ Current directory is a Git repository"

    # Check for uncommitted changes
    if git diff-index --quiet HEAD -- 2>/dev/null; then
      log_success "✅ Working directory is clean"
    else
      log_warn "⚠️ Working directory has uncommitted changes"
    fi

    # Check git remote
    local remote_url
    remote_url=$(git config --get remote.origin.url 2>/dev/null || echo "")
    if [[ -n "$remote_url" ]]; then
      log_success "✅ Git remote is configured: $remote_url"
    else
      log_info "ℹ️ No Git remote configured"
    fi
  else
    log_info "ℹ️ Not in a Git repository"
  fi

  if [[ "$validation_failed" == "true" ]]; then
    return 1
  fi

  return 0
}

# Validate CI/CD specific variables
validate_ci_env() {
  log_info "Validating CI/CD environment variables"

  local validation_failed=false

  # Validate common CI variables
  local ci_vars=(
    "CI:Continuous Integration indicator"
    "GITHUB_ACTIONS:GitHub Actions indicator"
    "GITHUB_REPOSITORY:GitHub repository name"
    "GITHUB_RUN_ID:GitHub Actions run ID"
    "GITHUB_SHA:Git commit SHA"
  )

  for var_entry in "${ci_vars[@]}"; do
    local var_name="${var_entry%:*}"
    local var_desc="${var_entry#*:}"

    if ! validate_required_var "$var_name" "$var_desc" "false"; then
      validation_failed=true
    fi
  done

  if [[ "$validation_failed" == "true" ]]; then
    return 1
  fi

  return 0
}

# Main validation function
validate_environment() {
  local scope="${1:-all}"

  log_info "Starting environment validation (scope: $scope)"

  local behavior
  behavior=$(get_behavior_mode)

  case "$behavior" in
    "DRY_RUN")
      echo "🔍 DRY RUN: Would validate environment"
      return 0
      ;;
    "PASS")
      log_success "PASS MODE: Environment validation simulated successfully"
      return 0
      ;;
    "FAIL")
      log_error "FAIL MODE: Simulating environment validation failure"
      return 1
      ;;
    "SKIP")
      log_info "SKIP MODE: Environment validation skipped"
      return 0
      ;;
    "TIMEOUT")
      log_info "TIMEOUT MODE: Simulating environment validation timeout"
      sleep 5
      return 124
      ;;
  esac

  # EXECUTE mode - Actual validation
  local overall_success=true

  case "$scope" in
    "all")
      log_info "Running comprehensive environment validation"

      if ! validate_mise_env; then overall_success=false; fi
      if ! validate_sops_env; then overall_success=false; fi
      if ! validate_git_env; then overall_success=false; fi
      if ! validate_ci_env; then overall_success=false; fi

      # Validate project-specific environments
      if [[ -f "package.json" ]] && ! validate_node_env; then overall_success=false; fi
      if [[ -f "requirements.txt" || -f "setup.py" || -f "pyproject.toml" ]] && ! validate_python_env; then overall_success=false; fi
      if [[ -f "go.mod" ]] && ! validate_go_env; then overall_success=false; fi
      if [[ -f "Cargo.toml" ]] && ! validate_rust_env; then overall_success=false; fi

      ;;
    "mise")
      validate_mise_env
      ;;
    "sops")
      validate_sops_env
      ;;
    "git")
      validate_git_env
      ;;
    "ci")
      validate_ci_env
      ;;
    "node")
      validate_node_env
      ;;
    "python")
      validate_python_env
      ;;
    "go")
      validate_go_env
      ;;
    "rust")
      validate_rust_env
      ;;
    *)
      log_error "Unknown validation scope: $scope"
      echo "Available scopes: all, mise, sops, git, ci, node, python, go, rust"
      return 1
      ;;
  esac

  if [[ "$overall_success" == "true" ]]; then
    log_success "✅ Environment validation completed successfully"
    return 0
  else
    log_error "❌ Environment validation failed"
    return 1
  fi
}

# Main execution
main() {
  local scope="${1:-all}"

  log_info "CI Environment Validation Script v$VALIDATE_ENV_VERSION"

  # Run environment validation
  if ! validate_environment "$scope"; then
    log_error "Environment validation failed for scope: $scope"
    exit 1
  fi

  log_info "Environment validation completed"
}

# CLI interface
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  case "${1:-}" in
    "help"|"--help"|"-h")
      cat << EOF
CI Environment Validation Script v$VALIDATE_ENV_VERSION

Usage: $0 [scope]

Scopes:
  all                                   Validate all environments (default)
  mise                                  Validate MISE environment
  sops                                  Validate SOPS environment
  git                                   Validate Git environment
  ci                                    Validate CI/CD variables
  node                                  Validate Node.js environment
  python                                Validate Python environment
  go                                    Validate Go environment
  rust                                  Validate Rust environment

Examples:
  $0                                     # Validate all environments
  $0 mise                               # Validate MISE environment only
  $0 node                               # Validate Node.js environment only
  $0 sops                               # Validate SOPS environment only

Environment Variables:
  CI_VALIDATE_ENV_BEHAVIOR     EXECUTE, DRY_RUN, PASS, FAIL, SKIP, TIMEOUT
  CI_TEST_MODE                 Global testability mode
  PIPELINE_SCRIPT_*_BEHAVIOR   Pipeline-level overrides

Testability Examples:
  CI_TEST_MODE=DRY_RUN $0
  CI_VALIDATE_ENV_BEHAVIOR=FAIL $0 mise
  PIPELINE_SCRIPT_CI_VALIDATE_ENV_BEHAVIOR=SKIP $0 node
EOF
      exit 0
      ;;
    *)
      main "$@"
      ;;
  esac
fi