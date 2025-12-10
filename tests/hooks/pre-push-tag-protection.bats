#!/usr/bin/env bats

# Load test helper
load "${BATS_TEST_DIRNAME}/../test_helper.bash"

setup() {
    # GIVEN: A git repository with hook scripts available
    setup_git_hooks_test
    configure_tag_protection_hook
    set_execute_mode
}

teardown() {
    # Cleanup test environment
    cleanup_git_hooks_test
}

@test "pre-push-tag-protection: script exists and is executable" {
    # GIVEN: The tag protection hook script should exist
    [[ -f "$TEST_HOOKS_DIR/pre-push-tag-protection.sh" ]]
    [[ -x "$TEST_HOOKS_DIR/pre-push-tag-protection.sh" ]]
}

@test "pre-push-tag-protection: shows help information" {
    # WHEN: Script is called with help flag
    run run_hook_script "pre-push-tag-protection.sh" "help"

    # THEN: Help information should be displayed
    assert_success
    assert_line --partial "Tag Protection Hook"
    assert_line --partial "Usage:"
}

@test "pre-push-tag-protection: validates git repository" {
    # GIVEN: Script runs outside a git repository
    cd "$BATS_TEST_TMPDIR"
    export PROJECT_ROOT="$BATS_TEST_TMPDIR"

    # WHEN: Tag protection check runs
    run "$TEST_HOOKS_DIR/pre-push-tag-protection.sh"

    # THEN: Should fail with git repository error
    assert_failure
    assert_line --partial "Not in a git repository"
}

@test "pre-push-tag-protection: allows valid version tags" {
    # GIVEN: Valid version tags are pushed
    create_version_tag
    echo "refs/tags/v1.2.3 $TEST_PROJECT_ROOT/HEAD" | run_hook_script "pre-push-tag-protection.sh"

    # WHEN: Tag protection check runs with valid version tag
    run bash -c "echo 'refs/tags/v1.2.3 $TEST_PROJECT_ROOT/HEAD' | '$TEST_HOOKS_DIR/pre-push-tag-protection.sh'"

    # THEN: Should allow version tags
    assert_success
    assert_line --partial "✓ Tag validation passed for: v1.2.3"
}

@test "pre-push-tag-protection: allows semantic version tags with prerelease" {
    # GIVEN: Semantic version with prerelease
    create_test_tag "v1.2.3-alpha.1"

    # WHEN: Tag protection check runs
    run bash -c "echo 'refs/tags/v1.2.3-alpha.1 $TEST_PROJECT_ROOT/HEAD' | '$TEST_HOOKS_DIR/pre-push-tag-protection.sh'"

    # THEN: Should allow version tags with prerelease
    assert_success
    assert_line --partial "✓ Tag validation passed for: v1.2.3-alpha.1"
}

@test "pre-push-tag-protection: allows semantic version tags with build metadata" {
    # GIVEN: Semantic version with build metadata
    create_test_tag "v1.2.3+build.123"

    # WHEN: Tag protection check runs
    run bash -c "echo 'refs/tags/v1.2.3+build.123 $TEST_PROJECT_ROOT/HEAD' | '$TEST_HOOKS_DIR/pre-push-tag-protection.sh'"

    # THEN: Should allow version tags with build metadata
    assert_success
    assert_line --partial "✓ Tag validation passed for: v1.2.3+build.123"
}

@test "pre-push-tag-protection: blocks environment tags in ENFORCE mode" {
    # GIVEN: Environment tags are protected
    configure_tag_protection_hook "ENFORCE"
    create_environment_tag

    # WHEN: Tag protection check runs with environment tag
    run bash -c "echo 'refs/tags/production $TEST_PROJECT_ROOT/HEAD' | '$TEST_HOOKS_DIR/pre-push-tag-protection.sh'"

    # THEN: Should block environment tags
    assert_failure
    assert_line --partial "Environment tag 'production' cannot be created manually"
    assert_line --partial "PROTECTION ENFORCED: Tag creation blocked"
}

@test "pre-push-tag-protection: warns about environment tags in WARN mode" {
    # GIVEN: Warning mode is enabled
    configure_tag_protection_hook "WARN"
    create_environment_tag

    # WHEN: Tag protection check runs with environment tag
    run bash -c "echo 'refs/tags/production $TEST_PROJECT_ROOT/HEAD' | '$TEST_HOOKS_DIR/pre-push-tag-protection.sh'"

    # THEN: Should warn but allow environment tags
    assert_success
    assert_line --partial "Environment tag 'production' cannot be created manually"
    assert_line --partial "PROTECTION WARNING: Manual tag creation may cause deployment issues"
}

@test "pre-push-tag-protection: blocks feature branch tags" {
    # GIVEN: Feature branch tags are protected
    create_feature_tag

    # WHEN: Tag protection check runs with feature tag
    run bash -c "echo 'refs/tags/feature/new-feature $TEST_PROJECT_ROOT/HEAD' | '$TEST_HOOKS_DIR/pre-push-tag-protection.sh'"

    # THEN: Should block feature tags
    assert_failure
    assert_line --partial "Feature branch tag 'feature/new-feature' is not allowed"
    assert_line --partial "PROTECTION ENFORCED: Tag creation blocked"
}

@test "pre-push-tag-protection: blocks hotfix branch tags" {
    # GIVEN: Hotfix branch tags are protected
    create_test_tag "hotfix/critical-bug"

    # WHEN: Tag protection check runs with hotfix tag
    run bash -c "echo 'refs/tags/hotfix/critical-bug $TEST_PROJECT_ROOT/HEAD' | '$TEST_HOOKS_DIR/pre-push-tag-protection.sh'"

    # THEN: Should block hotfix tags
    assert_failure
    assert_line --partial "Feature branch tag 'hotfix/critical-bug' is not allowed"
}

@test "pre-push-tag-protection: allows state tags" {
    # GIVEN: State tags are allowed
    create_test_tag "abc123-testing"

    # WHEN: Tag protection check runs with state tag
    run bash -c "echo 'refs/tags/abc123-testing $TEST_PROJECT_ROOT/HEAD' | '$TEST_HOOKS_DIR/pre-push-tag-protection.sh'"

    # THEN: Should allow state tags
    assert_success
    assert_line --partial "✓ Tag validation passed for: abc123-testing"
}

@test "pre-push-tag-protection: blocks duplicate immutable tags" {
    # GIVEN: An immutable tag already exists
    create_test_tag "v1.2.3"
    # Create the same tag again to simulate duplicate
    create_test_tag "v1.2.3" 2>/dev/null || true

    # WHEN: Tag protection check runs with duplicate tag
    run bash -c "echo 'refs/tags/v1.2.3 $TEST_PROJECT_ROOT/HEAD' | '$TEST_HOOKS_DIR/pre-push-tag-protection.sh'"

    # THEN: Should block duplicate immutable tags
    assert_failure
    assert_line --partial "version tag 'v1.2.3' already exists and is immutable"
}

@test "pre-push-tag-protection: allows movable environment tags" {
    # GIVEN: Environment tags are movable
    configure_tag_protection_hook "WARN"  # Use warn mode to allow
    create_environment_tag
    delete_test_tag "production"
    create_environment_tag

    # WHEN: Tag protection check runs with moved environment tag
    run bash -c "echo 'refs/tags/production $TEST_PROJECT_ROOT/HEAD' | '$TEST_HOOKS_DIR/pre-push-tag-protection.sh'"

    # THEN: Should warn but allow movable tags
    assert_success
    assert_line --partial "Environment tag 'production' is movable"
}

@test "pre-push-tag-protection: handles multiple tags in single push" {
    # GIVEN: Multiple tags are pushed
    create_version_tag
    create_test_tag "v2.0.0"
    create_test_tag "abc123-stable"

    # WHEN: Tag protection check runs with multiple tags
    run bash -c "echo 'refs/tags/v1.2.3 $TEST_PROJECT_ROOT/HEAD
refs/tags/v2.0.0 $TEST_PROJECT_ROOT/HEAD
refs/tags/abc123-stable $TEST_PROJECT_ROOT/HEAD' | '$TEST_HOOKS_DIR/pre-push-tag-protection.sh'"

    # THEN: Should validate all tags
    assert_success
    assert_line --partial "✓ Tag validation passed for: v1.2.3"
    assert_line --partial "✓ Tag validation passed for: v2.0.0"
    assert_line --partial "✓ Tag validation passed for: abc123-stable"
}

@test "pre-push-tag-protection: fails when any tag in batch is invalid" {
    # GIVEN: Mix of valid and invalid tags
    create_version_tag
    create_environment_tag

    # WHEN: Tag protection check runs with mixed tags
    run bash -c "echo 'refs/tags/v1.2.3 $TEST_PROJECT_ROOT/HEAD
refs/tags/production $TEST_PROJECT_ROOT/HEAD' | '$TEST_HOOKS_DIR/pre-push-tag-protection.sh'"

    # THEN: Should fail due to invalid tag
    assert_failure
    assert_line --partial "Invalid tags found: production"
}

@test "pre-push-tag-protection: skips protection when OFF mode" {
    # GIVEN: Protection is disabled
    configure_tag_protection_hook "OFF"
    create_environment_tag
    create_feature_tag

    # WHEN: Tag protection check runs with normally protected tags
    run bash -c "echo 'refs/tags/production $TEST_PROJECT_ROOT/HEAD
refs/tags/feature/test $TEST_PROJECT_ROOT/HEAD' | '$TEST_HOOKS_DIR/pre-push-tag-protection.sh'"

    # THEN: Should skip all protection
    assert_success
    assert_line --partial "Tag protection is disabled"
}

@test "pre-push-tag-protection: validates individual tags manually" {
    # GIVEN: Manual validation mode is used
    create_version_tag

    # WHEN: Individual tag is validated
    run run_hook_script "pre-push-tag-protection.sh" "check" "v1.2.3"

    # THEN: Should validate single tag
    assert_success
}

@test "pre-push-tag-protection: rejects invalid tag patterns manually" {
    # GIVEN: Invalid tag pattern is tested
    create_feature_tag

    # WHEN: Individual tag is validated
    run run_hook_script "pre-push-tag-protection.sh" "check" "feature/bad-tag"

    # THEN: Should reject invalid tag
    assert_failure
}

@test "pre-push-tag-protection: validates multiple tags manually" {
    # GIVEN: Multiple tags are validated
    create_version_tag
    create_test_tag "v2.0.0"
    create_test_tag "abc123-testing"

    # WHEN: Multiple tags are validated
    run run_hook_script "pre-push-tag-protection.sh" "validate" "v1.2.3" "v2.0.0" "abc123-testing"

    # THEN: Should validate all tags
    assert_success
    assert_line --partial "All tags validated successfully"
}

@test "pre-push-tag-protection: shows unknown tag patterns as warnings" {
    # GIVEN: Unknown tag pattern
    create_test_tag "random-tag-name"

    # WHEN: Unknown tag is validated
    run run_hook_script "pre-push-tag-protection.sh" "check" "random-tag-name"

    # THEN: Should show warning but allow in non-strict mode
    assert_failure
    assert_line --partial "Unknown tag pattern: 'random-tag-name'"
}

@test "pre-push-tag-protection: handles empty push gracefully" {
    # GIVEN: No tags are pushed

    # WHEN: Tag protection check runs with no input
    run bash -c "echo '' | '$TEST_HOOKS_DIR/pre-push-tag-protection.sh'"

    # THEN: Should succeed with no tags message
    assert_success
}

@test "pre-push-tag-protection: handles non-tag references gracefully" {
    # GIVEN: Non-tag references are pushed
    echo "refs/heads/main $TEST_PROJECT_ROOT/HEAD" | run_hook_script "pre-push-tag-protection.sh"

    # WHEN: Tag protection check runs with branch references
    run bash -c "echo 'refs/heads/main $TEST_PROJECT_ROOT/HEAD' | '$TEST_HOOKS_DIR/pre-push-tag-protection.sh'"

    # THEN: Should ignore non-tag references
    assert_success
}

@test "pre-push-tag-protection: respects TAG_PROTECTION_MODE environment variable" {
    # GIVEN: Protection mode is set via environment
    export TAG_PROTECTION_MODE="WARN"
    create_environment_tag

    # WHEN: Tag protection check runs
    run bash -c "echo 'refs/tags/production $TEST_PROJECT_ROOT/HEAD' | '$TEST_HOOKS_DIR/pre-push-tag-protection.sh'"

    # THEN: Should use configured protection mode
    assert_success
    assert_line --partial "Protection mode: WARN"
}

@test "pre-push-tag-protection: defaults to ENFORCE mode when mode is invalid" {
    # GIVEN: Invalid protection mode is set
    export TAG_PROTECTION_MODE="INVALID"
    create_environment_tag

    # WHEN: Tag protection check runs
    run bash -c "echo 'refs/tags/production $TEST_PROJECT_ROOT/HEAD' | '$TEST_HOOKS_DIR/pre-push-tag-protection.sh'"

    # THEN: Should default to ENFORCE mode
    assert_failure
    assert_line --partial "Unknown protection mode: INVALID, defaulting to ENFORCE"
}

@test "pre-push-tag-protection: works in DRY_RUN mode" {
    # GIVEN: Dry run mode is enabled
    set_dry_run_mode
    create_version_tag

    # WHEN: Tag protection check runs
    run bash -c "echo 'refs/tags/v1.2.3 $TEST_PROJECT_ROOT/HEAD' | '$TEST_HOOKS_DIR/pre-push-tag-protection.sh'"

    # THEN: Should simulate without actual validation
    assert_success
    assert_line --partial "DRY_RUN: Would validate tag protection"
}

@test "pre-push-tag-protection: works in PASS mode" {
    # GIVEN: Pass mode is enabled
    set_pass_mode
    create_environment_tag

    # WHEN: Tag protection check runs
    run bash -c "echo 'refs/tags/production $TEST_PROJECT_ROOT/HEAD' | '$TEST_HOOKS_DIR/pre-push-tag-protection.sh'"

    # THEN: Should simulate success regardless of actual tag validity
    assert_success
    assert_line --partial "PASS MODE: Tag protection validation simulated successfully"
}

@test "pre-push-tag-protection: works in FAIL mode" {
    # GIVEN: Fail mode is enabled
    set_fail_mode
    create_version_tag

    # WHEN: Tag protection check runs
    run bash -c "echo 'refs/tags/v1.2.3 $TEST_PROJECT_ROOT/HEAD' | '$TEST_HOOKS_DIR/pre-push-tag-protection.sh'"

    # THEN: Should simulate failure regardless of actual tag validity
    assert_failure
    assert_line --partial "FAIL MODE: Simulating tag protection validation failure"
}

@test "pre-push-tag-protection: works in SKIP mode" {
    # GIVEN: Skip mode is enabled
    set_skip_mode
    create_environment_tag

    # WHEN: Tag protection check runs
    run bash -c "echo 'refs/tags/production $TEST_PROJECT_ROOT/HEAD' | '$TEST_HOOKS_DIR/pre-push-tag-protection.sh'"

    # THEN: Should skip execution
    assert_success
    assert_line --partial "SKIP MODE: Tag protection validation skipped"
}

@test "pre-push-tag-protection: respects script version" {
    # WHEN: Help is requested
    run run_hook_script "pre-push-tag-protection.sh" "help"

    # THEN: Should show version information
    assert_success
    assert_line --partial "Tag Protection Hook v1.0.0"
}

@test "pre-push-tag-protection: handles malformed input gracefully" {
    # GIVEN: Malformed push input
    # WHEN: Tag protection check runs with malformed input
    run bash -c "echo 'malformed input without proper format' | '$TEST_HOOKS_DIR/pre-push-tag-protection.sh'"

    # THEN: Should handle gracefully
    assert_success
    # Should not fail due to malformed input
}

@test "pre-push-tag-protection: validates tag pattern edge cases" {
    # GIVEN: Edge case tag patterns
    create_test_tag "v0.0.1"  # Minimum valid version
    create_test_tag "v999.999.999"  # Maximum realistic version
    create_test_tag "v1.2.3-alpha.1+build.123"  # Complex version

    # WHEN: Complex versions are validated
    run run_hook_script "pre-push-tag-protection.sh" "validate" "v0.0.1" "v999.999.999" "v1.2.3-alpha.1+build.123"

    # THEN: Should validate complex versions
    assert_success
}

@test "pre-push-tag-protection: rejects clearly invalid tags" {
    # GIVEN: Clearly invalid tag patterns
    # WHEN: Invalid tags are validated
    run run_hook_script "pre-push-tag-protection.sh" "validate" "" "." "v1.2" "v1.2.3.4"

    # THEN: Should reject invalid tags
    assert_failure
}

@test "pre-push-tag-protection: provides helpful error messages" {
    # GIVEN: Invalid tag with specific pattern
    # WHEN: Invalid environment tag is validated
    run run_hook_script "pre-push-tag-protection.sh" "check" "production"

    # THEN: Should provide helpful error message
    assert_failure
    assert_line --partial "Use GitHub Actions tag-assignment workflow to manage environment tags"
}

@test "pre-push-tag-protection: handles release branch tags" {
    # GIVEN: Release branch tag pattern
    create_test_tag "release/v1.2.3"

    # WHEN: Release tag is validated
    run run_hook_script "pre-push-tag-protection.sh" "check" "release/v1.2.3"

    # THEN: Should block release branch tags
    assert_failure
    assert_line --partial "Feature branch tag 'release/v1.2.3' is not allowed"
}

@test "pre-push-tag-protection: allows state tags with different statuses" {
    # GIVEN: Various state tag patterns
    create_test_tag "abc123-stable"
    create_test_tag "def456-unstable"
    create_test_tag "ghi789-deprecated"
    create_test_tag "jkl012-maintenance"

    # WHEN: State tags are validated
    run run_hook_script "pre-push-tag-protection.sh" "validate" "abc123-stable" "def456-unstable" "ghi789-deprecated" "jkl012-maintenance"

    # THEN: Should allow all state tags
    assert_success
}