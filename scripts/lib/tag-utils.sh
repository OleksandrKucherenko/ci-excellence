#!/usr/bin/env bash
# Tag utility functions for CI/CD pipeline
# Provides version parsing, tag manipulation, and semver comparison

# Prevent double sourcing
if [[ "${CI_TAG_UTILS_SH_LOADED:-}" == "true" ]]; then
  return 0
fi
CI_TAG_UTILS_SH_LOADED=true

# Source common utilities if available
if [[ -f "scripts/lib/common.sh" ]]; then
  # shellcheck source=scripts/lib/common.sh
  source scripts/lib/common.sh
fi

# Parse version from tag name
parse_version_from_tag() {
  local tag_name="$1"

  # Extract version from tag (e.g., "api/v1.2.3" -> "v1.2.3", "v1.2.3-beta.1" -> "v1.2.3-beta.1")
  echo "$tag_name" | sed 's|.*/||'
}

# Extract sub-project path from tag name
extract_subproject_path() {
  local tag_name="$1"

  # Extract path before version (e.g., "api/v1.2.3" -> "api", "v1.2.3" -> "")
  local path
  path=$(echo "$tag_name" | sed 's|/v.*$||')

  # Return empty string if no path found
  if [[ "$path" == "$tag_name" ]]; then
    echo ""
  else
    echo "$path"
  fi
}

# Validate semver format
validate_semver() {
  local version="$1"

  # Basic semver validation (supports v prefix and prereleases)
  if [[ "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?$ ]]; then
    return 0
  else
    return 1
  fi
}

# Parse semver components
parse_semver() {
  local version="$1"
  local output_var_prefix="$2"

  if ! validate_semver "$version"; then
    echo "Invalid semver: $version" >&2
    return 1
  fi

  # Remove 'v' prefix if present
  local clean_version="${version#v}"

  # Extract components
  local major minor patch prerelease
  IFS='.' read -ra VERSION_PARTS <<< "$clean_version"
  major="${VERSION_PARTS[0]}"
  minor="${VERSION_PARTS[1]}"

  # Handle patch and potential prerelease
  if [[ "${VERSION_PARTS[2]}" =~ ^([0-9]+)(-.*)?$ ]]; then
    patch="${BASH_REMATCH[1]}"
    prerelease="${BASH_REMATCH[2]:-}"
    # Remove leading '-' from prerelease if present
    prerelease="${prerelease#-}"
  else
    patch="${VERSION_PARTS[2]}"
  fi

  # Export variables if prefix provided
  if [[ -n "$output_var_prefix" ]]; then
    declare -g "${output_var_prefix}_MAJOR=$major"
    declare -g "${output_var_prefix}_MINOR=$minor"
    declare -g "${output_var_prefix}_PATCH=$patch"
    declare -g "${output_var_prefix}_PRERELEASE=$prerelease"
  fi

  # Output in JSON format if no prefix
  if [[ -z "$output_var_prefix" ]]; then
    cat <<EOF
{
  "major": $major,
  "minor": $minor,
  "patch": $patch,
  "prerelease": "${prerelease:-}"
}
EOF
  fi
}

# Compare two semver versions
compare_semver() {
  local version1="$1"
  local version2="$2"

  # Parse both versions
  parse_semver "$version1" V1
  parse_semver "$version2" V2

  # Compare major versions
  if [[ $V1_MAJOR -lt $V2_MAJOR ]]; then
    echo -1
  elif [[ $V1_MAJOR -gt $V2_MAJOR ]]; then
    echo 1
  else
    # Compare minor versions
    if [[ $V1_MINOR -lt $V2_MINOR ]]; then
      echo -1
    elif [[ $V1_MINOR -gt $V2_MINOR ]]; then
      echo 1
    else
      # Compare patch versions
      if [[ $V1_PATCH -lt $V2_PATCH ]]; then
        echo -1
      elif [[ $V1_PATCH -gt $V2_PATCH ]]; then
        echo 1
      else
        # Compare prereleases (consider no prerelease > any prerelease)
        if [[ -z "$V1_PRERELEASE" && -n "$V2_PRERELEASE" ]]; then
          echo 1
        elif [[ -n "$V1_PRERELEASE" && -z "$V2_PRERELEASE" ]]; then
          echo -1
        elif [[ "$V1_PRERELEASE" < "$V2_PRERELEASE" ]]; then
          echo -1
        elif [[ "$V1_PRERELEASE" > "$V2_PRERELEASE" ]]; then
          echo 1
        else
          echo 0
        fi
      fi
    fi
  fi
}

# Get all version tags for a sub-project
get_version_tags() {
  local subproject_path="$1"

  local pattern
  if [[ -n "$subproject_path" ]]; then
    pattern="${subproject_path}/v*"
  else
    pattern="v*"
  fi

  git tag -l "$pattern" | grep -E 'v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?$' || true
}

# Get environment tag for a sub-project
get_environment_tag() {
  local environment="$1"
  local subproject_path="$2"

  local tag_name
  if [[ -n "$subproject_path" ]]; then
    tag_name="${subproject_path}/${environment}"
  else
    tag_name="$environment"
  fi

  echo "$tag_name"
}

# Get state tag for a version
get_state_tag() {
  local version="$1"
  local state="$2"
  local subproject_path="$3"

  local version_without_v="${version#v}"
  local tag_name

  if [[ -n "$subproject_path" ]]; then
    tag_name="${subproject_path}/v${version_without_v}-${state}"
  else
    tag_name="v${version_without_v}-${state}"
  fi

  echo "$tag_name"
}

# Check if tag exists
tag_exists() {
  local tag_name="$1"
  git rev-parse "$tag_name" >/dev/null 2>&1
}

# Get commit SHA that a tag points to
get_tag_commit() {
  local tag_name="$1"
  git rev-parse "$tag_name" 2>/dev/null || echo ""
}

# Check if tag is movable (environment tags are movable, others are not)
is_movable_tag() {
  local tag_name="$1"

  # Environment tags are movable
  if echo "$tag_name" | grep -qE "(production|staging|canary|sandbox|performance)$"; then
    return 0
  fi

  # All other tags are immutable
  return 1
}

# Create version tag
create_version_tag() {
  local version="$1"
  local commit_sha="${2:-HEAD}"
  local subproject_path="$3"
  local force="${4:-false}"

  local version_tag
  if [[ -n "$subproject_path" ]]; then
    version_tag="${subproject_path}/${version}"
  else
    version_tag="$version"
  fi

  if ! validate_semver "$version"; then
    log_error "Invalid semver format: $version"
    return 1
  fi

  if tag_exists "$version_tag" && [[ "$force" != "true" ]]; then
    log_error "Version tag already exists: $version_tag"
    return 1
  fi

  if [[ "$force" == "true" ]]; then
    git tag -f "$version_tag" "$commit_sha"
    log_info "Force-created version tag: $version_tag -> $commit_sha"
  else
    git tag "$version_tag" "$commit_sha"
    log_info "Created version tag: $version_tag -> $commit_sha"
  fi
}

# Create or move environment tag
create_environment_tag() {
  local environment="$1"
  local commit_sha="$2"
  local subproject_path="$3"

  local env_tag
  env_tag=$(get_environment_tag "$environment" "$subproject_path")

  # Environment tags are always movable
  git tag -f "$env_tag" "$commit_sha"
  log_info "Created/moved environment tag: $env_tag -> $commit_sha"
}

# Create state tag
create_state_tag() {
  local version="$1"
  local state="$2"
  local subproject_path="$3"

  local state_tag
  state_tag=$(get_state_tag "$version" "$state" "$subproject_path")

  if ! tag_exists "${subproject_path:+${subproject_path}/}${version}" && [[ -z "$subproject_path" ]]; then
    log_error "Version tag does not exist: ${version}"
    return 1
  elif [[ -n "$subproject_path" ]]; then
    if ! tag_exists "${subproject_path}/${version}"; then
      log_error "Version tag does not exist: ${subproject_path}/${version}"
      return 1
    fi
  fi

  if tag_exists "$state_tag"; then
    log_error "State tag already exists: $state_tag"
    return 1
  fi

  # State tags point to the same commit as their version tags
  local version_tag="${subproject_path:+${subproject_path}/}${version}"
  local commit_sha
  commit_sha=$(get_tag_commit "$version_tag")

  git tag "$state_tag" "$commit_sha"
  log_info "Created state tag: $state_tag -> $commit_sha"
}

# Find rollback target for an environment
find_rollback_target() {
  local environment="$1"
  local subproject_path="${2:-}"
  local prioritize_stable="${3:-true}"
  local exclude_deprecated="${4:-true}"

  local env_tag
  env_tag=$(get_environment_tag "$environment" "$subproject_path")

  if ! tag_exists "$env_tag"; then
    log_error "Environment tag not found: $env_tag"
    return 1
  fi

  local current_commit
  current_commit=$(get_tag_commit "$env_tag")

  # Find current version tag
  local current_version
  current_version=$(git tag --points-at "$current_commit" | grep -E "v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?$" | head -n1)

  if [[ -z "$current_version" ]]; then
    log_error "No version tag found on commit: $current_commit"
    return 1
  fi

  # Remove subproject path if present
  current_version=$(parse_version_from_tag "$current_version")

  # Get all version tags
  local all_versions
  all_versions=$(get_version_tags "$subproject_path")

  # Filter and sort versions
  local candidates=()
  for version in $all_versions; do
    local clean_version
    clean_version=$(parse_version_from_tag "$version")

    # Skip current version
    if [[ "$clean_version" == "$current_version" ]]; then
      continue
    fi

    # Check if version is deprecated (if exclude_deprecated is true)
    if [[ "$exclude_deprecated" == "true" ]]; then
      local deprecated_tag
      deprecated_tag=$(get_state_tag "$clean_version" "deprecated" "$subproject_path")
      if tag_exists "$deprecated_tag"; then
        log_debug "Skipping deprecated version: $clean_version"
        continue
      fi
    fi

    candidates+=("$clean_version")
  done

  # Sort candidates by semver (newest first)
  IFS=$'\n' candidates=($(sort -r <<<"${candidates[*]}"))
  unset IFS

  # Select target based on priority
  local target_version=""

  if [[ "$prioritize_stable" == "true" ]]; then
    # First try to find stable versions
    for version in "${candidates[@]}"; do
      local stable_tag
      stable_tag=$(get_state_tag "$version" "stable" "$subproject_path")
      if tag_exists "$stable_tag"; then
        target_version="$version"
        break
      fi
    done

    # If no stable version found, use newest non-stable version
    if [[ -z "$target_version" && ${#candidates[@]} -gt 0 ]]; then
      target_version="${candidates[0]}"
    fi
  else
    # Use newest version regardless of stable status
    if [[ ${#candidates[@]} -gt 0 ]]; then
      target_version="${candidates[0]}"
    fi
  fi

  if [[ -z "$target_version" ]]; then
    log_error "No suitable rollback target found"
    return 1
  fi

  echo "$target_version"
}

# Get version information for display
get_version_info() {
  local version="$1"
  local subproject_path="${2:-}"

  local version_tag="${subproject_path:+${subproject_path}/}${version}"

  if ! tag_exists "$version_tag"; then
    echo "Version tag not found: $version_tag"
    return 1
  fi

  local commit_sha
  commit_sha=$(get_tag_commit "$version_tag")

  local commit_date
  commit_date=$(git log -1 --format="%ci" "$commit_sha")

  local commit_message
  commit_message=$(git log -1 --format="%s" "$commit_sha")

  # Check for state tags
  local stable_tag unstable_tag deprecated_tag
  stable_tag=$(get_state_tag "$version" "stable" "$subproject_path")
  unstable_tag=$(get_state_tag "$version" "unstable" "$subproject_path")
  deprecated_tag=$(get_state_tag "$version" "deprecated" "$subproject_path")

  local state="none"
  if tag_exists "$stable_tag"; then
    state="stable"
  elif tag_exists "$unstable_tag"; then
    state="unstable"
  elif tag_exists "$deprecated_tag"; then
    state="deprecated"
  fi

  cat <<EOF
Version: $version
Tag: $version_tag
Commit: $commit_sha
Date: $commit_date
Message: $commit_message
State: $state
EOF
}

# List tags by type
list_tags_by_type() {
  local tag_type="$1"  # version, environment, state
  local subproject_path="${2:-}"

  case "$tag_type" in
    "version")
      get_version_tags "$subproject_path"
      ;;
    "environment")
      local envs="production staging canary sandbox performance"
      for env in $envs; do
        local env_tag
        env_tag=$(get_environment_tag "$env" "$subproject_path")
        if tag_exists "$env_tag"; then
          echo "$env_tag"
        fi
      done
      ;;
    "state")
      local states="stable unstable deprecated"
      for state in $states; do
        git tag -l "*-${state}" | grep -v "^[^/]*$" | while read -r tag; do
          if [[ -z "$subproject_path" || "$tag" == "${subproject_path}/*" ]]; then
            echo "$tag"
          fi
        done
      done
      ;;
    *)
      log_error "Unknown tag type: $tag_type"
      return 1
      ;;
  esac
}

# Export functions for use in other scripts
export -f parse_version_from_tag extract_subproject_path
export -f validate_semver parse_semver compare_semver
export -f get_version_tags get_environment_tag get_state_tag
export -f tag_exists get_tag_commit is_movable_tag
export -f create_version_tag create_environment_tag create_state_tag
export -f find_rollback_target get_version_info list_tags_by_type