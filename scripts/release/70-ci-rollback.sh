#!/usr/bin/env bash
# CI Rollback Script
# Rolls back deployments with full safety checks and validation

set -euo pipefail

# Source shared utilities
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Source tag utilities for rollback tag management
# shellcheck source=../lib/tag-utils.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/tag-utils.sh"

# Script configuration
readonly SCRIPT_NAME="$(basename "$0" .sh)"
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_DESCRIPTION="Roll back deployments with safety checks"

# Default rollback configuration
DEFAULT_ROLLBACK_TYPE="deployment"
DEFAULT_DRY_RUN=true
DEFAULT_CONFIRM_REQUIRED=true

# Usage information
usage() {
  cat <<EOF
Usage: $SCRIPT_NAME [OPTIONS] [TAG]

Roll back deployments with full safety checks and validation.

OPTIONS:
  -e, --environment ENV     Target environment (staging|production|dev)
  -t, --tag TAG            Specific rollback tag to use
  -l, --latest             Roll back to latest stable version
  -t, --type TYPE          Rollback type (deployment|config|all) [default: $DEFAULT_ROLLBACK_TYPE]
  -d, --dry-run            Preview rollback actions without executing (default)
  --no-dry-run             Actually execute rollback
  -f, --force              Force rollback even if checks fail
  --no-confirm             Skip confirmation prompt
  --timeout SECONDS        Rollback timeout [default: 300]
  -t, --test-mode MODE     Test mode (DRY_RUN|SIMULATE|EXECUTE)
  -h, --help               Show this help message
  -V, --version            Show version information

ARGUMENTS:
  TAG                      Specific tag to rollback to (overrides --tag option)

EXAMPLES:
  $SCRIPT_NAME                                    # Preview rollback to latest stable
  $SCRIPT_NAME --environment production --no-dry-run  # Rollback production to latest stable
  $SCRIPT_NAME --tag v1.2.3 --force             # Force rollback to specific version
  $SCRIPT_NAME --type config --no-confirm        # Rollback configuration without prompt

ROLLBACK TYPES:
  deployment    Roll back application deployment
  config        Roll back configuration changes
  all           Roll back both deployment and config

ENVIRONMENT VARIABLES:
  CI_TEST_MODE               Test mode override (DRY_RUN|SIMULATE|EXECUTE)
  CI_ROLLBACK_TYPE           Rollback type override
  CI_DRY_RUN                Enable/disable dry run (true|false)
  CI_FORCE_ROLLBACK          Force rollback (true|false)
  CI_ROLLBACK_CONFIRM        Require confirmation (true|false)
  ROLLBACK_TIMEOUT           Rollback timeout in seconds
  KUBE_CONFIG               Kubernetes configuration file

EXIT CODES:
  0     Success
  1     General error
  2     Rollback failed
  3     Validation failed
  4     Invalid arguments
  5     Prerequisites not met
  6     Confirmation declined
  7     Rollback tag not found

EOF
}

# Show version information
version() {
  echo "$SCRIPT_NAME version $SCRIPT_VERSION"
  echo "$SCRIPT_DESCRIPTION"
}

# Parse command line arguments
parse_args() {
  # Default options
  local opt_environment=""
  local opt_rollback_tag=""
  local opt_use_latest=false
  local opt_rollback_type="$DEFAULT_ROLLBACK_TYPE"
  local opt_dry_run="$DEFAULT_DRY_RUN"
  local opt_force_rollback=false
  local opt_confirm_required="$DEFAULT_CONFIRM_REQUIRED"
  local opt_timeout="300"
  local opt_test_mode=""

  # Parse options
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -e|--environment)
        shift
        if [[ -z "$1" ]]; then
          log_error "Environment cannot be empty"
          return 4
        fi
        case "$1" in
          staging|production|dev) ;;
          *)
            log_error "Invalid environment: $1. Use staging, production, or dev"
            return 4
            ;;
        esac
        opt_environment="$1"
        shift
        ;;
      -t|--tag)
        shift
        if [[ -z "$1" ]]; then
          log_error "Rollback tag cannot be empty"
          return 4
        fi
        opt_rollback_tag="$1"
        shift
        ;;
      -l|--latest)
        opt_use_latest=true
        shift
        ;;
      -t|--type)
        shift
        if [[ -z "$1" ]]; then
          log_error "Rollback type cannot be empty"
          return 4
        fi
        case "$1" in
          deployment|config|all) ;;
          *)
            log_error "Invalid rollback type: $1. Use deployment, config, or all"
            return 4
            ;;
        esac
        opt_rollback_type="$1"
        shift
        ;;
      -d|--dry-run)
        opt_dry_run=true
        shift
        ;;
      --no-dry-run)
        opt_dry_run=false
        shift
        ;;
      -f|--force)
        opt_force_rollback=true
        shift
        ;;
      --no-confirm)
        opt_confirm_required=false
        shift
        ;;
      --timeout)
        shift
        if [[ -z "$1" ]]; then
          log_error "Timeout cannot be empty"
          return 4
        fi
        if ! [[ "$1" =~ ^[0-9]+$ ]]; then
          log_error "Timeout must be a positive integer"
          return 4
        fi
        opt_timeout="$1"
        shift
        ;;
      -t|--test-mode)
        shift
        if [[ -z "$1" ]]; then
          log_error "Test mode cannot be empty"
          return 4
        fi
        case "$1" in
          DRY_RUN|SIMULATE|EXECUTE) ;;
          *)
            log_error "Invalid test mode: $1. Use DRY_RUN, SIMULATE, or EXECUTE"
            return 4
            ;;
        esac
        opt_test_mode="$1"
        shift
        ;;
      -h|--help)
        usage
        return 0
        ;;
      -V|--version)
        version
        return 0
        ;;
      -*)
        log_error "Unknown option: $1"
        usage
        return 4
        ;;
      *)
        # Accept tag as argument
        if [[ -z "$opt_rollback_tag" ]]; then
          opt_rollback_tag="$1"
        else
          log_error "Unexpected argument: $1"
          usage
          return 4
        fi
        shift
        ;;
    esac
  done

  # Set global variables
  export ROLLBACK_ENVIRONMENT="$opt_environment"
  export ROLLBACK_TAG="$opt_rollback_tag"
  export USE_LATEST="$opt_use_latest"
  export ROLLBACK_TYPE="$opt_rollback_type"
  export DRY_RUN="$opt_dry_run"
  export FORCE_ROLLBACK="$opt_force_rollback"
  export CONFIRM_REQUIRED="$opt_confirm_required"
  export ROLLBACK_TIMEOUT="$opt_timeout"

  # Resolve test mode
  local resolved_mode
  if ! resolved_mode=$(resolve_test_mode "$SCRIPT_NAME" "rollback" "$opt_test_mode"); then
    return 1
  fi
  export TEST_MODE="$resolved_mode"

  return 0
}

# Check rollback prerequisites
check_prerequisites() {
  log_info "Checking rollback prerequisites"

  local missing_tools=()

  # Check for git
  if ! command -v git >/dev/null 2>&1; then
    missing_tools+=("git")
  fi

  # Check for deployment tools
  if command -v kubectl >/dev/null 2>&1; then
    export ROLLBACK_PLATFORM="kubernetes"
  elif command -v docker >/dev/null 2>&1; then
    export ROLLBACK_PLATFORM="docker"
  else
    missing_tools+=("kubectl or docker for deployment rollback")
  fi

  if [[ ${#missing_tools[@]} -gt 0 ]]; then
    log_error "Missing rollback tools: ${missing_tools[*]}"
    return 5
  fi

  log_success "✅ Rollback prerequisites met"
  return 0
}

# Configure rollback environment
configure_rollback_environment() {
  log_info "Configuring rollback environment"

  # Export rollback environment variables
  export ROLLBACK_ENVIRONMENT="$ROLLBACK_ENVIRONMENT"
  export ROLLBACK_TAG="$ROLLBACK_TAG"
  export USE_LATEST="$USE_LATEST"
  export ROLLBACK_TYPE="$ROLLBACK_TYPE"
  export DRY_RUN="$DRY_RUN"
  export FORCE_ROLLBACK="$FORCE_ROLLBACK"
  export TEST_MODE="$TEST_MODE"

  # Set rollback metadata
  export ROLLBACK_ID="rollback-$(date +%Y%m%d-%H%M%S)-$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
  export ROLLBACK_TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  # Configure platform-specific settings
  case "${ROLLBACK_PLATFORM:-}" in
    "kubernetes")
      export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"
      export KUBE_NAMESPACE="${ROLLBACK_ENVIRONMENT}"
      ;;
    "docker")
      export DOCKER_HOST="${DOCKER_HOST:-unix:///var/run/docker.sock}"
      ;;
  esac

  log_info "Rollback environment configured:"
  log_info "  Environment: ${ROLLBACK_ENVIRONMENT:-auto-detect}"
  log_info "  Rollback type: $ROLLBACK_TYPE"
  log_info "  Rollback tag: ${ROLLBACK_TAG:-auto-detect}"
  log_info "  Use latest: $USE_LATEST"
  log_info "  Dry run: $DRY_RUN"
  log_info "  Platform: ${ROLLBACK_PLATFORM:-standard}"

  return 0
}

# Find rollback tag
find_rollback_tag() {
  log_info "Finding rollback tag"

  # If tag is explicitly provided, validate it
  if [[ -n "$ROLLBACK_TAG" ]]; then
    if git rev-parse --verify "$ROLLBACK_TAG" >/dev/null 2>&1; then
      log_info "Using provided rollback tag: $ROLLBACK_TAG"
      return 0
    else
      log_error "Rollback tag not found: $ROLLBACK_TAG"
      return 7
    fi
  fi

  # If using latest, find the latest stable tag
  if [[ "$USE_LATEST" == "true" ]]; then
    local latest_tag
    latest_tag=$(find_latest_tag "stable")
    if [[ -n "$latest_tag" ]]; then
      export ROLLBACK_TAG="$latest_tag"
      log_info "Found latest stable tag: $ROLLBACK_TAG"
      return 0
    else
      log_error "No stable tags found for rollback"
      return 7
    fi
  fi

  # If environment specified, find latest environment tag
  if [[ -n "$ROLLBACK_ENVIRONMENT" ]]; then
    local env_tag
    env_tag=$(find_latest_tag "env-${ROLLBACK_ENVIRONMENT}")
    if [[ -n "$env_tag" ]]; then
      export ROLLBACK_TAG="$env_tag"
      log_info "Found latest environment tag: $ROLLBACK_TAG"
      return 0
    fi
  fi

  # Find latest rollback tag
  local rollback_tag
  rollback_tag=$(find_latest_tag "rollback")
  if [[ -n "$rollback_tag" ]]; then
    export ROLLBACK_TAG="$rollback_tag"
    log_info "Found latest rollback tag: $ROLLBACK_TAG"
    return 0
  fi

  log_error "No suitable rollback tag found"
  return 7
}

# Validate rollback safety
validate_rollback_safety() {
  log_info "Validating rollback safety"

  case "$TEST_MODE" in
    "DRY_RUN"|"SIMULATE")
      log_info "Would validate rollback safety"
      return 0
      ;;
  esac

  # Check if rollback tag is current HEAD
  local current_commit
  current_commit=$(git rev-parse HEAD 2>/dev/null || echo "")
  local rollback_commit
  rollback_commit=$(git rev-parse "$ROLLBACK_TAG" 2>/dev/null || echo "")

  if [[ "$current_commit" == "$rollback_commit" ]]; then
    log_warning "⚠️ Rollback tag points to current commit - no changes will be made"
    if [[ "$FORCE_ROLLBACK" != "true" ]]; then
      return 3
    fi
  fi

  # Check for rollback conflicts
  local merge_base
  merge_base=$(git merge-base "$current_commit" "$rollback_commit" 2>/dev/null || echo "")
  if [[ -z "$merge_base" ]]; then
    log_error "Rollback tag is not related to current branch"
    return 3
  fi

  log_success "✅ Rollback safety validation passed"
  return 0
}

# Confirm rollback action
confirm_rollback() {
  if [[ "$CONFIRM_REQUIRED" != "true" ]]; then
    log_info "Confirmation skipped"
    return 0
  fi

  if [[ "$TEST_MODE" != "EXECUTE" ]]; then
    log_info "Confirmation skipped in test mode"
    return 0
  fi

  log_warning ""
  log_warning "🚨 ROLLBACK CONFIRMATION REQUIRED"
  log_warning ""

  # Show rollback details
  log_warning "Environment: ${ROLLBACK_ENVIRONMENT:-all}"
  log_warning "Rollback tag: $ROLLBACK_TAG"
  log_warning "Rollback type: $ROLLBACK_TYPE"
  log_warning "Rollback ID: $ROLLBACK_ID"

  if [[ -n "$ROLLBACK_ENVIRONMENT" ]]; then
    log_warning "Target environment: $ROLLBACK_ENVIRONMENT"
  fi

  log_warning ""
  log_warning "This will:"
  log_warning "• Roll back deployment to version: $ROLLBACK_TAG"
  log_warning "• Potentially cause service disruption"
  log_warning "• Create rollback tracking tag"

  log_warning ""
  read -p "Do you want to proceed with rollback? (yes/no): " confirmation

  case "$confirmation" in
    "yes"|"y"|"YES"|"Y")
      log_info "Rollback confirmed by user"
      return 0
      ;;
    *)
      log_error "Rollback cancelled by user"
      return 6
      ;;
  esac
}

# Create rollback tracking tag
create_rollback_tracking_tag() {
  log_info "Creating rollback tracking tag"

  case "$TEST_MODE" in
    "DRY_RUN"|"SIMULATE")
      log_info "Would create rollback tracking tag"
      return 0
      ;;
  esac

  local tracking_tag="rollback-complete-${ROLLBACK_ENVIRONMENT:-all}-$(date +%Y%m%d-%H%M%S)"
  local tracking_message="Rollback completed - From $(git rev-parse --short HEAD 2>/dev/null || echo 'unknown') to $ROLLBACK_TAG - Rollback ID: $ROLLBACK_ID"

  if create_git_tag "$tracking_tag" "$tracking_message"; then
    log_success "✅ Rollback tracking tag created: $tracking_tag"
    export ROLLBACK_TRACKING_TAG="$tracking_tag"
  else
    log_warning "⚠️ Failed to create rollback tracking tag"
  fi

  return 0
}

# Rollback deployment
rollback_deployment() {
  if [[ "$ROLLBACK_TYPE" != "deployment" && "$ROLLBACK_TYPE" != "all" ]]; then
    log_info "Skipping deployment rollback (type: $ROLLBACK_TYPE)"
    return 0
  fi

  log_info "Rolling back deployment"

  case "$TEST_MODE" in
    "DRY_RUN")
      log_info "Would rollback deployment to $ROLLBACK_TAG"
      return 0
      ;;
    "SIMULATE")
      log_info "Simulating deployment rollback"
      sleep 3
      return 0
      ;;
  esac

  # Kubernetes rollback
  if [[ "${ROLLBACK_PLATFORM}" == "kubernetes" ]]; then
    log_info "Rolling back Kubernetes deployment"

    # Get previous deployment revision
    local previous_revision
    previous_revision=$(kubectl rollout history deployment --namespace="$KUBE_NAMESPACE" | grep "$ROLLBACK_TAG" | tail -1 | awk '{print $1}' || echo "")

    if [[ -n "$previous_revision" ]]; then
      log_info "Rolling back to revision: $previous_revision"
      if kubectl rollout undo deployment --to-revision="$previous_revision" --namespace="$KUBE_NAMESPACE" --timeout="${ROLLBACK_TIMEOUT}s"; then
        log_success "✅ Kubernetes deployment rollback completed"
      else
        log_error "❌ Kubernetes deployment rollback failed"
        return 2
      fi
    else
      log_warning "No previous deployment found for tag: $ROLLBACK_TAG"
      log_warning "Attempting to apply rollback manifest"
      # TODO: Implement manifest-based rollback
    fi
  fi

  # Docker rollback
  if [[ "${ROLLBACK_PLATFORM}" == "docker" ]]; then
    log_info "Rolling back Docker deployment"

    # Stop current services
    if [[ -f "docker-compose.yml" ]]; then
      docker-compose down

      # Reset to rollback tag
      git checkout "$ROLLBACK_TAG"

      # Start services with rollback version
      docker-compose up -d

      log_success "✅ Docker deployment rollback completed"
    else
      log_error "No docker-compose.yml found for rollback"
      return 2
    fi
  fi

  return 0
}

# Rollback configuration
rollback_config() {
  if [[ "$ROLLBACK_TYPE" != "config" && "$ROLLBACK_TYPE" != "all" ]]; then
    log_info "Skipping configuration rollback (type: $ROLLBACK_TYPE)"
    return 0
  fi

  log_info "Rolling back configuration"

  case "$TEST_MODE" in
    "DRY_RUN")
      log_info "Would rollback configuration"
      return 0
      ;;
    "SIMULATE")
      log_info "Simulating configuration rollback"
      sleep 2
      return 0
      ;;
  esac

  # Rollback configuration files
  local config_files=(
    "config/environments/"
    "secrets/"
    ".env"
    "docker-compose.yml"
    "docker-compose.override.yml"
  )

  for config_file in "${config_files[@]}"; do
    if [[ -e "$config_file" ]]; then
      log_info "Rolling back configuration: $config_file"
      git checkout "$ROLLBACK_TAG" -- "$config_file"
    fi
  done

  log_success "✅ Configuration rollback completed"
  return 0
}

# Verify rollback
verify_rollback() {
  log_info "Verifying rollback"

  case "$TEST_MODE" in
    "DRY_RUN"|"SIMULATE")
      log_info "Would verify rollback"
      return 0
      ;;
  esac

  local current_commit
  current_commit=$(git rev-parse HEAD 2>/dev/null || echo "")
  local rollback_commit
  rollback_commit=$(git rev-parse "$ROLLBACK_TAG" 2>/dev/null || echo "")

  if [[ "$current_commit" == "$rollback_commit" ]]; then
    log_success "✅ Rollback verified - current commit matches rollback tag"
  else
    log_warning "⚠️ Rollback verification - commit mismatch detected"
    log_warning "Current: $current_commit"
    log_warning "Expected: $rollback_commit"
  fi

  # Verify deployment health if applicable
  if [[ "$ROLLBACK_TYPE" == "deployment" || "$ROLLBACK_TYPE" == "all" ]]; then
    local health_check_url="${HEALTH_CHECK_URL:-http://localhost:3000/health}"
    if command -v curl >/dev/null 2>&1; then
      log_info "Checking deployment health after rollback"
      if curl -s -o /dev/null -w "%{http_code}" "$health_check_url" --connect-timeout 10 | grep -q "^[23]..$"; then
        log_success "✅ Rollback health check passed"
      else
        log_warning "⚠️ Rollback health check failed - manual verification required"
      fi
    fi
  fi

  return 0
}

# Generate rollback report
generate_rollback_report() {
  local rollback_status="$1"
  local start_time="$2"
  local end_time=$(date +%s)

  log_info "Generating rollback report"

  local rollback_duration=$((end_time - start_time))
  local output_dir="${ROLLBACK_REPORT_OUTPUT:-reports/rollback}"
  mkdir -p "$output_dir"

  local report_file="$output_dir/rollback-report-$(date +%Y%m%d-%H%M%S).json"

  # Build report content
  cat > "$report_file" << EOF
{
  "rollback": {
    "script": "$SCRIPT_NAME",
    "version": "$SCRIPT_VERSION",
    "status": "$rollback_status",
    "type": "$ROLLBACK_TYPE",
    "test_mode": "$TEST_MODE",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "duration_seconds": $rollback_duration,
    "rollback_id": "$ROLLBACK_ID"
  },
  "configuration": {
    "environment": "${ROLLBACK_ENVIRONMENT:-all}",
    "rollback_tag": "$ROLLBACK_TAG",
    "dry_run": "$DRY_RUN",
    "force_rollback": "$FORCE_ROLLBACK",
    "timeout": "$ROLLBACK_TIMEOUT"
  },
  "artifacts": {
    "rollback_tag": "$ROLLBACK_TAG",
    "tracking_tag": "${ROLLBACK_TRACKING_TAG:-none}"
  }
}
EOF

  log_success "✅ Rollback report generated: $report_file"

  # Export for CI systems
  export ROLLBACK_REPORT_FILE="$report_file"

  return 0
}

# Main rollback function
main() {
  local start_time
  start_time=$(date +%s)

  log_info "🔄 Starting CI rollback"
  log_info "Script version: $SCRIPT_VERSION"

  # Parse command line arguments
  if ! parse_args "$@"; then
    return 1
  fi

  log_info "Rollback configuration:"
  log_info "  Environment: ${ROLLBACK_ENVIRONMENT:-auto-detect}"
  log_info "  Rollback tag: ${ROLLBACK_TAG:-auto-detect}"
  log_info "  Use latest: $USE_LATEST"
  log_info "  Rollback type: $ROLLBACK_TYPE"
  log_info "  Dry run: $DRY_RUN"
  log_info "  Force rollback: $FORCE_ROLLBACK"
  log_info "  Confirm required: $CONFIRM_REQUIRED"
  log_info "  Timeout: $ROLLBACK_TIMEOUT seconds"
  log_info "  Test mode: $TEST_MODE"

  # Run rollback pipeline
  if ! check_prerequisites; then
    return 5
  fi

  if ! configure_rollback_environment; then
    return 1
  fi

  if ! find_rollback_tag; then
    return 7
  fi

  if ! validate_rollback_safety; then
    return 3
  fi

  if ! confirm_rollback; then
    return 6
  fi

  # Execute rollback based on type
  local rollback_result=0

  if ! rollback_deployment; then
    rollback_result=2
  fi

  if ! rollback_config; then
    rollback_result=2
  fi

  # Verify rollback
  verify_rollback

  # Create rollback tracking tag
  create_rollback_tracking_tag

  # Determine overall result
  if [[ $rollback_result -eq 0 ]]; then
    log_success "✅ Rollback completed successfully"
    generate_rollback_report "success" "$start_time"

    # Show actionable items for CI
    if [[ -n "${CI:-}" ]]; then
      echo
      log_info "🔗 Next steps for CI pipeline:"
      log_info "   • Verify deployment health"
      log_info "   • Create environment state tag: scripts/release/50-ci-tag-assignment.sh --type state --environment ${ROLLBACK_ENVIRONMENT:-all} --state rolled-back"
      log_info "   • Monitor system metrics and alerts"
      log_info "   • Review rollback report: $ROLLBACK_REPORT_FILE"
    fi

    return 0
  else
    log_error "❌ Rollback failed (exit code: $rollback_result)"
    generate_rollback_report "failed" "$start_time"
    return $rollback_result
  fi
}

# Error handling
trap 'log_error "Script failed with exit code $?"' ERR

# Execute main function with all arguments
main "$@"