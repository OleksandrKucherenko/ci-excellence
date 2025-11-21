#!/usr/bin/env bash
# Git Tag Protection Hook
# Prevents manual creation of protected environment tags
# Enforces that environment tags must be created via Tag Assignment workflow

set -euo pipefail

# Source utilities if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/../lib/common.sh" ]]; then
  # shellcheck source=../lib/common.sh
  source "${SCRIPT_DIR}/../lib/common.sh"
fi

# Configuration
PROTECTED_ENVIRONMENTS="production staging canary sandbox performance"
ALLOWED_TAG_PATTERNS="v*.*.* */v*.*.* */v*.*.*-stable */v*.*.*-unstable */v*.*.*-deprecated"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

log_error() {
  echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $*" >&2
}

log_info() {
  echo -e "${GREEN}[INFO]${NC} $*" >&2
}

# Check if a tag is a protected environment tag
is_protected_environment_tag() {
  local tag="$1"

  # Strip the "refs/tags/" prefix if present
  local clean_tag="${tag#refs/tags/}"

  # Extract the last component after last slash
  local tag_component="${clean_tag##*/}"

  # Check if it matches a protected environment
  for env in $PROTECTED_ENVIRONMENTS; do
    if [[ "$tag_component" == "$env" ]]; then
      return 0
    fi
  done

  return 1
}

# Check if a tag follows allowed patterns
is_allowed_tag_pattern() {
  local tag="$1"

  # Strip the "refs/tags/" prefix if present
  local clean_tag="${tag#refs/tags/}"

  # Check against allowed patterns
  for pattern in $ALLOWED_TAG_PATTERNS; do
    # Convert shell pattern to regex
    local regex_pattern
    regex_pattern=$(echo "$pattern" | sed 's/\*/.*/g')

    if [[ "$clean_tag" =~ ^${regex_pattern}$ ]]; then
      return 0
    fi
  done

  return 1
}

# Check for admin exemption
is_admin_exempt() {
  if [[ "${ALLOW_PROTECTED_TAG_PUSH:-false}" == "true" ]]; then
    log_warning "⚠️  Protected tag protection bypassed by ALLOW_PROTECTED_TAG_PUSH=true"
    log_warning "   This should only be used for emergency admin operations"
    return 0
  fi
  return 1
}

# Validate tag creation
validate_tag_creation() {
  local tag="$1"
  local operation="$2"  # "create" or "push"

  # Check if this is a protected environment tag
  if is_protected_environment_tag "$tag"; then
    log_error "🚫 Protected environment tag detected: $tag"
    log_error "   Environment tags must be created via the Tag Assignment workflow"
    log_error "   Use: https://github.com/${GITHUB_REPOSITORY:-owner/repo}/actions/workflows/tag-assignment.yml"
    log_error ""
    log_error "To create environment tags:"
    log_error "1. Go to Actions → Tag Assignment workflow"
    log_error "2. Select tag_type: 'environment'"
    log_error "3. Choose the environment and version"
    log_error "4. Run the workflow"
    return 1
  fi

  # Check if tag follows allowed patterns
  if ! is_allowed_tag_pattern "$tag"; then
    log_warning "⚠️  Tag does not follow recommended patterns: $tag"
    log_warning "   Recommended patterns: $ALLOWED_TAG_PATTERNS"
    log_warning "   Continue anyway (this is just a warning)"
  fi

  # Check admin exemption
  if is_admin_exempt; then
    log_info "✅ Admin exemption granted for protected tag operation"
    return 0
  fi

  log_info "✅ Tag validation passed: $tag"
  return 0
}

# Get list of tags being pushed/created
get_being_pushed_tags() {
  local remote="$1"
  local url="$2"

  # Extract tags from the push arguments
  # The pre-push hook receives: <remote> <url> <ref>...<ref>
  shift 2  # Remove remote and url from arguments

  local tags=()
  for ref in "$@"; do
    # Handle different ref formats
    case "$ref" in
      refs/tags/*)
        tags+=("$ref")
        ;;
      +refs/tags/*:refs/tags/*)
        # Format for force push: +refs/tags/v1.0.0:refs/tags/v1.0.0
        local tag="${ref#+refs/tags/}"
        tag="${tag%:refs/tags/*}"
        tags+=("refs/tags/$tag")
        ;;
      refs/tags/*:refs/tags/*)
        # Format for push with different name: refs/tags/v1.0.0:refs/tags/v1.0.1
        local tag="${ref#refs/tags/}"
        tag="${tag%:refs/tags/*}"
        tags+=("refs/tags/$tag")
        ;;
    esac
  done

  printf '%s\n' "${tags[@]}"
}

# Main validation logic
main() {
  log_info "🔍 Validating tag protection for pre-push hook"

  # Check if this is a tag push
  if [[ $# -lt 3 ]]; then
    # Not enough arguments for tag validation
    log_info "No tag operations to validate"
    return 0
  fi

  local remote="$1"
  local url="$2"

  # Get tags being pushed
  local tags
  readarray -t tags < <(get_being_pushed_tags "$remote" "$url" "${@:3}")

  if [[ ${#tags[@]} -eq 0 ]]; then
    log_info "No tags in this push"
    return 0
  fi

  log_info "Found ${#tags[@]} tag(s) to validate:"

  local validation_errors=0

  for tag in "${tags[@]}"; do
    echo "  - $tag"

    if ! validate_tag_creation "$tag" "push"; then
      ((validation_errors++))
    fi
  done

  if [[ $validation_errors -gt 0 ]]; then
    log_error ""
    log_error "🚫 Tag validation failed with $validation_errors error(s)"
    log_error ""
    log_error "To fix this:"
    log_error "1. Cancel this push"
    log_error "2. Use the Tag Assignment workflow instead"
    log_error "3. Or set ALLOW_PROTECTED_TAG_PUSH=true for emergency admin use"
    return 1
  fi

  log_info "✅ All tags passed validation"
  return 0
}

# Alternative entry point for manual testing
test_validation() {
  local tag="$1"

  log_info "Testing tag validation for: $tag"

  if validate_tag_creation "$tag" "test"; then
    log_info "✅ Tag would be allowed"
    return 0
  else
    log_error "❌ Tag would be blocked"
    return 1
  fi
}

# Show usage information
show_usage() {
  cat <<EOF
Git Tag Protection Hook Usage:

This hook prevents manual creation of protected environment tags.

Protected environments: $PROTECTED_ENVIRONMENTS
Allowed tag patterns: $ALLOWED_TAG_PATTERNS

Environment tags must be created via the Tag Assignment workflow:
https://github.com/\${GITHUB_REPOSITORY:-owner/repo}/actions/workflows/tag-assignment.yml

For testing:
  $0 test <tag-name>

Examples:
  $0 test production              # ❌ Blocked (protected environment tag)
  $0 test v1.2.3                 # ✅ Allowed (version tag)
  $0 test api/v1.2.3             # ✅ Allowed (sub-project version tag)
  $0 test v1.2.3-stable         # ✅ Allowed (state tag)

Admin override:
  Set ALLOW_PROTECTED_TAG_PUSH=true to bypass protection for emergency operations.
EOF
}

# Command line argument handling
case "${1:-}" in
  "test")
    if [[ $# -ne 2 ]]; then
      echo "Usage: $0 test <tag-name>"
      exit 1
    fi
    test_validation "$2"
    ;;
  "help"|"-h"|"--help")
    show_usage
    exit 0
    ;;
  "")
    # Run as pre-push hook
    main "$@"
    ;;
  *)
    # Run as pre-push hook with arguments
    main "$@"
    ;;
esac