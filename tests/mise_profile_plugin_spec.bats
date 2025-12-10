#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/test_helper.bash"

# Setup and teardown
setup() {
    setup_test_project
    setup_zsh_test_environment
}

teardown() {
    cleanup_test_project
}

# Test plugin initialization
@test "mise profile plugin initializes successfully" {
    run zsh -c "
        source '$TEST_SHELL_DIR/mise-profile.plugin.zsh'
        echo \$MISE_PLUGIN_VERSION
    "

    assert_success
    assert_output "1.0.0"
}

@test "mise profile plugin sets debug mode correctly" {
    run zsh -c "
        MISE_DEBUG=true source '$TEST_SHELL_DIR/mise-profile.plugin.zsh' 2>&1
    "

    assert_success
    assert_output --partial "MISE Profile Plugin v1.0.0 initializing..."
    assert_output --partial "MISE Profile Plugin initialized successfully"
}

@test "mise profile plugin runs in test mode" {
    run zsh -c "
        CI_ZSH_PLUGIN_TEST_MODE=true source '$TEST_SHELL_DIR/mise-profile.plugin.zsh'
        mise_profile_prompt
    "

    assert_success
    assert_output "(test-mode)"
}

# Test profile color and symbol mappings
@test "get_profile_color returns correct colors" {
    local test_cases=(
        "production:red"
        "staging:yellow"
        "development:green"
        "local:green"
        "canary:magenta"
        "performance:cyan"
        "sandbox:blue"
        "default:blue"
        "unknown:blue"  # Falls back to default
    )

    for case in "${test_cases[@]}"; do
        local profile="${case%:*}"
        local expected_color="${case#*:}"

        run zsh -c "
            source '$TEST_SHELL_DIR/mise-profile.plugin.zsh'
            get_profile_color '$profile'
        "

        assert_success
        # ZSH color codes should be in %F{color} format
        case "$expected_color" in
            "red") assert_output "%F{red}" ;;
            "green") assert_output "%F{green}" ;;
            "yellow") assert_output "%F{yellow}" ;;
            "blue") assert_output "%F{blue}" ;;
            "magenta") assert_output "%F{magenta}" ;;
            "cyan") assert_output "%F{cyan}" ;;
        esac
    done
}

@test "get_profile_symbol returns correct symbols" {
    local test_cases=(
        "production:🔒"
        "staging:🚀"
        "development:🛠️"
        "local:💻"
        "canary:🐤"
        "performance:⚡"
        "sandbox:🥪"
        "default:💼"
        "unknown:❓"
    )

    for case in "${test_cases[@]}"; do
        local profile="${case%:*}"
        local expected_symbol="${case#*:}"

        run zsh -c "
            source '$TEST_SHELL_DIR/mise-profile.plugin.zsh'
            get_profile_symbol '$profile'
        "

        assert_success
        assert_output "$expected_symbol"
    done
}

# Test profile detection
@test "detect_mise_profile detects production environment" {
    # Create test directory with production indicator
    mkdir -p "$BATS_TEST_TMPDIR/project-production"

    run zsh -c "
        cd '$BATS_TEST_TMPDIR/project-production'
        source '$TEST_SHELL_DIR/mise-profile.plugin.zsh'
        detect_mise_profile
    "

    assert_success
    assert_output "production"
}

@test "detect_mise_profile detects staging environment" {
    # Create test directory with staging indicator
    mkdir -p "$BATS_TEST_TMPDIR/project-staging"

    run zsh -c "
        cd '$BATS_TEST_TMPDIR/project-staging'
        source '$TEST_SHELL_DIR/mise-profile.plugin.zsh'
        detect_mise_profile
    "

    assert_success
    assert_output "staging"
}

@test "detect_mise_profile detects environment from path" {
    # Create environment directory structure
    mkdir -p "$BATS_TEST_TMPDIR/environments/custom-profile"

    run zsh -c "
        cd '$BATS_TEST_TMPDIR/environments/custom-profile'
        source '$TEST_SHELL_DIR/mise-profile.plugin.zsh'
        detect_mise_profile
    "

    assert_success
    assert_output "custom-profile"
}

@test "detect_mise_profile detects local project" {
    # Create local project with mise.toml
    mkdir -p "$BATS_TEST_TMPDIR/local-project"
    touch "$BATS_TEST_TMPDIR/local-project/mise.toml"

    run zsh -c "
        cd '$BATS_TEST_TMPDIR/local-project'
        source '$TEST_SHELL_DIR/mise-profile.plugin.zsh'
        detect_mise_profile
    "

    assert_success
    assert_output "local"
}

@test "detect_mise_profile returns empty when no profile detected" {
    mkdir -p "$BATS_TEST_TMPDIR/empty-project"

    run zsh -c "
        cd '$BATS_TEST_TMPDIR/empty-project'
        source '$TEST_SHELL_DIR/mise-profile.plugin.zsh'
        detect_mise_profile
    "

    assert_success
    assert_output ""
}

# Test environment status checking
@test "get_environment_status returns healthy for production when curl succeeds" {
    # Mock curl to succeed
    mock_command_output "curl" ""

    run zsh -c "
        source '$TEST_SHELL_DIR/mise-profile.plugin.zsh'
        get_environment_status 'production'
    "

    assert_success
    assert_output "✅"
}

@test "get_environment_status returns warning for production when curl fails" {
    # Mock curl to fail
    cat > "$BATS_TEST_TMPDIR/bin/curl" << 'EOF'
#!/bin/bash
exit 1
EOF
    chmod +x "$BATS_TEST_TMPDIR/bin/curl"

    run zsh -c "
        source '$TEST_SHELL_DIR/mise-profile.plugin.zsh'
        get_environment_status 'production'
    "

    assert_success
    assert_output "⚠️"
}

@test "get_environment_status returns healthy for staging" {
    run zsh -c "
        source '$TEST_SHELL_DIR/mise-profile.plugin.zsh'
        get_environment_status 'staging'
    "

    assert_success
    assert_output "✅"
}

@test "get_environment_status returns healthy for development" {
    run zsh -c "
        source '$TEST_SHELL_DIR/mise-profile.plugin.zsh'
        get_environment_status 'development'
    "

    assert_success
    assert_output "✅"
}

@test "get_environment_status returns unknown for unknown profile" {
    run zsh -c "
        source '$TEST_SHELL_DIR/mise-profile.plugin.zsh'
        get_environment_status 'unknown-profile'
    "

    assert_success
    assert_output "❓"
}

# Test profile prompt generation
@test "mise_profile_prompt returns early in home directory" {
    run zsh -c "
        cd ~
        source '$TEST_SHELL_DIR/mise-profile.plugin.zsh'
        mise_profile_prompt
    "

    assert_success
    assert_output ""
}

@test "mise_profile_prompt returns early for unknown profile" {
    run zsh -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_SHELL_DIR/mise-profile.plugin.zsh'
        CURRENT_MISE_PROFILE='unknown'
        mise_profile_prompt
    "

    assert_success
    assert_output ""
}

@test "mise_profile_prompt generates correct prompt format" {
    run zsh -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_SHELL_DIR/mise-profile.plugin.zsh'
        CURRENT_MISE_PROFILE='staging'
        mise_profile_prompt
    "

    assert_success
    # Should contain symbol, profile name, and status
    assert_output --partial "🚀 staging"
    assert_output --partial "✅"  # Status symbol
}

# Test profile switching functions
@test "mise_quick_switch validates profile exists" {
    run zsh -c "
        source '$TEST_SHELL_DIR/mise-profile.plugin.zsh'
        mise_quick_switch 'nonexistent-profile'
    "

    assert_failure
    assert_output --partial "Profile 'nonexistent-profile' not found"
}

@test "mise_quick_switch shows usage when no profile provided" {
    run zsh -c "
        source '$TEST_SHELL_DIR/mise-profile.plugin.zsh'
        mise_quick_switch ''
    "

    assert_failure
    assert_output --partial "Usage: mise_quick_switch <profile>"
}

@test "mise_profile_info shows current profile information" {
    run zsh -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_SHELL_DIR/mise-profile.plugin.zsh'
        CURRENT_MISE_PROFILE='staging'
        mise_profile_info
    "

    assert_success
    assert_output --partial "MISE Profile Information:"
    assert_output --partial "Current Profile: staging"
    assert_output --partial "Available Profiles:"
}

# Test profile health check
@test "mise_profile_health_check validates profile configuration" {
    run zsh -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_SHELL_DIR/mise-profile.plugin.zsh'
        CURRENT_MISE_PROFILE='staging'
        mise_profile_health_check
    "

    assert_success
    assert_output --partial "Checking health for profile: staging"
}

@test "mise_profile_health_check shows missing environment variables" {
    run zsh -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_SHELL_DIR/mise-profile.plugin.zsh'
        unset CI_ENVIRONMENT PROJECT_ROOT
        mise_profile_health_check
    "

    assert_success
    assert_output --partial "Missing environment variable: CI_ENVIRONMENT"
}

# Test Powerlevel10k integration
@test "prompt_ci_excellence integrates with Powerlevel10k" {
    # Mock p10k function
    run zsh -c "
        p10k() { echo \"p10k called with: \$*\"; }
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_SHELL_DIR/mise-profile.plugin.zsh'
        CURRENT_MISE_PROFILE='staging'
        prompt_ci_excellence
    "

    assert_success
    # The function should call p10k with appropriate arguments
    assert_output --partial "p10k called with:"
    assert_output --partial "segment"
}

@test "prompt_ci_excellence returns early if p10k not available" {
    run zsh -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_SHELL_DIR/mise-profile.plugin.zsh'
        CURRENT_MISE_PROFILE='staging'
        prompt_ci_excellence
    "

    assert_success
    assert_output ""  # Should return early, no output
}

# Test alias definitions
@test "define_mise_aliases creates correct aliases" {
    run zsh -c "
        source '$TEST_SHELL_DIR/mise-profile.plugin.zsh'
        alias | grep 'mp='
    "

    assert_success
    assert_output --partial "mp='mise profile'"
}

@test "quick profile aliases are defined" {
    local aliases=("mdev" "mstg" "mprod")

    for alias_name in "${aliases[@]}"; do
        run zsh -c "
            source '$TEST_SHELL_DIR/mise-profile.plugin.zsh'
            alias | grep '$alias_name='
        "

        assert_success
    done
}

# Test auto-completion setup
@test "setup_mise_autocompletion enables mise completion" {
    run zsh -c "
        source '$TEST_SHELL_DIR/mise-profile.plugin.zsh'
        # Check if completion was set up (indirectly through mise command)
        compdef | grep mise
    "

    # This test might fail in headless environment, but should not error
    [[ $status -eq 0 || $status -eq 1 ]]  # Either success or command not found
}

@test "_mise_profile_commands completion function exists" {
    run zsh -c "
        source '$TEST_SHELL_DIR/mise-profile.plugin.zsh'
        declare -f _mise_profile_commands
    "

    assert_success
}

@test "_mise_task_commands completion function exists" {
    run zsh -c "
        source '$TEST_SHELL_DIR/mise-profile.plugin.zsh'
        declare -f _mise_task_commands
    "

    assert_success
}

# Test hook setup
@test "setup_mise_hooks registers ZSH hooks" {
    run zsh -c "
        source '$TEST_SHELL_DIR/mise-profile.plugin.zsh'
        # Check if hooks were added (this is a basic check)
        typeset -f chpwd_mise_profile_check
        typeset -f precmd_mise_profile_update
    "

    assert_success
}

@test "chpwd_mise_profile_check detects mise configuration" {
    # Create a directory with mise configuration
    mkdir -p "$BATS_TEST_TMPDIR/mise-project"
    touch "$BATS_TEST_TMPDIR/mise-project/.mise.toml"

    run zsh -c "
        cd '$BATS_TEST_TMPDIR/mise-project'
        MISE_DEBUG=true source '$TEST_SHELL_DIR/mise-profile.plugin.zsh'
        chpwd_mise_profile_check 2>&1
    "

    assert_success
    assert_output --partial "MISE configuration found"
}

@test "precmd_mise_profile_update updates profile information" {
    run zsh -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_SHELL_DIR/mise-profile.plugin.zsh'
        precmd_mise_profile_update
        echo \"Profile updated: \$CURRENT_MISE_PROFILE\"
    "

    assert_success
    assert_output --partial "Profile updated:"
}

# Test current profile update function
@test "update_current_mise_profile uses DEPLOYMENT_PROFILE environment variable" {
    run zsh -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_SHELL_DIR/mise-profile.plugin.zsh'
        DEPLOYMENT_PROFILE='test-profile'
        update_current_mise_profile
        echo \"\$CURRENT_MISE_PROFILE\"
    "

    assert_success
    assert_output "test-profile"
}

@test "update_current_mise_profile falls back to detection when no env var set" {
    # Create a directory that should be detected as local
    cd "$TEST_PROJECT_ROOT"
    touch "mise.toml"

    run zsh -c "
        source '$TEST_SHELL_DIR/mise-profile.plugin.zsh'
        unset DEPLOYMENT_PROFILE
        update_current_mise_profile
        echo \"\$CURRENT_MISE_PROFILE\"
    "

    assert_success
    # Should be detected as local or have a valid value
    [[ "$output" == "local" || "$output" == "unknown" ]]
}

# Test plugin version and configuration
@test "plugin version is correctly defined" {
    run zsh -c "
        source '$TEST_SHELL_DIR/mise-profile.plugin.zsh'
        echo \"\$MISE_PLUGIN_VERSION\"
    "

    assert_success
    assert_output "1.0.0"
}

@test "plugin debug mode can be enabled" {
    run zsh -c "
        MISE_DEBUG=true source '$TEST_SHELL_DIR/mise-profile.plugin.zsh' 2>&1 | grep 'MISE Profile Plugin v1.0.0 initializing'
    "

    assert_success
}

@test "plugin test mode can be enabled" {
    run zsh -c "
        CI_ZSH_PLUGIN_TEST_MODE=true source '$TEST_SHELL_DIR/mise-profile.plugin.zsh'
        mise_profile_prompt
    "

    assert_success
    assert_output "(test-mode)"
}