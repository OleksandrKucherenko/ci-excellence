#!/usr/bin/env bash
# GitHub Actions Workflow Validator
# Validates workflow syntax and structure

set -euo pipefail

# Source utilities if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/../lib/common.sh" ]]; then
  # shellcheck source=../lib/common.sh
  source "${SCRIPT_DIR}/../lib/common.sh"
fi

# Configuration
WORKFLOWS_DIR=".github/workflows"
VALIDATION_REPORT="/tmp/workflow-validation-report.txt"
ERROR_COUNT=0
WARNING_COUNT=0

# Check if action-validator is available
check_action_validator() {
  if ! command -v action-validator >/dev/null 2>&1; then
    log_warning "action-validator not found, installing..."
    if command -v mise >/dev/null 2>&1; then
      mise install action-validator
    else
      log_error "Cannot install action-validator without mise"
      return 1
    fi
  fi
}

# Validate single workflow file
validate_workflow_file() {
  local workflow_file="$1"

  log_info "Validating workflow: $workflow_file"

  local temp_output
  temp_output=$(mktemp)

  # Basic YAML syntax check
  if command -v yq >/dev/null 2>&1; then
    if ! yq eval '.' "$workflow_file" > "$temp_output" 2>&1; then
      log_error "YAML syntax error in $workflow_file:"
      cat "$temp_output" >&2
      ((ERROR_COUNT++))
      rm -f "$temp_output"
      return 1
    fi
  elif command -v python >/dev/null 2>&1; then
    if ! python -c "import yaml; yaml.safe_load(open('$workflow_file'))" 2>"$temp_output"; then
      log_error "YAML syntax error in $workflow_file:"
      cat "$temp_output" >&2
      ((ERROR_COUNT++))
      rm -f "$temp_output"
      return 1
    fi
  else
    log_warning "No YAML validator available, skipping syntax check for $workflow_file"
  fi

  # Action validator check
  if check_action_validator; then
    if ! action-validator "$workflow_file" > "$temp_output" 2>&1; then
      log_error "Action validation error in $workflow_file:"
      cat "$temp_output" >&2
      ((ERROR_COUNT++))
      rm -f "$temp_output"
      return 1
    fi
  fi

  rm -f "$temp_output"
  log_success "Workflow validation passed: $workflow_file"
  return 0
}

# Validate workflow structure and content
validate_workflow_content() {
  local workflow_file="$1"

  log_debug "Analyzing workflow content: $workflow_file"

  local workflow_name
  workflow_name=$(yq eval '.name // "Unnamed"' "$workflow_file" 2>/dev/null || echo "Unnamed")

  # Check for required fields
  local required_fields=("on")
  for field in "${required_fields[@]}"; do
    if ! yq eval ".$field" "$workflow_file" >/dev/null 2>&1; then
      log_error "Missing required field '$field' in $workflow_file"
      ((ERROR_COUNT++))
    fi
  done

  # Check for jobs
  local job_count
  job_count=$(yq eval '.jobs | length // 0' "$workflow_file" 2>/dev/null || echo "0")

  if [[ "$job_count" -eq 0 ]]; then
    log_error "No jobs defined in $workflow_file"
    ((ERROR_COUNT++))
    return 1
  fi

  # Validate each job
  local job_names
  readarray -t job_names < <(yq eval '.jobs | keys | .[]' "$workflow_file" 2>/dev/null || true)

  for job_name in "${job_names[@]}"; do
    validate_job "$workflow_file" "$job_name"
  done

  log_success "Content validation passed: $workflow_name"
}

# Validate individual job
validate_job() {
  local workflow_file="$1"
  local job_name="$2"

  log_debug "Validating job: $job_name"

  # Check for runs-on
  if ! yq eval ".jobs.${job_name}.\"runs-on\"" "$workflow_file" >/dev/null 2>&1; then
    log_error "Job '$job_name' missing 'runs-on' in $workflow_file"
    ((ERROR_COUNT++))
    return 1
  fi

  # Check for timeout configuration (warning if missing)
  if ! yq eval ".jobs.${job_name}.timeout-minutes" "$workflow_file" >/dev/null 2>&1; then
    log_warning "Job '$job_name' missing timeout-minutes in $workflow_file"
    ((WARNING_COUNT++))
  fi

  # Check for environment variables in sensitive steps
  local steps_count
  steps_count=$(yq eval ".jobs.${job_name}.steps | length // 0" "$workflow_file" 2>/dev/null || echo "0")

  for ((i=0; i<steps_count; i++)); do
    local step_name
    step_name=$(yq eval ".jobs.${job_name}.steps[$i].name // \"Step $i\"" "$workflow_file" 2>/dev/null || echo "Step $i")
    local step_uses
    step_uses=$(yq eval ".jobs.${job_name}.steps[$i].uses // \"\"" "$workflow_file" 2>/dev/null || echo "")

    # Check for specific patterns
    if [[ "$step_uses" =~ actions/checkout ]]; then
      # Check if using specific version
      if [[ ! "$step_uses" =~ @v[0-9] ]]; then
        log_warning "Step '$step_name' in job '$job_name' should pin action version (currently: $step_uses)"
        ((WARNING_COUNT++))
      fi
    fi
  done
}

# Generate validation report
generate_report() {
  cat > "$VALIDATION_REPORT" <<EOF
# GitHub Actions Workflow Validation Report

Generated: $(date '+%Y-%m-%d %H:%M:%S UTC')

## Summary
- Errors: $ERROR_COUNT
- Warnings: $WARNING_COUNT
- Total workflows: $(find "$WORKFLOWS_DIR" -name "*.yml" -o -name "*.yaml" | wc -l)

EOF

  if [[ $ERROR_COUNT -eq 0 ]]; then
    echo "✅ All workflows passed validation" >> "$VALIDATION_REPORT"
  else
    echo "❌ $ERROR_COUNT error(s) found" >> "$VALIDATION_REPORT"
  fi

  if [[ $WARNING_COUNT -gt 0 ]]; then
    echo "⚠️  $WARNING_COUNT warning(s) found" >> "$VALIDATION_REPORT"
  fi
}

# Main validation function
main() {
  local specific_file="${1:-}"

  log_info "Starting GitHub Actions workflow validation"

  if [[ -n "$specific_file" ]]; then
    # Validate specific file
    if [[ -f "$specific_file" ]]; then
      validate_workflow_file "$specific_file"
      validate_workflow_content "$specific_file"
    else
      log_error "Workflow file not found: $specific_file"
      return 1
    fi
  else
    # Validate all workflow files
    if [[ ! -d "$WORKFLOWS_DIR" ]]; then
      log_error "Workflows directory not found: $WORKFLOWS_DIR"
      return 1
    fi

    local workflow_files=()
    readarray -t workflow_files < <(find "$WORKFLOWS_DIR" -name "*.yml" -o -name "*.yaml" | sort)

    if [[ ${#workflow_files[@]} -eq 0 ]]; then
      log_warning "No workflow files found in $WORKFLOWS_DIR"
      return 0
    fi

    for workflow_file in "${workflow_files[@]}"; do
      validate_workflow_file "$workflow_file"
      validate_workflow_content "$workflow_file"
    done
  fi

  generate_report

  # Output report summary
  if [[ $ERROR_COUNT -eq 0 ]]; then
    log_success "All workflows validated successfully"
    if [[ -n "${CI:-}" ]]; then
      echo "## Workflow Validation Results" >> "$GITHUB_STEP_SUMMARY"
      echo "✅ All workflows passed validation" >> "$GITHUB_STEP_SUMMARY"
    fi
  else
    log_error "Workflow validation failed with $ERROR_COUNT error(s)"
    if [[ -n "${CI:-}" ]]; then
      echo "## Workflow Validation Results" >> "$GITHUB_STEP_SUMMARY"
      echo "❌ Validation failed with $ERROR_COUNT error(s)" >> "$GITHUB_STEP_SUMMARY"
      cat "$VALIDATION_REPORT" >> "$GITHUB_STEP_SUMMARY"
    fi
    return 1
  fi

  if [[ -n "${REPORT_OUTPUT:-}" ]]; then
    cp "$VALIDATION_REPORT" "$REPORT_OUTPUT"
  fi
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi