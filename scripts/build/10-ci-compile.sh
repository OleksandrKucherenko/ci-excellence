#!/bin/bash
# CI Compile Script with Full Testability Support
# Compiles project based on detected type with hierarchical testability control

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/scripts/lib/common.sh" 2>/dev/null || {
  echo "Failed to source common utilities" >&2
  exit 1
}

# Configuration
readonly COMPILE_SCRIPT_VERSION="1.0.0"

# Testability configuration
get_script_behavior() {
  local script_name="ci_compile"
  local default_behavior="EXECUTE"

  # Priority order: PIPELINE_COMPILE_MODE > COMPILE_MODE > CI_TEST_MODE > default
  local behavior

  # 1. Pipeline-specific override (highest priority)
  if [[ -n "${PIPELINE_COMPILE_MODE:-}" ]]; then
    behavior="$PIPELINE_COMPILE_MODE"
    log_debug "Using PIPELINE_COMPILE_MODE: $behavior"
  # 2. Script-specific override
  elif [[ -n "${COMPILE_MODE:-}" ]]; then
    behavior="$COMPILE_MODE"
    log_debug "Using COMPILE_MODE: $behavior"
  # 3. Global testability mode
  elif [[ -n "${CI_TEST_MODE:-}" ]]; then
    behavior="$CI_TEST_MODE"
    log_debug "Using CI_TEST_MODE: $behavior"
  # 4. Default behavior
  else
    behavior="$default_behavior"
    log_debug "Using default behavior: $behavior"
  fi

  echo "$behavior"
}

# Detect project type based on project structure
detect_project_type() {
  local project_path="${1:-$PROJECT_ROOT}"

  if [[ -f "$project_path/package.json" ]]; then
    echo "nodejs"
  elif [[ -f "$project_path/pyproject.toml" ]] || [[ -f "$project_path/setup.py" ]] || [[ -f "$project_path/requirements.txt" ]]; then
    echo "python"
  elif [[ -f "$project_path/go.mod" ]]; then
    echo "go"
  elif [[ -f "$project_path/Cargo.toml" ]]; then
    echo "rust"
  elif [[ -f "$project_path/Makefile" ]]; then
    echo "generic"
  elif [[ -f "$project_path/build.gradle" ]] || [[ -f "$project_path/build.gradle.kts" ]]; then
    echo "gradle"
  elif [[ -f "$project_path/pom.xml" ]]; then
    echo "maven"
  else
    echo "generic"
  fi
}

# Ensure build directory exists
ensure_build_directory() {
  local build_dir="${1:-$PROJECT_ROOT/dist}"

  mkdir -p "$build_dir"
  log_debug "Created build directory: $build_dir"
}

# Generate build metadata
generate_build_metadata() {
  local build_dir="${1:-$PROJECT_ROOT/dist}"
  local project_type="${2:-$(detect_project_type)}"

  local metadata_file="$build_dir/build-metadata.json"

  cat > "$metadata_file" << EOF
{
  "build_timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "build_version": "$(git rev-parse HEAD 2>/dev/null || echo "unknown")",
  "build_branch": "$(git branch --show-current 2>/dev/null || echo "unknown")",
  "project_type": "$project_type",
  "compile_mode": "$(get_script_behavior)",
  "compile_script_version": "$COMPILE_SCRIPT_VERSION",
  "build_environment": {
    "ci": "${CI:-false}",
    "github_actions": "${GITHUB_ACTIONS:-false}",
    "runner_os": "${RUNNER_OS:-unknown}",
    "node_version": "${NODE_VERSION:-unknown}",
    "python_version": "${PYTHON_VERSION:-unknown}",
    "go_version": "${GO_VERSION:-unknown}"
  }
}
EOF

  log_debug "Generated build metadata: $metadata_file"
}

# Compile Node.js project
compile_nodejs_project() {
  log_info "Compiling Node.js project"

  # Install dependencies
  if command -v npm >/dev/null 2>&1; then
    log_info "Installing npm dependencies"
    npm ci --silent
  else
    log_error "npm is not available"
    return 1
  fi

  # TypeScript compilation
  if [[ -f "tsconfig.json" ]] && command -v tsc >/dev/null 2>&1; then
    log_info "Compiling TypeScript"
    if ! tsc --noEmit; then
      log_error "TypeScript compilation failed"
      return 1
    fi
    tsc
    log_success "TypeScript compilation completed"
  fi

  # Build step
  if npm run build --silent 2>/dev/null; then
    log_success "Node.js build completed"
  else
    log_error "Node.js build failed"
    return 1
  fi

  return 0
}

# Compile Python project
compile_python_project() {
  log_info "Compiling Python project"

  # Install dependencies
  if command -v pip >/dev/null 2>&1; then
    log_info "Installing Python dependencies"
    if [[ -f "requirements.txt" ]]; then
      pip install -r requirements.txt
    fi
    if [[ -f "pyproject.toml" ]]; then
      pip install -e .
    fi
  else
    log_error "pip is not available"
    return 1
  fi

  # Python compilation (bytecode)
  if command -v python >/dev/null 2>&1; then
    log_info "Compiling Python bytecode"
    python -m compileall . -q
    log_success "Python compilation completed"
  else
    log_error "python is not available"
    return 1
  fi

  return 0
}

# Compile Go project
compile_go_project() {
  log_info "Compiling Go project"

  # Download dependencies
  if command -v go >/dev/null 2>&1; then
    log_info "Downloading Go dependencies"
    go mod download
    go mod tidy

    # Build project
    log_info "Building Go project"
    if ! go build -o dist/$(basename "$PWD") ./...; then
      log_error "Go build failed"
      return 1
    fi
    log_success "Go compilation completed"
  else
    log_error "go is not available"
    return 1
  fi

  return 0
}

# Compile Rust project
compile_rust_project() {
  log_info "Compiling Rust project"

  if command -v cargo >/dev/null 2>&1; then
    # Check project
    log_info "Checking Rust project"
    if ! cargo check; then
      log_error "Rust check failed"
      return 1
    fi

    # Build project
    log_info "Building Rust project"
    if ! cargo build --release; then
      log_error "Rust build failed"
      return 1
    fi
    log_success "Rust compilation completed"
  else
    log_error "cargo is not available"
    return 1
  fi

  return 0
}

# Compile generic project using Makefile
compile_generic_project() {
  log_info "Compiling generic project"

  if [[ -f "Makefile" ]] && command -v make >/dev/null 2>&1; then
    log_info "Running make build"
    if ! make build; then
      log_error "Generic build failed"
      return 1
    fi
    log_success "Generic compilation completed"
  else
    log_warn "No Makefile found, skipping compilation"
  fi

  return 0
}

# Compile Gradle project
compile_gradle_project() {
  log_info "Compiling Gradle project"

  if command -v ./gradlew >/dev/null 2>&1; then
    log_info "Running Gradle build"
    if ! ./gradlew build; then
      log_error "Gradle build failed"
      return 1
    fi
    log_success "Gradle compilation completed"
  elif command -v gradle >/dev/null 2>&1; then
    log_info "Running Gradle build"
    if ! gradle build; then
      log_error "Gradle build failed"
      return 1
    fi
    log_success "Gradle compilation completed"
  else
    log_error "Gradle is not available"
    return 1
  fi

  return 0
}

# Compile Maven project
compile_maven_project() {
  log_info "Compiling Maven project"

  if command -v mvn >/dev/null 2>&1; then
    log_info "Running Maven compile"
    if ! mvn compile; then
      log_error "Maven compilation failed"
      return 1
    fi

    log_info "Running Maven package"
    if ! mvn package -DskipTests; then
      log_error "Maven packaging failed"
      return 1
    fi
    log_success "Maven compilation completed"
  else
    log_error "Maven is not available"
    return 1
  fi

  return 0
}

# Run compilation for detected project type
run_compilation() {
  local project_type="${1:-$(detect_project_type)}"
  local compile_success=true

  ensure_build_directory

  case "$project_type" in
    "nodejs")
      compile_nodejs_project || compile_success=false
      ;;
    "python")
      compile_python_project || compile_success=false
      ;;
    "go")
      compile_go_project || compile_success=false
      ;;
    "rust")
      compile_rust_project || compile_success=false
      ;;
    "gradle")
      compile_gradle_project || compile_success=false
      ;;
    "maven")
      compile_maven_project || compile_success=false
      ;;
    "generic")
      compile_generic_project || compile_success=false
      ;;
    *)
      log_warn "Unknown project type: $project_type, using generic compilation"
      compile_generic_project || compile_success=false
      ;;
  esac

  if [[ "$compile_success" == "true" ]]; then
    generate_build_metadata "" "$project_type"
    log_success "Compilation completed successfully for $project_type project"
    return 0
  else
    log_error "Compilation failed for $project_type project"
    return 1
  fi
}

# Main compilation function
main() {
  local project_type="${1:-}"
  local behavior
  behavior=$(get_script_behavior)

  log_info "CI Compile Script v$COMPILE_SCRIPT_VERSION"

  case "$behavior" in
    "DRY_RUN")
      echo "🔍 DRY RUN: Would compile project"
      if [[ -n "$project_type" ]]; then
        echo "Project type: $project_type"
      else
        echo "Project type: $(detect_project_type)"
      fi
      echo "Would create build artifacts"
      return 0
      ;;
    "PASS")
      echo "✅ PASS MODE: Compile simulated successfully"
      return 0
      ;;
    "FAIL")
      echo "❌ FAIL MODE: Simulating compile failure"
      return 1
      ;;
    "SKIP")
      echo "⏭️ SKIP MODE: Compile skipped"
      return 0
      ;;
    "TIMEOUT")
      echo "⏰ TIMEOUT MODE: Simulating compile timeout"
      sleep 5
      return 124
      ;;
  esac

  # EXECUTE mode - Actual compilation
  log_info "🚀 EXECUTE: Compiling project"

  # Use provided project type or detect automatically
  if [[ -z "$project_type" ]]; then
    project_type=$(detect_project_type)
  fi

  log_info "Project type: $project_type"

  # Change to project root if not already there
  if [[ "$PWD" != "$PROJECT_ROOT" ]]; then
    cd "$PROJECT_ROOT"
  fi

  # Run compilation
  if run_compilation "$project_type"; then
    log_success "✅ Compile script completed successfully"
    return 0
  else
    log_error "❌ Compile script failed"
    return 1
  fi
}

# CLI interface
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Parse command line arguments
  case "${1:-}" in
    "help"|"--help"|"-h")
      cat << EOF
CI Compile Script v$COMPILE_SCRIPT_VERSION

Compiles project based on detected type with full testability support.

Usage:
  ./scripts/build/10-ci-compile.sh [project_type]

Project Types:
  nodejs   - Node.js/TypeScript project (package.json detected)
  python   - Python project (pyproject.toml, requirements.txt detected)
  go       - Go project (go.mod detected)
  rust     - Rust project (Cargo.toml detected)
  gradle   - Gradle project (build.gradle detected)
  maven    - Maven project (pom.xml detected)
  generic  - Generic project with Makefile

Environment Variables:
  PIPELINE_COMPILE_MODE    EXECUTE, DRY_RUN, PASS, FAIL, SKIP, TIMEOUT
  COMPILE_MODE            EXECUTE, DRY_RUN, PASS, FAIL, SKIP, TIMEOUT
  CI_TEST_MODE            Global testability mode
  CI_JOB_TIMEOUT_MINUTES  Timeout override for compile operations
  PROJECT_ROOT            Project root directory (default: auto-detected)

Testability:
  This script supports hierarchical testability control:
  1. PIPELINE_COMPILE_MODE (highest priority)
  2. COMPILE_MODE
  3. CI_TEST_MODE (global)
  4. Default: EXECUTE

Examples:
  # Auto-detect and compile
  ./scripts/build/10-ci-compile.sh

  # Compile specific project type
  ./scripts/build/10-ci-compile.sh nodejs

  # Dry run compilation
  COMPILE_MODE=DRY_RUN ./scripts/build/10-ci-compile.sh

  # Simulate failure
  COMPILE_MODE=FAIL ./scripts/build/10-ci-compile.sh

  # Pipeline-level override
  PIPELINE_COMPILE_MODE=SKIP ./scripts/build/10-ci-compile.sh

Integration:
  This script integrates with:
  - GitHub Actions workflows
  - Local development environments
  - CI/CD pipeline orchestration
  - Multi-language project support
EOF
      exit 0
      ;;
    "detect")
      # Detection mode
      echo "Detected project type: $(detect_project_type)"
      ;;
    "validate")
      # Validation mode
      echo "Validating compile setup..."

      project_type=$(detect_project_type)
      echo "Project type: $project_type"

      case "$project_type" in
        "nodejs")
          command -v npm >/dev/null && echo "✅ npm available" || echo "❌ npm not available"
          command -v tsc >/dev/null && echo "✅ TypeScript available" || echo "⚠️ TypeScript not available"
          ;;
        "python")
          command -v python >/dev/null && echo "✅ python available" || echo "❌ python not available"
          command -v pip >/dev/null && echo "✅ pip available" || echo "❌ pip not available"
          ;;
        "go")
          command -v go >/dev/null && echo "✅ go available" || echo "❌ go not available"
          ;;
        "rust")
          command -v cargo >/dev/null && echo "✅ cargo available" || echo "❌ cargo not available"
          ;;
        "generic")
          command -v make >/dev/null && echo "✅ make available" || echo "⚠️ make not available"
          ;;
      esac
      ;;
    *)
      main "$@"
      ;;
  esac
fi