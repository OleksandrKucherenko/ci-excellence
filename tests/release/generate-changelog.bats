#!/usr/bin/env bats

# Load deployment test helper
load "${BATS_TEST_DIRNAME}/../test_helper.bash"

setup() {
    # GIVEN: A clean test environment with git repository
    setup_deployment_test_project

    # Initialize a git repository for changelog testing
    cd "$TEST_PROJECT_ROOT"
    git init --quiet
    git config user.email "test@example.com"
    git config user.name "Test User"
    echo "# Test project" > README.md
    git add README.md
    git commit -m "Initial commit" --quiet
    git tag v1.0.0
    echo "New feature" >> README.md
    git add README.md
    git commit -m "Add new feature" --quiet
}

teardown() {
    # Cleanup test environment
    cleanup_deployment_test_project
}

@test "generate changelog script runs without errors" {
    # WHEN: Running the generate-changelog script
    run bash -c "${TEST_RELEASE_DIR}/generate-changelog.sh"

    # THEN: Script executes successfully
    assert_success
}

@test "generate changelog script provides clear output" {
    # WHEN: Running the script
    run bash -c "${TEST_RELEASE_DIR}/generate-changelog.sh"

    # THEN: Output is properly formatted
    assert_success
    assert_line --partial "========================================="
    assert_line --partial "Generating Changelog"
    assert_line --partial "Changelog Generated"
}

@test "generate changelog script includes usage documentation" {
    # GIVEN: Script should document its purpose
    # WHEN: Checking script content
    run grep -E "# CI Pipeline Stub: Generate Changelog" "${TEST_RELEASE_DIR}/generate-changelog.sh"

    # THEN: Documentation is present
    assert_success
    assert_output "# CI Pipeline Stub: Generate Changelog"
}

@test "generate changelog script uses set -euo pipefail" {
    # GIVEN: Script should use strict error handling
    # WHEN: Checking script content
    run grep -E "set -euo pipefail" "${TEST_RELEASE_DIR}/generate-changelog.sh"

    # THEN: Strict mode is enabled
    assert_success
    assert_output "set -euo pipefail"
}

@test "generate changelog script includes proper shebang" {
    # GIVEN: Script should have proper shebang
    # WHEN: Checking script content
    run head -n 1 "${TEST_RELEASE_DIR}/generate-changelog.sh"

    # THEN: Shebang is present
    assert_success
    assert_output "#!/usr/bin/env bash"
}

@test "generate changelog script provides extensible structure" {
    # GIVEN: Script should be extensible
    # WHEN: Checking for customization points
    run grep -E "# Add your changelog generation commands here" "${TEST_RELEASE_DIR}/generate-changelog.sh"

    # THEN: Customization point is present
    assert_success
}

@test "generate changelog script shows stub execution message" {
    # WHEN: Running the script
    run bash -c "${TEST_RELEASE_DIR}/generate-changelog.sh"

    # THEN: Stub execution message is shown
    assert_success
    assert_output --partial "✓ Changelog generation stub executed"
    assert_output --partial "Customize this script in scripts/release/generate-changelog.sh"
}