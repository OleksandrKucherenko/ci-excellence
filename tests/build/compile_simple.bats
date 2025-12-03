#!/usr/bin/env bats

# Basic test setup
setup() {
    TEST_TEMP_DIR="${BATS_TMPDIR}/ci-excellence-test-$$"
    mkdir -p "$TEST_TEMP_DIR"
    PROJECT_ROOT="/mnt/wsl/workspace/ci-excellence"
    FAKE_PROJECT_ROOT="${TEST_TEMP_DIR}/project"
    mkdir -p "$FAKE_PROJECT_ROOT"
}

teardown() {
    rm -rf "$TEST_TEMP_DIR"
}

@test "compile.sh exists and contains expected content" {
    # GIVEN: Compile script should exist
    # THEN: Script file should exist
    [ -f "$PROJECT_ROOT/scripts/build/compile.sh" ]
}

@test "compile.sh has proper bash shebang and error handling" {
    # GIVEN: Compile script is available
    run cat "$PROJECT_ROOT/scripts/build/compile.sh"

    # THEN: Script should have proper structure
    [ "$status" -eq 0 ]
    [[ "$output" == *"#!/usr/bin/env bash"* ]]
    [[ "$output" == *"set -euo pipefail"* ]]
}

@test "compile.sh shows proper compilation section headers" {
    # GIVEN: Compile script is available
    run cat "$PROJECT_ROOT/scripts/build/compile.sh"

    # THEN: Script should contain proper section headers
    [ "$status" -eq 0 ]
    [[ "$output" == *"========================================="* ]]
    [[ "$output" == *"Compiling/Building Project"* ]]
    [[ "$output" == *"Build Complete"* ]]
}

@test "compile.sh contains commented examples for different project types" {
    # GIVEN: Compile script is available
    run cat "$PROJECT_ROOT/scripts/build/compile.sh"

    # THEN: Script should contain examples for various build systems
    [ "$status" -eq 0 ]
    [[ "$output" == *"TypeScript compilation"* ]]
    [[ "$output" == *"JavaScript bundling with webpack"* ]]
    [[ "$output" == *"Go build"* ]]
    [[ "$output" == *"Rust build"* ]]
}

@test "compile.sh contains placeholder text for customization" {
    # GIVEN: Compile script is available
    run cat "$PROJECT_ROOT/scripts/build/compile.sh"

    # THEN: Script should indicate it needs customization
    [ "$status" -eq 0 ]
    [[ "$output" == *"Build stub executed"* ]]
    [[ "$output" == *"Customize this script in scripts/build/compile.sh"* ]]
}

@test "compile.sh can be executed without errors" {
    # GIVEN: Compile script exists
    # WHEN: Running the script directly
    run bash "$PROJECT_ROOT/scripts/build/compile.sh"

    # THEN: Script should execute successfully
    [ "$status" -eq 0 ]
    [[ "$output" == *"Compiling/Building Project"* ]]
    [[ "$output" == *"Build stub executed"* ]]
    [[ "$output" == *"Build Complete"* ]]
}

@test "compile.sh handles missing dependencies gracefully" {
    # GIVEN: Compile script in a directory with no project files
    cd "$BATS_TMPDIR"

    # WHEN: Running the script
    run bash "$PROJECT_ROOT/scripts/build/compile.sh"

    # THEN: Script should still complete (since it's a stub)
    [ "$status" -eq 0 ]
    [[ "$output" == *"Build stub executed"* ]]
}