#!/bin/bash
# CI Bundle Script with Full Testability Support
# Creates distribution bundles for deployment with hierarchical testability control

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/scripts/lib/common.sh" 2>/dev/null || {
  echo "Failed to source common utilities" >&2
  exit 1
}

# Configuration
readonly BUNDLE_SCRIPT_VERSION="1.0.0"
readonly DEFAULT_BUNDLE_DIR="$PROJECT_ROOT/dist"

# Testability configuration
get_script_behavior() {
  local script_name="ci_bundle"
  local default_behavior="EXECUTE"

  # Priority order: PIPELINE_BUNDLE_MODE > BUNDLE_MODE > CI_TEST_MODE > default
  local behavior

  # 1. Pipeline-specific override (highest priority)
  if [[ -n "${PIPELINE_BUNDLE_MODE:-}" ]]; then
    behavior="$PIPELINE_BUNDLE_MODE"
    log_debug "Using PIPELINE_BUNDLE_MODE: $behavior"
  # 2. Script-specific override
  elif [[ -n "${BUNDLE_MODE:-}" ]]; then
    behavior="$BUNDLE_MODE"
    log_debug "Using BUNDLE_MODE: $behavior"
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
  elif [[ -f "$project_path/pyproject.toml" ]] || [[ -f "$project_path/setup.py" ]]; then
    echo "python"
  elif [[ -f "$project_path/go.mod" ]]; then
    echo "go"
  elif [[ -f "$project_path/Cargo.toml" ]]; then
    echo "rust"
  elif [[ -f "$project_path/Makefile" ]]; then
    echo "generic"
  else
    echo "generic"
  fi
}

# Ensure bundle directory exists
ensure_bundle_directory() {
  local bundle_dir="${1:-$DEFAULT_BUNDLE_DIR}"

  mkdir -p "$bundle_dir"
  log_debug "Created bundle directory: $bundle_dir"
}

# Generate bundle metadata
generate_bundle_metadata() {
  local bundle_dir="${1:-$DEFAULT_BUNDLE_DIR}"
  local project_type="${2:-$(detect_project_type)}"
  local bundle_name="${3:-}"

  local metadata_file="$bundle_dir/bundle-metadata.json"

  cat > "$metadata_file" << EOF
{
  "bundle_timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "bundle_name": "$bundle_name",
  "project_type": "$project_type",
  "bundle_mode": "$(get_script_behavior)",
  "bundle_script_version": "$BUNDLE_SCRIPT_VERSION",
  "bundle_environment": {
    "ci": "${CI:-false}",
    "github_actions": "${GITHUB_ACTIONS:-false}",
    "runner_os": "${RUNNER_OS:-unknown}",
    "github_sha": "${GITHUB_SHA:-$(git rev-parse HEAD 2>/dev/null || echo 'unknown')}",
    "github_ref": "${GITHUB_REF:-$(git branch --show-current 2>/dev/null || echo 'unknown')}"
  }
}
EOF

  log_debug "Generated bundle metadata: $metadata_file"
}

# Bundle Node.js project
bundle_nodejs_project() {
  local bundle_dir="${1:-$DEFAULT_BUNDLE_DIR}"

  log_info "Bundling Node.js project"

  # Check if dist directory exists from compilation
  if [[ ! -d "$PROJECT_ROOT/dist" ]]; then
    log_error "No dist directory found. Run compile script first."
    return 1
  fi

  # Create bundle directory
  local bundle_name="$(basename "$PROJECT_ROOT")-bundle"
  local target_dir="$bundle_dir/$bundle_name"

  ensure_bundle_directory "$bundle_dir"
  rm -rf "$target_dir"
  mkdir -p "$target_dir"

  # Copy compiled files
  if [[ -d "$PROJECT_ROOT/dist" ]]; then
    cp -r "$PROJECT_ROOT/dist"/* "$target_dir/"
  fi

  # Copy package.json
  if [[ -f "$PROJECT_ROOT/package.json" ]]; then
    cp "$PROJECT_ROOT/package.json" "$target_dir/"
  fi

  # Copy node_modules if requested (for production)
  if [[ "${INCLUDE_NODE_MODULES:-false}" == "true" ]]; then
    if [[ -d "$PROJECT_ROOT/node_modules" ]]; then
      cp -r "$PROJECT_ROOT/node_modules" "$target_dir/"
    fi
  else
    # Create production dependencies file
    if [[ -f "$PROJECT_ROOT/package.json" ]]; then
      echo "Run 'npm ci --production' to install dependencies" > "$target_dir/INSTALL.md"
    fi
  fi

  # Create startup script
  cat > "$target_dir/start.sh" << 'EOF'
#!/bin/bash
set -euo pipefail

echo "Starting Node.js application..."

if [[ ! -d "node_modules" ]]; then
  echo "Installing dependencies..."
  npm ci --production
fi

if command -v node >/dev/null 2>&1; then
  node dist/index.js
else
  echo "Error: node is not available"
  exit 1
fi
EOF
  chmod +x "$target_dir/start.sh"

  # Create tarball
  cd "$bundle_dir"
  tar -czf "$bundle_name.tar.gz" "$bundle_name"

  log_success "Node.js bundle created: $bundle_dir/$bundle_name.tar.gz"
  return 0
}

# Bundle Python project
bundle_python_project() {
  local bundle_dir="${1:-$DEFAULT_BUNDLE_DIR}"

  log_info "Bundling Python project"

  # Create bundle directory
  local bundle_name="$(basename "$PROJECT_ROOT")-bundle"
  local target_dir="$bundle_dir/$bundle_name"

  ensure_bundle_directory "$bundle_dir"
  rm -rf "$target_dir"
  mkdir -p "$target_dir"

  # Copy source code
  if [[ -d "$PROJECT_ROOT/src" ]]; then
    cp -r "$PROJECT_ROOT/src" "$target_dir/"
  fi

  # Copy configuration files
  for config_file in "pyproject.toml" "requirements.txt" "setup.py" "setup.cfg"; do
    if [[ -f "$PROJECT_ROOT/$config_file" ]]; then
      cp "$PROJECT_ROOT/$config_file" "$target_dir/"
    fi
  done

  # Copy any Python bytecode
  if [[ -d "$PROJECT_ROOT/__pycache__" ]]; then
    cp -r "$PROJECT_ROOT/__pycache__" "$target_dir/"
  fi

  # Create startup script
  cat > "$target_dir/start.sh" << 'EOF'
#!/bin/bash
set -euo pipefail

echo "Starting Python application..."

if command -v python >/dev/null 2>&1; then
  if [[ -f "requirements.txt" ]]; then
    echo "Installing dependencies..."
    pip install -r requirements.txt
  fi

  python -m src.main
else
  echo "Error: python is not available"
  exit 1
fi
EOF
  chmod +x "$target_dir/start.sh"

  # Create tarball
  cd "$bundle_dir"
  tar -czf "$bundle_name.tar.gz" "$bundle_name"

  log_success "Python bundle created: $bundle_dir/$bundle_name.tar.gz"
  return 0
}

# Bundle Go project
bundle_go_project() {
  local bundle_dir="${1:-$DEFAULT_BUNDLE_DIR}"

  log_info "Bundling Go project"

  # Check if binary exists from compilation
  local binary_name="$(basename "$PROJECT_ROOT")"
  if [[ -f "$PROJECT_ROOT/dist/$binary_name" ]]; then
    binary_path="$PROJECT_ROOT/dist/$binary_name"
  elif [[ -f "$PROJECT_ROOT/$binary_name" ]]; then
    binary_path="$PROJECT_ROOT/$binary_name"
  else
    log_error "No compiled binary found. Run compile script first."
    return 1
  fi

  # Create bundle directory
  local bundle_name="$binary_name-bundle"
  local target_dir="$bundle_dir/$bundle_name"

  ensure_bundle_directory "$bundle_dir"
  rm -rf "$target_dir"
  mkdir -p "$target_dir"

  # Copy binary
  cp "$binary_path" "$target_dir/"

  # Copy configuration files
  if [[ -f "$PROJECT_ROOT/go.mod" ]]; then
    cp "$PROJECT_ROOT/go.mod" "$target_dir/"
  fi
  if [[ -f "$PROJECT_ROOT/go.sum" ]]; then
    cp "$PROJECT_ROOT/go.sum" "$target_dir/"
  fi

  # Copy any static assets or templates
  if [[ -d "$PROJECT_ROOT/static" ]]; then
    cp -r "$PROJECT_ROOT/static" "$target_dir/"
  fi
  if [[ -d "$PROJECT_ROOT/templates" ]]; then
    cp -r "$PROJECT_ROOT/templates" "$target_dir/"
  fi

  # Create startup script
  cat > "$target_dir/start.sh" << EOF
#!/bin/bash
set -euo pipefail

echo "Starting Go application..."

if [[ -f "$binary_name" ]]; then
  chmod +x "$binary_name"
  ./"$binary_name"
else
  echo "Error: $binary_name not found"
  exit 1
fi
EOF
  chmod +x "$target_dir/start.sh"

  # Create tarball
  cd "$bundle_dir"
  tar -czf "$bundle_name.tar.gz" "$bundle_name"

  log_success "Go bundle created: $bundle_dir/$bundle_name.tar.gz"
  return 0
}

# Bundle Rust project
bundle_rust_project() {
  local bundle_dir="${1:-$DEFAULT_BUNDLE_DIR}"

  log_info "Bundling Rust project"

  # Check if binary exists from compilation
  local binary_name="$(basename "$PROJECT_ROOT")"
  if [[ -f "$PROJECT_ROOT/target/release/$binary_name" ]]; then
    binary_path="$PROJECT_ROOT/target/release/$binary_name"
  elif [[ -f "$PROJECT_ROOT/target/debug/$binary_name" ]]; then
    binary_path="$PROJECT_ROOT/target/debug/$binary_name"
  else
    log_error "No compiled binary found. Run compile script first."
    return 1
  fi

  # Create bundle directory
  local bundle_name="$binary_name-bundle"
  local target_dir="$bundle_dir/$bundle_name"

  ensure_bundle_directory "$bundle_dir"
  rm -rf "$target_dir"
  mkdir -p "$target_dir"

  # Copy binary
  cp "$binary_path" "$target_dir/"

  # Copy configuration files
  if [[ -f "$PROJECT_ROOT/Cargo.toml" ]]; then
    cp "$PROJECT_ROOT/Cargo.toml" "$target_dir/"
  fi

  # Copy any static assets
  if [[ -d "$PROJECT_ROOT/static" ]]; then
    cp -r "$PROJECT_ROOT/static" "$target_dir/"
  fi

  # Create startup script
  cat > "$target_dir/start.sh" << EOF
#!/bin/bash
set -euo pipefail

echo "Starting Rust application..."

if [[ -f "$binary_name" ]]; then
  chmod +x "$binary_name"
  ./"$binary_name"
else
  echo "Error: $binary_name not found"
  exit 1
fi
EOF
  chmod +x "$target_dir/start.sh"

  # Create tarball
  cd "$bundle_dir"
  tar -czf "$bundle_name.tar.gz" "$bundle_name"

  log_success "Rust bundle created: $bundle_dir/$bundle_name.tar.gz"
  return 0
}

# Bundle generic project
bundle_generic_project() {
  local bundle_dir="${1:-$DEFAULT_BUNDLE_DIR}"

  log_info "Bundling generic project"

  # Create bundle directory
  local bundle_name="$(basename "$PROJECT_ROOT")-bundle"
  local target_dir="$bundle_dir/$bundle_name"

  ensure_bundle_directory "$bundle_dir"
  rm -rf "$target_dir"
  mkdir -p "$target_dir"

  # Copy all files except excluded ones
  local exclude_patterns=(
    "--exclude=.git"
    "--exclude=node_modules"
    "--exclude=target"
    "--exclude=dist"
    "--exclude=__pycache__"
    "--exclude=.pytest_cache"
    "--exclude=.coverage"
    "--exclude=*.log"
  )

  rsync -av "${exclude_patterns[@]}" "$PROJECT_ROOT/" "$target_dir/"

  # Create startup script if Makefile exists
  if [[ -f "$target_dir/Makefile" ]]; then
    cat > "$target_dir/start.sh" << 'EOF'
#!/bin/bash
set -euo pipefail

echo "Starting generic project..."

if command -v make >/dev/null 2>&1; then
  make start || make run || make default
else
  echo "Error: make is not available"
  exit 1
fi
EOF
    chmod +x "$target_dir/start.sh"
  fi

  # Create tarball
  cd "$bundle_dir"
  tar -czf "$bundle_name.tar.gz" "$bundle_name"

  log_success "Generic bundle created: $bundle_dir/$bundle_name.tar.gz"
  return 0
}

# Run bundling for detected project type
run_bundling() {
  local project_type="${1:-$(detect_project_type)}"
  local bundle_dir="${2:-$DEFAULT_BUNDLE_DIR}"
  local bundle_success=true

  ensure_bundle_directory "$bundle_dir"

  case "$project_type" in
    "nodejs")
      bundle_nodejs_project "$bundle_dir" || bundle_success=false
      ;;
    "python")
      bundle_python_project "$bundle_dir" || bundle_success=false
      ;;
    "go")
      bundle_go_project "$bundle_dir" || bundle_success=false
      ;;
    "rust")
      bundle_rust_project "$bundle_dir" || bundle_success=false
      ;;
    "generic")
      bundle_generic_project "$bundle_dir" || bundle_success=false
      ;;
    *)
      log_warn "Unknown project type: $project_type, using generic bundling"
      bundle_generic_project "$bundle_dir" || bundle_success=false
      ;;
  esac

  if [[ "$bundle_success" == "true" ]]; then
    generate_bundle_metadata "$bundle_dir" "$project_type" "$(basename "$PROJECT_ROOT")-bundle"
    log_success "✅ Bundling completed successfully"
    return 0
  else
    log_error "❌ Bundling failed"
    return 1
  fi
}

# Main bundling function
main() {
  local project_type="${1:-}"
  local bundle_dir="${2:-$DEFAULT_BUNDLE_DIR}"
  local behavior
  behavior=$(get_script_behavior)

  log_info "CI Bundle Script v$BUNDLE_SCRIPT_VERSION"

  case "$behavior" in
    "DRY_RUN")
      echo "🔍 DRY RUN: Would bundle project"
      if [[ -n "$project_type" ]]; then
        echo "Project type: $project_type"
      else
        echo "Project type: $(detect_project_type)"
      fi
      echo "Bundle directory: $bundle_dir"
      echo "Would create deployment bundle"
      return 0
      ;;
    "PASS")
      echo "✅ PASS MODE: Bundle simulated successfully"
      return 0
      ;;
    "FAIL")
      echo "❌ FAIL MODE: Simulating bundle failure"
      return 1
      ;;
    "SKIP")
      echo "⏭️ SKIP MODE: Bundle skipped"
      return 0
      ;;
    "TIMEOUT")
      echo "⏰ TIMEOUT MODE: Simulating bundle timeout"
      sleep 5
      return 124
      ;;
  esac

  # EXECUTE mode - Actual bundling
  log_info "🚀 EXECUTE: Bundling project"

  # Use provided project type or detect automatically
  if [[ -z "$project_type" ]]; then
    project_type=$(detect_project_type)
  fi

  log_info "Project type: $project_type"
  log_info "Bundle directory: $bundle_dir"

  # Change to project root if not already there
  if [[ "$PWD" != "$PROJECT_ROOT" ]]; then
    cd "$PROJECT_ROOT"
  fi

  # Run bundling
  if run_bundling "$project_type" "$bundle_dir"; then
    log_success "✅ Bundle script completed successfully"
    return 0
  else
    log_error "❌ Bundle script failed"
    return 1
  fi
}

# CLI interface
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Parse command line arguments
  case "${1:-}" in
    "help"|"--help"|"-h")
      cat << EOF
CI Bundle Script v$BUNDLE_SCRIPT_VERSION

Creates distribution bundles for deployment with full testability support.

Usage:
  ./scripts/build/40-ci-bundle.sh [project_type] [bundle_directory]

Project Types:
  nodejs   - Node.js project (compiled JS, package.json)
  python   - Python project (source, requirements, bytecode)
  go       - Go project (compiled binary, go.mod)
  rust     - Rust project (compiled binary, Cargo.toml)
  generic  - Generic project (all files, Makefile support)

Bundle Directory:
  Default: ./dist
  Custom: Provide second argument

Environment Variables:
  PIPELINE_BUNDLE_MODE   EXECUTE, DRY_RUN, PASS, FAIL, SKIP, TIMEOUT
  BUNDLE_MODE           EXECUTE, DRY_RUN, PASS, FAIL, SKIP, TIMEOUT
  CI_TEST_MODE          Global testability mode
  INCLUDE_NODE_MODULES  Include node_modules in bundle (default: false)
  CI_JOB_TIMEOUT_MINUTES  Timeout override for bundle operations

Bundle Contents:
- Compiled artifacts/binaries
- Configuration files
- Startup scripts
- Deployment metadata
- Installation instructions

Testability:
  This script supports hierarchical testability control:
  1. PIPELINE_BUNDLE_MODE (highest priority)
  2. BUNDLE_MODE
  3. CI_TEST_MODE (global)
  4. Default: EXECUTE

Examples:
  # Auto-detect and bundle
  ./scripts/build/40-ci-bundle.sh

  # Bundle specific project type
  ./scripts/build/40-ci-bundle.sh nodejs

  # Bundle to custom directory
  ./scripts/build/40-ci-bundle.sh nodejs ./releases

  # Include node_modules in bundle
  INCLUDE_NODE_MODULES=true ./scripts/build/40-ci-bundle.sh nodejs

  # Dry run bundling
  BUNDLE_MODE=DRY_RUN ./scripts/build/40-ci-bundle.sh

Integration:
  This script integrates with:
  - GitHub Actions workflows
  - CI/CD pipeline orchestration
  - Deployment automation
  - Multi-language project bundling
EOF
      exit 0
      ;;
    "detect")
      # Detection mode
      echo "Detected project type: $(detect_project_type)"
      ;;
    "validate")
      # Validation mode
      echo "Validating bundle setup..."

      local project_type
      project_type=$(detect_project_type)
      echo "Project type: $project_type"

      # Check for compiled artifacts
      case "$project_type" in
        "nodejs")
          [[ -d "dist" ]] && echo "✅ dist directory exists" || echo "⚠️ dist directory not found"
          ;;
        "go"|"rust")
          [[ -d "dist" ]] && echo "✅ dist directory exists" || echo "⚠️ dist directory not found"
          ;;
      esac

      # Check for bundling tools
      command -v tar >/dev/null && echo "✅ tar available" || echo "❌ tar not available"
      command -v rsync >/dev/null && echo "✅ rsync available" || echo "⚠️ rsync not available"
      ;;
    *)
      main "$@"
      ;;
  esac
fi