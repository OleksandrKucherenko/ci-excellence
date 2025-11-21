#!/usr/bin/env bash
# CI Compile Script
# Builds the application and validates compilation success

set -euo pipefail

# Source shared utilities
# shellcheck source=../../scripts/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Script configuration
readonly SCRIPT_NAME="$(basename "$0" .sh)"
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_DESCRIPTION="Compile and build application"

# Default build configuration
DEFAULT_BUILD_PROFILE="release"
DEFAULT_CLEAN_BUILD=false
DEFAULT_VERIFICATION=true

# Usage information
usage() {
  cat <<EOF
Usage: $SCRIPT_NAME [OPTIONS]

Compile and build the application with full verification.

OPTIONS:
  -p, --profile PROFILE       Build profile (debug|release) [default: $DEFAULT_BUILD_PROFILE]
  -c, --clean                 Clean build (remove artifacts first)
  -v, --verify                Verify build output after compilation
  -t, --test-mode MODE        Test mode (DRY_RUN|SIMULATE|EXECUTE)
  -h, --help                  Show this help message
  -V, --version               Show version information

EXAMPLES:
  $SCRIPT_NAME                           # Build with default settings
  $SCRIPT_NAME --profile debug           # Debug build
  $SCRIPT_NAME --clean --verify          # Clean build with verification
  $SCRIPT_NAME --test-mode DRY_RUN       # Preview compilation steps

BUILD PROFILES:
  debug          Build without optimization, include debug symbols
  release        Build with optimization, strip debug symbols
  test           Build for testing (may include test utilities)

ENVIRONMENT VARIABLES:
  CI_TEST_MODE               Test mode override (DRY_RUN|SIMULATE|EXECUTE)
  CI_BUILD_PROFILE           Build profile override
  CI_CLEAN_BUILD             Force clean build (true|false)
  CI_VERIFICATION_ENABLED    Enable/disable build verification
  BUILD_OUTPUT_DIR          Build output directory
  CACHE_ENABLED            Enable/disable build caching

EXIT CODES:
  0     Success
  1     General error
  2     Build failed
  3     Verification failed
  4     Invalid arguments
  5     Prerequisites not met

EOF
}

# Show version information
version() {
  echo "$SCRIPT_NAME version $SCRIPT_VERSION"
  echo "$SCRIPT_DESCRIPTION"
}

# Parse command line arguments
parse_args() {
  # Default options
  local opt_profile="$DEFAULT_BUILD_PROFILE"
  local opt_clean_build="$DEFAULT_CLEAN_BUILD"
  local opt_verification="$DEFAULT_VERIFICATION"
  local opt_test_mode=""

  # Parse options
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -p|--profile)
        shift
        if [[ -z "$1" ]]; then
          log_error "Profile cannot be empty"
          return 4
        fi
        opt_profile="$1"
        shift
        ;;
      -c|--clean)
        opt_clean_build=true
        shift
        ;;
      -v|--verify)
        opt_verification=true
        shift
        ;;
      -t|--test-mode)
        shift
        if [[ -z "$1" ]]; then
          log_error "Test mode cannot be empty"
          return 4
        fi
        case "$1" in
          DRY_RUN|SIMULATE|EXECUTE) ;;
          *)
            log_error "Invalid test mode: $1. Use DRY_RUN, SIMULATE, or EXECUTE"
            return 4
            ;;
        esac
        opt_test_mode="$1"
        shift
        ;;
      -h|--help)
        usage
        return 0
        ;;
      -V|--version)
        version
        return 0
        ;;
      -*)
        log_error "Unknown option: $1"
        usage
        return 4
        ;;
      *)
        log_error "Unexpected argument: $1"
        usage
        return 4
        ;;
    esac
  done

  # Set global variables
  export BUILD_PROFILE="$opt_profile"
  export CLEAN_BUILD="$opt_clean_build"
  export VERIFICATION_ENABLED="$opt_verification"

  # Resolve test mode
  local resolved_mode
  if ! resolved_mode=$(resolve_test_mode "$SCRIPT_NAME" "build" "$opt_test_mode"); then
    return 1
  fi
  export TEST_MODE="$resolved_mode"

  return 0
}

# Validate build profile
validate_build_profile() {
  local profile="$1"
  local valid_profiles=("debug" "release" "test")

  for valid_profile in "${valid_profiles[@]}"; do
    if [[ "$profile" == "$valid_profile" ]]; then
      return 0
    fi
  done

  log_error "Invalid build profile: $profile"
  log_info "Valid profiles: ${valid_profiles[*]}"
  return 1
}

# Check build prerequisites
check_prerequisites() {
  log_info "Checking build prerequisites"

  local missing_tools=()

  # Check for Node.js and npm if package.json exists
  if [[ -f "package.json" ]]; then
    if ! command -v node >/dev/null 2>&1; then
      missing_tools+=("node")
    fi
    if ! command -v npm >/dev/null 2>&1; then
      missing_tools+=("npm")
    fi
  fi

  # Check for bun if bun.lockb exists
  if [[ -f "bun.lockb" ]]; then
    if ! command -v bun >/dev/null 2>&1; then
      missing_tools+=("bun")
    fi
  fi

  # Check for bun if bun.lock exists
  if [[ -f "bun.lock" ]]; then
    if ! command -v bun >/dev/null 2>&1; then
      missing_tools+=("bun")
    fi
  fi

  # Check for tsconfig.json (TypeScript project)
  if [[ -f "tsconfig.json" ]]; then
    if ! command -v tsc >/dev/null 2>&1 && ! command -v bun >/dev/null 2>&1; then
      missing_tools+=("typescript")
    fi
  fi

  if [[ ${#missing_tools[@]} -gt 0 ]]; then
    log_error "Missing build tools: ${missing_tools[*]}"
    return 5
  fi

  # Validate build profile
  if ! validate_build_profile "$BUILD_PROFILE"; then
    return 5
  fi

  log_success "✅ Build prerequisites met"
  return 0
}

# Configure build environment
configure_build_environment() {
  log_info "Configuring build environment"

  # Export build environment variables
  export NODE_ENV="${BUILD_PROFILE}"
  export BUILD_PROFILE="$BUILD_PROFILE"
  export BUILD_TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  export BUILD_COMMIT="${GITHUB_SHA:-$(git rev-parse HEAD 2>/dev/null || echo 'unknown')}"
  export BUILD_BRANCH="${GITHUB_REF_NAME:-$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')}"

  # Set output directory
  local output_dir="${BUILD_OUTPUT_DIR:-dist}"
  export BUILD_OUTPUT_DIR="$output_dir"

  # Configure build profile specific settings
  case "$BUILD_PROFILE" in
    "debug")
      export NODE_OPTIONS="--inspect"
      export SOURCE_MAP=true
      ;;
    "release")
      export NODE_OPTIONS="--optimize"
      export SOURCE_MAP=false
      ;;
    "test")
      export NODE_ENV="test"
      export SOURCE_MAP=true
      ;;
  esac

  # Configure caching
  export CACHE_ENABLED="${CACHE_ENABLED:-true}"
  export CACHE_DIR="${CACHE_DIR:-.cache/build}"

  log_info "Build environment configured:"
  log_info "  Profile: $BUILD_PROFILE"
  log_info "  Output: $BUILD_OUTPUT_DIR"
  log_info "  Cache enabled: $CACHE_ENABLED"
  log_info "  Node environment: $NODE_ENV"

  return 0
}

# Clean build artifacts
clean_build() {
  log_info "Cleaning build artifacts"

  local artifacts=(
    "node_modules/.cache"
    ".nyc_output"
    "coverage"
    "dist"
    "build"
    ".next"
    ".turbo"
    "out"
    "tsconfig.tsbuildinfo"
    "*.tsbuildinfo"
  )

  local removed_count=0

  for artifact in "${artifacts[@]}"; do
    if [[ -e "$artifact" ]]; then
      case "$TEST_MODE" in
        "DRY_RUN")
          log_info "Would remove: $artifact"
          ;;
        "SIMULATE")
          log_info "Simulating removal of: $artifact"
          ;;
        "EXECUTE")
          rm -rf "$artifact"
          log_info "Removed: $artifact"
          ;;
      esac
      ((removed_count++))
    fi
  done

  case "$TEST_MODE" in
    "DRY_RUN"|"SIMULATE")
      log_info "Would clean $removed_count build artifacts"
      ;;
    "EXECUTE")
      log_info "Cleaned $removed_count build artifacts"
      ;;
  esac

  return 0
}

# Install dependencies
install_dependencies() {
  log_info "Installing dependencies"

  case "$TEST_MODE" in
    "DRY_RUN")
      log_info "Would install dependencies"
      return 0
      ;;
    "SIMULATE")
      log_info "Simulating dependency installation"
      sleep 1
      return 0
      ;;
  esac

  # Check available package managers and use the best one
  local pkg_manager_cmd=""
  local pkg_manager_lock=""

  # Prefer bun if available and lock file exists
  if [[ -f "bun.lockb" || -f "bun.lock" ]] && command -v bun >/dev/null 2>&1; then
    pkg_manager_cmd="bun"
    pkg_manager_lock="bun.lockb"
  # Use npm if package-lock.json exists
  elif [[ -f "package-lock.json" ]]; then
    pkg_manager_cmd="npm"
    pkg_manager_lock="package-lock.json"
  # Default to npm if package.json exists
  elif [[ -f "package.json" ]]; then
    pkg_manager_cmd="npm"
  else
    log_warning "No package manager detected, skipping dependency installation"
    return 0
  fi

  log_info "Using package manager: $pkg_manager_cmd"

  # Install dependencies based on package manager
  case "$pkg_manager_cmd" in
    "bun")
      if [[ "$CACHE_ENABLED" == "true" ]]; then
        bun install --frozen-lockfile
      else
        bun install --frozen-lockfile --no-cache
      fi
      ;;
    "npm")
      if [[ "$CACHE_ENABLED" == "true" ]]; then
        npm ci --cache "$CACHE_DIR/npm"
      else
        npm ci --no-cache
      fi
      ;;
  esac

  log_success "✅ Dependencies installed"
  return 0
}

# Run TypeScript compilation
run_typescript_compile() {
  log_info "Running TypeScript compilation"

  if [[ ! -f "tsconfig.json" ]]; then
    log_info "No TypeScript configuration found, skipping compilation"
    return 0
  fi

  case "$TEST_MODE" in
    "DRY_RUN")
      log_info "Would compile TypeScript code"
      return 0
      ;;
    "SIMULATE")
      log_info "Simulating TypeScript compilation"
      sleep 2
      return 0
      ;;
  esac

  # Use tsc if available, otherwise use bun
  if command -v tsc >/dev/null 2>&1; then
    log_info "Using TypeScript compiler"

    # Set compilation flags based on build profile
    local tsc_flags=""
    case "$BUILD_PROFILE" in
      "release")
        tsc_flags="--noEmitOnError --strict"
        ;;
      "debug"|"test")
        tsc_flags="--sourceMap --declaration"
        ;;
    esac

    if tsc $tsc_flags; then
      log_success "✅ TypeScript compilation successful"
    else
      log_error "❌ TypeScript compilation failed"
      return 2
    fi
  elif command -v bun >/dev/null 2>&1; then
    log_info "Using bun for TypeScript compilation"

    # Set build flags based on build profile
    local bun_flags=""
    case "$BUILD_PROFILE" in
      "release")
        bun_flags="--minify"
        ;;
      "debug"|"test")
        bun_flags="--sourcemap"
        ;;
    esac

    if bun build $bun_flags --outdir "$BUILD_OUTPUT_DIR" $(find src -name "*.ts" 2>/dev/null || echo ""); then
      log_success "✅ Bun build successful"
    else
      log_error "❌ Bun build failed"
      return 2
    fi
  else
    log_error "No TypeScript compiler available"
    return 5
  fi

  return 0
}

# Run application build
run_application_build() {
  log_info "Running application build"

  case "$TEST_MODE" in
    "DRY_RUN")
      log_info "Would build application"
      return 0
      ;;
    "SIMULATE")
      log_info "Simulating application build"
      sleep 3
      return 0
      ;;
  esac

  # Check for build scripts in package.json
  local build_script=""
  if [[ -f "package.json" ]]; then
    build_script=$(node -e "console.log(JSON.parse(require('fs').readFileSync('package.json', 'utf8')).scripts?.build || '')" 2>/dev/null || echo "")
  fi

  if [[ -n "$build_script" ]]; then
    log_info "Running npm build script: $build_script"

    # Prefer bun if available
    if command -v bun >/dev/null 2>&1; then
      if bun run build; then
        log_success "✅ Application build successful"
      else
        log_error "❌ Application build failed"
        return 2
      fi
    elif command -v npm >/dev/null 2>&1; then
      if npm run build; then
        log_success "✅ Application build successful"
      else
        log_error "❌ Application build failed"
        return 2
      fi
    else
      log_error "No package manager available for build script"
      return 5
    fi
  else
    log_info "No build script found in package.json, skipping application build"
  fi

  return 0
}

# Verify build output
verify_build_output() {
  if [[ "$VERIFICATION_ENABLED" != "true" ]]; then
    log_info "Build verification disabled"
    return 0
  fi

  log_info "Verifying build output"

  case "$TEST_MODE" in
    "DRY_RUN")
      log_info "Would verify build output"
      return 0
      ;;
    "SIMULATE")
      log_info "Simulating build verification"
      sleep 1
      return 0
      ;;
  esac

  local verification_failed=false

  # Check if output directory exists and has content
  if [[ ! -d "$BUILD_OUTPUT_DIR" ]]; then
    log_error "Build output directory does not exist: $BUILD_OUTPUT_DIR"
    verification_failed=true
  else
    local file_count
    file_count=$(find "$BUILD_OUTPUT_DIR" -type f | wc -l)
    if [[ $file_count -eq 0 ]]; then
      log_error "Build output directory is empty: $BUILD_OUTPUT_DIR"
      verification_failed=true
    else
      log_info "Build output contains $file_count files"
    fi
  fi

  # Check for common build artifacts
  local expected_files=("index.js" "main.js" "app.js")
  for expected_file in "${expected_files[@]}"; do
    local expected_path="$BUILD_OUTPUT_DIR/$expected_file"
    if [[ -f "$expected_path" ]]; then
      log_info "Found expected build artifact: $expected_file"
    fi
  done

  # Check file sizes (detect empty files)
  if [[ -d "$BUILD_OUTPUT_DIR" ]]; then
    local empty_files
    empty_files=$(find "$BUILD_OUTPUT_DIR" -type f -size 0 2>/dev/null | wc -l)
    if [[ $empty_files -gt 0 ]]; then
      log_warning "Found $empty_files empty files in build output"
    fi
  fi

  if [[ "$verification_failed" == "true" ]]; then
    log_error "❌ Build verification failed"
    return 3
  fi

  log_success "✅ Build verification successful"
  return 0
}

# Generate build report
generate_build_report() {
  local build_status="$1"
  local start_time="$2"
  local end_time=$(date +%s)

  log_info "Generating build report"

  local build_duration=$((end_time - start_time))
  local output_dir="${BUILD_REPORT_OUTPUT:-reports/build}"
  mkdir -p "$output_dir"

  local report_file="$output_dir/build-report-$(date +%Y%m%d-%H%M%S).json"

  # Build report content
  cat > "$report_file" << EOF
{
  "build": {
    "script": "$SCRIPT_NAME",
    "version": "$SCRIPT_VERSION",
    "status": "$build_status",
    "profile": "$BUILD_PROFILE",
    "test_mode": "$TEST_MODE",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "duration_seconds": $build_duration,
    "environment": {
      "node_env": "$NODE_ENV",
      "build_output_dir": "$BUILD_OUTPUT_DIR",
      "cache_enabled": "$CACHE_ENABLED",
      "build_commit": "$BUILD_COMMIT",
      "build_branch": "$BUILD_BRANCH"
    }
  },
  "output": {
    "directory": "$BUILD_OUTPUT_DIR",
    "files_count": $(find "$BUILD_OUTPUT_DIR" -type f 2>/dev/null | wc -l || echo 0),
    "directory_exists": $([[ -d "$BUILD_OUTPUT_DIR" ]] && echo "true" || echo "false")
  },
  "verification": {
    "enabled": "$VERIFICATION_ENABLED",
    "passed": $([[ "$build_status" == "success" ]] && echo "true" || echo "false")
  }
}
EOF

  log_success "✅ Build report generated: $report_file"

  # Export for CI systems
  export BUILD_REPORT_FILE="$report_file"

  return 0
}

# Main compilation function
main() {
  local start_time
  start_time=$(date +%s)

  log_info "🔨 Starting CI compilation"
  log_info "Script version: $SCRIPT_VERSION"

  # Parse command line arguments
  if ! parse_args "$@"; then
    return 1
  fi

  log_info "Build configuration:"
  log_info "  Profile: $BUILD_PROFILE"
  log_info "  Clean build: $CLEAN_BUILD"
  log_info "  Verification: $VERIFICATION_ENABLED"
  log_info "  Test mode: $TEST_MODE"

  # Run compilation pipeline
  if ! check_prerequisites; then
    return 5
  fi

  if ! configure_build_environment; then
    return 1
  fi

  if [[ "$CLEAN_BUILD" == "true" ]]; then
    if ! clean_build; then
      return 1
    fi
  fi

  if ! install_dependencies; then
    return 2
  fi

  if ! run_typescript_compile; then
    return 2
  fi

  if ! run_application_build; then
    return 2
  fi

  if ! verify_build_output; then
    return 3
  fi

  # Success
  log_success "✅ CI compilation completed successfully"
  generate_build_report "success" "$start_time"

  # Show actionable items for CI
  if [[ -n "${CI:-}" ]]; then
    echo
    log_info "🔗 Next steps for CI pipeline:"
    log_info "   • Run tests: scripts/ci/50-ci-test.sh"
    log_info "   • Run linting: scripts/ci/40-ci-lint.sh"
    log_info "   • Publish artifacts: scripts/ci/60-ci-publish.sh"
  fi

  return 0
}

# Error handling
trap 'log_error "Script failed with exit code $?"' ERR

# Execute main function with all arguments
main "$@"