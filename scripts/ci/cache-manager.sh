#!/usr/bin/env bash
# GitHub Actions Cache Manager
# Manages dependency and build artifact caching for CI/CD pipelines

set -euo pipefail

# Source utilities if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/../lib/common.sh" ]]; then
  # shellcheck source=../lib/common.sh
  source "${SCRIPT_DIR}/../lib/common.sh"
fi

# Configuration
CACHE_DIR="/tmp/ci-cache"
NODE_MODULES_CACHE_KEY="node-modules-${RUNNER_OS:-linux}"
BUILD_CACHE_KEY="build-${GITHUB_REF_NAME:-main}-${GITHUB_SHA:-unknown}"
DEPS_CACHE_KEY="deps-${RUNNER_OS:-linux}"

# Cache types and their configurations
declare -A CACHE_CONFIGS=(
  ["node_modules"]="${NODE_MODULES_CACHE_KEY}"
  ["build"]="${BUILD_CACHE_KEY}"
  ["deps"]="${DEPS_CACHE_KEY}"
  ["test-results"]="test-results-${GITHUB_REF_NAME:-main}"
  ["coverage"]="coverage-${GITHUB_REF_NAME:-main}"
)

# Generate cache key with file hash
generate_cache_key() {
  local base_key="$1"
  local hash_file="$2"
  local extra_info="${3:-}"

  if [[ -f "$hash_file" ]]; then
    local file_hash
    if command -v sha256sum >/dev/null 2>&1; then
      file_hash=$(sha256sum "$hash_file" | cut -d' ' -f1)
    elif command -v shasum >/dev/null 2>&1; then
      file_hash=$(shasum -a 256 "$hash_file" | cut -d' ' -f1)
    else
      file_hash=$(stat -c %Y "$hash_file" 2>/dev/null || stat -f %m "$hash_file" 2>/dev/null || echo "unknown")
    fi
    echo "${base_key}-${file_hash:0:8}${extra_info:+-${extra_info}}"
  else
    echo "${base_key}${extra_info:+-${extra_info}}"
  fi
}

# Setup cache directory
setup_cache_dir() {
  mkdir -p "$CACHE_DIR"
  log_debug "Cache directory created: $CACHE_DIR"
}

# Save cache with compression
save_cache() {
  local cache_name="$1"
  local source_dir="$2"
  local cache_key="${3:-}"

  if [[ ! -d "$source_dir" ]]; then
    log_warning "Source directory not found for cache: $source_dir"
    return 0
  fi

  if [[ -z "$cache_key" ]]; then
    cache_key="${CACHE_CONFIGS[$cache_name]:-$cache_name}"
  fi

  local cache_file="${CACHE_DIR}/${cache_name}-${cache_key}.tar.gz"

  log_info "Saving cache: $cache_name (key: $cache_key)"
  log_debug "Source: $source_dir"
  log_debug "Cache file: $cache_file"

  # Create compressed archive
  if command -v tar >/dev/null 2>&1; then
    tar -czf "$cache_file" -C "$(dirname "$source_dir")" "$(basename "$source_dir")"
    log_success "Cache saved: $cache_name ($source_dir -> $cache_file)"
  else
    log_error "tar command not available for cache creation"
    return 1
  fi
}

# Restore cache with decompression
restore_cache() {
  local cache_name="$1"
  local target_dir="$2"
  local cache_key="${3:-}"
  local fallback_key="${4:-}"

  if [[ -z "$cache_key" ]]; then
    cache_key="${CACHE_CONFIGS[$cache_name]:-$cache_name}"
  fi

  local cache_file="${CACHE_DIR}/${cache_name}-${cache_key}.tar.gz"

  # Try exact match first
  if [[ -f "$cache_file" ]]; then
    log_info "Restoring cache: $cache_name (key: $cache_key)"
    log_debug "Target: $target_dir"
    log_debug "Cache file: $cache_file"

    # Ensure target directory exists
    mkdir -p "$(dirname "$target_dir")"

    # Extract archive
    if command -v tar >/dev/null 2>&1; then
      tar -xzf "$cache_file" -C "$(dirname "$target_dir")"
      log_success "Cache restored: $cache_name ($cache_file -> $target_dir)"
      return 0
    else
      log_error "tar command not available for cache extraction"
      return 1
    fi
  fi

  # Try fallback key if provided
  if [[ -n "$fallback_key" ]]; then
    local fallback_file="${CACHE_DIR}/${cache_name}-${fallback_key}.tar.gz"
    if [[ -f "$fallback_file" ]]; then
      log_info "Restoring fallback cache: $cache_name (key: $fallback_key)"
      mkdir -p "$(dirname "$target_dir")"
      tar -xzf "$fallback_file" -C "$(dirname "$target_dir")"
      log_success "Fallback cache restored: $cache_name"
      return 0
    fi
  fi

  log_info "Cache not found: $cache_name (key: $cache_key)"
  return 1
}

# Clean up old cache files
cleanup_cache() {
  local cache_name="$1"
  local keep_count="${2:-3}"

  log_info "Cleaning up old cache files for: $cache_name"

  local cache_files=()
  readarray -t cache_files < <(find "$CACHE_DIR" -name "${cache_name}-*.tar.gz" -printf "%T@ %p\n" | sort -nr | cut -d' ' -f2-)

  local files_to_remove=$(( ${#cache_files[@]} - keep_count ))
  if [[ $files_to_remove -gt 0 ]]; then
    for ((i=keep_count; i<${#cache_files[@]}; i++)); do
      local file_to_remove="${cache_files[$i]}"
      log_debug "Removing old cache: $file_to_remove"
      rm -f "$file_to_remove"
    done
    log_success "Cleaned up $files_to_remove old cache files for $cache_name"
  else
    log_debug "No old cache files to remove for $cache_name"
  fi
}

# List available caches
list_caches() {
  local cache_name="${1:-}"

  log_info "Available caches:"

  if [[ -n "$cache_name" ]]; then
    find "$CACHE_DIR" -name "${cache_name}-*.tar.gz" -ls
  else
    find "$CACHE_DIR" -name "*.tar.gz" -ls
  fi
}

# Get cache statistics
get_cache_stats() {
  log_info "Cache statistics:"

  local total_size=0
  local total_files=0

  if [[ -d "$CACHE_DIR" ]]; then
    while IFS= read -r -d '' file; do
      local file_size
      file_size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo 0)
      ((total_size += file_size))
      ((total_files++))
    done < <(find "$CACHE_DIR" -name "*.tar.gz" -print0)

    echo "Total cache files: $total_files"
    echo "Total cache size: $(numfmt --to=iec "$total_size")"
  else
    echo "Cache directory not found: $CACHE_DIR"
  fi
}

# Cache manager for Node.js dependencies
cache_node_modules() {
  local action="${1:-auto}"
  local project_root="${2:-.}"

  local node_modules_dir="${project_root}/node_modules"
  local package_json="${project_root}/package.json"
  local package_lock="${project_root}/package-lock.json"

  case "$action" in
    "save")
      if [[ -d "$node_modules_dir" ]]; then
        local cache_key
        cache_key=$(generate_cache_key "node-modules" "$package_lock" "dependencies")
        save_cache "node_modules" "$node_modules_dir" "$cache_key"
        cleanup_cache "node_modules" 2
      else
        log_warning "node_modules directory not found, cannot save cache"
      fi
      ;;
    "restore")
      local cache_key
      cache_key=$(generate_cache_key "node-modules" "$package_lock" "dependencies")
      if ! restore_cache "node_modules" "$node_modules_dir" "$cache_key"; then
        log_info "Node.js cache miss, dependencies will be installed fresh"
        return 1
      fi
      ;;
    "auto")
      # Check if we should restore or save
      if [[ -d "$node_modules_dir" ]]; then
        cache_node_modules "save" "$project_root"
      else
        cache_node_modules "restore" "$project_root"
      fi
      ;;
    *)
      log_error "Unknown action for Node.js cache: $action"
      return 1
      ;;
  esac
}

# Cache manager for build artifacts
cache_build_artifacts() {
  local action="${1:-auto}"
  local build_dir="${2:-build}"
  local hash_files="${3:-src/**}"

  case "$action" in
    "save")
      if [[ -d "$build_dir" ]]; then
        local cache_key
        cache_key=$(generate_cache_key "build" "$hash_files" "build-artifacts")
        save_cache "build" "$build_dir" "$cache_key"
        cleanup_cache "build" 2
      else
        log_warning "Build directory not found, cannot save cache"
      fi
      ;;
    "restore")
      local cache_key
      cache_key=$(generate_cache_key "build" "$hash_files" "build-artifacts")
      restore_cache "build" "$build_dir" "$cache_key"
      ;;
    "auto")
      if [[ -d "$build_dir" ]]; then
        cache_build_artifacts "save" "$build_dir" "$hash_files"
      else
        cache_build_artifacts "restore" "$build_dir" "$hash_files"
      fi
      ;;
    *)
      log_error "Unknown action for build cache: $action"
      return 1
      ;;
  esac
}

# Cache manager for test results
cache_test_results() {
  local action="${1:-save}"
  local test_results_dir="${2:-test-results}"
  local cache_key="${3:-test-results}"

  case "$action" in
    "save")
      if [[ -d "$test_results_dir" ]]; then
        save_cache "test-results" "$test_results_dir" "$cache_key"
      fi
      ;;
    "restore")
      restore_cache "test-results" "$test_results_dir" "$cache_key"
      ;;
    *)
      log_error "Unknown action for test results cache: $action"
      return 1
      ;;
  esac
}

# Generate GitHub Actions cache steps
generate_github_actions_cache_steps() {
  local cache_type="$1"
  local path="$2"
  local key="${3:-}"
  local restore_keys="${4:-}"

  cat <<EOF
    - name: Cache ${cache_type}
      uses: actions/cache@v4
      with:
        path: ${path}
        key: ${key}
        restore-keys: |
          ${restore_keys}
EOF
}

# Main cache management function
main() {
  local action="${1:-help}"
  shift

  case "$action" in
    "setup")
      setup_cache_dir
      ;;
    "save")
      local cache_name="$1"
      local source_dir="$2"
      local cache_key="${3:-}"
      save_cache "$cache_name" "$source_dir" "$cache_key"
      ;;
    "restore")
      local cache_name="$1"
      local target_dir="$2"
      local cache_key="${3:-}"
      restore_cache "$cache_name" "$target_dir" "$cache_key"
      ;;
    "cleanup")
      local cache_name="$1"
      local keep_count="${2:-3}"
      cleanup_cache "$cache_name" "$keep_count"
      ;;
    "list")
      local cache_name="${1:-}"
      list_caches "$cache_name"
      ;;
    "stats")
      get_cache_stats
      ;;
    "node-modules")
      cache_node_modules "$@"
      ;;
    "build")
      cache_build_artifacts "$@"
      ;;
    "test-results")
      cache_test_results "$@"
      ;;
    "github-steps")
      generate_github_actions_cache_steps "$@"
      ;;
    "help")
      cat <<EOF
Usage: $0 <action> [options]

Actions:
  setup                          Set up cache directory
  save <name> <source> [key]     Save cache
  restore <name> <target> [key]  Restore cache
  cleanup <name> [count]         Clean up old caches (keep count, default: 3)
  list [name]                    List available caches
  stats                          Show cache statistics
  node-modules <action> [root]   Manage Node.js dependencies cache
  build <action> <dir> [files]   Manage build artifacts cache
  test-results <action> <dir>    Manage test results cache
  github-steps <type> <path>     Generate GitHub Actions cache steps
  help                          Show this help message

Examples:
  $0 save node_modules ./node_modules
  $0 restore node-modules ./node_modules node-modules-v1.2.3
  $0 cleanup node-modules 2
  $0 node-modules restore .
  $0 build save ./build src/**/*
EOF
      ;;
    *)
      log_error "Unknown action: $action"
      main "help"
      return 1
      ;;
  esac
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi