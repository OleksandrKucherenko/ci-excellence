#!/bin/bash
# CI Tag Assignment Script
# Manages git tag operations for version, environment, and state tags

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/scripts/lib/common.sh" 2>/dev/null || {
  echo "Failed to source common utilities" >&2
  exit 1
}

# Source tag utilities
source "$PROJECT_ROOT/scripts/lib/tag-utils.sh" 2>/dev/null || {
  echo "Failed to source tag utilities" >&2
  exit 1
}

# Configuration
readonly TAG_ASSIGNMENT_VERSION="1.0.0"

# Testability configuration
get_behavior_mode() {
  local script_name="tag_assignment"
  get_script_behavior "$script_name" "EXECUTE"
}

# Validate input parameters for GitHub Actions
validate_inputs() {
  local tag_type="${INPUT_TAG_TYPE:-}"
  local version="${INPUT_VERSION:-}"
  local environment="${INPUT_ENVIRONMENT:-}"
  local state="${INPUT_STATE:-}"
  local subproject="${INPUT_SUBPROJECT:-}"
  local commit_sha="${INPUT_COMMIT_SHA:-}"
  local force_move="${INPUT_FORCE_MOVE:-false}"

  log_info "Validating tag assignment inputs"
  log_info "Tag Type: $tag_type"
  log_info "Version: $version"
  log_info "Environment: $environment"
  log_info "State: $state"
  log_info "Subproject: $subproject"
  log_info "Force Move: $force_move"

  # Validate tag type
  case "$tag_type" in
    "version"|"environment"|"state")
      log_success "Valid tag type: $tag_type"
      ;;
    *)
      log_error "Invalid tag type: $tag_type"
      log_error "Must be one of: version, environment, state"
      exit 1
      ;;
  esac

  # Validate required parameters based on tag type
  case "$tag_type" in
    "version")
      if [[ -z "$version" ]]; then
        log_error "Version is required for version tag type"
        exit 1
      fi
      if ! is_valid_version_tag "$version"; then
        log_error "Invalid version format: $version"
        exit 1
      fi
      ;;
    "environment")
      if [[ -z "$environment" ]]; then
        log_error "Environment is required for environment tag type"
        exit 1
      fi
      if ! is_valid_environment_tag "$environment"; then
        log_error "Invalid environment: $environment"
        exit 1
      fi
      ;;
    "state")
      if [[ -z "$version" ]]; then
        log_error "Version is required for state tag type"
        exit 1
      fi
      if [[ -z "$state" ]]; then
        log_error "State is required for state tag type"
        exit 1
      fi
      if ! is_valid_state_tag "${version}-${state}"; then
        log_error "Invalid state: $state"
        exit 1
      fi
      ;;
  esac

  # Validate subproject if provided
  if [[ -n "$subproject" ]]; then
    if [[ ! "$subproject" =~ ^[a-z0-9][a-z0-9\-]*[a-z0-9]$ ]]; then
      log_error "Invalid subproject format: $subproject"
      log_error "Subproject must be lowercase alphanumeric with hyphens"
      exit 1
    fi
  fi

  # Resolve commit SHA
  if [[ -z "$commit_sha" ]]; then
    commit_sha=$(git rev-parse HEAD)
    log_info "Using current HEAD commit: $commit_sha"
  else
    # Validate commit SHA exists
    if ! git rev-parse --verify "$commit_sha" >/dev/null 2>&1; then
      log_error "Invalid commit SHA: $commit_sha"
      exit 1
    fi
  fi

  # Generate tag name and set outputs for GitHub Actions
  local tag_name
  case "$tag_type" in
    "version")
      tag_name="$version"
      if [[ -n "$subproject" ]]; then
        tag_name="${version}-${subproject}"
      fi
      ;;
    "environment")
      tag_name="$environment"
      ;;
    "state")
      tag_name="${version}-${state}"
      if [[ -n "$subproject" ]]; then
        tag_name="${version}-${subproject}-${state}"
      fi
      ;;
  esac

  # Determine if deployment should be triggered (only for environment tags)
  local should_deploy="false"
  if [[ "$tag_type" == "environment" ]]; then
    should_deploy="true"
  fi

  # Set GitHub Actions outputs
  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    {
      echo "tag_name=$tag_name"
      echo "tag_type=$tag_type"
      echo "commit_sha=$commit_sha"
      echo "force_move=$force_move"
      echo "should_deploy=$should_deploy"
    } >> "$GITHUB_OUTPUT"
  fi

  log_success "Input validation completed successfully"
  log_info "Tag Name: $tag_name"
  log_info "Commit SHA: $commit_sha"
  log_info "Should Deploy: $should_deploy"
}

# Create or move tag based on type and parameters
create_tag() {
  local tag_type="${TAG_TYPE:-}"
  local version="${VERSION:-}"
  local environment="${ENVIRONMENT:-}"
  local state="${STATE:-}"
  local subproject="${SUBPROJECT:-}"
  local commit_sha="${COMMIT_SHA:-}"
  local force_move="${FORCE_MOVE:-false}"

  log_info "Creating tag (type: $tag_type, commit: $commit_sha)"

  case "$tag_type" in
    "version")
      create_version_tag "$version" "$commit_sha" "$force_move" "$subproject"
      ;;
    "environment")
      create_environment_tag "$environment" "$commit_sha" "$force_move"
      ;;
    "state")
      create_state_tag "$state" "$version" "$commit_sha" "$force_move" "$subproject"
      ;;
    *)
      log_error "Unknown tag type: $tag_type"
      return 1
      ;;
  esac
}

# Create version tag
create_version_tag() {
  local version="$1"
  local commit_sha="$2"
  local force_move="${3:-false}"
  local subproject="${4:-}"

  local tag_name="$version"
  if [[ -n "$subproject" ]]; then
    tag_name="${version}-${subproject}"
  fi

  # Check if tag already exists
  if git show-ref --verify --quiet "refs/tags/$tag_name" 2>/dev/null; then
    if [[ "$force_move" == "true" ]]; then
      log_warn "Force moving existing version tag: $tag_name"
      git tag -f -a "$tag_name" -m "Force moved version tag: $tag_name

Commit: $commit_sha
Previous state: overwritten
$(format_tag_message "version" "$tag_name" "Force moved version tag")" "$commit_sha"
    else
      log_error "Version tag $tag_name already exists and is immutable"
      log_error "Use force_move=true to override"
      return 1
    fi
  else
    log_success "Creating new version tag: $tag_name"
    git tag -a "$tag_name" -m "$(format_tag_message "version" "$tag_name" "Created version tag")" "$commit_sha"
  fi

  log_success "Version tag $tag_name points to commit $commit_sha"
}

# Create environment tag
create_environment_tag() {
  local environment="$1"
  local commit_sha="$2"
  local force_move="${3:-false}"

  local old_commit=""
  local old_commit_short=""

  # Check if environment tag exists and get old commit
  if git show-ref --verify --quiet "refs/tags/$environment" 2>/dev/null; then
    old_commit=$(git rev-list -n 1 "$environment" 2>/dev/null || echo "")
    old_commit_short="${old_commit:0:7}"
    log_info "Environment tag $environment exists, currently points to: $old_commit_short"
  fi

  # Create or move environment tag
  if [[ -n "$old_commit" ]]; then
    if [[ "$force_move" == "true" || "$old_commit" != "$commit_sha" ]]; then
      log_info "Moving environment tag: $environment"
      log_info "Old commit: $old_commit_short → New commit: ${commit_sha:0:7}"

      git tag -f -a "$environment" -m "Moved environment tag: $environment

Old commit: $old_commit ($old_commit_short)
New commit: $commit_sha (${commit_sha:0:7})
$(format_tag_message "environment" "$environment" "Moved environment tag")" "$commit_sha"

      log_success "Environment tag $environment moved successfully"
    else
      log_info "Environment tag $environment already points to $commit_sha"
    fi
  else
    log_success "Creating new environment tag: $environment"
    git tag -a "$environment" -m "$(format_tag_message "environment" "$environment" "Created environment tag")" "$commit_sha"
  fi
}

# Create state tag
create_state_tag() {
  local state="$1"
  local version="$2"
  local commit_sha="$3"
  local force_move="${4:-false}"
  local subproject="${5:-}"

  local tag_name="${version}-${state}"
  if [[ -n "$subproject" ]]; then
    tag_name="${version}-${subproject}-${state}"
  fi

  # Check if state tag already exists
  if git show-ref --verify --quiet "refs/tags/$tag_name" 2>/dev/null; then
    if [[ "$force_move" == "true" ]]; then
      log_warn "Force moving existing state tag: $tag_name"
      git tag -f -a "$tag_name" -m "Force moved state tag: $tag_name

State: $state
Version: $version
Commit: $commit_sha
Previous state: overwritten
$(format_tag_message "state" "$tag_name" "Force moved state tag")" "$commit_sha"
    else
      log_error "State tag $tag_name already exists and is immutable"
      log_error "Use force_move=true to override"
      return 1
    fi
  else
    log_success "Creating new state tag: $tag_name"
    git tag -a "$tag_name" -m "Created state tag: $tag_name

State: $state
Version: $version
Commit: $commit_sha
$(format_tag_message "state" "$tag_name" "Created state tag")" "$commit_sha"
  fi

  log_success "State tag $tag_name points to commit $commit_sha"
}

# Generate notification message for tag assignment results
generate_notification() {
  local tag_name="${TAG_NAME:-}"
  local tag_type="${TAG_TYPE:-}"
  local commit_sha="${COMMIT_SHA:-}"
  local validate_result="${VALIDATE_RESULT:-success}"
  local create_result="${CREATE_RESULT:-success}"
  local deploy_result="${DEPLOY_RESULT:-skipped}"

  local status="success"
  if [[ "$validate_result" != "success" || "$create_result" != "success" ]]; then
    status="failure"
  fi

  local emoji="✅"
  if [[ "$status" == "failure" ]]; then
    emoji="❌"
  fi

  cat << EOF
$emoji Tag Assignment Summary

**Tag**: $tag_name
**Type**: $tag_type
**Commit**: ${commit_sha:0:7}
**Status**: $status

**Results**:
- Validation: $validate_result
- Creation: $create_result
- Deployment: $deploy_result

**Actions**:
EOF

  if [[ "$status" == "success" ]]; then
    echo "- [View Tag]($GITHUB_SERVER_URL/$GITHUB_REPOSITORY/releases/tag/$tag_name)"
    if [[ "$tag_type" == "environment" ]]; then
      echo "- [View Deployment]($GITHUB_SERVER_URL/$GITHUB_REPOSITORY/deployments)"
    fi
  else
    echo "- [View Workflow]($GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID)"
  fi
}

# Push tags to remote repository
push_tags_to_remote() {
  local tag_name="$1"

  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    log_info "Pushing tag to remote repository"

    # Configure git with token
    git config --global credential.helper ''
    git config --global credential.helper '!echo password=$GITHUB_TOKEN; echo username=x-access-token'

    # Push the tag
    if git push origin "refs/tags/$tag_name"; then
      log_success "Tag $tag_name pushed successfully"
    else
      log_error "Failed to push tag $tag_name"
      return 1
    fi
  else
    log_warn "No GITHUB_TOKEN provided, skipping remote push"
  fi
}

# Main execution
main() {
  local command="${1:-}"

  case "$command" in
    "validate-inputs")
      validate_inputs
      ;;
    "create-tag")
      create_tag

      # Push to remote if tag was created successfully
      if [[ -n "${TAG_NAME:-}" ]] && [[ "$?" -eq 0 ]]; then
        push_tags_to_remote "$TAG_NAME"
      fi
      ;;
    "notify-results")
      generate_notification
      ;;
    "help"|"--help"|"-h")
      cat << EOF
Tag Assignment Script v$TAG_ASSIGNMENT_VERSION

Usage: $0 <command>

Commands:
  validate-inputs    Validate input parameters (used by GitHub Actions)
  create-tag         Create or move tag based on inputs
  notify-results     Generate notification message
  help               Show this help message

Environment Variables:
  TAG_ASSIGNMENT_MODE   EXECUTE, DRY_RUN, PASS, FAIL, SKIP, TIMEOUT
  TAG_TYPE            Tag type (version, environment, state)
  VERSION             Version string (v1.2.3)
  ENVIRONMENT         Environment name (production, staging, etc.)
  STATE               State name (testing, stable, unstable, etc.)
  SUBPROJECT          Subproject name (optional)
  COMMIT_SHA          Commit SHA to tag (defaults to HEAD)
  FORCE_MOVE          Force move existing tags (true/false)
  GITHUB_TOKEN        Token for pushing tags to remote
  GITHUB_OUTPUT       File for GitHub Actions outputs
  GITHUB_REPOSITORY   Repository name (org/repo)
  GITHUB_SERVER_URL   GitHub server URL
  GITHUB_RUN_ID       Workflow run ID
  GITHUB_RUN_NUMBER   Workflow run number
  GITHUB_ACTOR        Actor who triggered the workflow

Examples:
  # Create version tag
  TAG_TYPE=version VERSION=v1.2.3 COMMIT_SHA=abc123 $0 create-tag

  # Create environment tag
  TAG_TYPE=environment ENVIRONMENT=production COMMIT_SHA=def456 $0 create-tag

  # Create state tag with subproject
  TAG_TYPE=state VERSION=v1.2.3 STATE=stable SUBPROJECT=api $0 create-tag
EOF
      ;;
    *)
      log_error "Unknown command: $command"
      log_error "Use 'help' for usage information"
      exit 1
      ;;
  esac
}

# CLI interface
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi