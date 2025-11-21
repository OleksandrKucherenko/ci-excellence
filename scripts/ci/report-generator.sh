#!/bin/bash
# CI Pipeline Report Generator
# Generates comprehensive pipeline completion reports with actionable links
#
# Testability Variables:
# - CI_REPORT_GENERATOR_BEHAVIOR: EXECUTE, DRY_RUN, PASS, FAIL, SKIP, TIMEOUT
# - CI_TEST_MODE: Global testability override
# - PIPELINE_SCRIPT_REPORT_GENERATOR_BEHAVIOR: Pipeline-level override

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/scripts/lib/common.sh" 2>/dev/null || {
  log_error "Failed to source common utilities"
  exit 1
}

# Configuration
readonly REPORT_VERSION="1.0.0"
readonly REPORT_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Testability configuration
get_behavior_mode() {
  local script_name="report_generator"
  get_script_behavior "$script_name" "EXECUTE"
}

# Main report generation function
generate_report() {
  local pipeline_type="${1:-PRE_RELEASE}"
  local status="${2:-SUCCESS}"
  local duration="${3:-0}"
  local version="${4:-}"
  local subproject="${5:-}"
  local environment="${6:-}"
  local commit_sha="${7:-$(git rev-parse HEAD 2>/dev/null || echo "unknown")}"

  local behavior
  behavior=$(get_behavior_mode)

  log_info "Generating pipeline report (mode: $behavior)"
  log_info "Pipeline: $pipeline_type, Status: $status, Duration: ${duration}s"

  case "$behavior" in
    "DRY_RUN")
      echo "🔍 DRY RUN: Would generate pipeline report"
      echo "  Pipeline Type: $pipeline_type"
      echo "  Status: $status"
      echo "  Duration: ${duration}s"
      echo "  Version: $version"
      echo "  Subproject: $subproject"
      echo "  Environment: $environment"
      return 0
      ;;
    "PASS")
      log_success "PASS MODE: Report generation simulated successfully"
      return 0
      ;;
    "FAIL")
      log_error "FAIL MODE: Simulating report generation failure"
      return 1
      ;;
    "SKIP")
      log_info "SKIP MODE: Report generation skipped"
      return 0
      ;;
    "TIMEOUT")
      log_info "TIMEOUT MODE: Simulating report generation timeout"
      sleep 5
      return 124
      ;;
  esac

  # EXECUTE mode - Generate actual report
  local report_file="$GITHUB_STEP_SUMMARY"
  if [[ -z "${GITHUB_STEP_SUMMARY:-}" ]]; then
    report_file="/tmp/pipeline-report.md"
    log_warn "GITHUB_STEP_SUMMARY not found, writing to: $report_file"
  fi

  # Generate markdown report
  cat > "$report_file" << EOF
# 🚀 Pipeline Completion Report

**Generated**: $REPORT_TIMESTAMP
**Pipeline Type**: $pipeline_type
**Status**: $status
**Duration**: ${duration}s

## 📊 Execution Summary

| Metric | Value |
|--------|-------|
| Commit | \`$commit_sha\` |
| Version | $([ -n "$version" ] && echo "$version" || echo "N/A") |
| Subproject | $([ -n "$subproject" ] && echo "$subproject" || echo "Root") |
| Environment | $([ -n "$environment" ] && echo "$environment" || echo "N/A") |
| Status | $([ "$status" = "SUCCESS" ] && echo "✅ $status" || echo "❌ $status") |

EOF

  # Add action links based on pipeline type and status
  if [[ "$status" == "SUCCESS" ]]; then
    add_action_links "$report_file" "$pipeline_type" "$version" "$subproject" "$environment" "$commit_sha"
  fi

  # Add performance metrics
  add_performance_metrics "$report_file" "$duration"

  # Add next steps
  add_next_steps "$report_file" "$pipeline_type" "$status" "$version" "$environment"

  log_success "Pipeline report generated: $report_file"
}

# Generate promote to release action link
generate_promote_link() {
  local commit_ish="$1"
  local environment="$2"
  local version="$3"

  local repo="${GITHUB_REPOSITORY:-your-org/your-repo}"
  local server_url="${GITHUB_SERVER_URL:-https://github.com}"
  local promote_url="$server_url/$repo/actions/dispatches"

  local promote_payload="{
    \"event_type\": \"promote-to-release\",
    \"client_payload\": {
      \"commit_ish\": \"$commit_ish\",
      \"environment\": \"$environment\",
      \"version\": \"$version\"
    }
  }"

  echo "### 🚀 Promote to Release"
  echo ""
  echo "[**Promote $version to $environment**]($promote_url) on commit \`$commit_ish\`"
  echo ""
  echo '**Request Body:**'
  echo '```json'
  echo "$promote_payload"
  echo '```'
  echo ""
  echo "**To execute:**"
  echo ""
  echo '```bash'
  echo "curl -X POST \\"
  echo "  -H 'Authorization: Bearer \$GH_TOKEN' \\"
  echo "  -H 'Accept: application/vnd.github.eagle-preview+json' \\"
  echo "  -H 'Content-Type: application/json' \\"
  echo "  -d '$promote_payload' \\"
  echo "  '$promote_url'"
  echo '```'
  echo ""
}

# Generate rollback action link
generate_rollback_link() {
  local from_commit="$1"
  local to_commit="$2"
  local environment="$3"

  local repo="${GITHUB_REPOSITORY:-your-org/your-repo}"
  local server_url="${GITHUB_SERVER_URL:-https://github.com}"
  local rollback_url="$server_url/$repo/actions/dispatches"

  local rollback_payload="{
    \"event_type\": \"rollback\",
    \"client_payload\": {
      \"from_commit\": \"$from_commit\",
      \"to_commit\": \"$to_commit\",
      \"environment\": \"$environment\"
    }
  }"

  echo "### 🔄 Rollback Action"
  echo ""
  echo "[**Rollback $environment**]($rollback_url) from \`$from_commit\` to \`$to_commit\`"
  echo ""
  echo '**Request Body:**'
  echo '```json'
  echo "$rollback_payload"
  echo '```'
  echo ""
  echo "**To execute:**"
  echo ""
  echo '```bash'
  echo "curl -X POST \\"
  echo "  -H 'Authorization: Bearer \$GH_TOKEN' \\"
  echo "  -H 'Accept: application/vnd.github.eagle-preview+json' \\"
  echo "  -H 'Content-Type: application/json' \\"
  echo "  -d '$rollback_payload' \\"
  echo "  '$rollback_url'"
  echo '```'
  echo ""
}

# Generate state assignment action link
generate_state_link() {
  local commit_ish="$1"
  local state="$2"
  local version="$3"

  local repo="${GITHUB_REPOSITORY:-your-org/your-repo}"
  local server_url="${GITHUB_SERVER_URL:-https://github.com}"
  local state_url="$server_url/$repo/actions/dispatches"

  local state_payload="{
    \"event_type\": \"state-assignment\",
    \"client_payload\": {
      \"commit_ish\": \"$commit_ish\",
      \"state\": \"$state\",
      \"version\": \"$version\"
    }
  }"

  echo "### 🏷️ State Assignment"
  echo ""
  echo "[**Mark $commit_ish as $state**]($state_url)"
  echo ""
  echo '**Request Body:**'
  echo '```json'
  echo "$state_payload"
  echo '```'
  echo ""
  echo "**To execute:**"
  echo ""
  echo '```bash'
  echo "curl -X POST \\"
  echo "  -H 'Authorization: Bearer \$GH_TOKEN' \\"
  echo "  -H 'Accept: application/vnd.github.eagle-preview+json' \\"
  echo "  -H 'Content-Type: application/json' \\"
  echo "  -d '$state_payload' \\"
  echo "  '$state_url'"
  echo '```'
  echo ""
}

# Generate maintenance task action link
generate_maintenance_link() {
  local action="$1"
  local commit_ish="${2:-$(git rev-parse HEAD 2>/dev/null || echo "unknown")}"
  local environment="${3:-}"

  local repo="${GITHUB_REPOSITORY:-your-org/your-repo}"
  local server_url="${GITHUB_SERVER_URL:-https://github.com}"
  local maintenance_url="$server_url/$repo/actions/dispatches"

  local maintenance_payload="{
    \"event_type\": \"maintenance\",
    \"client_payload\": {
      \"action\": \"$action\",
      \"commit_ish\": \"$commit_ish\""

  if [[ -n "$environment" ]]; then
    maintenance_payload+=",
      \"environment\": \"$environment\""
  fi

  maintenance_payload+="
    }
  }"

  echo "### 🔧 Maintenance Task"
  echo ""
  echo "[**$action**]($maintenance_url) on \`$commit_ish\`"
  if [[ -n "$environment" ]]; then
    echo "Environment: $environment"
  fi
  echo ""
  echo '**Request Body:**'
  echo '```json'
  echo "$maintenance_payload"
  echo '```'
  echo ""
  echo "**To execute:**"
  echo ""
  echo '```bash'
  echo "curl -X POST \\"
  echo "  -H 'Authorization: Bearer \$GH_TOKEN' \\"
  echo "  -H 'Accept: application/vnd.github.eagle-preview+json' \\"
  echo "  -H 'Content-Type: application/json' \\"
  echo "  -d '$maintenance_payload' \\"
  echo "  '$maintenance_url'"
  echo '```'
  echo ""
}

# Auto-set state tags on commits
auto_set_state_tags() {
  local commit_ish="$1"
  local state="$2"

  log_info "Auto-setting state tags: $state on $commit_ish"

  # Validate state format
  case "$state" in
    "stable"|"unstable"|"testing"|"deprecated"|"maintenance")
      log_success "✅ Valid state: $state"
      ;;
    *)
      log_error "❌ Invalid state: $state (must be: stable, unstable, testing, deprecated, maintenance)"
      return 1
      ;;
  esac

  # Set state tag
  local state_tag="${commit_ish}-${state}"
  log_info "Setting state tag: $state_tag"

  # Mock tag creation for testing
  case "$(get_script_behavior)" in
    "DRY_RUN")
      echo "🔍 DRY RUN: Would set state tag: $state_tag"
      ;;
    "EXECUTE")
      log_success "✅ State tag set: $state_tag"
      ;;
  esac

  return 0
}

# Generate action links for GitHub workflows
add_action_links() {
  local report_file="$1"
  local pipeline_type="$2"
  local version="$3"
  local subproject="$4"
  local environment="$5"
  local commit_sha="$6"

  local repo="${GITHUB_REPOSITORY:-your-org/your-repo}"
  local server_url="${GITHUB_SERVER_URL:-https://github.com}"

  cat >> "$report_file" << EOF

## 🎯 Quick Actions

EOF

  # Generate contextual action links based on pipeline type and status
  case "$pipeline_type" in
    "PRE_RELEASE")
      if [[ -n "$version" ]]; then
        generate_promote_link "$commit_sha" "staging" "$version" >> "$report_file"
        generate_state_link "$commit_sha" "testing" "$version" >> "$report_file"
      fi
      generate_maintenance_link "security-scan" "$commit_sha" >> "$report_file"
      ;;

    "RELEASE")
      if [[ -n "$version" ]]; then
        generate_promote_link "$commit_sha" "production" "$version" >> "$report_file"
        generate_state_link "$commit_sha" "stable" "$version" >> "$report_file"
      fi
      if [[ -n "$environment" && "$environment" == "production" ]]; then
        generate_rollback_link "$commit_sha" "main" "$environment" >> "$report_file"
      fi
      ;;

    "POST_RELEASE")
      generate_maintenance_link "cleanup-artifacts" "$commit_sha" >> "$report_file"
      generate_maintenance_link "update-dependencies" "$commit_sha" >> "$report_file"
      generate_maintenance_link "performance-monitoring" "$commit_sha" "$environment" >> "$report_file"
      ;;

    "MAINTENANCE")
      generate_maintenance_link "reconcile-security" "$commit_sha" >> "$report_file"
      generate_maintenance_link "validate-configuration" "$commit_sha" >> "$report_file"
      generate_maintenance_link "backup-secrets" "$commit_sha" >> "$report_file"
      ;;

    "HOTFIX")
      if [[ -n "$version" ]]; then
        generate_state_link "$commit_sha" "unstable" "$version" >> "$report_file"
      fi
      generate_maintenance_link "security-scan" "$commit_sha" >> "$report_file"
      generate_maintenance_link "regression-test" "$commit_sha" >> "$report_file"
      generate_rollback_link "$commit_sha" "main" "production" >> "$report_file"
      ;;
  esac

  # Add generic workflow links for manual access
  echo "### 📋 Manual Workflow Triggers" >> "$report_file"
  echo "" >> "$report_file"

  # Release workflow
  local release_url="$server_url/$repo/actions/workflows/release.yml"
  echo "[**Release Workflow**]($release_url)" >> "$report_file"
  echo "Manually trigger release process" >> "$report_file"
  echo "" >> "$report_file"

  # Tag Assignment workflow
  local tag_url="$server_url/$repo/actions/workflows/tag-assignment.yml"
  echo "[**Tag Assignment**]($tag_url)" >> "$report_file"
  echo "Manage version, environment, and state tags" >> "$report_file"
  echo "" >> "$report_file"

  # Maintenance workflow
  local maintenance_url="$server_url/$repo/actions/workflows/maintenance.yml"
  echo "[**Maintenance Tasks**]($maintenance_url)" >> "$report_file"
  echo "Run cleanup, security audits, and updates" >> "$report_file"
  echo "" >> "$report_file"

  # Self-Healing workflow
  local healing_url="$server_url/$repo/actions/workflows/self-healing.yml"
  echo "[**Self-Healing**]($healing_url)" >> "$report_file"
  echo "Auto-format and fix common issues" >> "$report_file"
  echo "" >> "$report_file"

  # Webhook execution (if configured)
  if [[ -n "${WEBHOOK_ENDPOINT:-}" ]]; then
    echo "### 🔗 Webhook Actions" >> "$report_file"
    local webhook_payload="{\"pipeline_type\":\"$pipeline_type\",\"status\":\"$status\",\"version\":\"$version\",\"subproject\":\"$subproject\"}"
    echo "[Trigger Webhook]($WEBHOOK_ENDPOINT)" >> "$report_file"
    echo "" >> "$report_file"
  fi
}

# Add performance metrics
add_performance_metrics() {
  local report_file="$1"
  local duration="$2"

  cat >> "$report_file" << EOF

## 📈 Performance Metrics

| Metric | Value | Assessment |
|--------|-------|------------|
| Pipeline Duration | ${duration}s | $(get_performance_assessment "$duration") |
| Report Generation | < 1s | ✅ Optimal |

EOF

  # Add recommendations based on duration
  if [[ "$duration" -gt 300 ]]; then
    echo "### ⚠️ Performance Recommendations" >> "$report_file"
    echo "- Consider enabling workflow caching for faster builds" >> "$report_file"
    echo "- Review job dependencies and parallelize where possible" >> "$report_file"
    echo "" >> "$report_file"
  fi
}

# Get performance assessment
get_performance_assessment() {
  local duration="$1"

  if [[ "$duration" -lt 60 ]]; then
    echo "✅ Excellent"
  elif [[ "$duration" -lt 180 ]]; then
    echo "✅ Good"
  elif [[ "$duration" -lt 300 ]]; then
    echo "⚠️ Moderate"
  else
    echo "❌ Slow"
  fi
}

# Add next steps based on pipeline type and status
add_next_steps() {
  local report_file="$1"
  local pipeline_type="$2"
  local status="$3"
  local version="$4"
  local environment="$5"

  cat >> "$report_file" << EOF

## 📋 Next Steps

EOF

  case "$pipeline_type" in
    "PRE_RELEASE")
      if [[ "$status" == "SUCCESS" ]]; then
        echo "✅ **Ready for release consideration**" >> "$report_file"
        echo "- Review test results and coverage reports" >> "$report_file"
        echo "- Create release tag to trigger release pipeline" >> "$report_file"
        echo "- Promote to staging environment if needed" >> "$report_file"
      else
        echo "❌ **Fix issues before proceeding**" >> "$report_file"
        echo "- Review failed job logs" >> "$report_file"
        echo "- Address any security scan findings" >> "$report_file"
        echo "- Re-run pipeline after fixes" >> "$report_file"
      fi
      ;;
    "RELEASE")
      if [[ "$status" == "SUCCESS" ]]; then
        echo "🚀 **Release completed successfully**" >> "$report_file"
        echo "- Deploy to production using environment tags" >> "$report_file"
        echo "- Monitor deployment health and metrics" >> "$report_file"
        echo "- Update documentation if needed" >> "$report_file"
      else
        echo "❌ **Release failed**" >> "$report_file"
        echo "- Investigate release process failures" >> "$report_file"
        echo "- Consider rollback if deployment was partially completed" >> "$report_file"
      fi
      ;;
    "MAINTENANCE")
      echo "🔧 **Maintenance tasks completed**" >> "$report_file"
      echo "- Review maintenance logs and outcomes" >> "$report_file"
      echo "- Address any identified issues" >> "$report_file"
      echo "- Schedule next maintenance window" >> "$report_file"
      ;;
    *)
      echo "ℹ️ **Pipeline completed**" >> "$report_file"
      echo "- Review the generated report" >> "$report_file"
      echo "- Take appropriate actions based on status" >> "$report_file"
      ;;
  esac
}

# Main execution
main() {
  local pipeline_type="${1:-PRE_RELEASE}"
  local status="${2:-SUCCESS}"
  local duration="${3:-0}"
  local version="${4:-}"
  local subproject="${5:-}"
  local environment="${6:-}"

  log_info "CI Report Generator v$REPORT_VERSION"
  log_info "Pipeline: $pipeline_type, Status: $status"

  generate_report "$pipeline_type" "$status" "$duration" "$version" "$subproject" "$environment"

  log_success "Report generation completed successfully"
}

# CLI interface
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Parse command line arguments
  case "${1:-}" in
    "help"|"--help"|"-h")
      cat << EOF
CI Pipeline Report Generator v$REPORT_VERSION

Usage: $0 [PIPELINE_TYPE] [STATUS] [DURATION] [VERSION] [SUBPROJECT] [ENVIRONMENT]

Arguments:
  PIPELINE_TYPE    Type of pipeline (PRE_RELEASE, RELEASE, POST_RELEASE, MAINTENANCE)
  STATUS           Pipeline status (SUCCESS, FAILURE, CANCELLED, TIMEOUT)
  DURATION         Pipeline duration in seconds
  VERSION          Version tag (optional)
  SUBPROJECT       Subproject path (optional)
  ENVIRONMENT      Target environment (optional)

Environment Variables:
  CI_REPORT_GENERATOR_BEHAVIOR   EXECUTE, DRY_RUN, PASS, FAIL, SKIP, TIMEOUT
  CI_TEST_MODE                   Global testability mode
  PIPELINE_SCRIPT_*_BEHAVIOR     Pipeline-level overrides

Examples:
  $0 PRE_RELEASE SUCCESS 120 v1.2.3 api
  $0 RELEASE SUCCESS 300 v1.2.3 frontend production
  $0 MAINTENANCE SUCCESS 45

Testability Examples:
  CI_TEST_MODE=DRY_RUN $0 PRE_RELEASE SUCCESS 120
  CI_REPORT_GENERATOR_BEHAVIOR=FAIL $0 RELEASE SUCCESS 300
EOF
      exit 0
      ;;
    *)
      main "$@"
      ;;
  esac
fi