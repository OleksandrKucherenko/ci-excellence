#!/bin/bash
# Tag Utilities for Git Operations
# Provides utilities for version parsing, tag manipulation, and semver comparison

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/scripts/lib/common.sh" 2>/dev/null || {
  echo "Failed to source common utilities" >&2
  exit 1
}

# Tag pattern definitions
readonly VERSION_TAG_REGEX="^(.*/)?v([0-9]+)\.([0-9]+)\.([0-9]+)(-([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))?(\+([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))?$"
readonly ENVIRONMENT_TAG_REGEX="^(.*/)?(production|staging|canary|sandbox|performance)$"
readonly STATE_TAG_REGEX="^(.*/)?v([0-9]+)\.([0-9]+)\.([0-9]+)(-[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?-(stable|unstable|deprecated)$"

# Parse version tag components
parse_version_tag() {
  local tag="$1"
  local component="$2"  # major, minor, patch, prerelease, build, subproject

  if [[ ! "$tag" =~ $VERSION_TAG_REGEX ]]; then
    log_error "Invalid version tag format: $tag"
    return 1
  fi

  local subproject="${BASH_REMATCH[1]%/}"
  local major="${BASH_REMATCH[2]}"
  local minor="${BASH_REMATCH[3]}"
  local patch="${BASH_REMATCH[4]}"
  local prerelease="${BASH_REMATCH[6]}"
  local build="${BASH_REMATCH[8]}"

  case "$component" in
    "subproject")
      echo "${subproject:-}"
      ;;
    "major")
      echo "$major"
      ;;
    "minor")
      echo "$minor"
      ;;
    "patch")
      echo "$patch"
      ;;
    "prerelease")
      echo "${prerelease:-}"
      ;;
    "build")
      echo "${build:-}"
      ;;
    "full")
      echo "${major}.${minor}.${patch}${prerelease:+-$prerelease}${build:++$build}"
      ;;
    *)
      log_error "Unknown component: $component"
      return 1
      ;;
  esac
}

# Parse environment tag
parse_environment_tag() {
  local tag="$1"
  local component="$2"  # subproject, environment

  if [[ ! "$tag" =~ $ENVIRONMENT_TAG_REGEX ]]; then
    log_error "Invalid environment tag format: $tag"
    return 1
  fi

  local subproject="${BASH_REMATCH[1]%/}"
  local environment="${BASH_REMATCH[2]}"

  case "$component" in
    "subproject")
      echo "${subproject:-}"
      ;;
    "environment")
      echo "$environment"
      ;;
    *)
      log_error "Unknown component: $component"
      return 1
      ;;
  esac
}

# Parse state tag
parse_state_tag() {
  local tag="$1"
  local component="$2"  # subproject, version, state

  if [[ ! "$tag" =~ $STATE_TAG_REGEX ]]; then
    log_error "Invalid state tag format: $tag"
    return 1
  fi

  local subproject="${BASH_REMATCH[1]%/}"
  local version="${BASH_REMATCH[2]}.${BASH_REMATCH[3]}.${BASH_REMATCH[4]}${BASH_REMATCH[6]:+-${BASH_REMATCH[6]}}"
  local state="${BASH_REMATCH[10]}"

  case "$component" in
    "subproject")
      echo "${subproject:-}"
      ;;
    "version")
      echo "$version"
      ;;
    "state")
      echo "$state"
      ;;
    *)
      log_error "Unknown component: $component"
      return 1
      ;;
  esac
}

# Get tag type
get_tag_type() {
  local tag="$1"

  if [[ "$tag" =~ $VERSION_TAG_REGEX ]]; then
    echo "version"
  elif [[ "$tag" =~ $ENVIRONMENT_TAG_REGEX ]]; then
    echo "environment"
  elif [[ "$tag" =~ $STATE_TAG_REGEX ]]; then
    echo "state"
  else
    echo "unknown"
  fi
}

# Validate tag format
validate_tag() {
  local tag="$1"
  local expected_type="${2:-}"  # version, environment, state, or empty for any

  local tag_type
  tag_type=$(get_tag_type "$tag")

  if [[ "$tag_type" == "unknown" ]]; then
    log_error "Unknown tag format: $tag"
    return 1
  fi

  if [[ -n "$expected_type" && "$tag_type" != "$expected_type" ]]; then
    log_error "Tag type mismatch. Expected: $expected_type, Got: $tag_type"
    return 1
  fi

  return 0
}

# Semantic version comparison
compare_versions() {
  local version1="$1"
  local operator="$2"  # lt, le, eq, ne, ge, gt
  local version2="$3"

  # Parse versions
  local v1_major v1_minor v1_patch v1_prerelease
  local v2_major v2_minor v2_patch v2_prerelease

  v1_major=$(parse_version_tag "v$version1" "major")
  v1_minor=$(parse_version_tag "v$version1" "minor")
  v1_patch=$(parse_version_tag "v$version1" "patch")
  v1_prerelease=$(parse_version_tag "v$version1" "prerelease")

  v2_major=$(parse_version_tag "v$version2" "major")
  v2_minor=$(parse_version_tag "v$version2" "minor")
  v2_patch=$(parse_version_tag "v$version2" "patch")
  v2_prerelease=$(parse_version_tag "v$version2" "prerelease")

  # Compare major.minor.patch
  local result
  if [[ $v1_major -ne $v2_major ]]; then
    result=$((v1_major - v2_major))
  elif [[ $v1_minor -ne $v2_minor ]]; then
    result=$((v1_minor - v2_minor))
  elif [[ $v1_patch -ne $v2_patch ]]; then
    result=$((v1_patch - v2_patch))
  else
    # Both have same version, compare prerelease
    if [[ -z "$v1_prerelease" && -z "$v2_prerelease" ]]; then
      result=0
    elif [[ -z "$v1_prerelease" ]]; then
      result=1  # Release > prerelease
    elif [[ -z "$v2_prerelease" ]]; then
      result=-1  # Prerelease < release
    else
      # Compare prerelease strings
      if [[ "$v1_prerelease" == "$v2_prerelease" ]]; then
        result=0
      else
        # Simple string comparison (could be enhanced for semver prerelease rules)
        result=$(printf '%s\n%s\n' "$v1_prerelease" "$v2_prerelease" | sort -V | head -1)
        if [[ "$result" == "$v1_prerelease" ]]; then
          result=-1
        else
          result=1
        fi
      fi
    fi
  fi

  # Apply operator
  case "$operator" in
    "lt") [[ $result -lt 0 ]] ;;
    "le") [[ $result -le 0 ]] ;;
    "eq") [[ $result -eq 0 ]] ;;
    "ne") [[ $result -ne 0 ]] ;;
    "ge") [[ $result -ge 0 ]] ;;
    "gt") [[ $result -gt 0 ]] ;;
    *)
      log_error "Unknown comparison operator: $operator"
      return 1
      ;;
  esac
}

# Increment version
increment_version() {
  local version="$1"
  local increment_type="$2"  # major, minor, patch

  local major minor patch
  major=$(parse_version_tag "v$version" "major")
  minor=$(parse_version_tag "v$version" "minor")
  patch=$(parse_version_tag "v$version" "patch")

  case "$increment_type" in
    "major")
      ((major++))
      minor=0
      patch=0
      ;;
    "minor")
      ((minor++))
      patch=0
      ;;
    "patch")
      ((patch++))
      ;;
    *)
      log_error "Invalid increment type: $increment_type"
      return 1
      ;;
  esac

  echo "${major}.${minor}.${patch}"
}

# Get latest version tag
get_latest_version() {
  local pattern="${1:-v*}"
  local subproject="${2:-}"

  local git_args=()
  git_args+=("--sort=-version:refname")
  git_args+=("--count=1")

  if [[ -n "$subproject" ]]; then
    pattern="${subproject}/${pattern}"
  fi

  local latest_tag
  latest_tag=$(git tag -l "$pattern" "${git_args[@]}" 2>/dev/null || echo "")

  if [[ -z "$latest_tag" ]]; then
    log_warn "No version tags found matching pattern: $pattern"
    return 1
  fi

  echo "$latest_tag"
}

# Get commit for tag
get_tag_commit() {
  local tag="$1"

  local commit
  commit=$(git rev-list -n 1 "$tag" 2>/dev/null || echo "")

  if [[ -z "$commit" ]]; then
    log_error "Tag not found: $tag"
    return 1
  fi

  echo "$commit"
}

# Check if tag exists
tag_exists() {
  local tag="$1"

  git rev-parse --verify "refs/tags/$tag" >/dev/null 2>&1
}

# Check if tag is movable
is_tag_movable() {
  local tag="$1"

  local tag_type
  tag_type=$(get_tag_type "$tag")

  case "$tag_type" in
    "environment")
      echo "true"
      ;;
    "version"|"state")
      echo "false"
      ;;
    *)
      echo "false"
      ;;
  esac
}

# Check if tag is protected
is_tag_protected() {
  local tag="$1"

  local tag_type
  tag_type=$(get_tag_type "$tag")

  case "$tag_type" in
    "environment")
      echo "true"
      ;;
    *)
      echo "false"
      ;;
  esac
}

# Create tag with validation
create_tag() {
  local tag="$1"
  local commit="${2:-HEAD}"
  local message="${3:-Tag: $tag}"
  local force="${4:-false}"

  # Validate tag format
  if ! validate_tag "$tag"; then
    return 1
  fi

  # Check if tag exists
  if tag_exists "$tag"; then
    local is_movable
    is_movable=$(is_tag_movable "$tag")

    if [[ "$is_movable" != "true" && "$force" != "true" ]]; then
      log_error "Tag already exists and is not movable: $tag"
      return 1
    fi
  fi

  local force_flag=""
  if [[ "$force" == "true" ]]; then
    force_flag="--force"
  fi

  log_info "Creating tag: $tag (commit: $commit)"
  git tag -a "$force_flag" -m "$message" "$commit" "$tag"

  log_success "✅ Tag created: $tag"
}

# Move tag (only for movable tags)
move_tag() {
  local tag="$1"
  local new_commit="${2:-HEAD}"
  local message="${3:-Moved tag: $tag}"

  local is_movable
  is_movable=$(is_tag_movable "$tag")

  if [[ "$is_movable" != "true" ]]; then
    log_error "Tag is not movable: $tag"
    return 1
  fi

  local old_commit
  old_commit=$(get_tag_commit "$tag")

  log_info "Moving tag: $tag"
  log_info "  From: $old_commit"
  log_info "  To: $new_commit"

  create_tag "$tag" "$new_commit" "$message" "true"
}

# Delete tag
delete_tag() {
  local tag="$1"

  if ! tag_exists "$tag"; then
    log_error "Tag not found: $tag"
    return 1
  fi

  local is_protected
  is_protected=$(is_tag_protected "$tag")

  if [[ "$is_protected" == "true" ]]; then
    # Check for emergency override
    if [[ "${ALLOW_PROTECTED_TAG_PUSH:-false}" != "true" ]]; then
      log_error "Cannot delete protected tag without override: $tag"
      return 1
    fi
    log_warn "Deleting protected tag with emergency override: $tag"
  fi

  log_info "Deleting tag: $tag"
  git tag -d "$tag"

  log_success "✅ Tag deleted: $tag"
}

# List tags with filtering
list_tags() {
  local tag_type="${1:-}"  # version, environment, state, or empty for all
  local subproject="${2:-}"

  local pattern="*"
  if [[ -n "$subproject" ]]; then
    pattern="${subproject}/*"
  fi

  while IFS= read -r -d '' tag; do
    local current_tag_type
    current_tag_type=$(get_tag_type "$tag")

    if [[ -z "$tag_type" || "$current_tag_type" == "$tag_type" ]]; then
      local commit
      commit=$(get_tag_commit "$tag")
      local date
      date=$(git log -1 --format="%ci" "$commit" 2>/dev/null || echo "unknown")
      local message
      message=$(git tag -l --format="%(contents:subject)" "$tag" 2>/dev/null || echo "No message")

      printf "%-40s %10s %s\n" "$tag" "$current_tag_type" "$date"
    fi
  done < <(git tag -l "$pattern" -z 2>/dev/null || true)
}

# Main execution (for CLI usage)
main() {
  local action="${1:-help}"
  shift || true

  case "$action" in
    "parse")
      if [[ $# -lt 2 ]]; then
        echo "Usage: $0 parse <tag> <component>" >&2
        exit 1
      fi
      parse_version_tag "$@"
      ;;
    "compare")
      if [[ $# -lt 3 ]]; then
        echo "Usage: $0 compare <version1> <operator> <version2>" >&2
        exit 1
      fi
      compare_versions "$@"
      ;;
    "increment")
      if [[ $# -lt 2 ]]; then
        echo "Usage: $0 increment <version> <major|minor|patch>" >&2
        exit 1
      fi
      increment_version "$@"
      ;;
    "latest")
      get_latest_version "$@"
      ;;
    "exists")
      tag_exists "$@"
      ;;
    "create")
      create_tag "$@"
      ;;
    "move")
      move_tag "$@"
      ;;
    "delete")
      delete_tag "$@"
      ;;
    "list")
      list_tags "$@"
      ;;
    "help"|"--help"|"-h")
      cat << EOF
Tag Utilities v1.0.0

Usage: $0 <action> [options]

Actions:
  parse <tag> <component>                Parse tag component (major, minor, patch, prerelease, build, full)
  compare <v1> <op> <v2>                Compare versions (lt, le, eq, ne, ge, gt)
  increment <version> <type>            Increment version (major, minor, patch)
  latest [pattern] [subproject]         Get latest version tag
  exists <tag>                         Check if tag exists
  create <tag> [commit] [message] [force] Create tag
  move <tag> [commit] [message]         Move movable tag
  delete <tag>                         Delete tag
  list [type] [subproject]              List tags (version, environment, state)

Examples:
  $0 parse v1.2.3 major
  $0 compare 1.2.3 lt 1.3.0
  $0 increment 1.2.3 minor
  $0 latest "v*" api
  $0 exists v1.2.3
  $0 create v1.2.3 HEAD "Release 1.2.3"
  $0 list version
EOF
      exit 0
      ;;
    *)
      echo "Unknown action: $action" >&2
      echo "Use '$0 help' for usage information" >&2
      exit 1
      ;;
  esac
}

# CLI interface
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi