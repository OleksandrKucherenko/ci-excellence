#!/bin/bash
# Pre-push Tag Protection Hook
# Prevents manual creation of protected environment tags and validates tag patterns

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/scripts/lib/common.sh" 2>/dev/null || {
  echo "Failed to source common utilities" >&2
  exit 1
}

# Configuration
readonly TAG_PROTECTION_VERSION="1.0.0"

# Testability configuration
get_behavior_mode() {
  local script_name="tag_protection"
  get_script_behavior "$script_name" "ENFORCE"
}

# Get protection mode from environment
get_protection_mode() {
  local mode="${TAG_PROTECTION_MODE:-ENFORCE}"

  case "$mode" in
    "ENFORCE"|"WARN"|"OFF")
      echo "$mode"
      ;;
    *)
      log_warn "Unknown protection mode: $mode, defaulting to ENFORCE"
      echo "ENFORCE"
      ;;
  esac
}

# Validate git repository
validate_git_repository() {
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    log_error "Not in a git repository"
    return 1
  fi
  return 0
}

# Determine tag type based on pattern
get_tag_type() {
  local tag="$1"

  # Version tags (semantic versioning)
  if [[ "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+([a-zA-Z0-9\-\.\+]*)?$ ]]; then
    echo "version"
    return 0
  fi

  # Environment tags (movable deployment targets)
  case "$tag" in
    "production"|"staging"|"development"|"testing"|"uat")
      echo "environment"
      return 0
      ;;
  esac

  # State tags (immutable commit-state markers)
  if [[ "$tag" =~ ^[a-f0-9]{7,40}-(testing|stable|unstable|deprecated|maintenance)$ ]]; then
    echo "state"
    return 0
  fi

  # Feature branch tags (protected)
  if [[ "$tag" =~ ^(feature|hotfix|release|bugfix)/.+$ ]]; then
    echo "feature"
    return 0
  fi

  echo "unknown"
}

# Validate tag pattern
validate_tag_pattern() {
  local tag="$1"
  local tag_type
  tag_type=$(get_tag_type "$tag")

  case "$tag_type" in
    "version"|"state")
      log_debug "Tag '$tag' has valid pattern: $tag_type"
      return 0
      ;;
    "environment")
      log_error "Environment tag '$tag' cannot be created manually"
      log_error "Use GitHub Actions tag-assignment workflow to manage environment tags"
      return 1
      ;;
    "feature")
      log_error "Feature branch tag '$tag' is not allowed"
      log_error "Feature branch tags are managed automatically by CI/CD"
      return 1
      ;;
    "unknown")
      log_warn "Unknown tag pattern: '$tag'"
      log_warn "Use semantic versioning (v1.2.3) or state tags (abc123-testing)"
      return 1
      ;;
    *)
      log_error "Invalid tag type: $tag_type"
      return 1
      ;;
  esac
}

# Check tag immutability
validate_tag_immutability() {
  local tag="$1"
  local tag_type
  tag_type=$(get_tag_type "$tag")

  case "$tag_type" in
    "version"|"state")
      # Version and state tags should be immutable
      if git show-ref --verify --quiet "refs/tags/$tag" 2>/dev/null; then
        log_error "$tag_type tag '$tag' already exists and is immutable"
        log_error "Immutable tags cannot be moved or recreated"
        return 1
      fi
      ;;
    "environment")
      # Environment tags are movable (deployment targets)
      if git show-ref --verify --quiet "refs/tags/$tag" 2>/dev/null; then
        log_info "Environment tag '$tag' is movable"
        return 0
      fi
      ;;
  esac

  return 0
}

# Check individual tag protection
check_tag_protection() {
  local tag="$1"
  local protection_mode
  protection_mode=$(get_protection_mode)

  # Skip protection checks if mode is OFF
  if [[ "$protection_mode" == "OFF" ]]; then
    log_info "Tag protection is disabled"
    return 0
  fi

  # Validate tag pattern
  if ! validate_tag_pattern "$tag"; then
    case "$protection_mode" in
      "ENFORCE")
        log_error "PROTECTION ENFORCED: Tag creation blocked"
        log_error "Create a pull request to the repository with CI/CD changes instead"
        return 1
        ;;
      "WARN")
        log_warn "PROTECTION WARNING: Manual tag creation may cause deployment issues"
        log_warn "Consider using the tag-assignment workflow for managed tag creation"
        return 0
        ;;
    esac
  fi

  # Validate tag immutability
  if ! validate_tag_immutability "$tag"; then
    case "$protection_mode" in
      "ENFORCE")
        log_error "PROTECTION ENFORCED: Immutable tag modification blocked"
        return 1
        ;;
      "WARN")
        log_warn "PROTECTION WARNING: Modifying immutable tag may cause issues"
        return 0
        ;;
    esac
  fi

  log_success "Tag validation passed for: $tag"
  return 0
}

# Validate multiple tags
validate_tags() {
  local tags=("$@")
  local invalid_tags=()
  local protection_mode
  protection_mode=$(get_protection_mode)

  if [[ ${#tags[@]} -eq 0 ]]; then
    log_debug "No tags to validate"
    return 0
  fi

  log_info "Validating ${#tags[@]} tags (mode: $protection_mode)"

  for tag in "${tags[@]}"; do
    if ! check_tag_protection "$tag"; then
      invalid_tags+=("$tag")
    fi
  done

  if [[ ${#invalid_tags[@]} -gt 0 ]]; then
    log_error "Invalid tags found: ${invalid_tags[*]}"

    if [[ "$protection_mode" == "ENFORCE" ]]; then
      log_error "Push blocked due to invalid tags"
      return 1
    else
      log_warn "Invalid tags detected but push allowed in $protection_mode mode"
      return 0
    fi
  fi

  log_success "All tags validated successfully"
  return 0
}

# Process pre-push hook input
process_pre_push() {
  local push_info="$1"

  if [[ -z "$push_info" ]]; then
    log_debug "No push information provided"
    return 0
  fi

  local tags=()

  # Parse push information to extract tags
  while IFS= read -r line; do
    if [[ "$line" =~ ^refs/tags/ ]]; then
      local tag="${line#refs/tags/}"
      tags+=("$tag")
    fi
  done <<< "$push_info"

  if [[ ${#tags[@]} -eq 0 ]]; then
    log_debug "No tags in push to validate"
    return 0
  fi

  log_info "Processing pre-push hook with ${#tags[@]} tags: ${tags[*]}"

  validate_tags "${tags[@]}"
}

# Main execution
main() {
  local behavior
  behavior=$(get_behavior_mode)

  case "$behavior" in
    "DRY_RUN")
      echo "🔍 DRY RUN: Would validate tag protection"
      return 0
      ;;
    "PASS")
      log_success "PASS MODE: Tag protection validation simulated successfully"
      return 0
      ;;
    "FAIL")
      log_error "FAIL MODE: Simulating tag protection validation failure"
      return 1
      ;;
    "SKIP")
      log_info "SKIP MODE: Tag protection validation skipped"
      return 0
      ;;
    "TIMEOUT")
      log_info "TIMEOUT MODE: Simulating tag protection validation timeout"
      sleep 5
      return 124
      ;;
  esac

  # EXECUTE mode - Actual validation
  log_info "Tag Protection Hook v$TAG_PROTECTION_VERSION"

  # Validate we're in a git repository
  if ! validate_git_repository; then
    return 1
  fi

  # Get protection mode
  local protection_mode
  protection_mode=$(get_protection_mode)
  log_info "Protection mode: $protection_mode"

  # Process input from stdin (standard pre-push hook interface)
  local push_info=""
  while IFS= read -r line; do
    push_info+="$line"$'\n'
  done

  process_pre_push "$push_info"
}

# CLI interface
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Parse command line arguments
  case "${1:-}" in
    "help"|"--help"|"-h")
      cat << EOF
Tag Protection Hook v$TAG_PROTECTION_VERSION

This script validates git tags before pushing to prevent:
- Manual creation of environment tags (production, staging, etc.)
- Modification of immutable version and state tags
- Creation of feature branch tags
- Invalid tag patterns

Usage:
  Used as a git pre-push hook via Lefthook configuration

Environment Variables:
  TAG_PROTECTION_MODE   ENFORCE, WARN, OFF (default: ENFORCE)
  CI_TEST_MODE          Global testability mode

Protection Modes:
  ENFORCE               Block invalid tag creation (default)
  WARN                  Allow invalid tags but show warnings
  OFF                   Disable all tag protection

Tag Patterns:
  Version:              v1.2.3, v1.2.3-alpha.1, v1.2.3+build.123
  State:                abc123-testing, abc123-stable, abc123-unstable
  Environment (managed): production, staging, development, testing, uat
  Feature (protected):   feature/*, hotfix/*, release/*

Examples:
  # Allow version tag
  git tag v1.2.3 && git push origin v1.2.3

  # Block environment tag (use GitHub Actions instead)
  git tag production  # ❌ Blocked by hook

  # Block feature branch tag
  git tag feature/new-feature  # ❌ Blocked by hook

Configuration:
  Add to .lefthook.yml:
    pre-push:
      commands:
        - run: ./scripts/hooks/pre-push-tag-protection.sh
EOF
      exit 0
      ;;
    "validate")
      # Manual validation mode for testing
      if [[ $# -lt 2 ]]; then
        echo "Usage: $0 validate <tag1> [tag2] ..."
        exit 1
      fi
      shift
      validate_tags "$@"
      exit $?
      ;;
    "check")
      # Check single tag
      if [[ $# -lt 2 ]]; then
        echo "Usage: $0 check <tag>"
        exit 1
      fi
      check_tag_protection "$2"
      exit $?
      ;;
    *)
      main "$@"
      ;;
  esac
fi