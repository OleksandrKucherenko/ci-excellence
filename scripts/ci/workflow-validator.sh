#!/bin/bash
# GitHub Actions Workflow Validator
# Validates GitHub Actions YAML syntax and basic structure

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/scripts/lib/common.sh" 2>/dev/null || {
  echo "Failed to source common utilities" >&2
  exit 1
}

# Configuration
readonly VALIDATOR_VERSION="1.0.0"

# Testability configuration
get_behavior_mode() {
  local script_name="workflow_validator"
  get_script_behavior "$script_name" "EXECUTE"
}

# Validate single workflow file
validate_workflow() {
  local workflow_file="$1"
  local behavior
  behavior=$(get_behavior_mode)

  log_info "Validating workflow: $workflow_file (mode: $behavior)"

  case "$behavior" in
    "DRY_RUN")
      echo "🔍 DRY RUN: Would validate $workflow_file"
      return 0
      ;;
    "PASS")
      log_success "PASS MODE: Workflow validation simulated successfully"
      return 0
      ;;
    "FAIL")
      log_error "FAIL MODE: Simulating workflow validation failure"
      return 1
      ;;
    "SKIP")
      log_info "SKIP MODE: Workflow validation skipped"
      return 0
      ;;
    "TIMEOUT")
      log_info "TIMEOUT MODE: Simulating validation timeout"
      sleep 5
      return 124
      ;;
  esac

  # EXECUTE mode - Actual validation
  if [[ ! -f "$workflow_file" ]]; then
    log_error "Workflow file not found: $workflow_file"
    return 1
  fi

  # Basic YAML syntax check
  if command -v yamllint >/dev/null 2>&1; then
    if ! yamllint -d relaxed "$workflow_file" >/dev/null 2>&1; then
      log_error "YAML syntax error in $workflow_file"
      return 1
    fi
  else
    # Fallback basic check
    if command -v python3 >/dev/null 2>&1; then
      python3 -c "
import yaml
import sys
try:
    with open('$workflow_file', 'r') as f:
        yaml.safe_load(f)
    except yaml.YAMLError as e:
    print(f'YAML error: {e}', file=sys.stderr)
    sys.exit(1)
" 2>/dev/null || {
        log_error "YAML syntax validation failed for $workflow_file"
        return 1
      }
    fi
  fi

  # Use action-validator if available
  if command -v action-validator >/dev/null 2>&1; then
    if ! action-validator "$workflow_file" >/dev/null 2>&1; then
      log_error "Action validator failed for $workflow_file"
      return 1
    fi
  else
    log_warn "action-validator not available, skipping detailed validation"
  fi

  # Basic structure checks
  local workflow_name
  workflow_name=$(grep -E "^\s*name:" "$workflow_file" | head -1 | cut -d':' -f2- | tr -d ' "' || echo "unnamed")

  local triggers
  triggers=$(grep -E "^\s*on:" "$workflow_file" | head -1 | cut -d':' -f2- | tr -d ' "' || echo "none")

  log_success "✅ Workflow '$workflow_name' is valid (triggers: $triggers)"
  return 0
}

# Validate all workflows in directory
validate_all_workflows() {
  local workflows_dir="${1:-$PROJECT_ROOT/.github/workflows}"
  local behavior
  behavior=$(get_behavior_mode)

  log_info "Validating all workflows in: $workflows_dir"

  if [[ "$behavior" == "DRY_RUN" ]]; then
    echo "🔍 DRY RUN: Would validate all workflows in $workflows_dir"
    return 0
  fi

  if [[ ! -d "$workflows_dir" ]]; then
    log_warn "Workflows directory not found: $workflows_dir"
    return 0
  fi

  local workflow_files=()
  while IFS= read -r -d '' file; do
    workflow_files+=("$file")
  done < <(find "$workflows_dir" -name "*.yml" -o -name "*.yaml" -print0 2>/dev/null || true)

  if [[ ${#workflow_files[@]} -eq 0 ]]; then
    log_warn "No workflow files found in $workflows_dir"
    return 0
  fi

  local failed_count=0
  local total_count=${#workflow_files[@]}

  log_info "Found $total_count workflow files to validate"

  for workflow_file in "${workflow_files[@]}"; do
    if ! validate_workflow "$workflow_file"; then
      ((failed_count++))
    fi
  done

  if [[ $failed_count -eq 0 ]]; then
    log_success "✅ All $total_count workflows are valid"
    return 0
  else
    log_error "❌ $failed_count out of $total_count workflows failed validation"
    return 1
  fi
}

# Main execution
main() {
  local target="${1:-all}"

  log_info "GitHub Actions Workflow Validator v$VALIDATOR_VERSION"

  case "$target" in
    "all")
      validate_all_workflows
      ;;
    *)
      if [[ -f "$target" ]]; then
        validate_workflow "$target"
      else
        log_error "File not found: $target"
        echo "Usage: $0 [workflow_file|all]"
        exit 1
      fi
      ;;
  esac
}

# CLI interface
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  case "${1:-}" in
    "help"|"--help"|"-h")
      cat << EOF
GitHub Actions Workflow Validator v$VALIDATOR_VERSION

Usage: $0 [WORKFLOW_FILE|all]

Arguments:
  WORKFLOW_FILE    Path to specific workflow file to validate
  all              Validate all workflows in .github/workflows directory (default)

Environment Variables:
  CI_WORKFLOW_VALIDATOR_BEHAVIOR  EXECUTE, DRY_RUN, PASS, FAIL, SKIP, TIMEOUT
  CI_TEST_MODE                      Global testability mode
  PIPELINE_SCRIPT_*_BEHAVIOR        Pipeline-level overrides

Examples:
  $0                                    # Validate all workflows
  $0 .github/workflows/pre-release.yml # Validate specific file
  $0 all                                # Validate all workflows explicitly

Testability Examples:
  CI_TEST_MODE=DRY_RUN $0
  CI_WORKFLOW_VALIDATOR_BEHAVIOR=FAIL $0 .github/workflows/pre-release.yml
EOF
      exit 0
      ;;
    *)
      main "$@"
      ;;
  esac
fi