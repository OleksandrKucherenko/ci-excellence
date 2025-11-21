#!/usr/bin/env bash
# Pre-commit Message Check Hook
# Enforces conventional commit message format

set -euo pipefail

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

log_success() {
  echo -e "${GREEN}✅ $*${NC}" >&2
}

# Commit message file
COMMIT_MSG_FILE="$1"

# Conventional commit types
TYPES="feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert|improvement|release"

# Scopes specific to this project
SCOPES="ci|cd|pipeline|workflows|scripts|deployment|security|testing|docs|config|release|maintenance|hooks|lefthook|mise"

# Check if commitizen is available
check_commitizen() {
  if command -v uvx >/dev/null 2>&1 && uvx --from commitizen cz version >/dev/null 2>&1; then
    return 0
  elif command -v cz >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

# Validate commit message using regex
validate_with_regex() {
  local message="$1"

  # Remove leading/trailing whitespace
  message="$(echo "$message" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

  # Check if there's a colon after the type (and optional scope)
  if [[ ! "$message" =~ ^[a-zA-Z_]+.*:.* ]]; then
    return 1
  fi

  # Extract type, scope, and description using simpler methods
  local type_part="${message%%:*}"
  local description="${message#*: }"

  # Extract type and optional scope from type_part
  if [[ "$type_part" == *\(* ]]; then
    # Has scope: type(scope)
    local type="${type_part%%(*}"
    local scope_with_parens="${type_part#*\(}"
    local scope="${scope_with_parens%)}"
  else
    # No scope: just type
    local type="$type_part"
    local scope=""
  fi

  # Validate type
  local type_valid=false
  for allowed_type in $TYPES; do
    if [[ "$type" == "$allowed_type" ]]; then
      type_valid=true
      break
    fi
  done

  if [[ "$type_valid" == "false" ]]; then
    return 1
  fi

  # Validate description length (minimum 3 characters)
  if [[ ${#description} -lt 3 ]]; then
    return 1
  fi

  # Check scope if present
  if [[ -n "$scope" ]]; then
    # Scope should be lowercase and use hyphens
    if [[ "$scope" =~ [[:upper:]] || "$scope" =~ [[:space:]] ]]; then
      return 1
    fi

    # Check against allowed scopes
    local scope_valid=false
    for allowed_scope in $SCOPES; do
      if [[ "$scope" == "$allowed_scope" ]]; then
        scope_valid=true
        break
      fi
    done

    # Allow generic scopes not in the list (comment this out if you want to restrict to specific scopes)
    # if [[ "$scope_valid" == "false" ]]; then
    #   return 1
    # fi
  fi

  # Validate description format (no leading/trailing whitespace)
  if [[ "$description" =~ ^[[:space:]] || "$description" =~ [[:space:]]$ ]]; then
    return 1
  fi

  # Check for common issues
  if [[ "$message" =~ \.$ ]]; then
    log_warning "⚠️  Commit message should not end with a period"
  fi

  return 0
}

# Validate commit message using commitizen
validate_with_commitizen() {
  local message="$1"

  # Prefer uvx for commitizen execution
  if command -v uvx >/dev/null 2>&1; then
    if uvx --from commitizen cz check --message "$message" 2>/dev/null; then
      return 0
    else
      return 1
    fi
  elif command -v cz >/dev/null 2>&1; then
    if cz check --message "$message" 2>/dev/null; then
      return 0
    else
      return 1
    fi
  else
    return 1
  fi
}

# Provide helpful feedback
show_commit_help() {
  cat <<EOF
${RED}❌ Invalid commit message format${NC}

${GREEN}✅ Conventional commit format:${NC}
<type>${YELLOW}[optional scope]${NC}</type><description>

${GREEN}Examples:${NC}
  feat(pipeline): add automated deployment system
  fix(security): resolve credential exposure vulnerability
  docs(readme): update installation instructions
  test(ci): add integration test coverage
  chore(deps): update dependencies to latest versions

${GREEN}Available types:${NC}
  feat     - New feature
  fix      - Bug fix
  docs     - Documentation
  style    - Formatting, missing semi-colons, etc
  refactor - Code refactoring without feature changes
  test     - Adding tests or refactoring tests
  chore    - Maintenance tasks, dependency updates
  perf     - Performance improvements
  ci       - CI/CD related changes
  build    - Build system or dependency changes
  revert   - Reverting previous changes
  improvement - Code improvements
  release  - Release-related changes

${GREEN}Available scopes:${NC}
  ci, cd, pipeline, workflows, scripts, deployment, security, testing, docs, config, release, maintenance, hooks, lefthook, mise

${GREEN}Tips:${NC}
  • Use imperative mood ("add feature", not "adds feature")
  • Keep the description concise but informative
  • Reference relevant issue numbers if available
  • Use "breaking:" for breaking changes (rare)

${YELLOW}To install commitizen:${NC}
  brew install commitizen
  uvx --from commitizen cz version  # Check availability via uvx
  npm install -g commitizen
  npx commitizen init  # Or add to package.json
EOF
}

# Main validation logic
main() {
  log_info "📝 Checking commit message format"

  # Read commit message
  if [[ ! -f "$COMMIT_MSG_FILE" ]]; then
    log_error "Commit message file not found: $COMMIT_MSG_FILE"
    return 1
  fi

  local message
  message=$(cat "$COMMIT_MSG_FILE")

  # Check if message is empty
  if [[ -z "$message" ]]; then
    log_error "Commit message is empty"
    show_commit_help
    return 1
  fi

  # Check for merge commits (these are usually auto-generated)
  if [[ "$message" == Merge* ]]; then
    log_info "Merge commit detected, skipping validation"
    return 0
  fi

  # Check for revert commits (these have special format)
  if [[ "$message" == revert* ]]; then
    log_info "Revert commit detected, skipping validation"
    return 0
  fi

  # Choose validation method
  local validation_method="regex"  # Fallback to regex
  if check_commitizen; then
    validation_method="commitizen"
    if command -v uvx >/dev/null 2>&1 && uvx --from commitizen cz version >/dev/null 2>&1; then
      log_info "Using commitizen (uvx) for validation"
    elif command -v cz >/dev/null 2>&1; then
      log_info "Using commitizen (cz) for validation"
    fi
  else
    log_info "Using regex validation (commitizen not found)"
  fi

  # Validate the message
  local validation_passed=false
  case "$validation_method" in
    "commitizen")
      if validate_with_commitizen "$message"; then
        validation_passed=true
      fi
      ;;
    "regex"|*)
      if validate_with_regex "$message"; then
        validation_passed=true
      fi
      ;;
  esac

  if [[ "$validation_passed" == "true" ]]; then
    log_success "✅ Commit message format is valid"

    # Show summary
    local type
    if [[ "$message" =~ ^($TYPES) ]]; then
      type="${BASH_REMATCH[1]}"
      log_info "Commit type: $type"
    fi

    return 0
  else
    show_commit_help
    return 1
  fi
}

# Execute main function with commit message file argument
main "$COMMIT_MSG_FILE"