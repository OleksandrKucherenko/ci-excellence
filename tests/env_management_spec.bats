#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/test_helper.bash"

# Setup and teardown
setup() {
    setup_test_project
    setup_profile_switching_test
}

teardown() {
    cleanup_test_project
}

# Helper function to create test environment scripts if they don't exist
create_test_env_scripts() {
    # Create env-create.sh mock if it doesn't exist
    if [[ ! -f "$TEST_PROFILE_DIR/env-create.sh" ]]; then
        cat > "$TEST_PROFILE_DIR/env-create.sh" << 'EOF'
#!/bin/bash
# Mock env-create script for testing
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/scripts/lib/common.sh" 2>/dev/null || exit 1

readonly SCRIPT_VERSION="1.0.0"
readonly DEFAULT_ENVIRONMENTS=("staging" "production")

usage() {
    cat << EOF
Usage: $0 <environment-name> [options]

Create a new environment with inheritance.

Options:
  --extends ENV        Inherit from existing environment
  --type TYPE          Environment type (development|testing|staging|production)
  --description DESC   Environment description
  --region REGION      Add region configuration
  --dry-run            Show what would be done without creating
  --help               Show this help message
EOF
}

validate_environment_name() {
    local env_name="$1"

    if [[ -z "$env_name" ]]; then
        log_error "Environment name is required"
        return 1
    fi

    if [[ ! "$env_name" =~ ^[a-z][a-z0-9-]*$ ]]; then
        log_error "Invalid environment name: $env_name"
        log_error "Environment names must start with lowercase letter and contain only lowercase letters, numbers, and hyphens"
        return 1
    fi

    if array_contains "$env_name" "${DEFAULT_ENVIRONMENTS[@]}"; then
        log_error "Cannot create default environment: $env_name"
        return 1
    fi
}

create_environment_directory() {
    local env_name="$1"
    local env_dir="$PROJECT_ROOT/environments/$env_name"

    if [[ -d "$env_dir" ]]; then
        log_error "Environment already exists: $env_name"
        return 1
    fi

    mkdir -p "$env_dir"
    log_success "Created environment directory: $env_dir"
}

create_environment_config() {
    local env_name="$1"
    local extends="${2:-}"
    local env_type="${3:-testing}"
    local description="${4:-}"

    local env_dir="$PROJECT_ROOT/environments/$env_name"
    local config_file="$env_dir/config.yml"

    cat > "$config_file" << YAML
environment:
  type: $env_type
  description: "${description:-$env_name environment}"
  created: "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

YAML

    if [[ -n "$extends" ]]; then
        cat >> "$config_file" << YAML
extends: $extends

YAML
    fi

    log_success "Created environment configuration: $config_file"
}

add_region() {
    local env_name="$1"
    local region="$2"

    local env_dir="$PROJECT_ROOT/environments/$env_name"
    local region_dir="$env_dir/regions/$region"

    mkdir -p "$region_dir"

    cat > "$region_dir/config.yml" << YAML
region:
  name: $region
  description: "$region region configuration"
  created: "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

YAML

    log_success "Added region: $region_dir"
}

main() {
    local env_name=""
    local extends=""
    local env_type="testing"
    local description=""
    local regions=()
    local dry_run=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --extends)
                extends="$2"
                shift 2
                ;;
            --type)
                env_type="$2"
                shift 2
                ;;
            --description)
                description="$2"
                shift 2
                ;;
            --region)
                regions+=("$2")
                shift 2
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --help)
                usage
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                if [[ -z "$env_name" ]]; then
                    env_name="$1"
                else
                    log_error "Unexpected argument: $1"
                    usage
                    exit 1
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$env_name" ]]; then
        log_error "Environment name is required"
        usage
        exit 1
    fi

    validate_environment_name "$env_name"

    if [[ "$dry_run" == "true" ]]; then
        log_info "DRY RUN: Would create environment: $env_name"
        [[ -n "$extends" ]] && log_info "  Extends: $extends"
        log_info "  Type: $env_type"
        [[ -n "$description" ]] && log_info "  Description: $description"
        [[ ${#regions[@]} -gt 0 ]] && log_info "  Regions: ${regions[*]}"
        return 0
    fi

    create_environment_directory "$env_name"
    create_environment_config "$env_name" "$extends" "$env_type" "$description"

    for region in "${regions[@]}"; do
        add_region "$env_name" "$region"
    done

    log_success "Environment created successfully: $env_name"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
EOF
        chmod +x "$TEST_PROFILE_DIR/env-create.sh"
    fi

    # Create env-delete.sh mock if it doesn't exist
    if [[ ! -f "$TEST_PROFILE_DIR/env-delete.sh" ]]; then
        cat > "$TEST_PROFILE_DIR/env-delete.sh" << 'EOF'
#!/bin/bash
# Mock env-delete script for testing
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/scripts/lib/common.sh" 2>/dev/null || exit 1

readonly SCRIPT_VERSION="1.0.0"
readonly DEFAULT_ENVIRONMENTS=("staging" "production")

usage() {
    cat << EOF
Usage: $0 <environment-name> [options]

Delete an environment (custom environments only).

Options:
  --force              Skip confirmation prompt
  --dry-run            Show what would be deleted without deleting
  --help               Show this help message
EOF
}

validate_environment_name() {
    local env_name="$1"

    if [[ -z "$env_name" ]]; then
        log_error "Environment name is required"
        return 1
    fi

    if array_contains "$env_name" "${DEFAULT_ENVIRONMENTS[@]}"; then
        log_error "Cannot delete default environment: $env_name"
        return 1
    fi
}

delete_environment() {
    local env_name="$1"
    local env_dir="$PROJECT_ROOT/environments/$env_name"

    if [[ ! -d "$env_dir" ]]; then
        log_error "Environment not found: $env_name"
        return 1
    fi

    rm -rf "$env_dir"
    log_success "Deleted environment: $env_name"
}

main() {
    local env_name=""
    local force=false
    local dry_run=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --force)
                force=true
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --help)
                usage
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                if [[ -z "$env_name" ]]; then
                    env_name="$1"
                else
                    log_error "Unexpected argument: $1"
                    usage
                    exit 1
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$env_name" ]]; then
        log_error "Environment name is required"
        usage
        exit 1
    fi

    validate_environment_name "$env_name"

    if [[ "$dry_run" == "true" ]]; then
        log_info "DRY RUN: Would delete environment: $env_name"
        return 0
    fi

    delete_environment "$env_name"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
EOF
        chmod +x "$TEST_PROFILE_DIR/env-delete.sh"
    fi

    # Create env-validate.sh mock if it doesn't exist
    if [[ ! -f "$TEST_PROFILE_DIR/env-validate.sh" ]]; then
        cat > "$TEST_PROFILE_DIR/env-validate.sh" << 'EOF'
#!/bin/bash
# Mock env-validate script for testing
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/scripts/lib/common.sh" 2>/dev/null || exit 1

readonly SCRIPT_VERSION="1.0.0"

validate_environment() {
    local env_name="$1"
    local env_dir="$PROJECT_ROOT/environments/$env_name"

    if [[ ! -d "$env_dir" ]]; then
        log_error "Environment directory not found: $env_dir"
        return 1
    fi

    local issues=0

    # Check config file
    local config_file="$env_dir/config.yml"
    if [[ ! -f "$config_file" ]]; then
        log_error "Config file not found: $config_file"
        ((issues++))
    else
        # Mock YAML validation
        log_success "Config file found: $config_file"
    fi

    # Check regions
    local regions_dir="$env_dir/regions"
    if [[ -d "$regions_dir" ]]; then
        local region_count
        region_count=$(find "$regions_dir" -mindepth 1 -maxdepth 1 -type d | wc -l)
        log_info "Found $region_count region(s)"
    fi

    if [[ $issues -eq 0 ]]; then
        log_success "Environment validation passed: $env_name"
        return 0
    else
        log_error "Environment validation failed: $env_name ($issues issues)"
        return 1
    fi
}

main() {
    if [[ $# -lt 1 ]]; then
        log_error "Usage: $0 <environment-name>"
        exit 1
    fi

    local env_name="$1"

    log_info "Validating environment: $env_name"
    validate_environment "$env_name"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
EOF
        chmod +x "$TEST_PROFILE_DIR/env-validate.sh"
    fi
}

# Tests for env-create.sh
@test "env-create shows help with --help flag" {
    create_test_env_scripts

    run run_profile_script "env-create.sh" "--help"

    assert_success
    assert_output --partial "Usage:"
    assert_output --partial "Create a new environment with inheritance"
}

@test "env-create validates environment name format" {
    create_test_env_scripts

    # Test invalid names
    run run_profile_script "env-create.sh" ""
    assert_failure
    assert_output --partial "Environment name is required"

    run run_profile_script "env-create.sh" "Invalid_Name"
    assert_failure
    assert_output --partial "Invalid environment name"

    run run_profile_script "env-create.sh" "123invalid"
    assert_failure
    assert_output --partial "Invalid environment name"
}

@test "env-create prevents creating default environments" {
    create_test_env_scripts

    for default_env in "staging" "production"; do
        run run_profile_script "env-create.sh" "$default_env"
        assert_failure
        assert_output --partial "Cannot create default environment: $default_env"
    done
}

@test "env-create creates environment directory" {
    create_test_env_scripts

    run run_profile_script "env-create.sh" "test-env"

    assert_success
    assert_output --partial "Created environment directory:"
    assert [ -d "$TEST_PROFILES_DIR/test-env" ]
}

@test "env-create creates configuration file" {
    create_test_env_scripts

    run run_profile_script "env-create.sh" "test-env"

    assert_success
    assert [ -f "$TEST_PROFILES_DIR/test-env/config.yml" ]
    assert_file_contains "$TEST_PROFILES_DIR/test-env/config.yml" "environment:"
    assert_file_contains "$TEST_PROFILES_DIR/test-env/config.yml" "type: testing"
}

@test "env-create handles inheritance" {
    create_test_env_scripts

    run run_profile_script "env-create.sh" "test-env" --extends "base-env"

    assert_success
    assert_file_contains "$TEST_PROFILES_DIR/test-env/config.yml" "extends: base-env"
}

@test "env-create handles custom type and description" {
    create_test_env_scripts

    run run_profile_script "env-create.sh" "test-env" \
        --type "development" \
        --description "Test development environment"

    assert_success
    assert_file_contains "$TEST_PROFILES_DIR/test-env/config.yml" "type: development"
    assert_file_contains "$TEST_PROFILES_DIR/test-env/config.yml" "description: \"Test development environment\""
}

@test "env-create adds regions" {
    create_test_env_scripts

    run run_profile_script "env-create.sh" "test-env" \
        --region "us-east" \
        --region "us-west"

    assert_success
    assert [ -d "$TEST_PROFILES_DIR/test-env/regions/us-east" ]
    assert [ -d "$TEST_PROFILES_DIR/test-env/regions/us-west" ]
    assert [ -f "$TEST_PROFILES_DIR/test-env/regions/us-east/config.yml" ]
    assert [ -f "$TEST_PROFILES_DIR/test-env/regions/us-west/config.yml" ]
}

@test "env-create handles dry-run mode" {
    create_test_env_scripts

    run run_profile_script "env-create.sh" "test-env" --dry-run

    assert_success
    assert_output --partial "DRY RUN: Would create environment: test-env"
    assert [ ! -d "$TEST_PROFILES_DIR/test-env" ]
}

@test "env-create fails for existing environment" {
    create_test_env_scripts

    # Create environment first
    mkdir -p "$TEST_PROFILES_DIR/test-env"

    run run_profile_script "env-create.sh" "test-env"

    assert_failure
    assert_output --partial "Environment already exists: test-env"
}

@test "env-create rejects unknown options" {
    create_test_env_scripts

    run run_profile_script "env-create.sh" "test-env" --unknown-option

    assert_failure
    assert_output --partial "Unknown option: --unknown-option"
}

# Tests for env-delete.sh
@test "env-delete shows help with --help flag" {
    create_test_env_scripts

    run run_profile_script "env-delete.sh" "--help"

    assert_success
    assert_output --partial "Usage:"
    assert_output --partial "Delete an environment (custom environments only)"
}

@test "env-delete validates environment name is required" {
    create_test_env_scripts

    run run_profile_script "env-delete.sh"

    assert_failure
    assert_output --partial "Environment name is required"
}

@test "env-delete prevents deleting default environments" {
    create_test_env_scripts

    for default_env in "staging" "production"; do
        run run_profile_script "env-delete.sh" "$default_env"
        assert_failure
        assert_output --partial "Cannot delete default environment: $default_env"
    done
}

@test "env-delete deletes existing environment" {
    create_test_env_scripts

    # Create test environment
    mkdir -p "$TEST_PROFILES_DIR/test-env"
    touch "$TEST_PROFILES_DIR/test-env/config.yml"
    mkdir -p "$TEST_PROFILES_DIR/test-env/regions/us-east"
    touch "$TEST_PROFILES_DIR/test-env/regions/us-east/config.yml"

    run run_profile_script "env-delete.sh" "test-env" --force

    assert_success
    assert_output --partial "Deleted environment: test-env"
    assert [ ! -d "$TEST_PROFILES_DIR/test-env" ]
}

@test "env-delete fails for nonexistent environment" {
    create_test_env_scripts

    run run_profile_script "env-delete.sh" "nonexistent-env"

    assert_failure
    assert_output --partial "Environment not found: nonexistent-env"
}

@test "env-delete handles dry-run mode" {
    create_test_env_scripts

    # Create test environment
    mkdir -p "$TEST_PROFILES_DIR/test-env"

    run run_profile_script "env-delete.sh" "test-env" --dry-run

    assert_success
    assert_output --partial "DRY RUN: Would delete environment: test-env"
    assert [ -d "$TEST_PROFILES_DIR/test-env" ]  # Should still exist
}

# Tests for env-validate.sh
@test "env-validate validates environment successfully" {
    create_test_env_scripts

    # Create valid environment
    mkdir -p "$TEST_PROFILES_DIR/test-env"
    cat > "$TEST_PROFILES_DIR/test-env/config.yml" << 'EOF'
environment:
  type: testing
  description: Test environment
EOF

    run run_profile_script "env-validate.sh" "test-env"

    assert_success
    assert_output --partial "Validating environment: test-env"
    assert_output --partial "Environment validation passed: test-env"
}

@test "env-validate fails for missing environment" {
    create_test_env_scripts

    run run_profile_script "env-validate.sh" "nonexistent-env"

    assert_failure
    assert_output --partial "Environment directory not found"
}

@test "env-validate fails for missing config file" {
    create_test_env_scripts

    # Create environment directory but no config
    mkdir -p "$TEST_PROFILES_DIR/test-env"

    run run_profile_script "env-validate.sh" "test-env"

    assert_failure
    assert_output --partial "Config file not found"
}

@test "env-validate counts regions" {
    create_test_env_scripts

    # Create environment with regions
    mkdir -p "$TEST_PROFILES_DIR/test-env"
    touch "$TEST_PROFILES_DIR/test-env/config.yml"
    mkdir -p "$TEST_PROFILES_DIR/test-env/regions"/{us-east,us-west,eu-west}

    run run_profile_script "env-validate.sh" "test-env"

    assert_success
    assert_output --partial "Found 3 region(s)"
}

@test "env-validate shows usage when no arguments" {
    create_test_env_scripts

    run run_profile_script "env-validate.sh"

    assert_failure
    assert_output --partial "Usage: $0 <environment-name>"
}

# Test integration between scripts
@test "environment management workflow integration" {
    create_test_env_scripts

    # Create environment
    run run_profile_script "env-create.sh" "integration-test" \
        --type "development" \
        --description "Integration test environment" \
        --region "us-east"

    assert_success
    assert [ -d "$TEST_PROFILES_DIR/integration-test" ]

    # Validate environment
    run run_profile_script "env-validate.sh" "integration-test"

    assert_success

    # Delete environment
    run run_profile_script "env-delete.sh" "integration-test" --force

    assert_success
    assert [ ! -d "$TEST_PROFILES_DIR/integration-test" ]
}

# Test error handling
@test "environment scripts handle missing dependencies gracefully" {
    create_test_env_scripts

    # Temporarily move common library
    mv "$TEST_LIB_DIR/common.sh" "$TEST_LIB_DIR/common.sh.bak"

    run run_profile_script "env-create.sh" "test-env"

    assert_failure  # Should exit with error when common library missing

    # Restore library
    mv "$TEST_LIB_DIR/common.sh.bak" "$TEST_LIB_DIR/common.sh"
}

@test "environment scripts handle permission issues" {
    create_test_env_scripts

    # Create readonly environments directory
    chmod 444 "$TEST_PROFILES_DIR"

    run run_profile_script "env-create.sh" "test-env"

    assert_failure

    # Restore permissions
    chmod 755 "$TEST_PROFILES_DIR"
}