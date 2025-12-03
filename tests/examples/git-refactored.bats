#!/usr/bin/env bats

# Example refactored git test using the new mock system
# This demonstrates how to use the extracted git mock libraries

# Load the mock loader system
load "${BATS_TEST_DIRNAME}/../mocks/mock-loader.bash"
load "${BATS_TEST_DIRNAME}/../test_helper.bash"

setup() {
    # GIVEN: Setup mocks for git operations
    bats_setup_with_mocks "git"

    # Create test git repository
    cd "$BATS_TEST_TMPDIR"
    git init
    git config user.name "Test User"
    git config user.email "test@example.com"
}

teardown() {
    # Clean up mocks and test environment
    bats_teardown_with_mocks
}

@test "git status works correctly" {
    # WHEN: Running git status
    run git status

    # THEN: Should show clean working directory
    assert_success
    assert_output --partial "nothing to commit"
}

@test "git add and commit work correctly" {
    # GIVEN: Create a test file
    echo "test content" > test.txt

    # WHEN: Adding and committing the file
    run git add test.txt
    assert_success

    run git commit -m "Add test file"
    assert_success
    assert_output --partial "Add test file"
}

@test "git branch operations work correctly" {
    # WHEN: Creating and switching branches
    run git checkout -b feature-branch
    assert_success
    assert_output --partial "Switched to a new branch 'feature-branch'"

    run git branch
    assert_success
    assert_output --partial "* feature-branch"
}

@test "git tag operations work correctly" {
    # WHEN: Creating and listing tags
    run git tag -a v1.0.0 -m "Release version 1.0.0"
    assert_success
    assert_output --partial "Created tag v1.0.0"

    run git tag -l
    assert_success
    assert_output "v1.0.0"
}

@test "git log shows commit history" {
    # WHEN: Running git log
    run git log --oneline

    # THEN: Should show commit history
    assert_success
    assert_output --partial "abc123def456"
}

@test "git mock can be configured for different scenarios" {
    # GIVEN: Configure git for deployment scenario
    setup_git_for_deployment_tests

    # WHEN: Checking current branch
    run git branch --show-current
    assert_output "main"

    # WHEN: Getting current SHA
    run git rev-parse HEAD
    assert_output "deploy123abc456def789ghi012jkl345mno678pqr"
}

@test "git mock can simulate uncommitted changes" {
    # GIVEN: Configure git to have uncommitted changes
    setup_git_repo_with_uncommitted_changes

    # WHEN: Running git status
    run git status

    # THEN: Should show uncommitted changes
    assert_failure
    assert_output --partial "Changes not staged for commit"
}

@test "git remote operations work correctly" {
    # WHEN: Adding and showing remotes
    run git remote add origin https://github.com/user/repo.git
    assert_success

    run git remote -v
    assert_success
    assert_output --partial "origin"
}

@test "git diff works correctly" {
    # GIVEN: Create a file with content
    echo "original content" > test.txt

    # WHEN: Modifying the file and checking diff
    echo "modified content" > test.txt
    run git diff test.txt

    # THEN: Should show diff output
    assert_success
    assert_output --partial "-original content"
    assert_output --partial "+modified content"
}