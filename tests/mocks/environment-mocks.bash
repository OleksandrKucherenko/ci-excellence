#!/usr/bin/env bash
# Environment Variable Mocks Library for BATS Testing
# Provides comprehensive environment setup patterns for different test scenarios

# CI Environment Setup
setup_ci_environment() {
    local ci_provider="${1:-github}"

    # Common CI environment variables
    export CI=true
    export CI_COMMIT_SHA="${CI_COMMIT_SHA:-abc123def4567890abcdef1234567890abcdef12}"
    export CI_COMMIT_BRANCH="${CI_COMMIT_BRANCH:-main}"
    export CI_COMMIT_MESSAGE="${CI_COMMIT_MESSAGE:-Test commit}"
    export CI_PIPELINE_ID="${CI_PIPELINE_ID:-12345}"
    export CI_JOB_ID="${CI_JOB_ID:-67890}"

    # GitHub Actions specific
    if [[ "$ci_provider" == "github" ]]; then
        export GITHUB_ACTIONS=true
        export GITHUB_REPOSITORY="${GITHUB_REPOSITORY:-user/repo}"
        export GITHUB_REF="${GITHUB_REF:-refs/heads/main}"
        export GITHUB_SHA="${GITHUB_SHA:-$CI_COMMIT_SHA}"
        export GITHUB_RUN_ID="${GITHUB_RUN_ID:-123456789}"
        export GITHUB_RUN_NUMBER="${GITHUB_RUN_NUMBER:-42}"
        export RUNNER_OS="${RUNNER_OS:-Linux}"
        export RUNNER_ARCH="${RUNNER_ARCH:-X64}"
        export GITHUB_WORKSPACE="${GITHUB_WORKSPACE:-/home/runner/work/repo/repo}"
    fi

    # GitLab CI specific
    if [[ "$ci_provider" == "gitlab" ]]; then
        export GITLAB_CI=true
        export CI_PROJECT_ID="${CI_PROJECT_ID:-1234}"
        export CI_MERGE_REQUEST_ID="${CI_MERGE_REQUEST_ID:-567}"
        export CI_MERGE_REQUEST_IID="${CI_MERGE_REQUEST_IID:-89}"
        export CI_PROJECT_PATH="${CI_PROJECT_PATH:-group/project}"
    fi

    # Jenkins specific
    if [[ "$ci_provider" == "jenkins" ]]; then
        export JENKINS_URL="${JENKINS_URL:-http://jenkins:8080}"
        export JOB_NAME="${JOB_NAME:-test-job}"
        export BUILD_NUMBER="${BUILD_NUMBER:-42}"
        export WORKSPACE="${WORKSPACE:-/var/jenkins/workspace/job}"
    fi
}

# Deployment Environment Setup
setup_deployment_environment() {
    local env="${1:-staging}"
    local region="${2:-us-east}"

    export DEPLOYMENT_ENVIRONMENT="$env"
    export AWS_REGION="${AWS_REGION:-${region}-1}"
    export AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-123456789012}"
    export KUBE_NAMESPACE="${KUBE_NAMESPACE:-${env}}"
    export SERVICE_NAME="${SERVICE_NAME:-test-service}"

    # Environment-specific configurations
    case "$env" in
        "production")
            export DEPLOYMENT_PROFILE="production"
            export LOG_LEVEL="warn"
            export ENABLE_METRICS="true"
            export SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL:-https://hooks.slack.com/production}"
            ;;
        "staging")
            export DEPLOYMENT_PROFILE="staging"
            export LOG_LEVEL="info"
            export ENABLE_METRICS="true"
            export SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL:-https://hooks.slack.com/staging}"
            ;;
        "development")
            export DEPLOYMENT_PROFILE="development"
            export LOG_LEVEL="debug"
            export ENABLE_METRICS="false"
            ;;
        "local")
            export DEPLOYMENT_PROFILE="local"
            export LOG_LEVEL="debug"
            export ENABLE_METRICS="false"
            ;;
    esac
}

# Security Environment Setup
setup_security_environment() {
    export SOPS_AGE_KEY_FILE="${SOPS_AGE_KEY_FILE:-$PROJECT_ROOT/.secrets/mise-age.txt}"
    export AGE_PUBLIC_KEY="${AGE_PUBLIC_KEY:-age1testkey1234567890abcdef}"
    export AGE_PRIVATE_KEY="${AGE_PRIVATE_KEY:-AGE-SECRET-KEY-1234567890ABCDEF}"
    export GITLEAKS_CONFIG="${GITLEAKS_CONFIG:-$PROJECT_ROOT/.gitleaks.toml}"
    export TRUFFLEHOG_CONFIG="${TRUFFLEHOG_CONFIG:-$PROJECT_ROOT/trufflehog.yml}"

    # AWS credentials for deployment
    export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-AKIAIOSFODNN7EXAMPLE}"
    export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY}"
    export AWS_SESSION_TOKEN="${AWS_SESSION_TOKEN:-}"
}

# Test Mode Environment Setup
setup_test_modes() {
    local mode="${1:-EXECUTE}"

    export CI_TEST_MODE="$mode"
    export TEST_TIMEOUT="${TEST_TIMEOUT:-30}"
    export TEST_RETRY_COUNT="${TEST_RETRY_COUNT:-3}"
    export TEST_PARALLEL_JOBS="${TEST_PARALLEL_JOBS:-4}"

    # Configure test-specific environment variables
    case "$mode" in
        "DRY_RUN")
            export DRY_RUN=true
            export SIMULATE_EXECUTION=true
            export SKIP_EXTERNAL_DEPENDENCIES=true
            ;;
        "PASS")
            export FORCE_SUCCESS=true
            export SKIP_VALIDATION=true
            ;;
        "FAIL")
            export FORCE_FAILURE=true
            export INJECT_FAILURES=true
            ;;
        "SKIP")
            export SKIP_EXECUTION=true
            ;;
        "TIMEOUT")
            export SIMULATE_TIMEOUT=true
            export FAKE_TIMEOUT_DELAY="${FAKE_TIMEOUT_DELAY:-5}"
            ;;
        "EXECUTE")
            # Normal execution mode - no special flags
            ;;
    esac
}

# Development Environment Setup
setup_development_environment() {
    local language="${1:-node}"

    export DEVELOPMENT_MODE=true
    export DEBUG="${DEBUG:-true}"
    export VERBOSE="${VERBOSE:-true}"
    export LOG_LEVEL="${LOG_LEVEL:-debug}"
    export HOT_RELOAD="${HOT_RELOAD:-true}"

    case "$language" in
        "node")
            export NODE_ENV="development"
            export npm_config_loglevel="verbose"
            export YARN_ENABLE_PROGRESS_BARS="true"
            ;;
        "python")
            export PYTHONPATH="${PYTHONPATH:-$PROJECT_ROOT/src}"
            export PYTHONDONTWRITEBYTECODE="1"
            export FLASK_ENV="development"
            export FLASK_DEBUG="1"
            ;;
        "go")
            export GOENV="development"
            export GOMOD="${GOMOD:-on}"
            export CGO_ENABLED="${CGO_ENABLED:-1}"
            ;;
        "rust")
            export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-$PROJECT_ROOT/target}"
            export RUST_LOG="debug"
            export RUST_BACKTRACE="1"
            ;;
    esac
}

# Production Environment Setup
setup_production_environment() {
    export NODE_ENV="production"
    export DEBUG=false
    export VERBOSE=false
    export LOG_LEVEL="error"
    export MINIMIZE_LOGS="true"

    # Performance optimizations
    export UV_THREADPOOL_SIZE="16"
    export NODE_OPTIONS="--max-old-space-size=4096"
    export GC_TYPE="incremental"

    # Security hardening
    export HELMET_ENABLED="true"
    export CSRF_PROTECTION="true"
    export RATE_LIMITING="true"
}

# Mock Failure Injection Environment
setup_mock_failure_injection() {
    local failures="$@"

    # Clear existing failure flags
    clear_mock_failures

    # Set failure flags for specified commands
    for failure in $failures; do
        case "$failure" in
            "npm"|"yarn"|"pnpm"|"bun")
                export "FAIL_${failure^^}=true"
                ;;
            "pip"|"go"|"cargo"|"mvn"|"gradle"|"dotnet")
                export "FAIL_${failure^^}=true"
                ;;
            "docker"|"kubectl"|"sops"|"gitleaks"|"trufflehog")
                export "FAIL_${failure^^}=true"
                ;;
            "git")
                export "FAIL_GIT=true"
                ;;
            "mise")
                export "FAIL_MISE=true"
                ;;
            "network")
                export "CURL_MOCK_MODE=fail"
                export "NETWORK_FAILURE=true"
                ;;
            "disk")
                export "DISK_FULL=true"
                export "NO_SPACE_LEFT=true"
                ;;
        esac
    done
}

# Build Environment Setup
setup_build_environment() {
    local project_type="${1:-node}"

    export BUILD_ENVIRONMENT="ci"
    export BUILD_NUMBER="${BUILD_NUMBER:-42}"
    export BUILD_TIMESTAMP="${BUILD_TIMESTAMP:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"
    export BUILD_URL="${BUILD_URL:-https://ci.example.com/build/42}"

    # Configure build-specific variables
    case "$project_type" in
        "node")
            export NODE_ENV="production"
            export npm_config_production="true"
            export NODE_OPTIONS="--max-old-space-size=2048"
            ;;
        "python")
            export PYTHONUNBUFFERED="1"
            export PYTHONDONTWRITEBYTECODE="1"
            export PIP_NO_CACHE_DIR="1"
            export PIP_DISABLE_PIP_VERSION_CHECK="1"
            ;;
        "go")
            export CGO_ENABLED="0"
            export GOOS="linux"
            export GOARCH="amd64"
            export GOMOD="${GOMOD:-on}"
            ;;
        "rust")
            export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-target}"
            export CARGO_PROFILE_RELEASE_LTO="true"
            export CARGO_PROFILE_RELEASE_PANIC="abort"
            ;;
        "java")
            export MAVEN_OPTS="-Xmx1024m"
            export GRADLE_OPTS="-Xmx1024m"
            ;;
        "dotnet")
            export DOTNET_CLI_TELEMETRY_OPTOUT="1"
            export DOTNET_NOLOGO="1"
            ;;
    esac
}

# Container Environment Setup
setup_container_environment() {
    export CONTAINERIZED="true"
    export DOCKER_CONTAINER="true"
    export CONTAINER_USER="${CONTAINER_USER:-ci}"
    export CONTAINER_UID="${CONTAINER_UID:-1000}"
    export CONTAINER_GID="${CONTAINER_GID:-1000}"

    # Container-specific paths
    export WORKSPACE="/workspace"
    export ARTIFACTS_DIR="/tmp/artifacts"
    export CACHE_DIR="/tmp/cache"

    # Docker environment variables
    export DOCKER_REGISTRY="${DOCKER_REGISTRY:-docker.io}"
    export DOCKER_IMAGE="${DOCKER_IMAGE:-test-app:latest}"
    export DOCKER_TAG="${DOCKER_TAG:-latest}"
}

# Notification Environment Setup
setup_notification_environment() {
    local notifications_enabled="${1:-true}"

    export NOTIFICATIONS_ENABLED="$notifications_enabled"

    if [[ "$notifications_enabled" == "true" ]]; then
        export SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL:-https://hooks.slack.com/services/test}"
        export DISCORD_WEBHOOK_URL="${DISCORD_WEBHOOK_URL:-https://discord.com/api/webhooks/test}"
        export EMAIL_SMTP_HOST="${EMAIL_SMTP_HOST:-smtp.example.com}"
        export EMAIL_FROM="${EMAIL_FROM:-ci@example.com}"
        export EMAIL_TO="${EMAIL_TO:-team@example.com}"

        # Notification preferences
        export NOTIFY_ON_SUCCESS="${NOTIFY_ON_SUCCESS:-false}"
        export NOTIFY_ON_FAILURE="${NOTIFY_ON_FAILURE:-true}"
        export NOTIFY_ON_DEPLOY="${NOTIFY_ON_DEPLOY:-true}"
        export NOTIFY_ROLLOUT="${NOTIFY_ROLLOUT:-true}"
    fi
}

# Environment Cleanup Function
cleanup_environment_mocks() {
    # Unset common CI variables
    unset CI GITHUB_ACTIONS GITLAB_CI JENKINS_URL
    unset CI_COMMIT_SHA CI_COMMIT_BRANCH CI_COMMIT_MESSAGE
    unset CI_PIPELINE_ID CI_JOB_ID GITHUB_REPOSITORY GITHUB_REF
    unset GITHUB_SHA GITHUB_RUN_ID GITHUB_RUN_NUMBER RUNNER_OS

    # Unset deployment variables
    unset DEPLOYMENT_ENVIRONMENT AWS_REGION AWS_ACCOUNT_ID KUBE_NAMESPACE
    unset SERVICE_NAME DEPLOYMENT_PROFILE LOG_LEVEL ENABLE_METRICS

    # Unset security variables
    unset SOPS_AGE_KEY_FILE AGE_PUBLIC_KEY AGE_PRIVATE_KEY
    unset GITLEAKS_CONFIG TRUFFLEHOG_CONFIG
    unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

    # Unset test mode variables
    unset CI_TEST_MODE TEST_TIMEOUT TEST_RETRY_COUNT TEST_PARALLEL_JOBS
    unset DRY_RUN SIMULATE_EXECUTION SKIP_EXTERNAL_DEPENDENCIES
    unset FORCE_SUCCESS SKIP_VALIDATION FORCE_FAILURE INJECT_FAILURES
    unset SKIP_EXECUTION SIMULATE_TIMEOUT FAKE_TIMEOUT_DELAY

    # Clear mock failures
    clear_mock_failures

    # Unset development variables
    unset DEVELOPMENT_MODE DEBUG VERBOSE LOG_LEVEL HOT_RELOAD
    unset NODE_ENV PYTHONPATH GOENV CGO_ENABLED RUST_LOG

    # Unset build variables
    unset BUILD_ENVIRONMENT BUILD_NUMBER BUILD_TIMESTAMP BUILD_URL
    unset npm_config_production NODE_OPTIONS PYTHONUNBUFFERED

    # Unset container variables
    unset CONTAINERIZED DOCKER_CONTAINER CONTAINER_USER
    unset WORKSPACE ARTIFACTS_DIR CACHE_DIR

    # Unset notification variables
    unset NOTIFICATIONS_ENABLED SLACK_WEBHOOK_URL DISCORD_WEBHOOK_URL
    unset EMAIL_SMTP_HOST EMAIL_FROM EMAIL_TO
    unset NOTIFY_ON_SUCCESS NOTIFY_ON_FAILURE NOTIFY_ON_DEPLOY NOTIFY_ROLLOUT
}