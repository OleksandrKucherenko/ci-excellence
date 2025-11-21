#!/usr/bin/env bash
# CI Tag Assignment Script
# Creates and manages git tags for version, environment, and state tags

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

# shellcheck source=../lib/tag-utils.sh
source "${SCRIPT_DIR}/../lib/tag-utils.sh"

# Get script and pipeline names for testability
SCRIPT_NAME=$(get_script_name "$0")
PIPELINE_NAME=$(get_pipeline_name)
MODE=$(resolve_test_mode "$SCRIPT_NAME" "$PIPELINE_NAME")

log_test_mode_source "$SCRIPT_NAME" "$PIPELINE_NAME" "$MODE"

# Input validation
TAG_TYPE="${INPUT_TAG_TYPE:-}"
VERSION="${INPUT_VERSION:-}"
ENVIRONMENT="${INPUT_ENVIRONMENT:-}"
STATE="${INPUT_STATE:-}"
SUB_PROJECT="${INPUT_SUB_PROJECT:-}"
COMMIT_SHA="${INPUT_COMMIT_SHA:-HEAD}"
FORCE_MOVE="${INPUT_FORCE_MOVE:-false}"

# Validate inputs
validate_inputs() {
  log_info "Validating tag assignment inputs"

  case "$TAG_TYPE" in
    "version")
      if [[ -z "$VERSION" ]]; then
        log_error "Version is required for version tags"
        return 1
      fi
      if ! validate_semver "$VERSION"; then
        log_error "Invalid semver format: $VERSION"
        return 1
      fi
      ;;
    "environment")
      if [[ -z "$ENVIRONMENT" ]]; then
        log_error "Environment is required for environment tags"
        return 1
      fi
      if [[ ! "$ENVIRONMENT" =~ ^(production|staging|canary|sandbox|performance)$ ]]; then
        log_error "Invalid environment: $ENVIRONMENT"
        log_error "Valid environments: production, staging, canary, sandbox, performance"
        return 1
      fi
      ;;
    "state")
      if [[ -z "$VERSION" ]]; then
        log_error "Version is required for state tags"
        return 1
      fi
      if [[ -z "$STATE" ]]; then
        log_error "State is required for state tags"
        return 1
      fi
      if [[ ! "$STATE" =~ ^(stable|unstable|deprecated)$ ]]; then
        log_error "Invalid state: $STATE"
        log_error "Valid states: stable, unstable, deprecated"
        return 1
      fi
      if ! validate_semver "$VERSION"; then
        log_error "Invalid semver format: $VERSION"
        return 1
      fi
      ;;
    *)
      log_error "Invalid tag type: $TAG_TYPE"
      log_error "Valid types: version, environment, state"
      return 1
      ;;
  esac

  # Validate sub-project path
  if [[ -n "$SUB_PROJECT" ]]; then
    if [[ "$SUB_PROJECT" == "/" || "$SUB_PROJECT" =~ ^/+|/+$ ]]; then
      log_error "Invalid sub-project path: $SUB_PROJECT"
      log_error "Sub-project path should not start or end with '/'"
      return 1
    fi
  fi

  # Validate commit SHA
  if ! git rev-parse --verify "$COMMIT_SHA" >/dev/null 2>&1; then
    log_error "Invalid commit SHA: $COMMIT_SHA"
    return 1
  fi

  log_success "Input validation passed"
}

# Create version tag
create_version_tag() {
  local version="$VERSION"
  local commit_sha="$COMMIT_SHA"
  local subproject_path="$SUB_PROJECT"

  log_info "Creating version tag: $version"
  log_info "Commit: $commit_sha"
  [[ -n "$subproject_path" ]] && log_info "Sub-project: $subproject_path"

  local version_tag="${subproject_path:+${subproject_path}/}${version}"

  # Check if tag already exists
  if tag_exists "$version_tag"; then
    log_error "Version tag already exists: $version_tag"
    log_error "Version tags are immutable"
    return 1
  fi

  # Create the tag
  if ! git tag "$version_tag" "$commit_sha"; then
    log_error "Failed to create version tag: $version_tag"
    return 1
  fi

  log_success "Created version tag: $version_tag -> $commit_sha"
  echo "$version_tag"
}

# Create or move environment tag
create_environment_tag() {
  local environment="$ENVIRONMENT"
  local commit_sha="$COMMIT_SHA"
  local subproject_path="$SUB_PROJECT"
  local force_move="$FORCE_MOVE"

  log_info "Creating/moving environment tag: $environment"
  log_info "Commit: $commit_sha"
  [[ -n "$subproject_path" ]] && log_info "Sub-project: $subproject_path"

  local env_tag
  env_tag=$(get_environment_tag "$environment" "$subproject_path")

  # Check if tag already exists and we're not forcing
  if tag_exists "$env_tag" && [[ "$force_move" != "true" ]]; then
    log_error "Environment tag already exists: $env_tag"
    log_error "Use force_move=true to override"
    return 1
  fi

  # Get old commit for logging if tag exists
  local old_commit=""
  if tag_exists "$env_tag"; then
    old_commit=$(get_tag_commit "$env_tag")
    log_info "Moving existing tag from: $old_commit"
  fi

  # Create or move the tag
  if ! git tag -f "$env_tag" "$commit_sha"; then
    log_error "Failed to create/move environment tag: $env_tag"
    return 1
  fi

  log_success "Environment tag updated: $env_tag -> $commit_sha"
  echo "$env_tag"
}

# Create state tag
create_state_tag() {
  local version="$VERSION"
  local state="$STATE"
  local subproject_path="$SUB_PROJECT"

  log_info "Creating state tag: $version-$state"
  [[ -n "$subproject_path" ]] && log_info "Sub-project: $subproject_path"

  local state_tag
  state_tag=$(get_state_tag "$version" "$state" "$subproject_path")

  # Check if state tag already exists
  if tag_exists "$state_tag"; then
    log_error "State tag already exists: $state_tag"
    log_error "State tags are immutable"
    return 1
  fi

  # Verify that corresponding version tag exists
  local version_tag="${subproject_path:+${subproject_path}/}${version}"
  if ! tag_exists "$version_tag"; then
    log_error "Version tag does not exist: $version_tag"
    log_error "State tags must reference existing version tags"
    return 1
  fi

  # Get commit from version tag
  local commit_sha
  commit_sha=$(get_tag_commit "$version_tag")

  # Create the state tag
  if ! git tag "$state_tag" "$commit_sha"; then
    log_error "Failed to create state tag: $state_tag"
    return 1
  fi

  log_success "Created state tag: $state_tag -> $commit_sha"
  echo "$state_tag"
}

# Push tags to remote
push_tags() {
  local tag_type="$1"
  local created_tag="$2"

  log_info "Pushing $tag_type tag to remote"

  case "$tag_type" in
    "environment")
      # Environment tags are movable, use force push
      git push -f origin "$created_tag"
      ;;
    "version"|"state")
      # Version and state tags are immutable
      git push origin "$created_tag"
      ;;
  esac

  log_success "Tag pushed to remote: $created_tag"
}

# Generate tag information output
generate_tag_info() {
  local tag_type="$1"
  local created_tag="$2"

  log_info "Tag information:"
  echo "tag_type=$tag_type"
  echo "tag_name=$created_tag"
  echo "repository=${GITHUB_REPOSITORY:-unknown}"

  # Get additional tag information
  if [[ "$tag_type" == "version" || "$tag_type" == "state" ]]; then
    local version="$VERSION"
    if [[ "$tag_type" == "state" ]]; then
      local version_info
      version_info=$(get_version_info "$version" "$SUB_PROJECT")
      echo "version_info=$version_info"
    fi
  fi

  # Get commit information
  local commit_sha="$COMMIT_SHA"
  local commit_date
  commit_date=$(git log -1 --format="%ci" "$commit_sha" 2>/dev/null || echo "Unknown")
  local commit_message
  commit_message=$(git log -1 --format="%s" "$commit_sha" 2>/dev/null || echo "Unknown")

  echo "commit_sha=$commit_sha"
  echo "commit_date=$commit_date"
  echo "commit_message=$commit_message"
}

# Main execution function
main() {
  log_info "Starting tag assignment for $TAG_TYPE"

  # Execute based on test mode
  case "$MODE" in
    DRY_RUN)
      log_info "Dry run: would create $TAG_TYPE tag"
      log_info "Inputs: TYPE=$TAG_TYPE, VERSION=$VERSION, ENVIRONMENT=$ENVIRONMENT, STATE=$STATE"
      log_info "Would push to remote if not in dry run mode"
      exit 0
      ;;
    PASS)
      log_info "Simulated tag assignment success"
      echo "tag_type=$TAG_TYPE"
      echo "tag_name=simulated-$TAG_TYPE-tag"
      exit 0
      ;;
    FAIL)
      log_error "Simulated tag assignment failure"
      exit 1
      ;;
    SKIP)
      log_info "Skipping tag assignment"
      exit 0
      ;;
    TIMEOUT)
      log_warning "Simulating tag assignment timeout"
      sleep infinity
      ;;
    EXECUTE)
      # Continue with normal execution
      ;;
    *)
      log_error "Unknown test mode: $MODE"
      exit 1
      ;;
  esac

  # Validate inputs
  validate_inputs

  # Create tag based on type
  local created_tag=""
  case "$TAG_TYPE" in
    "version")
      created_tag=$(create_version_tag)
      ;;
    "environment")
      created_tag=$(create_environment_tag)
      ;;
    "state")
      created_tag=$(create_state_tag)
      ;;
  esac

  # Push tag to remote
  push_tags "$TAG_TYPE" "$created_tag"

  # Generate tag information for downstream steps
  generate_tag_info "$TAG_TYPE" "$created_tag"

  log_success "Tag assignment completed successfully"
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi