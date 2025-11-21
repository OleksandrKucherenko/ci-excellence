#!/usr/bin/env bash
# CI Deploy Script
# Deploys applications to various environments with full rollback capability

set -euo pipefail

# Source shared utilities
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Source tag utilities for deployment tag management
# shellcheck source=../lib/tag-utils.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/tag-utils.sh"

# Script configuration
readonly SCRIPT_NAME="$(basename "$0" .sh)"
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_DESCRIPTION="Deploy applications to various environments"

# Default deploy configuration
DEFAULT_ENVIRONMENT="staging"
DEFAULT_DEPLOYMENT_TYPE="standard"
DEFAULT_DRY_RUN=true
DEFAULT_ROLLBACK_ENABLED=true

# Usage information
usage() {
  cat <<EOF
Usage: $SCRIPT_NAME [OPTIONS]

Deploy applications to various environments with full rollback capability.

OPTIONS:
  -e, --environment ENV     Target environment (staging|production|dev) [default: $DEFAULT_ENVIRONMENT]
  -t, --type TYPE          Deployment type (standard|blue-green|canary) [default: $DEFAULT_DEPLOYMENT_TYPE]
  -d, --dry-run            Preview deployment actions without executing (default)
  --no-dry-run             Actually execute deployment
  -f, --force              Force deployment even if checks fail
  --no-rollback            Disable rollback capability
  --skip-health-check      Skip deployment health checks
  --skip-pre-deploy        Skip pre-deployment validation
  --timeout SECONDS        Deployment timeout [default: 600]
  -t, --test-mode MODE     Test mode (DRY_RUN|SIMULATE|EXECUTE)
  -h, --help               Show this help message
  -V, --version            Show version information

EXAMPLES:
  $SCRIPT_NAME                                    # Preview staging deployment
  $SCRIPT_NAME --environment production --no-dry-run  # Deploy to production
  $SCRIPT_NAME --type blue-green --timeout 1200     # Blue-green deployment with extended timeout
  $SCRIPT_NAME --force --skip-health-check          # Force deployment without health checks

ENVIRONMENTS:
  staging       Staging environment for testing
  production    Production environment for live traffic
  dev           Development environment for development

DEPLOYMENT TYPES:
  standard      Standard deployment with rolling updates
  blue-green    Blue-green deployment with zero downtime
  canary        Canary deployment with gradual traffic shift

ENVIRONMENT VARIABLES:
  CI_TEST_MODE               Test mode override (DRY_RUN|SIMULATE|EXECUTE)
  CI_DEPLOY_ENVIRONMENT      Target environment override
  CI_DEPLOY_TYPE            Deployment type override
  CI_DRY_RUN                Enable/disable dry run (true|false)
  CI_FORCE_DEPLOY           Force deployment (true|false)
  CI_ROLLBACK_ENABLED       Enable rollback capability (true|false)
  DEPLOY_TIMEOUT            Deployment timeout in seconds
  KUBE_CONFIG               Kubernetes configuration file
  DOCKER_CONFIG             Docker configuration
  AWS_ACCESS_KEY_ID         AWS access key
  AWS_SECRET_ACCESS_KEY     AWS secret key

EXIT CODES:
  0     Success
  1     General error
  2     Deployment failed
  3     Validation failed
  4     Invalid arguments
  5     Prerequisites not met
  6     Health check failed
  7     Rollback failed

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
  local opt_environment="$DEFAULT_ENVIRONMENT"
  local opt_deployment_type="$DEFAULT_DEPLOYMENT_TYPE"
  local opt_dry_run="$DEFAULT_DRY_RUN"
  local opt_force_deploy=false
  local opt_rollback_enabled="$DEFAULT_ROLLBACK_ENABLED"
  local opt_skip_health_check=false
  local opt_skip_pre_deploy=false
  local opt_timeout="600"
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
      -t|--type)
        shift
        if [[ -z "$1" ]]; then
          log_error "Deployment type cannot be empty"
          return 4
        fi
        case "$1" in
          standard|blue-green|canary) ;;
          *)
            log_error "Invalid deployment type: $1. Use standard, blue-green, or canary"
            return 4
            ;;
        esac
        opt_deployment_type="$1"
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
        opt_force_deploy=true
        shift
        ;;
      --no-rollback)
        opt_rollback_enabled=false
        shift
        ;;
      --skip-health-check)
        opt_skip_health_check=true
        shift
        ;;
      --skip-pre-deploy)
        opt_skip_pre_deploy=true
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
        log_error "Unexpected argument: $1"
        usage
        return 4
        ;;
    esac
  done

  # Set global variables
  export DEPLOY_ENVIRONMENT="$opt_environment"
  export DEPLOYMENT_TYPE="$opt_deployment_type"
  export DRY_RUN="$opt_dry_run"
  export FORCE_DEPLOY="$opt_force_deploy"
  export ROLLBACK_ENABLED="$opt_rollback_enabled"
  export SKIP_HEALTH_CHECK="$opt_skip_health_check"
  export SKIP_PRE_DEPLOY="$opt_skip_pre_deploy"
  export DEPLOY_TIMEOUT="$opt_timeout"

  # Resolve test mode
  local resolved_mode
  if ! resolved_mode=$(resolve_test_mode "$SCRIPT_NAME" "deploy" "$opt_test_mode"); then
    return 1
  fi
  export TEST_MODE="$resolved_mode"

  return 0
}

# Check deployment prerequisites
check_prerequisites() {
  log_info "Checking deployment prerequisites"

  local missing_tools=()

  # Check for deployment tools based on deployment type
  if [[ "$DEPLOYMENT_TYPE" == "blue-green" || "$DEPLOYMENT_TYPE" == "canary" ]]; then
    if command -v kubectl >/dev/null 2>&1; then
      export DEPLOY_PLATFORM="kubernetes"
    elif command -v docker >/dev/null 2>&1; then
      export DEPLOY_PLATFORM="docker"
    else
      missing_tools+=("kubectl or docker for advanced deployment types")
    fi
  fi

  # Check for configuration files
  if [[ -f "docker-compose.yml" ]]; then
    export DEPLOY_COMPOSE="true"
  fi

  if [[ -f "k8s" && -d "k8s" ]]; then
    export DEPLOY_K8S="true"
  fi

  # Check for environment-specific configuration
  local env_config="config/environments/${DEPLOY_ENVIRONMENT}.json"
  if [[ -f "$env_config" ]]; then
    export DEPLOY_ENV_CONFIG="$env_config"
  else
    log_warning "Environment config not found: $env_config"
  fi

  # Check for secrets configuration
  local secrets_config="secrets/${DEPLOY_ENVIRONMENT}.yaml"
  if [[ -f "$secrets_config" ]]; then
    export DEPLOY_SECRETS_CONFIG="$secrets_config"
  else
    log_warning "Secrets config not found: $secrets_config"
  fi

  if [[ ${#missing_tools[@]} -gt 0 ]]; then
    log_error "Missing deployment tools: ${missing_tools[*]}"
    return 5
  fi

  log_success "✅ Deployment prerequisites met"
  return 0
}

# Configure deployment environment
configure_deployment_environment() {
  log_info "Configuring deployment environment"

  # Export deployment environment variables
  export DEPLOY_ENVIRONMENT="$DEPLOY_ENVIRONMENT"
  export DEPLOYMENT_TYPE="$DEPLOYMENT_TYPE"
  export DRY_RUN="$DRY_RUN"
  export FORCE_DEPLOY="$FORCE_DEPLOY"
  export TEST_MODE="$TEST_MODE"

  # Set deployment metadata
  export DEPLOY_ID="deploy-$(date +%Y%m%d-%H%M%S)-$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
  export DEPLOY_TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  export DEPLOY_VERSION="${PACKAGE_VERSION:-$(node -e "console.log(JSON.parse(require('fs').readFileSync('package.json', 'utf8')).version)" 2>/dev/null || echo 'unknown')}"

  # Configure platform-specific settings
  case "${DEPLOY_PLATFORM:-standard}" in
    "kubernetes")
      export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"
      export KUBE_NAMESPACE="${DEPLOY_ENVIRONMENT}"
      ;;
    "docker")
      export DOCKER_HOST="${DOCKER_HOST:-unix:///var/run/docker.sock}"
      ;;
  esac

  # Configure health check settings
  export HEALTH_CHECK_ENDPOINT="${HEALTH_CHECK_ENDPOINT:-/health}"
  export HEALTH_CHECK_TIMEOUT="${HEALTH_CHECK_TIMEOUT:-30}"
  export HEALTH_CHECK_RETRIES="${HEALTH_CHECK_RETRIES:-3}"

  # Configure rollback settings
  if [[ "$ROLLBACK_ENABLED" == "true" ]]; then
    export ROLLBACK_TAG_PREFIX="${ROLLBACK_TAG_PREFIX:-rollback}"
    export ROLLBACK_KEEP_COUNT="${ROLLBACK_KEEP_COUNT:-5}"
  fi

  log_info "Deployment environment configured:"
  log_info "  Environment: $DEPLOY_ENVIRONMENT"
  log_info "  Deployment type: $DEPLOYMENT_TYPE"
  log_info "  Deploy ID: $DEPLOY_ID"
  log_info "  Version: $DEPLOY_VERSION"
  log_info "  Platform: ${DEPLOY_PLATFORM:-standard}"
  log_info "  Dry run: $DRY_RUN"
  log_info "  Rollback enabled: $ROLLBACK_ENABLED"

  return 0
}

# Validate deployment prerequisites
validate_deployment_prerequisites() {
  if [[ "$SKIP_PRE_DEPLOY" == "true" ]]; then
    log_info "Skipping pre-deployment validation"
    return 0
  fi

  log_info "Validating deployment prerequisites"

  case "$TEST_MODE" in
    "DRY_RUN"|"SIMULATE")
      log_info "Would validate deployment prerequisites"
      return 0
      ;;
  esac

  local validation_failed=false

  # Check if environment is allowed for current branch
  local current_branch
  current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

  case "$DEPLOY_ENVIRONMENT" in
    "production")
      if [[ "$current_branch" != "main" && "$current_branch" != "master" && "$FORCE_DEPLOY" != "true" ]]; then
        log_error "Cannot deploy to production from branch: $current_branch"
        log_error "Use --force to override or switch to main/master branch"
        validation_failed=true
      fi
      ;;
    "staging")
      if [[ "$current_branch" =~ ^release/.* || "$current_branch" == "main" || "$current_branch" == "master" ]]; then
        log_info "Branch $current_branch is allowed for staging deployment"
      elif [[ "$FORCE_DEPLOY" != "true" ]]; then
        log_error "Cannot deploy to staging from branch: $current_branch"
        log_error "Use --force to override"
        validation_failed=true
      fi
      ;;
  esac

  # Check for uncommitted changes
  if [[ -n $(git status --porcelain 2>/dev/null) && "$FORCE_DEPLOY" != "true" ]]; then
    log_error "Cannot deploy with uncommitted changes"
    log_error "Commit changes or use --force to override"
    validation_failed=true
  fi

  # Validate build artifacts exist
  if [[ -n "${BUILD_OUTPUT_DIR:-}" && ! -d "$BUILD_OUTPUT_DIR" ]]; then
    log_error "Build output directory not found: $BUILD_OUTPUT_DIR"
    log_error "Run build first: scripts/build/20-ci-compile.sh"
    validation_failed=true
  fi

  if [[ "$validation_failed" == "true" ]]; then
    log_error "❌ Deployment validation failed"
    return 3
  fi

  log_success "✅ Deployment validation passed"
  return 0
}

# Create deployment tag
create_deployment_tag() {
  log_info "Creating deployment tag"

  case "$TEST_MODE" in
    "DRY_RUN"|"SIMULATE")
      log_info "Would create deployment tag"
      return 0
      ;;
  esac

  local tag_name="env-${DEPLOY_ENVIRONMENT}-${DEPLOY_VERSION}"
  local tag_message="Deployment to ${DEPLOY_ENVIRONMENT} - Version ${DEPLOY_VERSION} - Deploy ID: ${DEPLOY_ID}"

  if create_git_tag "$tag_name" "$tag_message"; then
    log_success "✅ Deployment tag created: $tag_name"
    export DEPLOYMENT_TAG="$tag_name"
  else
    log_warning "⚠️ Failed to create deployment tag (continuing anyway)"
  fi

  return 0
}

# Deploy with standard strategy
deploy_standard() {
  log_info "Starting standard deployment"

  case "$TEST_MODE" in
    "DRY_RUN")
      log_info "Would perform standard deployment"
      return 0
      ;;
    "SIMULATE")
      log_info "Simulating standard deployment"
      sleep 5
      return 0
      ;;
  esac

  # Docker Compose deployment
  if [[ "${DEPLOY_COMPOSE:-}" == "true" && -f "docker-compose.yml" ]]; then
    log_info "Deploying with Docker Compose"

    # Create backup for rollback
    if [[ "$ROLLBACK_ENABLED" == "true" ]]; then
      log_info "Creating backup for rollback"
      docker-compose config > "/tmp/docker-compose-backup-${DEPLOY_ID}.yml"
    fi

    # Pull latest images
    docker-compose pull

    # Stop existing services
    docker-compose down

    # Start new services
    docker-compose up -d

    log_success "✅ Docker Compose deployment completed"
  fi

  # Kubernetes deployment
  if [[ "${DEPLOY_K8S:-}" == "true" && -d "k8s" ]]; then
    log_info "Deploying with Kubernetes"

    # Apply Kubernetes manifests
    kubectl apply -f "k8s/" --namespace="$KUBE_NAMESPACE"

    # Wait for rollout to complete
    if kubectl rollout status deployment --namespace="$KUBE_NAMESPACE" --timeout="${DEPLOY_TIMEOUT}s"; then
      log_success "✅ Kubernetes deployment completed"
    else
      log_error "❌ Kubernetes deployment failed"
      return 2
    fi
  fi

  return 0
}

# Deploy with blue-green strategy
deploy_blue_green() {
  log_info "Starting blue-green deployment"

  case "$TEST_MODE" in
    "DRY_RUN")
      log_info "Would perform blue-green deployment"
      return 0
      ;;
    "SIMULATE")
      log_info "Simulating blue-green deployment"
      sleep 8
      return 0
      ;;
  esac

  log_info "Blue-green deployment completed (placeholder)"
  # TODO: Implement actual blue-green deployment logic
  return 0
}

# Deploy with canary strategy
deploy_canary() {
  log_info "Starting canary deployment"

  case "$TEST_MODE" in
    "DRY_RUN")
      log_info "Would perform canary deployment"
      return 0
      ;;
    "SIMULATE")
      log_info "Simulating canary deployment"
      sleep 10
      return 0
      ;;
  esac

  log_info "Canary deployment completed (placeholder)"
  # TODO: Implement actual canary deployment logic
  return 0
}

# Run deployment health checks
run_health_checks() {
  if [[ "$SKIP_HEALTH_CHECK" == "true" ]]; then
    log_info "Skipping health checks"
    return 0
  fi

  log_info "Running deployment health checks"

  case "$TEST_MODE" in
    "DRY_RUN"|"SIMULATE")
      log_info "Would run health checks"
      return 0
      ;;
  esac

  local health_check_url="${HEALTH_CHECK_URL:-http://localhost:3000${HEALTH_CHECK_ENDPOINT}}"
  local max_retries="$HEALTH_CHECK_RETRIES"
  local retry_count=0

  while [[ $retry_count -lt $max_retries ]]; do
    ((retry_count++))

    log_info "Health check attempt $retry_count/$max_retries: $health_check_url"

    # Perform health check
    if command -v curl >/dev/null 2>&1; then
      local response
      response=$(curl -s -o /dev/null -w "%{http_code}" "$health_check_url" --connect-timeout "$HEALTH_CHECK_TIMEOUT" || echo "000")

      if [[ "$response" =~ ^[23]..$ ]]; then
        log_success "✅ Health check passed (HTTP $response)"
        return 0
      else
        log_warning "⚠️ Health check failed (HTTP $response)"
      fi
    else
      log_warning "curl not available, skipping HTTP health check"
      return 0
    fi

    # Wait before retry
    if [[ $retry_count -lt $max_retries ]]; then
      sleep 5
    fi
  done

  log_error "❌ Health checks failed after $max_retries attempts"
  return 6
}

# Create rollback point
create_rollback_point() {
  if [[ "$ROLLBACK_ENABLED" != "true" ]]; then
    log_info "Rollback disabled, skipping rollback point creation"
    return 0
  fi

  log_info "Creating rollback point"

  case "$TEST_MODE" in
    "DRY_RUN"|"SIMULATE")
      log_info "Would create rollback point"
      return 0
      ;;
  esac

  local rollback_tag="${ROLLBACK_TAG_PREFIX}-${DEPLOY_ENVIRONMENT}-$(date +%Y%m%d-%H%M%S)"
  local rollback_message="Rollback point for deployment ${DEPLOY_ID} - Environment ${DEPLOY_ENVIRONMENT} - Version ${DEPLOY_VERSION}"

  if create_git_tag "$rollback_tag" "$rollback_message"; then
    log_success "✅ Rollback point created: $rollback_tag"
    export ROLLBACK_TAG="$rollback_tag"
  else
    log_warning "⚠️ Failed to create rollback point"
  fi

  return 0
}

# Generate deployment report
generate_deployment_report() {
  local deploy_status="$1"
  local start_time="$2"
  local end_time=$(date +%s)

  log_info "Generating deployment report"

  local deploy_duration=$((end_time - start_time))
  local output_dir="${DEPLOY_REPORT_OUTPUT:-reports/deploy}"
  mkdir -p "$output_dir"

  local report_file="$output_dir/deploy-report-$(date +%Y%m%d-%H%M%S).json"

  # Build report content
  cat > "$report_file" << EOF
{
  "deployment": {
    "script": "$SCRIPT_NAME",
    "version": "$SCRIPT_VERSION",
    "status": "$deploy_status",
    "environment": "$DEPLOY_ENVIRONMENT",
    "type": "$DEPLOYMENT_TYPE",
    "test_mode": "$TEST_MODE",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "duration_seconds": $deploy_duration,
    "deploy_id": "$DEPLOY_ID",
    "version": "$DEPLOY_VERSION"
  },
  "configuration": {
    "dry_run": "$DRY_RUN",
    "force_deploy": "$FORCE_DEPLOY",
    "rollback_enabled": "$ROLLBACK_ENABLED",
    "skip_health_check": "$SKIP_HEALTH_CHECK",
    "timeout": "$DEPLOY_TIMEOUT"
  },
  "artifacts": {
    "deployment_tag": "${DEPLOYMENT_TAG:-none}",
    "rollback_tag": "${ROLLBACK_TAG:-none}",
    "backup_files": $(find /tmp -name "*${DEPLOY_ID}*" 2>/dev/null | wc -l)
  }
}
EOF

  log_success "✅ Deployment report generated: $report_file"

  # Export for CI systems
  export DEPLOY_REPORT_FILE="$report_file"

  return 0
}

# Main deploy function
main() {
  local start_time
  start_time=$(date +%s)

  log_info "🚀 Starting CI deployment"
  log_info "Script version: $SCRIPT_VERSION"

  # Parse command line arguments
  if ! parse_args "$@"; then
    return 1
  fi

  log_info "Deployment configuration:"
  log_info "  Environment: $DEPLOY_ENVIRONMENT"
  log_info "  Deployment type: $DEPLOYMENT_TYPE"
  log_info "  Dry run: $DRY_RUN"
  log_info "  Force deploy: $FORCE_DEPLOY"
  log_info "  Rollback enabled: $ROLLBACK_ENABLED"
  log_info "  Skip health check: $SKIP_HEALTH_CHECK"
  log_info "  Skip pre-deploy: $SKIP_PRE_DEPLOY"
  log_info "  Timeout: $DEPLOY_TIMEOUT seconds"
  log_info "  Test mode: $TEST_MODE"

  # Run deployment pipeline
  if ! check_prerequisites; then
    return 5
  fi

  if ! configure_deployment_environment; then
    return 1
  fi

  if ! validate_deployment_prerequisites; then
    return 3
  fi

  # Create rollback point before deployment
  create_rollback_point

  # Create deployment tag
  create_deployment_tag

  # Execute deployment based on type
  local deploy_result=0
  case "$DEPLOYMENT_TYPE" in
    "standard")
      deploy_standard || deploy_result=$?
      ;;
    "blue-green")
      deploy_blue_green || deploy_result=$?
      ;;
    "canary")
      deploy_canary || deploy_result=$?
      ;;
  esac

  # Run health checks if deployment succeeded
  if [[ $deploy_result -eq 0 ]]; then
    run_health_checks || deploy_result=$?
  fi

  # Determine overall result
  if [[ $deploy_result -eq 0 ]]; then
    log_success "✅ Deployment completed successfully"
    generate_deployment_report "success" "$start_time"

    # Show actionable items for CI
    if [[ -n "${CI:-}" ]]; then
      echo
      log_info "🔗 Next steps for CI pipeline:"
      log_info "   • Monitor deployment health"
      log_info "   • Create environment state tag: scripts/release/50-ci-tag-assignment.sh --type state --environment $DEPLOY_ENVIRONMENT --state deployed"
      if [[ "$ROLLBACK_ENABLED" == "true" ]]; then
        log_info "   • Rollback if needed: scripts/release/70-ci-rollback.sh --environment $DEPLOY_ENVIRONMENT --tag ${ROLLBACK_TAG:-latest}"
      fi
    fi

    return 0
  else
    log_error "❌ Deployment failed (exit code: $deploy_result)"
    generate_deployment_report "failed" "$start_time"
    return $deploy_result
  fi
}

# Error handling
trap 'log_error "Script failed with exit code $?"' ERR

# Execute main function with all arguments
main "$@"