#!/usr/bin/env bash
set -euo pipefail

# CI Script: Pre-Release Summary with Report Generator Integration
# Purpose: Generate comprehensive pre-release pipeline summary with actionable links

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/scripts/lib/common.sh" 2>/dev/null || {
  echo "Failed to source common utilities" >&2
  exit 1
}

# Source report generator
source "$PROJECT_ROOT/scripts/ci/report-generator.sh" 2>/dev/null || {
  echo "Failed to source report generator" >&2
  exit 1
}

# Job results from workflow dependencies
SETUP_RESULT="${1:-unknown}"
COMPILE_RESULT="${2:-unknown}"
LINT_RESULT="${3:-unknown}"
UNIT_RESULT="${4:-unknown}"
INTEGRATION_RESULT="${5:-unknown}"
E2E_RESULT="${6:-unknown}"
SECURITY_RESULT="${7:-unknown}"
BUNDLE_RESULT="${8:-unknown}"

# Feature flags from environment
ENABLE_COMPILE="${ENABLE_COMPILE:-false}"
ENABLE_LINT="${ENABLE_LINT:-false}"
ENABLE_UNIT_TESTS="${ENABLE_UNIT_TESTS:-false}"
ENABLE_INTEGRATION_TESTS="${ENABLE_INTEGRATION_TESTS:-false}"
ENABLE_E2E_TESTS="${ENABLE_E2E_TESTS:-false}"
ENABLE_SECURITY_SCAN="${ENABLE_SECURITY_SCAN:-false}"
ENABLE_BUNDLE="${ENABLE_BUNDLE:-false}"

# Calculate overall pipeline status
determine_overall_status() {
  local failed_jobs=0
  local total_jobs=0

  # Check each job result
  for job in "$COMPILE_RESULT" "$LINT_RESULT" "$UNIT_RESULT" "$INTEGRATION_RESULT" "$E2E_RESULTS" "$SECURITY_RESULT" "$BUNDLE_RESULT"; do
    if [[ "$job" != "skipped" && "$job" != "unknown" ]]; then
      total_jobs=$((total_jobs + 1))
      if [[ "$job" == "failure" ]]; then
        failed_jobs=$((failed_jobs + 1))
      fi
    fi
  done

  # Determine overall status
  if [[ "$failed_jobs" -eq 0 ]]; then
    echo "SUCCESS"
  elif [[ "$failed_jobs" -eq "$total_jobs" ]]; then
    echo "FAILURE"
  else
    echo "PARTIAL"
  fi
}

# Generate pipeline metrics
generate_pipeline_metrics() {
  local duration="$1"
  local status="$2"

  # Count enabled jobs
  local enabled_jobs=0
  [[ "$ENABLE_COMPILE" == "true" ]] && enabled_jobs=$((enabled_jobs + 1))
  [[ "$ENABLE_LINT" == "true" ]] && enabled_jobs=$((enabled_jobs + 1))
  [[ "$ENABLE_UNIT_TESTS" == "true" ]] && enabled_jobs=$((enabled_jobs + 1))
  [[ "$ENABLE_INTEGRATION_TESTS" == "true" ]] && enabled_jobs=$((enabled_jobs + 1))
  [[ "$ENABLE_E2E_TESTS" == "true" ]] && enabled_jobs=$((enabled_jobs + 1))
  [[ "$ENABLE_SECURITY_SCAN" == "true" ]] && enabled_jobs=$((enabled_jobs + 1))
  [[ "$ENABLE_BUNDLE" == "true" ]] && enabled_jobs=$((enabled_jobs + 1))

  echo "Pipeline Metrics: $enabled_jobs jobs executed, Duration: ${duration}s, Status: $status"
}

# Main execution
main() {
  log_info "Pre-Release Pipeline Summary Generator"

  # Determine pipeline status
  local overall_status
  overall_status=$(determine_overall_status)

  # Calculate pipeline duration (mock for now)
  local pipeline_duration="${GITHUB_RUN_DURATION:-120}"

  # Generate version tag if available
  local version_tag="${GITHUB_REF_NAME:-}"
  if [[ "$version_tag" =~ ^refs/tags/ ]]; then
    version_tag="${version_tag#refs/tags/}"
  elif [[ -z "$version_tag" || "$version_tag" =~ ^(main|develop)$ ]]; then
    version_tag="latest"
  fi

  # Extract subproject from path
  local subproject="${GITHUB_WORKFLOW_REF:-}"
  subproject="${subproject#*/}"
  subproject="${subproject%/*}"

  # Generate comprehensive report using report generator
  log_info "Generating comprehensive pre-release report"

  # Set environment for report generator
  export GITHUB_STEP_SUMMARY="${GITHUB_STEP_SUMMARY:-/tmp/pre-release-summary.md}"

  # Generate the main report
  if ! generate_report "PRE_RELEASE" "$overall_status" "$pipeline_duration" "$version_tag" "$subproject" "staging"; then
    log_error "Failed to generate main report"
    exit 1
  fi

  # Add custom pre-release specific information
  cat >> "$GITHUB_STEP_SUMMARY" << EOF

## 📊 Pre-Release Job Details

| Job | Status | Enabled | Duration |
|-----|--------|---------|----------|
| Setup | $SETUP_RESULT | Always | - |
EOF

  # Add job details only if enabled
  if [[ "$ENABLE_COMPILE" == "true" ]]; then
    echo "| Compile | $COMPILE_RESULT | ✅ | - |" >> "$GITHUB_STEP_SUMMARY"
  fi

  if [[ "$ENABLE_LINT" == "true" ]]; then
    echo "| Lint | $LINT_RESULT | ✅ | - |" >> "$GITHUB_STEP_SUMMARY"
  fi

  if [[ "$ENABLE_UNIT_TESTS" == "true" ]]; then
    echo "| Unit Tests | $UNIT_RESULT | ✅ | - |" >> "$GITHUB_STEP_SUMMARY"
  fi

  if [[ "$ENABLE_INTEGRATION_TESTS" == "true" ]]; then
    echo "| Integration Tests | $INTEGRATION_RESULT | ✅ | - |" >> "$GITHUB_STEP_SUMMARY"
  fi

  if [[ "$ENABLE_E2E_TESTS" == "true" ]]; then
    echo "| E2E Tests | $E2E_RESULT | ✅ | - |" >> "$GITHUB_STEP_SUMMARY"
  fi

  if [[ "$ENABLE_SECURITY_SCAN" == "true" ]]; then
    echo "| Security Scan | $SECURITY_RESULT | ✅ | - |" >> "$GITHUB_STEP_SUMMARY"
  fi

  if [[ "$ENABLE_BUNDLE" == "true" ]]; then
    echo "| Bundle | $BUNDLE_RESULT | ✅ | - |" >> "$GITHUB_STEP_SUMMARY"
  fi

  # Add artifact information
  cat >> "$GITHUB_STEP_SUMMARY" << EOF

## 📦 Generated Artifacts

EOF

  if [[ "$ENABLE_COMPILE" == "true" && "$COMPILE_RESULT" == "success" ]]; then
    echo "- **Build Output**: Compiled artifacts available in build-output" >> "$GITHUB_STEP_SUMMARY"
  fi

  if [[ "$ENABLE_UNIT_TESTS" == "true" && "$UNIT_RESULT" == "success" ]]; then
    echo "- **Test Results**: Unit test coverage and reports available in unit-test-results" >> "$GITHUB_STEP_SUMMARY"
  fi

  if [[ "$ENABLE_INTEGRATION_TESTS" == "true" && "$INTEGRATION_RESULT" == "success" ]]; then
    echo "- **Integration Results**: Integration test reports available in integration-test-results" >> "$GITHUB_STEP_SUMMARY"
  fi

  if [[ "$ENABLE_E2E_TESTS" == "true" && "$E2E_RESULT" == "success" ]]; then
    echo "- **E2E Results**: End-to-end test reports and screenshots available in e2e-test-results" >> "$GITHUB_STEP_SUMMARY"
  fi

  if [[ "$ENABLE_SECURITY_SCAN" == "true" && "$SECURITY_RESULT" == "success" ]]; then
    echo "- **Security Reports**: Gitleaks and Trufflehog reports available in security-reports" >> "$GITHUB_STEP_SUMMARY"
  fi

  if [[ "$ENABLE_BUNDLE" == "true" && "$BUNDLE_RESULT" == "success" ]]; then
    echo "- **Bundle Output**: Packaged artifacts available in bundle-output" >> "$GITHUB_STEP_SUMMARY"
  fi

  # Generate pipeline metrics
  local metrics
  metrics=$(generate_pipeline_metrics "$pipeline_duration" "$overall_status")
  log_info "$metrics"

  # Auto-set state tags based on results
  local commit_sha="${GITHUB_SHA:-unknown}"
  if [[ "$overall_status" == "SUCCESS" ]]; then
    auto_set_state_tags "$commit_sha" "testing"
  else
    auto_set_state_tags "$commit_sha" "unstable"
  fi

  log_success "Pre-Release summary completed successfully"
}

# Execute main function
main "$@"
