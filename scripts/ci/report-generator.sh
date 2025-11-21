#!/usr/bin/env bash
# GitHub Actions Report Generator
# Generates actionable pipeline reports with links to trigger other workflows

set -euo pipefail

# Source utilities if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/../lib/common.sh" ]]; then
  # shellcheck source=../lib/common.sh
  source "${SCRIPT_DIR}/../lib/common.sh"
fi

if [[ -f "${SCRIPT_DIR}/../lib/tag-utils.sh" ]]; then
  # shellcheck source=../lib/tag-utils.sh
  source "${SCRIPT_DIR}/../lib/tag-utils.sh"
fi

# Configuration
REPORT_OUTPUT="${GITHUB_STEP_SUMMARY:-/tmp/pipeline-report.md}"
REPO_NAME="${GITHUB_REPOSITORY:-owner/repo}"
WORKFLOW_NAME="${GITHUB_WORKFLOW:-Unknown Workflow}"
RUN_ID="${GITHUB_RUN_ID:-unknown}"
STATUS="${1:-success}"
VERSION="${2:-}"
ENVIRONMENT="${3:-}"

# GitHub URL generation
generate_workflow_url() {
  local workflow="$1"
  local inputs="${2:-}"

  local base_url="https://github.com/${REPO_NAME}/actions/workflows/${workflow}.yml"

  if [[ -n "$inputs" ]]; then
    echo "${base_url}?inputs=${inputs}"
  else
    echo "${base_url}"
  fi
}

# Generate workflow dispatch URL with parameters
generate_dispatch_url() {
  local workflow="$1"
  shift
  local params=("$@")

  local base_url="https://github.com/${REPO_NAME}/actions/workflows/${workflow}.yml"

  if [[ ${#params[@]} -eq 0 ]]; then
    echo "${base_url}"
    return
  fi

  local encoded_params=""
  local param_count=0

  for param in "${params[@]}"; do
    if [[ $((param_count % 2)) -eq 0 ]]; then
      # Parameter name
      if [[ $param_count -gt 0 ]]; then
        encoded_params+=","
      fi
      encoded_params+="${param}:"
    else
      # Parameter value (URL encode)
      local encoded_value
      encoded_value=$(printf '%s' "$param" | jq -sRr @uri 2>/dev/null || echo "$param")
      encoded_params+="${encoded_value}"
    fi
    ((param_count++))
  done

  echo "${base_url}?inputs=${encoded_params}"
}

# Create action link object
create_action_link() {
  local label="$1"
  local url="$2"
  local description="${3:-}"
  local icon="${4:-link}"
  local category="${5:-general}"

  cat <<EOF
- **${label}** [${icon}](${url})
EOF

  if [[ -n "$description" ]]; then
    echo "  - ${description}"
  fi
}

# Generate version-based action links
generate_version_links() {
  local version="$1"
  local subproject_path="${2:-}"

  if [[ -z "$version" ]]; then
    return
  fi

  echo ""
  echo "### Version Actions"
  echo ""

  # Promote to Release
  if echo "$WORKFLOW_NAME" | grep -qi "pre-release"; then
    create_action_link "Promote to Release" \
      "$(generate_dispatch_url "release.yml" "version" "${version}" "skip_npm" "false" "skip_docker" "false")" \
      "Create release for version ${version}" \
      "🚀" \
      "release"
  fi

  # Deploy links
  if echo "$WORKFLOW_NAME" | grep -qi "release"; then
    # Deploy to Staging
    create_action_link "Deploy to Staging" \
      "$(generate_dispatch_url "tag-assignment.yml" "tag_type" "environment" "environment" "staging" "version" "$version" "sub_project" "$subproject_path")" \
      "Deploy ${version} to staging" \
      "🚀" \
      "deployment"

    # Deploy to Production
    create_action_link "Deploy to Production" \
      "$(generate_dispatch_url "tag-assignment.yml" "tag_type" "environment" "environment" "production" "version" "$version" "sub_project" "$subproject_path")" \
      "Deploy ${version} to production" \
      "🚀" \
      "deployment"
  fi

  # Tag as Stable
  create_action_link "Mark as Stable" \
    "$(generate_dispatch_url "tag-assignment.yml" "tag_type" "state" "version" "$version" "state" "stable" "sub_project" "$subproject_path")" \
    "Mark ${version} as stable" \
      "✅" \
      "state"

  # Tag as Unstable
  create_action_link "Mark as Unstable" \
    "$(generate_dispatch_url "tag-assignment.yml" "tag_type" "state" "version" "$version" "state" "unstable" "sub_project" "$subproject_path")" \
    "Mark ${version} as unstable" \
      "⚠️" \
      "state"
}

# Generate environment-based action links
generate_environment_links() {
  local environment="$1"
  local subproject_path="${2:-}"

  if [[ -z "$environment" ]]; then
    return
  fi

  echo ""
  echo "### Environment Actions"
  echo ""

  # Rollback
  create_action_link "Rollback ${environment^}" \
    "$(generate_dispatch_url "rollback.yml" "environment" "$environment" "sub_project" "$subproject_path" "target_version" "auto")" \
    "Rollback ${environment} to previous version" \
      "↩️" \
      "rollback"

  # Deploy to other environments
  if [[ "$environment" != "staging" ]]; then
    create_action_link "Deploy to Staging" \
      "$(generate_dispatch_url "tag-assignment.yml" "tag_type" "environment" "environment" "staging" "sub_project" "$subproject_path")" \
      "Deploy current version to staging" \
      "🚀" \
      "deployment"
  fi

  if [[ "$environment" != "production" ]]; then
    create_action_link "Deploy to Production" \
      "$(generate_dispatch_url "tag-assignment.yml" "tag_type" "environment" "environment" "production" "sub_project" "$subproject_path")" \
      "Deploy current version to production" \
      "🚀" \
      "deployment"
  fi

  # Verify deployment
  create_action_link "Verify Deployment" \
    "$(generate_dispatch_url "post-release.yml" "environment" "$environment" "sub_project" "$subproject_path")" \
    "Run post-release verification" \
      "✅" \
      "verification"
}

# Generate maintenance links
generate_maintenance_links() {
  echo ""
  echo "### Maintenance Tasks"
  echo ""

  local maintenance_tasks=(
    "cleanup:Cleanup old artifacts and deprecated tags"
    "sync-files:Synchronize shared files across sub-projects"
    "deprecate-old-versions:Auto-mark old versions as deprecated"
    "security-audit:Run comprehensive security audit"
    "dependency-update:Check for and propose dependency updates"
    "all:Run all maintenance tasks"
  )

  for task_info in "${maintenance_tasks[@]}"; do
    local task="${task_info%:*}"
    local description="${task_info#*:}"

    create_action_link "${description^}" \
      "$(generate_dispatch_url "maintenance.yml" "task_mode" "$task" "dry_run" "false")" \
      "Execute ${task} maintenance" \
      "🔧" \
      "maintenance"
  done
}

# Generate self-healing links
generate_self_healing_links() {
  echo ""
  echo "### Self-Healing Actions"
  echo ""

  # Auto-format
  create_action_link "Auto-Format Code" \
    "$(generate_dispatch_url "self-healing.yml" "scope" "format")" \
    "Automatically format bash scripts" \
      "🎨" \
      "healing"

  # Auto-lint
  create_action_link "Auto-Lint Fixes" \
    "$(generate_dispatch_url "self-healing.yml" "scope" "lint")" \
      "Apply automatic linting fixes" \
      "🔧" \
      "healing"

  # Full self-healing
  create_action_link "Complete Self-Healing" \
    "$(generate_dispatch_url "self-healing.yml" "scope" "all")" \
      "Run format and lint fixes" \
      "✨" \
      "healing"
}

# Generate debugging links
generate_debugging_links() {
  echo ""
  echo "### Debugging & Diagnostics"
  echo ""

  # View workflow run
  create_action_link "View Workflow Run" \
    "https://github.com/${REPO_NAME}/actions/runs/${RUN_ID}" \
      "View detailed workflow execution logs" \
      "👁️" \
      "debug"

  # Download artifacts
  create_action_link "Download Artifacts" \
    "https://github.com/${REPO_NAME}/actions/runs/${RUN_ID}#artifacts" \
      "Download workflow artifacts and logs" \
      "📦" \
      "debug"

  # Re-run workflow
  create_action_link "Re-run Workflow" \
    "https://github.com/${REPO_NAME}/actions/runs/${RUN_ID}?rerun=1" \
      "Re-run the failed workflow" \
      "🔄" \
      "debug"

  # View branch
  if [[ -n "${GITHUB_REF_NAME:-}" ]]; then
    create_action_link "View Branch" \
      "https://github.com/${REPO_NAME}/tree/${GITHUB_REF_NAME}" \
      "View the source branch" \
      "🌳" \
      "debug"
  fi
}

# Detect current version and environment
detect_context() {
  local detected_version=""
  local detected_environment=""
  local detected_subproject=""

  # Try to detect from git tags
  if command -v git >/dev/null 2>&1 && [[ -d ".git" ]]; then
    local current_commit="${GITHUB_SHA:-HEAD}"

    # Check for version tags on current commit
    local version_tags
    version_tags=$(git tag --points-at "$current_commit" 2>/dev/null | grep -E "v[0-9]+\.[0-9]+\.[0-9]+" || true)

    if [[ -n "$version_tags" ]]; then
      detected_version=$(echo "$version_tags" | head -n1 | sed 's|.*/||')
      detected_subproject=$(echo "$version_tags" | head -n1 | sed 's|/v.*$||')
      if [[ "$detected_subproject" == "$detected_version" ]]; then
        detected_subproject=""
      fi
    fi

    # Check for environment tags on current commit
    local env_tags
    env_tags=$(git tag --points-at "$current_commit" 2>/dev/null | grep -E "(production|staging|canary|sandbox|performance)$" || true)

    if [[ -n "$env_tags" ]]; then
      detected_environment=$(echo "$env_tags" | head -n1 | sed 's|.*/||')
    fi
  fi

  # Use provided values if available, otherwise use detected values
  VERSION="${VERSION:-$detected_version}"
  ENVIRONMENT="${ENVIRONMENT:-$detected_environment}"

  # Return detected subproject path
  if [[ -z "$detected_subproject" ]]; then
    echo ""
  else
    echo "$detected_subproject"
  fi
}

# Generate the complete report
generate_report() {
  local subproject_path
  subproject_path=$(detect_context)

  # Start report
  cat > "$REPORT_OUTPUT" <<EOF
# Pipeline Report - ${WORKFLOW_NAME}

## Status: ${STATUS^}

EOF

  # Add version information if available
  if [[ -n "$VERSION" ]]; then
    echo "## Version Information" >> "$REPORT_OUTPUT"
    echo "" >> "$REPORT_OUTPUT"
    echo "**Version:** \`${VERSION}\`" >> "$REPORT_OUTPUT"
    if [[ -n "$subproject_path" ]]; then
      echo "**Sub-project:** \`${subproject_path}\`" >> "$REPORT_OUTPUT"
    fi
    echo "" >> "$REPORT_OUTPUT"

    # Add version details
    if command -v git >/dev/null 2>&1; then
      local version_tag="${subproject_path:+${subproject_path}/}${VERSION}"
      if git rev-parse "$version_tag" >/dev/null 2>&1; then
        local commit_sha
        commit_sha=$(git rev-parse "$version_tag")
        local commit_date
        commit_date=$(git log -1 --format="%ci" "$version_tag" 2>/dev/null || echo "Unknown")
        local commit_message
        commit_message=$(git log -1 --format="%s" "$version_tag" 2>/dev/null || echo "Unknown")

        echo "**Commit:** [\`${commit_sha:0:8}\`](https://github.com/${REPO_NAME}/commit/${commit_sha})" >> "$REPORT_OUTPUT"
        echo "**Date:** ${commit_date}" >> "$REPORT_OUTPUT"
        echo "**Message:** ${commit_message}" >> "$REPORT_OUTPUT"
      fi
    fi
    echo "" >> "$REPORT_OUTPUT"
  fi

  # Add environment information if available
  if [[ -n "$ENVIRONMENT" ]]; then
    echo "## Environment Information" >> "$REPORT_OUTPUT"
    echo "" >> "$REPORT_OUTPUT"
    echo "**Environment:** \`${ENVIRONMENT}\`" >> "$REPORT_OUTPUT"
    if [[ -n "$VERSION" ]]; then
      echo "**Deployed Version:** \`${VERSION}\`" >> "$REPORT_OUTPUT"
    fi
    echo "" >> "$REPORT_OUTPUT"
  fi

  # Add main action sections
  if [[ "$STATUS" == "success" ]]; then
    generate_version_links "$VERSION" "$subproject_path"
    generate_environment_links "$ENVIRONMENT" "$subproject_path"
  fi

  generate_maintenance_links
  generate_self_healing_links
  generate_debugging_links

  # Add footer
  cat >> "$REPORT_OUTPUT" <<EOF

---
*Report generated at $(date '+%Y-%m-%d %H:%M:%S UTC')*
*Workflow: [${WORKFLOW_NAME}](https://github.com/${REPO_NAME}/actions/runs/${RUN_ID})*
EOF

  log_success "Pipeline report generated: $REPORT_OUTPUT"
}

# Main execution
main() {
  log_info "Starting pipeline report generation"

  # Ensure output directory exists
  local output_dir
  output_dir=$(dirname "$REPORT_OUTPUT")
  if [[ "$output_dir" != "." && "$output_dir" != "/tmp" ]]; then
    mkdir -p "$output_dir"
  fi

  # Generate the report
  generate_report

  log_success "Pipeline report completed"
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi