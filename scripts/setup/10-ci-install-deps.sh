#!/bin/bash
# CI Install Dependencies Script
# Installs project dependencies with testability support

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_ROOT/../.." && pwd)"
source "$PROJECT_ROOT/scripts/lib/common.sh" 2>/dev/null || {
  echo "Failed to source common utilities" >&2
  exit 1
}

# Configuration
readonly INSTALL_DEPS_VERSION="1.0.0"

# Testability configuration
get_behavior_mode() {
  local script_name="ci_install_deps"
  get_script_behavior "$script_name" "EXECUTE"
}

# Detect project type based on common indicators
detect_project_type() {
  # Check for Node.js indicators
  if [[ -f "package.json" ]]; then
    echo "node"
    return 0
  fi

  # Check for Python indicators
  if [[ -f "requirements.txt" ]] || [[ -f "setup.py" ]] || [[ -f "pyproject.toml" ]]; then
    echo "python"
    return 0
  fi

  # Check for Go indicators
  if [[ -f "go.mod" ]]; then
    echo "go"
    return 0
  fi

  # Check for Rust indicators
  if [[ -f "Cargo.toml" ]]; then
    echo "rust"
    return 0
  fi

  # Check for Java indicators
  if [[ -f "pom.xml" ]] || [[ -f "build.gradle" ]]; then
    echo "java"
    return 0
  fi

  # Check for C#/.NET indicators
  if [[ -f "*.csproj" ]] || [[ -f "*.sln" ]]; then
    echo "dotnet"
    return 0
  fi

  echo "unknown"
}

# Detect package manager for Node.js projects
detect_package_manager() {
  # Priority order: npm (package-lock.json) > yarn (yarn.lock) > pnpm (pnpm-lock.yaml) > bun (bun.lockb) > npm (default)

  if [[ -f "package-lock.json" ]]; then
    echo "npm"
  elif [[ -f "yarn.lock" ]]; then
    echo "yarn"
  elif [[ -f "pnpm-lock.yaml" ]]; then
    echo "pnpm"
  elif [[ -f "bun.lockb" ]]; then
    echo "bun"
  else
    echo "npm"
  fi
}

# Get dependency list for testing
get_dependency_list() {
  local project_type="$1"

  case "$project_type" in
    "node")
      # For npm ci, dependencies come from package-lock.json, no need to specify
      if [[ "$(detect_package_manager)" == "npm" ]]; then
        echo ""
      elif [[ "$(detect_package_manager)" == "yarn" ]]; then
        echo "--immutable"
      elif [[ "$(detect_package_manager)" == "pnpm" ]]; then
        echo "--frozen-lockfile"
      elif [[ "$(detect_package_manager)" == "bun" ]]; then
        echo "--no-save"
      fi
      ;;
    "python")
      if [[ -f "requirements.txt" ]]; then
        echo "-r requirements.txt"
      elif [[ -f "requirements-dev.txt" ]]; then
        echo "-r requirements-dev.txt"
      fi
      ;;
    "go")
      echo ""  # go mod download doesn't need arguments
      ;;
    "rust")
      echo ""  # cargo check doesn't need arguments for dependencies
      ;;
    *)
      echo ""
      ;;
  esac
}

# Validate project directory
validate_project_directory() {
  local project_dir="${1:-.}"

  if [[ ! -d "$project_dir" ]]; then
    log_error "Project directory not found: $project_dir"
    return 1
  fi

  return 0
}

# Install dependencies for Node.js projects
install_node_dependencies() {
  local package_manager
  package_manager=$(detect_package_manager)
  local dependency_list
  dependency_list=$(get_dependency_list "node")

  log_info "Installing Node.js dependencies using $package_manager"

  case "$package_manager" in
    "npm")
      log_info "Using npm (package-lock.json found)"
      if ! npm ci $dependency_list; then
        log_error "npm ci failed"
        return 1
      fi
      ;;
    "yarn")
      log_info "Using yarn (yarn.lock found)"
      if ! yarn install $dependency_list; then
        log_error "yarn install failed"
        return 1
      fi
      ;;
    "pnpm")
      log_info "Using pnpm (pnpm-lock.yaml found)"
      if ! pnpm install $dependency_list; then
        log_error "pnpm install failed"
        return 1
      fi
      ;;
    "bun")
      log_info "Using bun (bun.lockb found)"
      if ! bun install $dependency_list; then
        log_error "bun install failed"
        return 1
      fi
      ;;
  esac

  log_success "✅ Node.js dependencies installed successfully"
}

# Install dependencies for Python projects
install_python_dependencies() {
  local pip_cmd="pip"
  local dependency_list
  dependency_list=$(get_dependency_list "python")

  log_info "Installing Python dependencies"

  # Check if pip3 is available and use it over pip
  if command -v pip3 >/dev/null 2>&1; then
    pip_cmd="pip3"
    log_info "Using pip3 for dependency installation"
  fi

  # Upgrade pip first
  log_info "Upgrading $pip_cmd"
  if ! $pip_cmd install --upgrade pip; then
    log_warn "pip upgrade failed, continuing with dependency installation"
  fi

  # Install dependencies
  if [[ -n "$dependency_list" ]]; then
    log_info "Installing from: $dependency_list"
    if ! $pip_cmd install $dependency_list; then
      log_error "pip install failed"
      return 1
    fi
  else
    log_warn "No requirements file found, skipping Python dependency installation"
  fi

  log_success "✅ Python dependencies installed successfully"
}

# Install dependencies for Go projects
install_go_dependencies() {
  log_info "Installing Go dependencies"

  # Download dependencies
  log_info "Downloading Go modules"
  if ! go mod download; then
    log_error "go mod download failed"
    return 1
  fi

  # Verify dependencies
  log_info "Verifying Go modules"
  if ! go mod verify; then
    log_error "go mod verify failed"
    return 1
  fi

  log_success "✅ Go dependencies installed and verified successfully"
}

# Install dependencies for Rust projects
install_rust_dependencies() {
  log_info "Installing Rust dependencies"

  # Check and install dependencies
  log_info "Checking Rust dependencies"
  if ! cargo check; then
    log_error "cargo check failed"
    return 1
  fi

  log_success "✅ Rust dependencies checked successfully"
}

# Install dependencies for Java projects
install_java_dependencies() {
  log_info "Installing Java dependencies"

  if [[ -f "pom.xml" ]]; then
    log_info "Found Maven project (pom.xml)"
    if command -v mvn >/dev/null 2>&1; then
      if ! mvn clean install -DskipTests; then
        log_error "Maven install failed"
        return 1
      fi
    else
      log_error "Maven not found, cannot install dependencies"
      return 1
    fi
  elif [[ -f "build.gradle" ]]; then
    log_info "Found Gradle project (build.gradle)"
    if command -v gradle >/dev/null 2>&1; then
      if ! gradle build -x test; then
        log_error "Gradle build failed"
        return 1
      fi
    elif [[ -f "gradlew" ]]; then
      if ! ./gradlew build -x test; then
        log_error "Gradle wrapper build failed"
        return 1
      fi
    else
      log_error "Gradle not found and no gradlew found, cannot install dependencies"
      return 1
    fi
  else
    log_error "No Java build file found"
    return 1
  fi

  log_success "✅ Java dependencies installed successfully"
}

# Install dependencies for .NET projects
install_dotnet_dependencies() {
  log_info "Installing .NET dependencies"

  if command -v dotnet >/dev/null 2>&1; then
    if [[ -f "*.sln" ]]; then
      local solution_file
      solution_file=$(find . -maxdepth 1 -name "*.sln" | head -1)
      log_info "Found solution file: $solution_file"
      if ! dotnet restore "$solution_file"; then
        log_error "dotnet restore failed"
        return 1
      fi
    elif [[ -f "*.csproj" ]]; then
      local project_file
      project_file=$(find . -maxdepth 1 -name "*.csproj" | head -1)
      log_info "Found project file: $project_file"
      if ! dotnet restore "$project_file"; then
        log_error "dotnet restore failed"
        return 1
      fi
    else
      log_error "No .NET solution or project file found"
      return 1
    fi
  else
    log_error "dotnet CLI not found"
    return 1
  fi

  log_success "✅ .NET dependencies installed successfully"
}

# Main dependency installation function
install_dependencies() {
  local project_type="${1:-auto}"
  local project_dir="${2:-.}"

  log_info "Installing dependencies (type: $project_type, directory: $project_dir)"

  local behavior
  behavior=$(get_behavior_mode)

  case "$behavior" in
    "DRY_RUN")
      echo "🔍 DRY RUN: Would install dependencies for $project_type"
      return 0
      ;;
    "PASS")
      log_success "PASS MODE: Dependencies installation simulated successfully"
      return 0
      ;;
    "FAIL")
      log_error "FAIL MODE: Simulating dependencies installation failure"
      return 1
      ;;
    "SKIP")
      log_info "SKIP MODE: Dependencies installation skipped"
      return 0
      ;;
    "TIMEOUT")
      log_info "TIMEOUT MODE: Simulating dependencies installation timeout"
      sleep 5
      return 124
      ;;
  esac

  # EXECUTE mode - Actual dependency installation
  # Validate project directory
  if ! validate_project_directory "$project_dir"; then
    return 1
  fi

  # Change to project directory if specified
  if [[ "$project_dir" != "." ]]; then
    log_info "Changing to project directory: $project_dir"
    if ! cd "$project_dir"; then
      log_error "Failed to change to directory: $project_dir"
      return 1
    fi
  fi

  # Auto-detect project type if not specified
  if [[ "$project_type" == "auto" ]]; then
    project_type=$(detect_project_type)
    log_info "Auto-detected project type: $project_type"
  fi

  # Install dependencies based on project type
  case "$project_type" in
    "node")
      install_node_dependencies
      ;;
    "python")
      install_python_dependencies
      ;;
    "go")
      install_go_dependencies
      ;;
    "rust")
      install_rust_dependencies
      ;;
    "java")
      install_java_dependencies
      ;;
    "dotnet")
      install_dotnet_dependencies
      ;;
    "unknown")
      log_info "No dependency installation required for: $project_type"
      return 0
      ;;
    *)
      log_error "Unsupported project type: $project_type"
      return 1
      ;;
  esac

  log_success "✅ Dependencies installation completed successfully"
}

# Main execution
main() {
  local project_type="${1:-auto}"
  local project_dir="${2:-.}"

  log_info "CI Install Dependencies Script v$INSTALL_DEPS_VERSION"

  # Install dependencies
  if ! install_dependencies "$project_type" "$project_dir"; then
    log_error "❌ Dependency installation failed for: $project_type"
    exit 1
  fi

  log_info "Dependency installation process completed"
}

# CLI interface
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  case "${1:-}" in
    "help"|"--help"|"-h")
      cat << EOF
CI Install Dependencies Script v$INSTALL_DEPS_VERSION

Usage: $0 [project_type] [project_directory]

Arguments:
  project_type        Project type (auto, node, python, go, rust, java, dotnet)
                        Default: auto (auto-detect)
  project_directory   Project directory path
                        Default: current directory

Supported Project Types:
  auto                Auto-detect project type
  node                Node.js/TypeScript projects
  python              Python projects
  go                  Go projects
  rust                Rust projects
  java                Java/Maven/Gradle projects
  dotnet              .NET projects

Examples:
  $0                                   # Auto-detect and install in current directory
  $0 node                              # Install Node.js dependencies
  $0 python /path/to/project           # Install Python dependencies in specified directory

Environment Variables:
  CI_INSTALL_DEPS_BEHAVIOR  EXECUTE, DRY_RUN, PASS, FAIL, SKIP, TIMEOUT
  CI_TEST_MODE               Global testability mode
  PIPELINE_SCRIPT_*_BEHAVIOR Pipeline-level overrides

Testability Examples:
  CI_TEST_MODE=DRY_RUN $0
  CI_INSTALL_DEPS_BEHAVIOR=FAIL $0 node
  PIPELINE_SCRIPT_CI_INSTALL_DEPS_BEHAVIOR=SKIP $0
EOF
      exit 0
      ;;
    *)
      main "$@"
      ;;
  esac
fi