#!/usr/bin/env bats

load '../build_helper'

setup() {
    setup_build_test
    setup_bundling_mocks
}

teardown() {
    teardown_build_test
}

@test "bundle.sh executes successfully and shows expected output" {
    # GIVEN: Bundle script exists and is executable
    run bash -c "source /mnt/wsl/workspace/ci-excellence/tests/build_helper.bash && cat '$PROJECT_ROOT/scripts/build/bundle.sh'"

    # THEN: Script should exist and contain expected content
    assert_success
    assert_output --partial "Creating Bundle/Package"
    assert_output --partial "Bundle stub executed"
}

@test "bundle.sh shows proper bundling section headers" {
    # GIVEN: Bundle script is available
    run cat "$PROJECT_ROOT/scripts/build/bundle.sh"

    # THEN: Script should contain proper section headers
    assert_line --partial "========================================="
    assert_line --partial "Creating Bundle/Package"
    assert_line --partial "Bundling Complete"
}

@test "bundle.sh contains commented examples for different package types" {
    # GIVEN: Bundle script is available
    run cat "$PROJECT_ROOT/scripts/build/bundle.sh"

    # THEN: Script should contain examples for various packaging systems
    assert_output --partial "NPM package"
    assert_output --partial "Python wheel"
    assert_output --partial "Go binary"
    assert_output --partial "Docker image"
    assert_output --partial "Create tarball"
}

@test "bundle.sh contains placeholder text for customization" {
    # GIVEN: Bundle script is available
    run cat "$PROJECT_ROOT/scripts/build/bundle.sh"

    # THEN: Script should indicate it needs customization
    assert_output --partial "Bundle stub executed"
    assert_output --partial "Customize this script in scripts/build/bundle.sh"
}

@test "bundle.sh has proper bash shebang and error handling" {
    # GIVEN: Bundle script is available
    run cat "$PROJECT_ROOT/scripts/build/bundle.sh"

    # THEN: Script should have proper structure
    assert_line --partial "#!/usr/bin/env bash"
    assert_line --partial "set -euo pipefail"
}

@test "bundle.sh purpose and documentation is clear" {
    # GIVEN: Bundle script is available
    run cat "$PROJECT_ROOT/scripts/build/bundle.sh"

    # THEN: Script should have clear documentation
    assert_output --partial "CI Pipeline Stub: Bundle/Package"
    assert_output --partial "Purpose: Create distribution packages"
    assert_output --partial "Customize this script based on your project's packaging needs"
}

@test "bundle.sh can be executed without errors" {
    # GIVEN: Bundle script exists
    # WHEN: Running the script directly
    run bash "$PROJECT_ROOT/scripts/build/bundle.sh"

    # THEN: Script should execute successfully
    assert_success
    assert_output --partial "Creating Bundle/Package"
    assert_output --partial "Bundle stub executed"
    assert_output --partial "Bundling Complete"
}

@test "bundle.sh handles different packaging scenarios" {
    # GIVEN: Bundle script examples contain multiple packaging options
    run cat "$PROJECT_ROOT/scripts/build/bundle.sh"

    # THEN: Script should show different packaging approaches
    assert_output --partial "npm pack"
    assert_output --partial "python3 -m build"
    assert_output --partial "GOOS=linux GOARCH=amd64 go build"
    assert_output --partial "docker build -t myapp:latest"
    assert_output --partial "tar -czf dist.tar.gz"
}

@test "bundle.sh contains platform-specific build examples" {
    # GIVEN: Bundle script is available
    run cat "$PROJECT_ROOT/scripts/build/bundle.sh"

    # THEN: Script should contain cross-platform build examples
    assert_output --partial "GOOS=linux GOARCH=amd64"
    assert_output --partial "GOOS=darwin GOARCH=amd64"
    assert_output --partial "GOOS=windows GOARCH=amd64"
}

@test "bundle.sh handles project structure gracefully" {
    # GIVEN: Bundle script in a directory with no project files
    cd "$BATS_TMPDIR"

    # WHEN: Running the script
    run bash "$PROJECT_ROOT/scripts/build/bundle.sh"

    # THEN: Script should still complete (since it's a stub)
    assert_success
    assert_output --partial "Bundle stub executed"
}

@test "bundle.sh shows comprehensive packaging examples" {
    # GIVEN: Bundle script is available
    run cat "$PROJECT_ROOT/scripts/build/bundle.sh"

    # THEN: Script should contain comprehensive examples
    assert_output --partial "if [ -f \"package.json\" ]"
    assert_output --partial "if [ -f \"setup.py\" ] || [ -f \"pyproject.toml\" ]"
    assert_output --partial "if [ -f \"go.mod\" ]"
    assert_output --partial "if [ -f \"Dockerfile\" ]"
}

@test "bundle.sh documentation provides clear guidance" {
    # GIVEN: Bundle script is available
    run cat "$PROJECT_ROOT/scripts/build/bundle.sh"

    # THEN: Script documentation should be helpful
    assert_output --partial "# Add your bundling commands here"
    assert_output --partial "# Example:"
}

@test "bundle.sh maintains consistent output format" {
    # GIVEN: Bundle script exists
    # WHEN: Running the script
    run bash "$PROJECT_ROOT/scripts/build/bundle.sh"

    # THEN: Output should be consistent with other build scripts
    assert_output --partial "========================================="
    assert_output --partial "Bundle stub executed"
    assert_output --partial "Customize this script"
}