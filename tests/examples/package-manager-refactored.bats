#!/usr/bin/env bats

# Example refactored test using the new mock system
# This demonstrates how to use the extracted mock libraries

# Load the mock loader system
load "${BATS_TEST_DIRNAME}/../mocks/mock-loader.bash"
load "${BATS_TEST_DIRNAME}/../test_helper.bash"

setup() {
    # GIVEN: Setup mocks for Node.js development
    bats_setup_with_mocks "nodejs"

    # Create test project structure
    mkdir -p "$BATS_TEST_TMPDIR/project"
    cd "$BATS_TEST_TMPDIR/project"

    # Create package.json
    cat > package.json << 'EOF'
{
  "name": "test-project",
  "version": "1.0.0",
  "description": "Test project"
}
EOF
}

teardown() {
    # Clean up mocks and test environment
    bats_teardown_with_mocks
}

@test "npm install works with mock package manager" {
    # WHEN: Running npm install
    run npm install

    # THEN: Should succeed and show expected output
    assert_success
    assert_output --partial "added 20 packages"
    assert_output --partial "found 0 vulnerabilities"
}

@test "npm test runs successfully" {
    # WHEN: Running npm test
    run npm test

    # THEN: Should succeed and show test results
    assert_success
    assert_output --partial "Test Suites: 15 passed"
    assert_output --partial "Tests:       45 passed"
}

@test "npm build works correctly" {
    # WHEN: Running npm build
    run npm run build

    # THEN: Should succeed and show build completion
    assert_success
    assert_output --partial "Build completed successfully"
}

@test "package manager detection works" {
    # WHEN: Creating different lock files and testing detection
    touch package-lock.json
    run detect_package_manager
    assert_output "npm"

    rm package-lock.json
    touch yarn.lock
    run detect_package_manager
    assert_output "yarn"

    rm yarn.lock
    touch pnpm-lock.yaml
    run detect_package_manager
    assert_output "pnpm"
}

@test "install dependencies works with detected package manager" {
    # WHEN: Creating package-lock.json and installing dependencies
    touch package-lock.json
    run install_dependencies

    # THEN: Should succeed and install with npm
    assert_success
    assert_output --partial "npm ci successful"
}

@test "failure mode works correctly" {
    # GIVEN: Set npm mock to fail
    set_mocks_failure

    # WHEN: Running npm install
    run npm install

    # THEN: Should fail with appropriate error
    assert_failure
    assert_output --partial "npm ci failed"
}

@test "mock configuration can be customized" {
    # GIVEN: Configure specific npm version
    configure_mock "npm_version" "10.0.0"

    # WHEN: Running npm --version
    run npm --version

    # THEN: Should show configured version
    assert_success
    assert_output "10.0.0"
}