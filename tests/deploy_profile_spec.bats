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
@test "deploy-profile script shows help with --help flag" {
    run run_profile_script "deploy-profile.sh" "help"

    assert_success
    assert_output --partial "MISE Profile Switcher v1.0.0"
    assert_output --partial "Usage:"
    assert_output --partial "switch <profile> [region]"
}

@test "deploy-profile script shows help with -h flag" {
    run run_profile_script "deploy-profile.sh" "-h"

    assert_success
    assert_output --partial "MISE Profile Switcher v1.0.0"
}

@test "deploy-profile script handles DRY_RUN mode" {
    export CI_PROFILE_SWITCHER_BEHAVIOR="DRY_RUN"

    run run_profile_script "deploy-profile.sh" "switch" "staging"

    assert_success
    assert_output --partial "DRY RUN: Would switch to profile: staging"
}

@test "deploy-profile script handles PASS mode" {
    export CI_PROFILE_SWITCHER_BEHAVIOR="PASS"

    run run_profile_script "deploy-profile.sh" "switch" "staging"

    assert_success
    assert_output --partial "PASS MODE: Profile switch simulated successfully"
}

@test "deploy-profile script handles FAIL mode" {
    export CI_PROFILE_SWITCHER_BEHAVIOR="FAIL"

    run run_profile_script "deploy-profile.sh" "switch" "staging"

    assert_failure
    assert_output --partial "FAIL MODE: Simulating profile switch failure"
}

@test "deploy-profile script handles SKIP mode" {
    export CI_PROFILE_SWITCHER_BEHAVIOR="SKIP"

    run run_profile_script "deploy-profile.sh" "switch" "staging"

    assert_success
    assert_output --partial "SKIP MODE: Profile switch skipped"
}

@test "deploy-profile script handles TIMEOUT mode" {
    export CI_PROFILE_SWITCHER_BEHAVIOR="TIMEOUT"

    run run_profile_script "deploy-profile.sh" "switch" "staging"

    assert_failure 124  # Timeout exit code
    assert_output --partial "TIMEOUT MODE: Simulating profile switch timeout"
}

# Test profile validation
@test "validate_profile accepts supported profiles" {
    for profile in "local" "staging" "production" "canary" "sandbox" "performance"; do
        run bash -c "
            cd '$TEST_PROJECT_ROOT'
            source '$TEST_LIB_DIR/common.sh'
            source '$TEST_PROFILE_DIR/deploy-profile.sh'
            validate_profile '$profile'
        "

        assert_success
    done
}

@test "validate_profile accepts directory-based profiles" {
    # Create a custom profile directory
    mkdir -p "$TEST_PROFILES_DIR/custom-profile"

    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_PROFILE_DIR/deploy-profile.sh'
        validate_profile 'custom-profile'
    "

    assert_success
}

@test "validate_profile rejects invalid profiles" {
    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_PROFILE_DIR/deploy-profile.sh'
        validate_profile 'invalid-profile'
    "

    assert_failure
    assert_output --partial "Invalid profile: invalid-profile"
}

@test "validate_profile warns about missing profile directories" {
    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_PROFILE_DIR/deploy-profile.sh'
        validate_profile 'production'
    "

    assert_success
    assert_output --partial "Profile directory not found"
}

# Test profile switching
@test "switch_profile switches to staging profile" {
    run run_profile_script "deploy-profile.sh" "switch" "staging"

    assert_success
    assert_output --partial "Successfully switched to profile: staging"
    assert_output --partial "Current Profile Status:"
}

@test "switch_profile switches to production profile with region" {
    run run_profile_script "deploy-profile.sh" "switch" "production" "us-east"

    assert_success
    assert_output --partial "Successfully switched to profile: production"
    assert_env_var_set "DEPLOYMENT_PROFILE" "production"
    assert_env_var_set "DEPLOYMENT_REGION" "us-east"
}

@test "switch_profile handles already active profile" {
    export DEPLOYMENT_PROFILE="local"

    run run_profile_script "deploy-profile.sh" "switch" "local"

    assert_success
    assert_output --partial "Already on profile: local"
}

@test "switch_profile fails for invalid profile" {
    run run_profile_script "deploy-profile.sh" "switch" "invalid-profile"

    assert_failure
    assert_output --partial "Invalid profile: invalid-profile"
}

@test "switch_profile requires profile argument" {
    run run_profile_script "deploy-profile.sh" "switch"

    assert_failure
    assert_output --partial "Usage: $0 switch <profile> [region]"
}

# Test environment variable handling
@test "set_profile_env sets DEPLOYMENT_PROFILE" {
    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_PROFILE_DIR/deploy-profile.sh'
        set_profile_env 'staging'
        echo \"\$DEPLOYMENT_PROFILE\"
    "

    assert_success
    assert_output "staging"
}

@test "set_profile_env sets DEPLOYMENT_REGION when provided" {
    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_PROFILE_DIR/deploy-profile.sh'
        set_profile_env 'staging' 'us-east'
        echo \"\$DEPLOYMENT_REGION\"
    "

    assert_success
    assert_output "us-east"
}

@test "set_profile_env loads profile environment file" {
    # Create profile environment file
    cat > "$TEST_PROJECT_ROOT/config/.env.staging" << 'EOF'
PROFILE_VAR=staging_value
DEPLOYMENT_PROFILE=should_be_overridden
EOF

    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_PROFILE_DIR/deploy-profile.sh'
        set_profile_env 'staging'
        echo \"PROFILE_VAR: \$PROFILE_VAR\"
        echo \"DEPLOYMENT_PROFILE: \$DEPLOYMENT_PROFILE\"
    "

    assert_success
    assert_output --partial "PROFILE_VAR: staging_value"
    assert_output --partial "DEPLOYMENT_PROFILE: staging"  # Should override env file
}

# Test profile preference saving
@test "save_profile_preference updates .env.local" {
    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_PROFILE_DIR/deploy-profile.sh'
        save_profile_preference 'staging' 'us-east'
        cat .env.local
    "

    assert_success
    assert_output --partial 'DEPLOYMENT_PROFILE="staging"'
    assert_output --partial 'DEPLOYMENT_REGION="us-east"'
}

@test "save_profile_preference updates existing .env.local" {
    # Create existing .env.local
    cat > "$TEST_PROJECT_ROOT/.env.local" << 'EOF'
# Local environment overrides
DEPLOYMENT_PROFILE="local"
OTHER_VAR=value
EOF

    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_PROFILE_DIR/deploy-profile.sh'
        save_profile_preference 'staging'
        cat .env.local
    "

    assert_success
    assert_output --partial 'DEPLOYMENT_PROFILE="staging"'
    assert_output --partial "OTHER_VAR=value"  # Should preserve other vars
}

@test "load_profile_preference detects existing profile preference" {
    # Create .env.local with profile
    cat > "$TEST_PROJECT_ROOT/.env.local" << 'EOF'
DEPLOYMENT_PROFILE="staging"
EOF

    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_PROFILE_DIR/deploy-profile.sh'
        if load_profile_preference; then echo 'found'; else echo 'not found'; fi
    "

    assert_success
    assert_output "found"
}

@test "load_profile_preference returns false when no profile preference" {
    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_PROFILE_DIR/deploy-profile.sh'
        if load_profile_preference; then echo 'found'; else echo 'not found'; fi
    "

    assert_success
    assert_output "not found"
}

# Test profile status display
@test "show_profile_status displays current profile information" {
    export DEPLOYMENT_PROFILE="staging"
    export DEPLOYMENT_REGION="us-east"

    run run_profile_script "deploy-profile.sh" "status"

    assert_success
    assert_output --partial "Current Profile Status:"
    assert_output --partial "Profile: staging"
    assert_output --partial "Region: us-east"
    assert_output --partial "Configuration Directory: $TEST_PROFILES_DIR/staging"
}

@test "show_profile_status displays config preview when yq available" {
    export DEPLOYMENT_PROFILE="staging"

    run run_profile_script "deploy-profile.sh" "status"

    assert_success
    # Should attempt to show config preview
    assert_output --partial "Config File:"
}

@test "show_profile_status shows secrets file status" {
    export DEPLOYMENT_PROFILE="staging"

    # Create a secrets file
    touch "$TEST_PROFILES_DIR/staging/secrets.enc"

    run run_profile_script "deploy-profile.sh" "status"

    assert_success
    assert_output --partial "Secrets File: (encrypted)"
}

@test "show_profile_status shows region configuration" {
    export DEPLOYMENT_PROFILE="staging"
    export DEPLOYMENT_REGION="us-east"

    # Create region config
    mkdir -p "$TEST_PROFILES_DIR/staging/regions/us-east"
    touch "$TEST_PROFILES_DIR/staging/regions/us-east/config.yml"

    run run_profile_script "deploy-profile.sh" "status"

    assert_success
    assert_output --partial "Region Config:"
}

# Test profile listing
@test "list_profiles displays all available profiles" {
    run run_profile_script "deploy-profile.sh" "list"

    assert_success
    assert_output --partial "Available Profiles:"
    assert_output --partial "local"
    assert_output --partial "staging"
    assert_output --partial "production"
}

@test "list_profiles marks current profile" {
    export DEPLOYMENT_PROFILE="staging"

    run run_profile_script "deploy-profile.sh" "list"

    assert_success
    assert_output --partial "* staging"  # Current profile marked with *
}

@test "list_profiles shows configuration status" {
    # Create config file for one profile
    touch "$TEST_PROFILES_DIR/staging/config.yml"

    run run_profile_script "deploy-profile.sh" "list"

    assert_success
    # Should show config status for staging
    assert_line --partial "staging"
    assert_line --partial "Config: ✓"
}

@test "list_profiles shows regions" {
    # Create region directories
    mkdir -p "$TEST_PROFILES_DIR/staging/regions"/{us-east,us-west}
    touch "$TEST_PROFILES_DIR/staging/regions/us-east/config.yml"
    touch "$TEST_PROFILES_DIR/staging/regions/us-west/config.yml"

    run run_profile_script "deploy-profile.sh" "list"

    assert_success
    assert_output --partial "Region: us-east"
    assert_output --partial "Region: us-west"
}

# Test profile system initialization
@test "init_profile_system initializes with defaults" {
    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_PROFILE_DIR/deploy-profile.sh'
        unset DEPLOYMENT_PROFILE ENVIRONMENT_CONTEXT
        init_profile_system
        echo \"DEPLOYMENT_PROFILE: \$DEPLOYMENT_PROFILE\"
        echo \"ENVIRONMENT_CONTEXT: \$ENVIRONMENT_CONTEXT\"
    "

    assert_success
    assert_output --partial "DEPLOYMENT_PROFILE: local"
    assert_output --partial "ENVIRONMENT_CONTEXT: development"
}

@test "init_profile_system loads existing preference" {
    # Create .env.local with profile
    cat > "$TEST_PROJECT_ROOT/.env.local" << 'EOF'
DEPLOYMENT_PROFILE="staging"
ENVIRONMENT_CONTEXT="staging"
EOF

    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_PROFILE_DIR/deploy-profile.sh'
        init_profile_system
        echo \"DEPLOYMENT_PROFILE: \$DEPLOYMENT_PROFILE\"
    "

    assert_success
    assert_output --partial "DEPLOYMENT_PROFILE: staging"
}

@test "init_profile_system resets invalid profile" {
    # Create .env.local with invalid profile
    cat > "$TEST_PROJECT_ROOT/.env.local" << 'EOF'
DEPLOYMENT_PROFILE="invalid-profile"
EOF

    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_PROFILE_DIR/deploy-profile.sh'
        init_profile_system
        echo \"DEPLOYMENT_PROFILE: \$DEPLOYMENT_PROFILE\"
    "

    assert_success
    assert_output --partial "DEPLOYMENT_PROFILE: local"
}

# Test current profile retrieval
@test "get_current_profile returns environment variable" {
    export DEPLOYMENT_PROFILE="test-profile"

    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_PROFILE_DIR/deploy-profile.sh'
        get_current_profile
    "

    assert_success
    assert_output "test-profile"
}

@test "get_current_profile returns default when not set" {
    unset DEPLOYMENT_PROFILE

    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_PROFILE_DIR/deploy-profile.sh'
        get_current_profile
    "

    assert_success
    assert_output "local"
}

# Test different action arguments
@test "deploy-profile handles status action" {
    export DEPLOYMENT_PROFILE="staging"

    run run_profile_script "deploy-profile.sh" "status"

    assert_success
    assert_output --partial "Current Profile Status:"
}

@test "deploy-profile handles current action" {
    export DEPLOYMENT_PROFILE="staging"

    run run_profile_script "deploy-profile.sh" "current"

    assert_success
    assert_output "staging"
}

@test "deploy-profile handles validate action" {
    run run_profile_script "deploy-profile.sh" "validate" "staging"

    assert_success
}

@test "deploy-profile handles validate action for invalid profile" {
    run run_profile_script "deploy-profile.sh" "validate" "invalid-profile"

    assert_failure
    assert_output --partial "Invalid profile: invalid-profile"
}

@test "deploy-profile handles validate action without profile argument" {
    run run_profile_script "deploy-profile.sh" "validate"

    assert_failure
    assert_output --partial "Usage: $0 validate <profile>"
}

@test "deploy-profile handles init action" {
    run run_profile_script "deploy-profile.sh" "init"

    assert_success
    assert_output --partial "Profile system initialized"
}

@test "deploy-profile handles direct profile switching (implicit switch action)" {
    run run_profile_script "deploy-profile.sh" "staging"

    assert_success
    assert_output --partial "Successfully switched to profile: staging"
}

@test "deploy-profile handles unknown action" {
    run run_profile_script "deploy-profile.sh" "unknown-action"

    assert_failure
    assert_output --partial "Unknown action: unknown-action"
}

# Test error conditions
@test "deploy-profile handles missing common library" {
    # Temporarily move common library
    mv "$TEST_LIB_DIR/common.sh" "$TEST_LIB_DIR/common.sh.bak"

    run run_profile_script "deploy-profile.sh" "help"

    assert_failure
    assert_output --partial "Failed to source common utilities"

    # Restore library
    mv "$TEST_LIB_DIR/common.sh.bak" "$TEST_LIB_DIR/common.sh"
}

@test "deploy-profile shows next steps after successful switch" {
    run run_profile_script "deploy-profile.sh" "switch" "staging"

    assert_success
    assert_output --partial "Next steps:"
    assert_output --partial "View environment config:"
    assert_output --partial "Edit secrets:"
    assert_output --partial "Switch back:"
}

# Test shell prompt update
@test "update_shell_prompt respects UPDATE_SHELL_PROMPT=false" {
    export UPDATE_SHELL_PROMPT=false

    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_PROFILE_DIR/deploy-profile.sh'
        update_shell_prompt 'staging'
        echo \"prompt_updated: \$?\"
    "

    assert_success
    # Function should return early without error
}

# Test profile switching with environment file loading
@test "profile switching loads and respects environment file" {
    # Create profile environment file
    cat > "$TEST_PROJECT_ROOT/config/.env.staging" << 'EOF'
PROFILE_SPECIFIC_VAR=staging_value
COMMON_VAR=from_env_file
DEPLOYMENT_PROFILE=should_be_overridden
EOF

    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_PROFILE_DIR/deploy-profile.sh'
        set_profile_env 'staging'
        echo \"PROFILE_SPECIFIC_VAR: \$PROFILE_SPECIFIC_VAR\"
        echo \"COMMON_VAR: \$COMMON_VAR\"
        echo \"DEPLOYMENT_PROFILE: \$DEPLOYMENT_PROFILE\"
    "

    assert_success
    assert_output --partial "PROFILE_SPECIFIC_VAR: staging_value"
    assert_output --partial "COMMON_VAR: from_env_file"
    assert_output --partial "DEPLOYMENT_PROFILE: staging"  # Should override
}

# Test comprehensive profile switching flow
@test "comprehensive profile switching workflow" {
    # Setup initial state
    export DEPLOYMENT_PROFILE="local"
    export DEPLOYMENT_REGION=""

    # Create necessary files
    mkdir -p "$TEST_PROJECT_ROOT/config"
    cat > "$TEST_PROJECT_ROOT/config/.env.staging" << 'EOF'
ENV_VAR_FROM_FILE=staging_config
EOF

    run run_profile_script "deploy-profile.sh" "switch" "staging" "us-east"

    assert_success
    assert_output --partial "Successfully switched to profile: staging"

    # Verify environment variables are set
    assert_env_var_set "DEPLOYMENT_PROFILE" "staging"
    assert_env_var_set "DEPLOYMENT_REGION" "us-east"

    # Verify .env.local was updated
    assert_file_contains "$TEST_PROJECT_ROOT/.env.local" 'DEPLOYMENT_PROFILE="staging"'
    assert_file_contains "$TEST_PROJECT_ROOT/.env.local" 'DEPLOYMENT_REGION="us-east"'
}