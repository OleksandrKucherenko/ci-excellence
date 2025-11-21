#!/usr/bin/env bash
# CI Publish Script
# Publishes artifacts and manages package distribution

set -euo pipefail

# Source shared utilities
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Script configuration
readonly SCRIPT_NAME="$(basename "$0" .sh)"
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_DESCRIPTION="Publish artifacts and manage package distribution"

# Default publish configuration
DEFAULT_PUBLISH_TYPE="package"
DEFAULT_DRY_RUN=true
DEFAULT_SKIP_IF_UNCHANGED=true

# Usage information
usage() {
  cat <<EOF
Usage: $SCRIPT_NAME [OPTIONS]

Publish artifacts and manage package distribution.

OPTIONS:
  -t, --type TYPE           Publish type (package|docker|docs|release|all) [default: $DEFAULT_PUBLISH_TYPE]
  -d, --dry-run             Preview publish actions without executing (default)
  --no-dry-run              Actually execute publish actions
  -f, --force               Force publish even if unchanged
  --skip-if-unchanged       Skip publish if no changes detected (default)
  --registry REGISTRY       Package registry to publish to
  --tag TAG                 Publish tag (latest, beta, specific version)
  --notes FILE              Release notes file for releases
  -t, --test-mode MODE      Test mode (DRY_RUN|SIMULATE|EXECUTE)
  -h, --help                Show this help message
  -V, --version             Show version information

EXAMPLES:
  $SCRIPT_NAME                           # Preview package publishing
  $SCRIPT_NAME --no-dry-run              # Actually publish package
  $SCRIPT_NAME --type docker             # Publish Docker image
  $SCRIPT_NAME --type release --force    # Force publish release
  $SCRIPT_NAME --tag beta                # Publish with beta tag

PUBLISH TYPES:
  package       Publish npm/Node.js package
  docker        Publish Docker image
  docs          Publish documentation
  release       Create GitHub release
  all           Publish all applicable types

ENVIRONMENT VARIABLES:
  CI_TEST_MODE               Test mode override (DRY_RUN|SIMULATE|EXECUTE)
  CI_PUBLISH_TYPE            Publish type override
  CI_REGISTRY                Package registry URL
  CI_DRY_RUN                 Enable/disable dry run (true|false)
  CI_FORCE_PUBLISH           Force publishing (true|false)
  NPM_TOKEN                 npm publish token
  DOCKER_REGISTRY           Docker registry URL
  DOCKER_USERNAME           Docker username
  DOCKER_PASSWORD           Docker password
  GITHUB_TOKEN              GitHub token for releases

EXIT CODES:
  0     Success
  1     General error
  2     Publish failed
  3     Validation failed
  4     Invalid arguments
  5     Prerequisites not met
  6     Authentication failed

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
  local opt_publish_type="$DEFAULT_PUBLISH_TYPE"
  local opt_dry_run="$DEFAULT_DRY_RUN"
  local opt_force_publish=false
  local opt_skip_if_unchanged="$DEFAULT_SKIP_IF_UNCHANGED"
  local opt_registry=""
  local opt_tag=""
  local opt_notes_file=""
  local opt_test_mode=""

  # Parse options
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -t|--type)
        shift
        if [[ -z "$1" ]]; then
          log_error "Publish type cannot be empty"
          return 4
        fi
        case "$1" in
          package|docker|docs|release|all) ;;
          *)
            log_error "Invalid publish type: $1. Use package, docker, docs, release, or all"
            return 4
            ;;
        esac
        opt_publish_type="$1"
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
        opt_force_publish=true
        shift
        ;;
      --skip-if-unchanged)
        opt_skip_if_unchanged=true
        shift
        ;;
      --registry)
        shift
        if [[ -z "$1" ]]; then
          log_error "Registry cannot be empty"
          return 4
        fi
        opt_registry="$1"
        shift
        ;;
      --tag)
        shift
        if [[ -z "$1" ]]; then
          log_error "Tag cannot be empty"
          return 4
        fi
        opt_tag="$1"
        shift
        ;;
      --notes)
        shift
        if [[ -z "$1" ]]; then
          log_error "Release notes file cannot be empty"
          return 4
        fi
        opt_notes_file="$1"
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
  export PUBLISH_TYPE="$opt_publish_type"
  export DRY_RUN="$opt_dry_run"
  export FORCE_PUBLISH="$opt_force_publish"
  export SKIP_IF_UNCHANGED="$opt_skip_if_unchanged"
  export REGISTRY="$opt_registry"
  export PUBLISH_TAG="$opt_tag"
  export RELEASE_NOTES_FILE="$opt_notes_file"

  # Resolve test mode
  local resolved_mode
  if ! resolved_mode=$(resolve_test_mode "$SCRIPT_NAME" "publish" "$opt_test_mode"); then
    return 1
  fi
  export TEST_MODE="$resolved_mode"

  return 0
}

# Check publish prerequisites
check_prerequisites() {
  log_info "Checking publish prerequisites"

  local missing_tools=()

  # Check for Node.js and npm if package.json exists
  if [[ "$PUBLISH_TYPE" == "all" || "$PUBLISH_TYPE" == "package" ]]; then
    if [[ -f "package.json" ]]; then
      if ! command -v node >/dev/null 2>&1; then
        missing_tools+=("node")
      fi
      if ! command -v npm >/dev/null 2>&1; then
        missing_tools+=("npm")
      fi
    fi
  fi

  # Check for Docker if Docker publishing
  if [[ "$PUBLISH_TYPE" == "all" || "$PUBLISH_TYPE" == "docker" ]]; then
    if [[ -f "Dockerfile" ]]; then
      if ! command -v docker >/dev/null 2>&1; then
        missing_tools+=("docker")
      fi
    fi
  fi

  # Check for GitHub CLI if release publishing
  if [[ "$PUBLISH_TYPE" == "all" || "$PUBLISH_TYPE" == "release" ]]; then
    if ! command -v gh >/dev/null 2>&1; then
      missing_tools+=("gh (GitHub CLI)")
    fi
  fi

  # Check for authentication tokens
  if [[ "$PUBLISH_TYPE" == "all" || "$PUBLISH_TYPE" == "package" ]]; then
    if [[ -z "${NPM_TOKEN:-}" && -z "${CI_NPM_TOKEN:-}" ]]; then
      log_warning "npm token not found (NPM_TOKEN or CI_NPM_TOKEN)"
    fi
  fi

  if [[ "$PUBLISH_TYPE" == "all" || "$PUBLISH_TYPE" == "docker" ]]; then
    if [[ -z "${DOCKER_PASSWORD:-}" && -z "${CI_DOCKER_PASSWORD:-}" ]]; then
      log_warning "Docker credentials not found"
    fi
  fi

  if [[ "$PUBLISH_TYPE" == "all" || "$PUBLISH_TYPE" == "release" ]]; then
    if [[ -z "${GITHUB_TOKEN:-}" && -z "${CI_GITHUB_TOKEN:-}" ]]; then
      log_warning "GitHub token not found (GITHUB_TOKEN or CI_GITHUB_TOKEN)"
    fi
  fi

  if [[ ${#missing_tools[@]} -gt 0 ]]; then
    log_error "Missing publish tools: ${missing_tools[*]}"
    return 5
  fi

  log_success "✅ Publish prerequisites met"
  return 0
}

# Configure publish environment
configure_publish_environment() {
  log_info "Configuring publish environment"

  # Export publish environment variables
  export PUBLISH_TYPE="$PUBLISH_TYPE"
  export DRY_RUN="$DRY_RUN"
  export FORCE_PUBLISH="$FORCE_PUBLISH"
  export TEST_MODE="$TEST_MODE"

  # Configure registry settings
  export REGISTRY="${REGISTRY:-${CI_REGISTRY:-}}"
  export NPM_REGISTRY="${REGISTRY:-${CI_NPM_REGISTRY:-}}"
  export DOCKER_REGISTRY="${REGISTRY:-${CI_DOCKER_REGISTRY:-}}"

  # Configure tag settings
  export PUBLISH_TAG="${PUBLISH_TAG:-${CI_PUBLISH_TAG:-latest}}"

  # Configure package settings
  export PACKAGE_NAME="${PACKAGE_NAME:-$(node -e "console.log(JSON.parse(require('fs').readFileSync('package.json', 'utf8')).name)" 2>/dev/null || echo "")}"
  export PACKAGE_VERSION="${PACKAGE_VERSION:-$(node -e "console.log(JSON.parse(require('fs').readFileSync('package.json', 'utf8')).version)" 2>/dev/null || echo "")}"

  # Configure Docker settings
  export DOCKER_IMAGE_NAME="${DOCKER_IMAGE_NAME:-${PACKAGE_NAME:-}}"
  export DOCKER_IMAGE_TAG="${DOCKER_IMAGE_TAG:-${PACKAGE_VERSION:-latest}}"

  # Configure GitHub settings
  export GITHUB_REPO="${GITHUB_REPO:-$(git config --get remote.origin.url 2>/dev/null | sed 's/.*github.com[:/]\([^.]*\).*/\1/' || echo "")}"
  export GITHUB_OWNER="${GITHUB_OWNER:-$(echo "$GITHUB_REPO" | cut -d'/' -f1)}"

  log_info "Publish environment configured:"
  log_info "  Publish type: $PUBLISH_TYPE"
  log_info "  Dry run: $DRY_RUN"
  log_info "  Force publish: $FORCE_PUBLISH"
  log_info "  Registry: ${REGISTRY:-default}"
  log_info "  Tag: $PUBLISH_TAG"
  log_info "  Package name: ${PACKAGE_NAME:-unknown}"
  log_info "  Package version: ${PACKAGE_VERSION:-unknown}"

  return 0
}

# Check if changes exist
check_for_changes() {
  if [[ "$FORCE_PUBLISH" == "true" ]]; then
    log_info "Force publish enabled, skipping change detection"
    return 0
  fi

  log_info "Checking for changes since last publish"

  case "$TEST_MODE" in
    "DRY_RUN"|"SIMULATE")
      log_info "Would check for changes"
      return 0
      ;;
  esac

  local has_changes=false

  # Check for uncommitted changes
  if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
    log_info "Uncommitted changes detected"
    has_changes=true
  fi

  # Check for changes since last tag
  local last_tag
  last_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
  if [[ -n "$last_tag" ]]; then
    local commit_count
    commit_count=$(git rev-list --count "$last_tag..HEAD" 2>/dev/null || echo "0")
    if [[ $commit_count -gt 0 ]]; then
      log_info "Changes detected since last tag: $last_tag ($commit_count commits)"
      has_changes=true
    fi
  else
    log_info "No previous tags found, assuming first publish"
    has_changes=true
  fi

  if [[ "$has_changes" == "false" ]]; then
    log_info "No changes detected"
    if [[ "$SKIP_IF_UNCHANGED" == "true" ]]; then
      log_info "Skipping publish (skip-if-unchanged enabled)"
      return 1
    fi
  fi

  return 0
}

# Validate package before publishing
validate_package() {
  log_info "Validating package for publishing"

  if [[ ! -f "package.json" ]]; then
    log_error "package.json not found"
    return 3
  fi

  case "$TEST_MODE" in
    "DRY_RUN"|"SIMULATE")
      log_info "Would validate package"
      return 0
      ;;
  esac

  # Check package.json fields
  local required_fields=("name" "version" "description")
  for field in "${required_fields[@]}"; do
    local value
    value=$(node -e "console.log(JSON.parse(require('fs').readFileSync('package.json', 'utf8')).$field || '')" 2>/dev/null || echo "")
    if [[ -z "$value" ]]; then
      log_error "Required field missing in package.json: $field"
      return 3
    fi
  done

  # Validate version format
  if [[ ! "$PACKAGE_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?$ ]]; then
    log_error "Invalid version format: $PACKAGE_VERSION"
    return 3
  fi

  # Check if build output exists
  if [[ -n "${BUILD_OUTPUT_DIR:-}" && ! -d "$BUILD_OUTPUT_DIR" ]]; then
    log_warning "Build output directory not found: $BUILD_OUTPUT_DIR"
  fi

  log_success "✅ Package validation successful"
  return 0
}

# Publish npm package
publish_package() {
  log_info "Publishing npm package"

  if [[ ! -f "package.json" ]]; then
    log_info "No package.json found, skipping package publishing"
    return 0
  fi

  case "$TEST_MODE" in
    "DRY_RUN")
      log_info "Would publish package: ${PACKAGE_NAME}@${PACKAGE_VERSION}"
      return 0
      ;;
    "SIMULATE")
      log_info "Simulating package publish"
      sleep 2
      return 0
      ;;
  esac

  # Configure npm registry
  local npm_args=()
  if [[ -n "$NPM_REGISTRY" ]]; then
    npm_args+=("--registry" "$NPM_REGISTRY")
  fi

  # Configure publish tag
  if [[ "$PUBLISH_TAG" != "latest" ]]; then
    npm_args+=("--tag" "$PUBLISH_TAG")
  fi

  # Set npm token
  local npm_token="${NPM_TOKEN:-${CI_NPM_TOKEN:-}}"
  if [[ -n "$npm_token" ]]; then
    echo "//${NPM_REGISTRY:-registry.npmjs.org}/:_authToken=$npm_token" > ~/.npmrc
    chmod 600 ~/.npmrc
  fi

  log_info "Publishing package: ${PACKAGE_NAME}@${PACKAGE_VERSION}"
  log_info "npm publish ${npm_args[*]}"

  # Run npm publish
  if npm publish "${npm_args[@]}" --access public; then
    log_success "✅ Package published successfully"
  else
    local exit_code=$?
    log_error "❌ Package publishing failed"
    return $exit_code
  fi

  return 0
}

# Build and publish Docker image
publish_docker_image() {
  log_info "Publishing Docker image"

  if [[ ! -f "Dockerfile" ]]; then
    log_info "No Dockerfile found, skipping Docker publishing"
    return 0
  fi

  case "$TEST_MODE" in
    "DRY_RUN")
      log_info "Would build and push Docker image: ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}"
      return 0
      ;;
    "SIMULATE")
      log_info "Simulating Docker image build and push"
      sleep 3
      return 0
      ;;
  esac

  # Configure Docker registry
  local docker_registry="${DOCKER_REGISTRY:-docker.io}"
  local image_name="${DOCKER_IMAGE_NAME}"
  local image_tag="${DOCKER_IMAGE_TAG}"
  local full_image_name="${docker_registry}/${image_name}:${image_tag}"

  # Login to Docker registry
  local docker_username="${DOCKER_USERNAME:-${CI_DOCKER_USERNAME:-}}"
  local docker_password="${DOCKER_PASSWORD:-${CI_DOCKER_PASSWORD:-}}"
  if [[ -n "$docker_username" && -n "$docker_password" ]]; then
    log_info "Logging into Docker registry: $docker_registry"
    echo "$docker_password" | docker login "$docker_registry" -u "$docker_username" --password-stdin
  fi

  # Build Docker image
  log_info "Building Docker image: $full_image_name"
  if docker build -t "$full_image_name" .; then
    log_success "✅ Docker image built successfully"
  else
    log_error "❌ Docker image build failed"
    return 2
  fi

  # Push Docker image
  log_info "Pushing Docker image: $full_image_name"
  if docker push "$full_image_name"; then
    log_success "✅ Docker image pushed successfully"
  else
    log_error "❌ Docker image push failed"
    return 2
  fi

  return 0
}

# Publish documentation
publish_docs() {
  log_info "Publishing documentation"

  if [[ ! -d "docs" && ! -d ".vitepress" && ! -f "mkdocs.yml" ]]; then
    log_info "No documentation found, skipping docs publishing"
    return 0
  fi

  case "$TEST_MODE" in
    "DRY_RUN")
      log_info "Would publish documentation"
      return 0
      ;;
    "SIMULATE")
      log_info "Simulating documentation publish"
      sleep 2
      return 0
      ;;
  esac

  # Check for GitHub Pages publishing
  if command -v gh >/dev/null 2>&1; then
    log_info "Publishing to GitHub Pages"
    if gh-pages --dist docs --add --message "Update documentation"; then
      log_success "✅ Documentation published to GitHub Pages"
    else
      log_warning "⚠️ GitHub Pages publishing failed"
    fi
  fi

  return 0
}

# Create GitHub release
create_github_release() {
  log_info "Creating GitHub release"

  case "$TEST_MODE" in
    "DRY_RUN")
      log_info "Would create GitHub release: v${PACKAGE_VERSION}"
      return 0
      ;;
    "SIMULATE")
      log_info "Simulating GitHub release creation"
      sleep 2
      return 0
      ;;
  esac

  if ! command -v gh >/dev/null 2>&1; then
    log_warning "GitHub CLI not available, skipping release creation"
    return 0
  fi

  local release_tag="v${PACKAGE_VERSION}"
  local release_title="Release v${PACKAGE_VERSION}"
  local release_notes=""

  # Load release notes from file if provided
  if [[ -n "$RELEASE_NOTES_FILE" && -f "$RELEASE_NOTES_FILE" ]]; then
    release_notes=$(cat "$RELEASE_NOTES_FILE")
  else
    # Generate basic release notes
    release_notes=$(cat << EOF
# Release v${PACKAGE_VERSION}

## Changes
- Bug fixes and improvements
- Updated dependencies

## Installation
\`\`\`bash
npm install ${PACKAGE_NAME}@${PACKAGE_VERSION}
\`\`\`

## Links
- [Documentation](https://github.com/${GITHUB_REPO}#readme)
- [Changelog](https://github.com/${GITHUB_REPO}/blob/main/CHANGELOG.md)
EOF
)
  fi

  log_info "Creating GitHub release: $release_tag"

  # Create GitHub release
  if gh release create "$release_tag" \
    --title "$release_title" \
    --notes "$release_notes" \
    --latest; then
    log_success "✅ GitHub release created successfully"
  else
    log_error "❌ GitHub release creation failed"
    return 2
  fi

  return 0
}

# Generate publish report
generate_publish_report() {
  local publish_status="$1"
  local start_time="$2"
  local end_time=$(date +%s)

  log_info "Generating publish report"

  local publish_duration=$((end_time - start_time))
  local output_dir="${PUBLISH_REPORT_OUTPUT:-reports/publish}"
  mkdir -p "$output_dir"

  local report_file="$output_dir/publish-report-$(date +%Y%m%d-%H%M%S).json"

  # Build report content
  cat > "$report_file" << EOF
{
  "publish": {
    "script": "$SCRIPT_NAME",
    "version": "$SCRIPT_VERSION",
    "status": "$publish_status",
    "type": "$PUBLISH_TYPE",
    "test_mode": "$TEST_MODE",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "duration_seconds": $publish_duration,
    "configuration": {
      "dry_run": "$DRY_RUN",
      "force_publish": "$FORCE_PUBLISH",
      "registry": "${REGISTRY:-default}",
      "publish_tag": "$PUBLISH_TAG"
    }
  },
  "package": {
    "name": "${PACKAGE_NAME:-unknown}",
    "version": "${PACKAGE_VERSION:-unknown}",
    "registry": "${NPM_REGISTRY:-default}"
  },
  "artifacts": {
    "docker_image": "${DOCKER_IMAGE_NAME:-none}",
    "docker_tag": "${DOCKER_IMAGE_TAG:-none}",
    "github_release": "v${PACKAGE_VERSION:-unknown}"
  }
}
EOF

  log_success "✅ Publish report generated: $report_file"

  # Export for CI systems
  export PUBLISH_REPORT_FILE="$report_file"

  return 0
}

# Main publish function
main() {
  local start_time
  start_time=$(date +%s)

  log_info "🚀 Starting CI publish"
  log_info "Script version: $SCRIPT_VERSION"

  # Parse command line arguments
  if ! parse_args "$@"; then
    return 1
  fi

  log_info "Publish configuration:"
  log_info "  Publish type: $PUBLISH_TYPE"
  log_info "  Dry run: $DRY_RUN"
  log_info "  Force publish: $FORCE_PUBLISH"
  log_info "  Skip if unchanged: $SKIP_IF_UNCHANGED"
  log_info "  Registry: ${REGISTRY:-default}"
  log_info "  Tag: $PUBLISH_TAG"
  log_info "  Test mode: $TEST_MODE"

  # Run publish pipeline
  if ! check_prerequisites; then
    return 5
  fi

  if ! configure_publish_environment; then
    return 1
  fi

  if ! check_for_changes; then
    generate_publish_report "skipped" "$start_time"
    return 0
  fi

  local publish_results=()

  # Run publishing based on type
  case "$PUBLISH_TYPE" in
    "package")
      validate_package || publish_results+=("package_validation")
      publish_package || publish_results+=("package")
      ;;
    "docker")
      publish_docker_image || publish_results+=("docker")
      ;;
    "docs")
      publish_docs || publish_results+=("docs")
      ;;
    "release")
      create_github_release || publish_results+=("release")
      ;;
    "all")
      validate_package || publish_results+=("package_validation")
      publish_package || publish_results+=("package")
      publish_docker_image || publish_results+=("docker")
      publish_docs || publish_results+=("docs")
      create_github_release || publish_results+=("release")
      ;;
  esac

  # Determine overall result
  if [[ ${#publish_results[@]} -eq 0 ]]; then
    log_success "✅ Publish completed successfully"
    generate_publish_report "success" "$start_time"

    # Show actionable items for CI
    if [[ -n "${CI:-}" ]]; then
      echo
      log_info "🔗 Next steps for CI pipeline:"
      log_info "   • Deploy to production: scripts/release/60-ci-deploy.sh --environment production"
      log_info "   • Update git tags: scripts/release/50-ci-tag-assignment.sh"
    fi

    return 0
  else
    log_error "❌ Publish failed in: ${publish_results[*]}"
    generate_publish_report "failed" "$start_time"
    return 2
  fi
}

# Error handling
trap 'log_error "Script failed with exit code $?"' ERR

# Execute main function with all arguments
main "$@"