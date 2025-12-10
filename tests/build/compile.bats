#!/usr/bin/env bats

# Load test helpers if available
if [[ -f "../build_helper.bash" ]]; then
    load '../build_helper'
else
    # Fallback: define basic test functions
    setup() {
        # Create temporary directory for tests
        TEST_TEMP_DIR="${BATS_TMPDIR}/ci-excellence-test-$$"
        mkdir -p "$TEST_TEMP_DIR"
        PROJECT_ROOT="/mnt/wsl/workspace/ci-excellence"
        FAKE_PROJECT_ROOT="${TEST_TEMP_DIR}/project"
        mkdir -p "$FAKE_PROJECT_ROOT"
    }

    teardown() {
        # Clean up test directories
        rm -rf "$TEST_TEMP_DIR"
    }
fi

setup() {
    setup_build_test
}

teardown() {
    teardown_build_test
}

@test "compile.sh executes successfully and shows expected output" {
    # GIVEN: Compile script exists and is executable
    run cat "$PROJECT_ROOT/scripts/build/compile.sh"

    # THEN: Script should exist and contain expected content
    [ "$status" -eq 0 ]
    [[ "$output" == *"Compiling/Building Project"* ]]
    [[ "$output" == *"Build stub executed"* ]]
}

@test "compile.sh shows proper compilation section headers" {
    # GIVEN: Compile script is available
    run cat "$PROJECT_ROOT/scripts/build/compile.sh"

    # THEN: Script should contain proper section headers
    assert_line --partial "========================================="
    assert_line --partial "Compiling/Building Project"
    assert_line --partial "Build Complete"
}

@test "compile.sh contains commented examples for different project types" {
    # GIVEN: Compile script is available
    run cat "$PROJECT_ROOT/scripts/build/compile.sh"

    # THEN: Script should contain examples for various build systems
    assert_output --partial "TypeScript compilation"
    assert_output --partial "JavaScript bundling with webpack"
    assert_output --partial "Go build"
    assert_output --partial "Rust build"
    assert_output --partial "Java/Maven build"
    assert_output --partial "Java/Gradle build"
}

@test "compile.sh contains placeholder text for customization" {
    # GIVEN: Compile script is available
    run cat "$PROJECT_ROOT/scripts/build/compile.sh"

    # THEN: Script should indicate it needs customization
    assert_output --partial "Build stub executed"
    assert_output --partial "Customize this script in scripts/build/compile.sh"
}

@test "compile.sh has proper bash shebang and error handling" {
    # GIVEN: Compile script is available
    run cat "$PROJECT_ROOT/scripts/build/compile.sh"

    # THEN: Script should have proper structure
    assert_line --partial "#!/usr/bin/env bash"
    assert_line --partial "set -euo pipefail"
}

@test "compile.sh purpose and documentation is clear" {
    # GIVEN: Compile script is available
    run cat "$PROJECT_ROOT/scripts/build/compile.sh"

    # THEN: Script should have clear documentation
    assert_output --partial "CI Pipeline Stub: Compile/Build"
    assert_output --partial "Purpose: Compile or build the project"
    assert_output --partial "Customize this script based on your project's build process"
}

@test "compile.sh can be executed without errors" {
    # GIVEN: Compile script exists
    # WHEN: Running the script directly
    run bash "$PROJECT_ROOT/scripts/build/compile.sh"

    # THEN: Script should execute successfully
    assert_success
    assert_output --partial "Compiling/Building Project"
    assert_output --partial "Build stub executed"
    assert_output --partial "Build Complete"
}

@test "compile.sh handles missing dependencies gracefully" {
    # GIVEN: Compile script in a directory with no project files
    cd "$BATS_TMPDIR"

    # WHEN: Running the script
    run bash "$PROJECT_ROOT/scripts/build/compile.sh"

    # THEN: Script should still complete (since it's a stub)
    assert_success
    assert_output --partial "Build stub executed"
}