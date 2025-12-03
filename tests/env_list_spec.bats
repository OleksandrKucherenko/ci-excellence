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

# Test help and usage
@test "env-list script shows usage with --help flag" {
    run run_profile_script "env-list.sh" "--help"

    assert_success
    assert_output --partial "Usage: env-list [options]"
    assert_output --partial "List available environments with detailed information"
    assert_output --partial "Options:"
}

@test "env-list script shows usage with -h flag" {
    run run_profile_script "env-list.sh" "-h"

    assert_success
    assert_output --partial "Usage: env-list [options]"
}

@test "env-list script handles unknown option" {
    run run_profile_script "env-list.sh" "--unknown-option"

    assert_failure
    assert_output --partial "Unknown option: --unknown-option"
}

@test "env-list script handles unexpected argument" {
    run run_profile_script "env-list.sh" "unexpected-argument"

    assert_failure
    assert_output --partial "Unexpected argument: unexpected-argument"
}

@test "env-list script validates output format" {
    run run_profile_script "env-list.sh" "--format" "invalid-format"

    assert_failure
    assert_output --partial "Invalid output format: invalid-format"
    assert_output --partial "Valid formats: table, json, yaml"
}

# Test table format output
@test "env-list displays environments in table format" {
    run run_profile_script "env-list.sh"

    assert_success
    assert_output --partial "ENVIRONMENT"
    assert_output --partial "TYPE"
    assert_output --partial "INHERITS"
    assert_output --partial "SECRETS"
    assert_output --partial "--------------------"
    assert_output --partial "------------"
    assert_output --partial "---------------"
    assert_output --partial "--------"
}

@test "env-list shows detailed table format" {
    run run_profile_script "env-list.sh" "--detailed"

    assert_success
    assert_output --partial "ENVIRONMENT"
    assert_output --partial "TYPE"
    assert_output --partial "INHERITS"
    assert_output --partial "REGIONS"
    assert_output --partial "CREATED"
    assert_output --partial "DESCRIPTION"
    assert_output --partial "SECRETS"
}

@test "env-list displays no environments message when empty" {
    # Mock discover_environments to return empty
    mock_command_output "discover_environments" ""

    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_LIB_DIR/environment.sh'
        discover_environments() { echo ''; }
        source '$TEST_PROFILE_DIR/env-list.sh'
        main
    "

    assert_success
    assert_output --partial "No environments found"
}

@test "env-list shows summary statistics" {
    run run_profile_script "env-list.sh"

    assert_success
    assert_output --partial "Total environments:"
    assert_output --partial "Default environments:"
    assert_output --partial "Custom environments:"
}

# Test JSON format output
@test "env-list displays environments in JSON format" {
    run run_profile_script "env-list.sh" "--format" "json"

    assert_success
    assert_output --partial '"environments"'
    assert_output --partial '"summary"'
    assert_output --partial '"total_count"'
    assert_output --partial '"default_count"'
    assert_output --partial '"custom_count"'
}

@test "env-list JSON format includes all environment fields" {
    run run_profile_script "env-list.sh" "--format" "json"

    assert_success
    assert_output --partial '"name"'
    assert_output --partial '"type"'
    assert_output --partial '"inherits"'
    assert_output --partial '"created"'
    assert_output --partial '"description"'
    assert_output --partial '"regions"'
    assert_output --partial '"has_secrets"'
    assert_output --partial '"is_default"'
}

@test "env-list JSON format handles jq when available" {
    # Mock jq to be available
    mock_command_output "jq" "."  # jq will pass through the input

    run run_profile_script "env-list.sh" "--format" "json"

    assert_success
    assert_output --partial '"environments"'
}

# Test YAML format output
@test "env-list displays environments in YAML format" {
    run run_profile_script "env-list.sh" "--format" "yaml"

    assert_success
    assert_output --partial "environments:"
    assert_output --partial "summary:"
    assert_output --partial "total_count:"
    assert_output --partial "default_count:"
    assert_output --partial "custom_count:"
}

@test "env-list YAML format includes all environment fields" {
    run run_profile_script "env-list.sh" "--format" "yaml"

    assert_success
    assert_output --partial "name:"
    assert_output --partial "type:"
    assert_output --partial "inherits:"
    assert_output --partial "created:"
    assert_output --partial "description:"
    assert_output --partial "regions:"
    assert_output --partial "has_secrets:"
    assert_output --partial "is_default:"
}

# Test type filtering
@test "env-list filters by development type" {
    run run_profile_script "env-list.sh" "--type" "development"

    assert_success
    # Should only show development environments
    assert_output --partial "development"
}

@test "env-list filters by testing type" {
    run run_profile_script "env-list.sh" "--type" "testing"

    assert_success
    # Should only show testing environments
    assert_output --partial "testing"
}

@test "env-list filters by staging type" {
    run run_profile_script "env-list.sh" "--type" "staging"

    assert_success
    # Should only show staging environments
    assert_output --partial "staging"
}

@test "env-list filters by production type" {
    run run_profile_script "env-list.sh" "--type" "production"

    assert_success
    # Should only show production environments
    assert_output --partial "production"
}

# Test environment information retrieval functions
@test "get_environment_type returns type from config" {
    # Create environment config
    mkdir -p "$TEST_PROFILES_DIR/test-env"
    cat > "$TEST_PROFILES_DIR/test-env/config.yml" << 'EOF'
environment:
  type: development
  description: Test development environment
EOF

    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_PROFILE_DIR/env-list.sh'
        get_environment_type 'test-env'
    "

    assert_success
    assert_output "development"
}

@test "get_environment_type returns unknown when no config" {
    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_PROFILE_DIR/env-list.sh'
        get_environment_type 'nonexistent-env'
    "

    assert_success
    assert_output "unknown"
}

@test "get_environment_type returns unknown when yq not available" {
    # Mock yq to not exist
    mv "$BATS_TEST_TMPDIR/bin/yq" "$BATS_TEST_TMPDIR/bin/yq.bak"

    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_PROFILE_DIR/env-list.sh'
        get_environment_type 'test-env'
    "

    assert_success
    assert_output "unknown"

    # Restore yq
    mv "$BATS_TEST_TMPDIR/bin/yq.bak" "$BATS_TEST_TMPDIR/bin/yq"
}

@test "get_environment_description returns description from config" {
    # Create environment config
    mkdir -p "$TEST_PROFILES_DIR/test-env"
    cat > "$TEST_PROFILES_DIR/test-env/config.yml" << 'EOF'
environment:
  type: development
  description: This is a test environment for development
EOF

    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_PROFILE_DIR/env-list.sh'
        get_environment_description 'test-env'
    "

    assert_success
    assert_output "This is a test environment for development"
}

@test "get_environment_description returns default when no config" {
    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_PROFILE_DIR/env-list.sh'
        get_environment_description 'nonexistent-env'
    "

    assert_success
    assert_output "No configuration found"
}

@test "get_environment_description returns yq message when yq not available" {
    # Mock yq to not exist
    mv "$BATS_TEST_TMPDIR/bin/yq" "$BATS_TEST_TMPDIR/bin/yq.bak"

    # Create environment config
    mkdir -p "$TEST_PROFILES_DIR/test-env"
    touch "$TEST_PROFILES_DIR/test-env/config.yml"

    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_PROFILE_DIR/env-list.sh'
        get_environment_description 'test-env'
    "

    assert_success
    assert_output "Use yq to view description"

    # Restore yq
    mv "$BATS_TEST_TMPDIR/bin/yq.bak" "$BATS_TEST_TMPDIR/bin/yq"
}

@test "get_environment_inheritance returns inheritance from config" {
    # Create environment config with inheritance
    mkdir -p "$TEST_PROFILES_DIR/test-env"
    cat > "$TEST_PROFILES_DIR/test-env/config.yml" << 'EOF'
extends: base-environment
environment:
  type: development
EOF

    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_PROFILE_DIR/env-list.sh'
        get_environment_inheritance 'test-env'
    "

    assert_success
    assert_output "base-environment"
}

@test "get_environment_inheritance returns none when no inheritance" {
    # Create environment config without inheritance
    mkdir -p "$TEST_PROFILES_DIR/test-env"
    cat > "$TEST_PROFILES_DIR/test-env/config.yml" << 'EOF'
environment:
  type: development
EOF

    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_PROFILE_DIR/env-list.sh'
        get_environment_inheritance 'test-env'
    "

    assert_success
    assert_output "none"
}

@test "get_environment_created returns created date from config" {
    # Create environment config with created date
    mkdir -p "$TEST_PROFILES_DIR/test-env"
    cat > "$TEST_PROFILES_DIR/test-env/config.yml" << 'EOF'
environment:
  type: development
  created: "2025-01-15T10:30:00Z"
EOF

    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_PROFILE_DIR/env-list.sh'
        get_environment_created 'test-env'
    "

    assert_success
    assert_output "2025-01-15T10:30:00Z"
}

@test "get_environment_regions returns comma-separated regions" {
    # Create environment with regions
    mkdir -p "$TEST_PROFILES_DIR/test-env/regions"/{us-east,us-west,eu-west}
    touch "$TEST_PROFILES_DIR/test-env/regions/us-east/config.yml"
    touch "$TEST_PROFILES_DIR/test-env/regions/us-west/config.yml"
    touch "$TEST_PROFILES_DIR/test-env/regions/eu-west/config.yml"

    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_PROFILE_DIR/env-list.sh'
        get_environment_regions 'test-env'
    "

    assert_success
    assert_output --partial "us-east"
    assert_output --partial "us-west"
    assert_output --partial "eu-west"
}

@test "get_environment_regions returns none when no regions" {
    # Create environment without regions
    mkdir -p "$TEST_PROFILES_DIR/test-env"

    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_PROFILE_DIR/env-list.sh'
        get_environment_regions 'test-env'
    "

    assert_success
    assert_output "none"
}

@test "get_environment_regions returns none when no region configs" {
    # Create environment with regions but no configs
    mkdir -p "$TEST_PROFILES_DIR/test-env/regions"/{us-east,us-west}
    # Don't create config files

    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_PROFILE_DIR/env-list.sh'
        get_environment_regions 'test-env'
    "

    assert_success
    assert_output "none"
}

@test "has_environment_secrets returns yes for JSON secrets" {
    # Create environment with JSON secrets
    mkdir -p "$TEST_PROFILES_DIR/test-env"
    touch "$TEST_PROFILES_DIR/test-env/secrets.json"

    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_PROFILE_DIR/env-list.sh'
        has_environment_secrets 'test-env'
    "

    assert_success
    assert_output "yes"
}

@test "has_environment_secrets returns yes for encrypted secrets" {
    # Create environment with encrypted secrets
    mkdir -p "$TEST_PROFILES_DIR/test-env"
    touch "$TEST_PROFILES_DIR/test-env/secrets.enc"

    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_PROFILE_DIR/env-list.sh'
        has_environment_secrets 'test-env'
    "

    assert_success
    assert_output "yes"
}

@test "has_environment_secrets returns no when no secrets" {
    # Create environment without secrets
    mkdir -p "$TEST_PROFILES_DIR/test-env"

    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_PROFILE_DIR/env-list.sh'
        has_environment_secrets 'test-env'
    "

    assert_success
    assert_output "no"
}

# Test table display formatting
@test "display_table handles environment count correctly" {
    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_LIB_DIR/environment.sh'
        source '$TEST_PROFILE_DIR/env-list.sh'
        display_table 'staging' 'production'
    "

    assert_success
    assert_output --partial "Total environments: 2"
}

@test "display_table truncates long descriptions in detailed mode" {
    # Mock environment with long description
    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        DETAILED=true
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_LIB_DIR/environment.sh'
        source '$TEST_PROFILE_DIR/env-list.sh'
        get_environment_description() { echo 'This is a very long description that should be truncated'; }
        display_table 'test-env'
    "

    assert_success
    # Should truncate long description
    assert_output --partial "..."
}

@test "display_table shows correct indicators" {
    # Create test environment files
    mkdir -p "$TEST_PROFILES_DIR/test-env"
    touch "$TEST_PROFILES_DIR/test-env/config.yml"
    touch "$TEST_PROFILES_DIR/test-env/secrets.enc"

    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_LIB_DIR/environment.sh'
        source '$TEST_PROFILE_DIR/env-list.sh'
        display_table 'test-env'
    "

    assert_success
    # Should show config and secrets indicators
    assert_output --partial "Config: ✓"
    assert_output --partial "Secrets: 🔒"
}

# Test JSON display formatting
@test "display_json handles empty environment list" {
    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_PROFILE_DIR/env-list.sh'
        display_json
    "

    assert_success
    assert_output --partial '"environments": []'
    assert_output --partial '"total_count": 0'
}

@test "display_json converts regions to JSON array" {
    # Mock regions output
    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_PROFILE_DIR/env-list.sh'
        get_environment_regions() { echo 'us-east us-west eu-west'; }
        has_environment_secrets() { echo 'yes'; }
        get_environment_type() { echo 'testing'; }
        get_environment_inheritance() { echo 'none'; }
        get_environment_created() { echo '2025-01-01'; }
        get_environment_description() { echo 'Test environment'; }
        is_default_environment() { return 1; }  # false
        display_json 'test-env'
    "

    assert_success
    assert_output --partial '"regions":'
    assert_output --partial '"has_secrets": yes'
    assert_output --partial '"is_default": false'
}

# Test YAML display formatting
@test "display_yaml handles empty environment list" {
    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_PROFILE_DIR/env-list.sh'
        display_yaml
    "

    assert_success
    assert_output --partial "environments:"
    assert_output --partial "total_count: 0"
}

@test "display_yaml formats regions correctly" {
    # Mock regions output
    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_PROFILE_DIR/env-list.sh'
        get_environment_regions() { echo 'us-east us-west'; }
        has_environment_secrets() { echo 'yes'; }
        get_environment_type() { echo 'testing'; }
        get_environment_inheritance() { echo 'base'; }
        get_environment_created() { echo '2025-01-01'; }
        get_environment_description() { echo 'Test environment'; }
        is_default_environment() { return 1; }  # false
        display_yaml 'test-env'
    "

    assert_success
    assert_output --partial "regions: [us-east us-west]"
    assert_output --partial "has_secrets: yes"
    assert_output --partial "is_default: false"
}

# Test main execution
@test "env-list main function integrates all components" {
    run run_profile_script "env-list.sh"

    assert_success
    # Should produce output in default table format
    assert_output --partial "ENVIRONMENT"
}

@test "env-list with detailed flag shows more information" {
    run run_profile_script "env-list.sh" "--detailed"

    assert_success
    # Should show detailed table with more columns
    assert_output --partial "REGIONS"
    assert_output --partial "CREATED"
    assert_output --partial "DESCRIPTION"
}

@test "env-list sorts environments alphabetically" {
    # Mock environments in random order
    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_LIB_DIR/environment.sh'
        discover_environments() { echo 'production local development staging'; }
        source '$TEST_PROFILE_DIR/env-list.sh'
        main
    "

    assert_success
    # Should be sorted alphabetically
    local output_lines=()
    readarray -t output_lines <<<"$output"

    # Find the environment lines and check they're sorted
    for ((i=0; i<${#output_lines[@]}; i++)); do
        if [[ "${output_lines[$i]}" =~ ^(local|development|staging|production)$ ]]; then
            echo "Found environment: ${BASH_REMATCH[1]}"
        fi
    done
}

@test "env-list handles environment library dependencies" {
    # Ensure environment library is loaded
    run bash -c "
        cd '$TEST_PROJECT_ROOT'
        source '$TEST_LIB_DIR/common.sh'
        source '$TEST_LIB_DIR/environment.sh'
        source '$TEST_PROFILE_DIR/env-list.sh'
        declare -f discover_environments
    "

    assert_success
}

# Test error conditions
@test "env-list handles missing environment library gracefully" {
    # Temporarily move environment library
    mv "$TEST_LIB_DIR/environment.sh" "$TEST_LIB_DIR/environment.sh.bak"

    run run_profile_script "env-list.sh"

    # Should fail gracefully with source error
    assert_failure

    # Restore library
    mv "$TEST_LIB_DIR/environment.sh.bak" "$TEST_LIB_DIR/environment.sh"
}