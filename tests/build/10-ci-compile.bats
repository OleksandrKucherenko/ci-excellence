#!/usr/bin/env bats

load '../build_helper'

setup() {
    setup_build_test
    setup_all_build_mocks
    # Create mock common library in the expected location
    mkdir -p "${FAKE_PROJECT_ROOT}/scripts/lib"
    cp "${TEST_TEMP_DIR}/lib/common.sh" "${FAKE_PROJECT_ROOT}/scripts/lib/common.sh"
}

teardown() {
    teardown_build_test
}

@test "10-ci-compile.sh exists and is executable" {
    # GIVEN: CI compile script should exist
    # THEN: Script file should exist and be executable
    assert_file_exists "$PROJECT_ROOT/scripts/build/10-ci-compile.sh"
    assert_file_executable "$PROJECT_ROOT/scripts/build/10-ci-compile.sh"
}

@test "10-ci-compile.sh has proper shebang and error handling" {
    # GIVEN: CI compile script is available
    run cat "$PROJECT_ROOT/scripts/build/10-ci-compile.sh"

    # THEN: Script should have proper structure
    assert_line --partial "#!/bin/bash"
    assert_line --partial "set -euo pipefail"
}

@test "10-ci-compile.sh sources common utilities correctly" {
    # GIVEN: CI compile script sources common utilities
    run grep -n "source.*common.sh" "$PROJECT_ROOT/scripts/build/10-ci-compile.sh"

    # THEN: Script should source common utilities
    assert_success
    assert_output --partial "scripts/lib/common.sh"
}

@test "10-ci-compile.sh detects Node.js project correctly" {
    # GIVEN: A Node.js project structure
    create_fake_project "nodejs"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running compile script with detect mode
    run bash "$PROJECT_ROOT/scripts/build/10-ci-compile.sh" detect

    # THEN: Should detect Node.js project
    assert_success
    assert_output --partial "nodejs"
}

@test "10-ci-compile.sh detects Python project correctly" {
    # GIVEN: A Python project structure
    create_fake_project "python"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running compile script with detect mode
    run bash "$PROJECT_ROOT/scripts/build/10-ci-compile.sh" detect

    # THEN: Should detect Python project
    assert_success
    assert_output --partial "python"
}

@test "10-ci-compile.sh detects Go project correctly" {
    # GIVEN: A Go project structure
    create_fake_project "go"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running compile script with detect mode
    run bash "$PROJECT_ROOT/scripts/build/10-ci-compile.sh" detect

    # THEN: Should detect Go project
    assert_success
    assert_output --partial "go"
}

@test "10-ci-compile.sh detects Rust project correctly" {
    # GIVEN: A Rust project structure
    create_fake_project "rust"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running compile script with detect mode
    run bash "$PROJECT_ROOT/scripts/build/10-ci-compile.sh" detect

    # THEN: Should detect Rust project
    assert_success
    assert_output --partial "rust"
}

@test "10-ci-compile.sh detects generic project correctly" {
    # GIVEN: A generic project structure
    create_fake_project "generic"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running compile script with detect mode
    run bash "$PROJECT_ROOT/scripts/build/10-ci-compile.sh" detect

    # THEN: Should detect generic project
    assert_success
    assert_output --partial "generic"
}

@test "10-ci-compile.sh handles DRY_RUN mode correctly" {
    # GIVEN: Test environment with DRY_RUN mode
    export CI_TEST_MODE="DRY_RUN"
    create_fake_project "nodejs"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running compile script
    run bash "$PROJECT_ROOT/scripts/build/10-ci-compile.sh"

    # THEN: Should perform dry run
    assert_success
    assert_output --partial "DRY RUN"
    assert_output --partial "Would compile project"
    assert_output --partial "Would create build artifacts"
}

@test "10-ci-compile.sh handles PASS mode correctly" {
    # GIVEN: Test environment with PASS mode
    export CI_TEST_MODE="PASS"
    create_fake_project "nodejs"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running compile script
    run bash "$PROJECT_ROOT/scripts/build/10-ci-compile.sh"

    # THEN: Should simulate success
    assert_success
    assert_output --partial "PASS MODE"
    assert_output --partial "simulated successfully"
}

@test "10-ci-compile.sh handles FAIL mode correctly" {
    # GIVEN: Test environment with FAIL mode
    export CI_TEST_MODE="FAIL"
    create_fake_project "nodejs"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running compile script
    run bash "$PROJECT_ROOT/scripts/build/10-ci-compile.sh"

    # THEN: Should simulate failure
    assert_failure
    assert_output --partial "FAIL MODE"
    assert_output --partial "Simulating compile failure"
}

@test "10-ci-compile.sh handles SKIP mode correctly" {
    # GIVEN: Test environment with SKIP mode
    export CI_TEST_MODE="SKIP"
    create_fake_project "nodejs"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running compile script
    run bash "$PROJECT_ROOT/scripts/build/10-ci-compile.sh"

    # THEN: Should skip compilation
    assert_success
    assert_output --partial "SKIP MODE"
    assert_output --partial "Compile skipped"
}

@test "10-ci-compile.sh compiles Node.js project successfully" {
    # GIVEN: Node.js project with mocks
    create_fake_project "nodejs"
    setup_nodejs_mocks
    set_mock_output "tsc" "TypeScript compilation complete"
    set_mock_output "npm" "Build complete"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running compile script
    run bash "$PROJECT_ROOT/scripts/build/10-ci-compile.sh" nodejs

    # THEN: Should compile Node.js project
    assert_success
    assert_output --partial "Compiling Node.js project"
    assert_output --partial "Node.js build completed"
}

@test "10-ci-compile.sh compiles Python project successfully" {
    # GIVEN: Python project with mocks
    create_fake_project "python"
    setup_python_mocks
    set_mock_output "python" "Compilation complete"
    set_mock_output "pip" "Dependencies installed"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running compile script
    run bash "$PROJECT_ROOT/scripts/build/10-ci-compile.sh" python

    # THEN: Should compile Python project
    assert_success
    assert_output --partial "Compiling Python project"
    assert_output --partial "Python compilation completed"
}

@test "10-ci-compile.sh compiles Go project successfully" {
    # GIVEN: Go project with mocks
    create_fake_project "go"
    setup_go_mocks
    set_mock_output "go" "Build complete"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running compile script
    run bash "$PROJECT_ROOT/scripts/build/10-ci-compile.sh" go

    # THEN: Should compile Go project
    assert_success
    assert_output --partial "Compiling Go project"
    assert_output --partial "Go compilation completed"
}

@test "10-ci-compile.sh compiles Rust project successfully" {
    # GIVEN: Rust project with mocks
    create_fake_project "rust"
    setup_rust_mocks
    set_mock_output "cargo" "Build complete"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running compile script
    run bash "$PROJECT_ROOT/scripts/build/10-ci-compile.sh" rust

    # THEN: Should compile Rust project
    assert_success
    assert_output --partial "Compiling Rust project"
    assert_output --partial "Rust compilation completed"
}

@test "10-ci-compile.sh generates build metadata" {
    # GIVEN: Node.js project with mocks
    create_fake_project "nodejs"
    setup_nodejs_mocks
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running compile script
    run bash "$PROJECT_ROOT/scripts/build/10-ci-compile.sh" nodejs

    # THEN: Should generate build metadata
    assert_success
    assert_file_exists "${FAKE_PROJECT_ROOT}/dist/build-metadata.json"
}

@test "10-ci-compile.sh creates build directory" {
    # GIVEN: Node.js project with mocks
    create_fake_project "nodejs"
    setup_nodejs_mocks
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running compile script
    run bash "$PROJECT_ROOT/scripts/build/10-ci-compile.sh" nodejs

    # THEN: Should create build directory
    assert_success
    assert_dir_exists "${FAKE_PROJECT_ROOT}/dist"
}

@test "10-ci-compile.sh handles missing tools gracefully" {
    # GIVEN: Node.js project without npm
    create_fake_project "nodejs"
    remove_mock "npm"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running compile script
    run bash "$PROJECT_ROOT/scripts/build/10-ci-compile.sh" nodejs

    # THEN: Should fail gracefully
    assert_failure
    assert_output --partial "npm is not available"
}

@test "10-ci-compile.sh validates compilation setup" {
    # GIVEN: Node.js project with mocks
    create_fake_project "nodejs"
    setup_nodejs_mocks
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running compile script in validate mode
    run bash "$PROJECT_ROOT/scripts/build/10-ci-compile.sh" validate

    # THEN: Should validate setup
    assert_success
    assert_output --partial "Validating compile setup"
    assert_output --partial "Project type: nodejs"
    assert_output --partial "npm available"
}

@test "10-ci-compile.sh shows help information" {
    # GIVEN: CI compile script
    # WHEN: Running with help flag
    run bash "$PROJECT_ROOT/scripts/build/10-ci-compile.sh" help

    # THEN: Should show help information
    assert_success
    assert_output --partial "CI Compile Script"
    assert_output --partial "Usage:"
    assert_output --partial "Project Types:"
    assert_output --partial "Environment Variables:"
}

@test "10-ci-compile.sh supports hierarchical testability control" {
    # GIVEN: Pipeline-specific override
    export PIPELINE_COMPILE_MODE="PASS"
    create_fake_project "nodejs"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running compile script
    run bash "$PROJECT_ROOT/scripts/build/10-ci-compile.sh" nodejs

    # THEN: Should use pipeline override
    assert_success
    assert_output --partial "PASS MODE"
}

@test "10-ci-compile.sh supports script-specific testability control" {
    # GIVEN: Script-specific override
    export COMPILE_MODE="SKIP"
    create_fake_project "nodejs"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running compile script
    run bash "$PROJECT_ROOT/scripts/build/10-ci-compile.sh" nodejs

    # THEN: Should use script-specific override
    assert_success
    assert_output --partial "SKIP MODE"
}

@test "10-ci-compile.sh generates valid JSON metadata" {
    # GIVEN: Node.js project with mocks
    create_fake_project "nodejs"
    setup_nodejs_mocks
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running compile script
    run bash "$PROJECT_ROOT/scripts/build/10-ci-compile.sh" nodejs

    # THEN: Should generate valid JSON metadata
    assert_success
    run cat "${FAKE_PROJECT_ROOT}/dist/build-metadata.json"
    assert_success
    is_valid_json "$output"
}

@test "10-ci-compile.sh handles TypeScript compilation" {
    # GIVEN: Node.js project with TypeScript
    create_fake_project "nodejs"
    echo '{"compilerOptions": {"target": "ES2020"}}' > "${FAKE_PROJECT_ROOT}/tsconfig.json"
    setup_nodejs_mocks
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running compile script
    run bash "$PROJECT_ROOT/scripts/build/10-ci-compile.sh" nodejs

    # THEN: Should handle TypeScript compilation
    assert_success
    assert_output --partial "TypeScript compilation"
}

@test "10-ci-compile.sh provides comprehensive error reporting" {
    # GIVEN: Project with compilation failure
    create_fake_project "nodejs"
    setup_nodejs_mocks
    set_mock_mode "npm" "fail"
    set_mock_exit_code "npm" "1"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running compile script
    run bash "$PROJECT_ROOT/scripts/build/10-ci-compile.sh" nodejs

    # THEN: Should report compilation failure
    assert_failure
    assert_output --partial "Node.js build failed"
    assert_output --partial "Compile script failed"
}