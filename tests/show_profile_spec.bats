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

# Test script behavior modes
@test "show-profile script shows help with --help flag" {
    run run_profile_script "show-profile.sh" "help"

    assert_success
    assert_output --partial "Profile Status Display v1.0.0"
    assert_output --partial "Usage:"
    assert_output --partial "Actions:"
}

@test "show-profile script shows help with -h flag" {
    run run_profile_script "show-profile.sh" "-h"

    assert_success
    assert_output --partial "Profile Status Display v1.0.0"
}

@test "show-profile script handles DRY_RUN mode" {
    export CI_PROFILE_STATUS_BEHAVIOR="DRY_RUN"

    run run_profile_script "show-profile.sh" "status"

    assert_success
    assert_output --partial "DRY RUN: Would show profile status"
}

@test "show-profile script handles PASS mode" {
    export CI_PROFILE_STATUS_BEHAVIOR="PASS"

    run run_profile_script "show-profile.sh" "status"

    assert_success
    assert_output --partial "PASS MODE: Profile status displayed successfully"
}

@test "show-profile script handles FAIL mode" {
    export CI_PROFILE_STATUS_BEHAVIOR="FAIL"

    run run_profile_script "show-profile.sh" "status"

    assert_failure
    assert_output --partial "FAIL MODE: Simulating profile status display failure"
}

@test "show-profile script handles SKIP mode" {
    export CI_PROFILE_STATUS_BEHAVIOR="SKIP"

    run run_profile_script "show-profile.sh" "status"

    assert_success
    assert_output --partial "SKIP MODE: Profile status display skipped"
}

@test "show-profile script handles TIMEOUT mode" {
    export CI_PROFILE_STATUS_BEHAVIOR="TIMEOUT"

    run run_profile_script "show-profile.sh" "status"

    assert_failure 124  # Timeout exit code
    assert_output --partial "TIMEOUT MODE: Simulating profile status display timeout"
}

# Test profile information retrieval
@test "get_profile_info returns profile:region format" {
    export DEPLOYMENT_PROFILE="staging"
    export DEPLOYMENT_REGION="us-east"

    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_PROFILE_DIR/show-profile.sh'
        get_profile_info
    "

    assert_success
    assert_output "staging:us-east"
}

@test "get_profile_info uses default values when not set" {
    unset DEPLOYMENT_PROFILE DEPLOYMENT_REGION

    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_PROFILE_DIR/show-profile.sh'
        get_profile_info
    "

    assert_success
    assert_output "local:"
}

@test "get_profile_info uses provided parameters" {
    export DEPLOYMENT_PROFILE="production"
    export DEPLOYMENT_REGION="us-west"

    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_PROFILE_DIR/show-profile.sh'
        get_profile_info 'staging' 'us-east'
    "

    assert_success
    assert_output "staging:us-east"
}

# Test detailed profile status display
@test "show_profile_status displays comprehensive information" {
    export DEPLOYMENT_PROFILE="staging"
    export DEPLOYMENT_REGION="us-east"
    export ENVIRONMENT_CONTEXT="staging"

    # Create necessary directories and files
    mkdir -p "$TEST_PROFILES_DIR/staging/subdir1" "$TEST_PROFILES_DIR/staging/subdir2"
    touch "$TEST_PROFILES_DIR/staging/config.yml"
    touch "$TEST_PROFILES_DIR/staging/secrets.enc"

    run run_profile_script "show-profile.sh" "status"

    assert_success
    assert_output --partial "Deployment Profile Status"
    assert_output --partial "Profile Information:"
    assert_output --partial "Current Profile: staging"
    assert_output --partial "Environment Context: staging"
    assert_output --partial "Deployment Region: us-east"
    assert_output --partial "Configuration Root: $TEST_PROFILES_DIR"
}

@test "show_profile_status displays directory structure" {
    export DEPLOYMENT_PROFILE="staging"

    # Create subdirectories
    mkdir -p "$TEST_PROFILES_DIR/staging"/{regions,secrets,config}

    run run_profile_script "show-profile.sh" "status"

    assert_success
    assert_output --partial "Directory Structure:"
    assert_output --partial "Profile Directory: ✅ $TEST_PROFILES_DIR/staging"
    assert_output --partial "Subdirectories:"
    assert_output --partial "regions, secrets, config"
}

@test "show_profile_status handles missing profile directory" {
    export DEPLOYMENT_PROFILE="nonexistent"

    run run_profile_script "show-profile.sh" "status"

    assert_success
    assert_output --partial "Profile Directory: ❌ Not found: $TEST_PROFILES_DIR/nonexistent"
}

@test "show_profile_status displays configuration files" {
    export DEPLOYMENT_PROFILE="staging"

    # Create config and secrets files
    touch "$TEST_PROFILES_DIR/staging/config.yml"
    touch "$TEST_PROFILES_DIR/staging/secrets.enc"

    run run_profile_script "show-profile.sh" "status"

    assert_success
    assert_output --partial "Configuration Files:"
    assert_output --partial "Main Config: ✅ $TEST_PROFILES_DIR/staging/config.yml"
    assert_output --partial "Secrets File: 🔒 $TEST_PROFILES_DIR/staging/secrets.enc"
}

@test "show_profile_status handles missing configuration files" {
    export DEPLOYMENT_PROFILE="staging"

    # Create directory but no files
    mkdir -p "$TEST_PROFILES_DIR/staging"

    run run_profile_script "show-profile.sh" "status"

    assert_success
    assert_output --partial "Main Config: ❌ Not found"
    assert_output --partial "Secrets File: ❌ Not found"
}

@test "show_profile_status shows configuration preview when detailed" {
    export DEPLOYMENT_PROFILE="staging"

    # Create config file with content
    cat > "$TEST_PROFILES_DIR/staging/config.yml" << 'EOF'
environment:
  type: staging
  description: Staging environment
  created: "2025-01-01"

services:
  - name: web
    version: "1.0.0"
    replicas: 2
  - name: api
    version: "1.0.0"
    replicas: 1

regions:
  us-east:
    description: US East Coast
  us-west:
    description: US West Coast
EOF

    run run_profile_script "show-profile.sh" "status" "staging" "" "true"

    assert_success
    assert_output --partial "Configuration Preview:"
    # Should show YAML content preview
}

@test "show_profile_status shows secrets information when detailed" {
    export DEPLOYMENT_PROFILE="staging"

    # Create secrets file
    touch "$TEST_PROFILES_DIR/staging/secrets.enc"

    run run_profile_script "show-profile.sh" "status" "staging" "" "true"

    assert_success
    # Should show secrets status
    assert_output --partial "Secret Entries:"
}

@test "show_profile_status displays region configuration" {
    export DEPLOYMENT_PROFILE="staging"
    export DEPLOYMENT_REGION="us-east"

    # Create region directory and config
    mkdir -p "$TEST_PROFILES_DIR/staging/regions/us-east"
    cat > "$TEST_PROFILES_DIR/staging/regions/us-east/config.yml" << 'EOF'
region:
  name: us-east
  description: US East Coast

infrastructure:
  provider: aws
  region: us-east-1

services:
  - endpoint: https://staging.example.com
    port: 443
EOF

    run run_profile_script "show-profile.sh" "status"

    assert_success
    assert_output --partial "Region Configuration:"
    assert_output --partial "Region Directory: ✅ $TEST_PROFILES_DIR/staging/regions/us-east"
    assert_output --partial "Region Config: ✅ $TEST_PROFILES_DIR/staging/regions/us-east/config.yml"
}

@test "show_profile_status shows available regions when detailed" {
    export DEPLOYMENT_PROFILE="staging"

    # Create multiple regions
    mkdir -p "$TEST_PROFILES_DIR/staging/regions"/{us-east,us-west,eu-west}
    touch "$TEST_PROFILES_DIR/staging/regions/us-east/config.yml"
    touch "$TEST_PROFILES_DIR/staging/regions/us-west/config.yml"
    # Leave eu-west without config

    run run_profile_script "show-profile.sh" "status" "staging" "" "true"

    assert_success
    assert_output --partial "Available Regions:"
    assert_output --partial "✓ us-east"
    assert_output --partial "✓ us-west"
    assert_output --partial "✗ eu-west"
}

@test "show_profile_status displays environment variables" {
    export DEPLOYMENT_PROFILE="staging"
    export DEPLOYMENT_REGION="us-east"
    export ENVIRONMENT_CONTEXT="staging"
    export CI_JOB_TIMEOUT_MINUTES="60"
    export CI_TEST_MODE="false"

    run run_profile_script "show-profile.sh" "status"

    assert_success
    assert_output --partial "Environment Variables:"
    assert_output --partial "DEPLOYMENT_PROFILE: staging"
    assert_output --partial "DEPLOYMENT_REGION: us-east"
    assert_output --partial "ENVIRONMENT_CONTEXT: staging"
    assert_output --partial "CI_JOB_TIMEOUT_MINUTES: 60"
    assert_output --partial "CI_TEST_MODE: false"
}

@test "show_profile_status shows unset environment variables" {
    unset DEPLOYMENT_PROFILE DEPLOYMENT_REGION ENVIRONMENT_CONTEXT

    run run_profile_script "show-profile.sh" "status"

    assert_success
    assert_output --partial "Environment Variables:"
    assert_output --partial "DEPLOYMENT_PROFILE: (not set)"
    assert_output --partial "DEPLOYMENT_REGION: (not set)"
    assert_output --partial "ENVIRONMENT_CONTEXT: (not set)"
}

@test "show_profile_status displays quick actions" {
    run run_profile_script "show-profile.sh" "status"

    assert_success
    assert_output --partial "Quick Actions:"
    assert_output --partial "Switch profile: mise run switch-profile <profile>"
    assert_output --partial "Edit secrets: mise run edit-secrets"
    assert_output --partial "List profiles: mise run switch-profile list"
    assert_output --partial "Validate tools: mise run verify-tools"
}

@test "show_profile_status displays shell integration when available" {
    run run_profile_script "show-profile.sh" "status"

    assert_success
    assert_output --partial "Shell Integration:"
    assert_output --partial "ZSH plugin available: scripts/shell/mise-profile.plugin.zsh"
    assert_output --partial "Commands: mise_switch <profile>, mise_profile_status"
}

# Test summary status display
@test "show_summary_status displays compact information" {
    export DEPLOYMENT_PROFILE="staging"
    export DEPLOYMENT_REGION="us-east"
    export ENVIRONMENT_CONTEXT="staging"

    # Create config and secrets files
    touch "$TEST_PROFILES_DIR/staging/config.yml"
    touch "$TEST_PROFILES_DIR/staging/secrets.enc"

    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_PROFILE_DIR/show-profile.sh'
        show_summary_status
    "

    assert_success
    assert_output --partial "[staging|us-east]"
    assert_output --partial "(staging)"
    assert_output --partial "Config:✓"
    assert_output --partial "Secrets:🔒"
}

@test "show_summary_status handles missing files" {
    export DEPLOYMENT_PROFILE="staging"
    export ENVIRONMENT_CONTEXT="staging"

    # Don't create config or secrets files

    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_PROFILE_DIR/show-profile.sh'
        show_summary_status
    "

    assert_success
    assert_output --partial "[staging]"
    assert_output --partial "(staging)"
    assert_output --partial "Config:✗"
    assert_output --partial "Secrets:✗"
}

@test "show_summary_status handles profile without region" {
    export DEPLOYMENT_PROFILE="staging"
    export ENVIRONMENT_CONTEXT="staging"

    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_PROFILE_DIR/show-profile.sh'
        show_summary_status
    "

    assert_success
    assert_output --partial "[staging]"
    # Should not contain pipe character for region
    assert_output --not --partial "[staging|"
}

# Test profile validation
@test "validate_profile validates successful configuration" {
    export DEPLOYMENT_PROFILE="staging"
    export ENVIRONMENT_CONTEXT="staging"

    # Create necessary files
    mkdir -p "$TEST_PROFILES_DIR/staging"
    touch "$TEST_PROFILES_DIR/staging/config.yml"
    touch "$TEST_PROFILES_DIR/staging/secrets.enc"

    run run_profile_script "show-profile.sh" "validate"

    assert_success
    assert_output --partial "Validating profile configuration: staging"
    assert_output --partial "✅ Profile configuration is valid: staging"
}

@test "validate_profile fails for missing profile directory" {
    export DEPLOYMENT_PROFILE="nonexistent"

    run run_profile_script "show-profile.sh" "validate"

    assert_failure
    assert_output --partial "Profile directory not found: $TEST_PROFILES_DIR/nonexistent"
}

@test "validate_profile fails for missing config file" {
    export DEPLOYMENT_PROFILE="staging"

    # Create directory but no config
    mkdir -p "$TEST_PROFILES_DIR/staging"

    run run_profile_script "show-profile.sh" "validate"

    assert_failure
    assert_output --partial "Config file not found: $TEST_PROFILES_DIR/staging/config.yml"
}

@test "validate_profile warns about missing secrets file" {
    export DEPLOYMENT_PROFILE="staging"
    export ENVIRONMENT_CONTEXT="staging"

    # Create config but no secrets
    mkdir -p "$TEST_PROFILES_DIR/staging"
    touch "$TEST_PROFILES_DIR/staging/config.yml"

    run run_profile_script "show-profile.sh" "validate"

    assert_failure
    assert_output --partial "Secrets file not found: $TEST_PROFILES_DIR/staging/secrets.enc"
}

@test "validate_profile checks environment variables" {
    unset DEPLOYMENT_PROFILE ENVIRONMENT_CONTEXT

    # Create necessary files
    mkdir -p "$TEST_PROFILES_DIR/local"
    touch "$TEST_PROFILES_DIR/local/config.yml"

    run run_profile_script "show-profile.sh" "validate" "local"

    assert_failure
    assert_output --partial "DEPLOYMENT_PROFILE environment variable not set"
}

@test "validate_profile checks ENVIRONMENT_CONTEXT for non-local profiles" {
    export DEPLOYMENT_PROFILE="staging"
    unset ENVIRONMENT_CONTEXT

    # Create necessary files
    mkdir -p "$TEST_PROFILES_DIR/staging"
    touch "$TEST_PROFILES_DIR/staging/config.yml"

    run run_profile_script "show-profile.sh" "validate"

    assert_failure
    assert_output --partial "ENVIRONMENT_CONTEXT environment variable not set"
}

# Test config action
@test "config action shows profile configuration only" {
    export DEPLOYMENT_PROFILE="staging"
    export DEPLOYMENT_REGION="us-east"

    # Create config file
    cat > "$TEST_PROFILES_DIR/staging/config.yml" << 'EOF'
environment:
  type: staging
  description: Staging environment
EOF

    run run_profile_script "show-profile.sh" "config" "staging" "us-east"

    assert_success
    assert_output --partial "Profile Information:"
    assert_output --partial "Current Profile: staging"
    assert_output --partial "Configuration Preview:"
}

@test "config action requires profile argument" {
    run run_profile_script "show-profile.sh" "config"

    assert_failure
    assert_output --partial "Usage: $0 config <profile>"
}

# Test different action arguments
@test "show-profile handles status action (default)" {
    export DEPLOYMENT_PROFILE="staging"

    run run_profile_script "show-profile.sh"

    assert_success
    assert_output --partial "Deployment Profile Status"
}

@test "show-profile handles explicit status action" {
    export DEPLOYMENT_PROFILE="staging"

    run run_profile_script "show-profile.sh" "status"

    assert_success
    assert_output --partial "Deployment Profile Status"
}

@test "show-profile handles summary action" {
    export DEPLOYMENT_PROFILE="staging"

    run run_profile_script "show-profile.sh" "summary"

    assert_success
    # Should show compact format
    assert_output --partial "[staging]"
}

@test "show-profile handles unknown action" {
    run run_profile_script "show-profile.sh" "unknown-action"

    assert_failure
    assert_output --partial "Unknown action: unknown-action"
}

# Test error conditions
@test "show-profile handles missing common library" {
    # Temporarily move common library
    mv "$TEST_LIB_DIR/common.sh" "$TEST_LIB_DIR/common.sh.bak"

    run run_profile_script "show-profile.sh" "help"

    assert_failure
    assert_output --partial "Failed to source common utilities"

    # Restore library
    mv "$TEST_LIB_DIR/common.sh.bak" "$TEST_LIB_DIR/common.sh"
}

# Test integration with mise configuration
@test "show-profile detects mise configuration files" {
    # Create mise configuration in project root
    touch "$TEST_PROJECT_ROOT/.mise.toml"

    run run_profile_script "show-profile.sh" "status"

    assert_success
    # Should detect mise configuration
    assert_output --partial "Configuration Root: $TEST_PROFILES_DIR"
}

# Test comprehensive status display with all features
@test "comprehensive status display with all features" {
    export DEPLOYMENT_PROFILE="staging"
    export DEPLOYMENT_REGION="us-east"
    export ENVIRONMENT_CONTEXT="staging"
    export CI_JOB_TIMEOUT_MINUTES="60"
    export CI_TEST_MODE="false"

    # Create complete directory structure
    mkdir -p "$TEST_PROFILES_DIR/staging"/{regions,secrets,config}
    mkdir -p "$TEST_PROFILES_DIR/staging/regions"/{us-east,us-west,eu-west}

    # Create configuration files
    cat > "$TEST_PROFILES_DIR/staging/config.yml" << 'EOF'
environment:
  type: staging
  description: Staging environment for testing
  created: "2025-01-01"

services:
  - name: web
    version: "1.0.0"
    replicas: 2
  - name: api
    version: "1.0.0"
    replicas: 1
EOF

    cat > "$TEST_PROFILES_DIR/staging/regions/us-east/config.yml" << 'EOF'
region:
  name: us-east
  description: US East Coast

infrastructure:
  provider: aws
  region: us-east-1
  instance_type: t3.medium
EOF

    cat > "$TEST_PROFILES_DIR/staging/regions/us-west/config.yml" << 'EOF'
region:
  name: us-west
  description: US West Coast
EOF

    touch "$TEST_PROFILES_DIR/staging/secrets.enc"

    run run_profile_script "show-profile.sh" "status"

    assert_success
    assert_output --partial "Deployment Profile Status"
    assert_output --partial "Profile Information:"
    assert_output --partial "Directory Structure:"
    assert_output --partial "Configuration Files:"
    assert_output --partial "Region Configuration:"
    assert_output --partial "Environment Variables:"
    assert_output --partial "Available Regions:"
    assert_output --partial "Quick Actions:"
    assert_output --partial "Shell Integration:"
}

# Test with testability examples from help
@test "testability examples work correctly" {
    # Test DRY_RUN mode
    CI_TEST_MODE=DRY_RUN run run_profile_script "show-profile.sh" "status"
    assert_success
    assert_output --partial "DRY RUN: Would show profile status"

    # Test FAIL mode
    CI_PROFILE_STATUS_BEHAVIOR=FAIL run run_profile_script "show-profile.sh" "validate" "staging"
    assert_failure
    assert_output --partial "FAIL MODE: Simulating profile status display failure"
}