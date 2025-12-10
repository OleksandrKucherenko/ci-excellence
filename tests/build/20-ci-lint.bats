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

@test "20-ci-lint.sh exists and is executable" {
    # GIVEN: CI lint script should exist
    # THEN: Script file should exist and be executable
    assert_file_exists "$PROJECT_ROOT/scripts/build/20-ci-lint.sh"
    assert_file_executable "$PROJECT_ROOT/scripts/build/20-ci-lint.sh"
}

@test "20-ci-lint.sh has proper shebang and error handling" {
    # GIVEN: CI lint script is available
    run cat "$PROJECT_ROOT/scripts/build/20-ci-lint.sh"

    # THEN: Script should have proper structure
    assert_line --partial "#!/bin/bash"
    assert_line --partial "set -euo pipefail"
}

@test "20-ci-lint.sh sources common utilities correctly" {
    # GIVEN: CI lint script sources common utilities
    run grep -n "source.*common.sh" "$PROJECT_ROOT/scripts/build/20-ci-lint.sh"

    # THEN: Script should source common utilities
    assert_success
    assert_output --partial "scripts/lib/common.sh"
}

@test "20-ci-lint.sh detects Node.js project correctly" {
    # GIVEN: A Node.js project structure
    create_fake_project "nodejs"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running lint script with detect mode
    run bash "$PROJECT_ROOT/scripts/build/20-ci-lint.sh" detect

    # THEN: Should detect Node.js project
    assert_success
    assert_output --partial "nodejs"
}

@test "20-ci-lint.sh detects Python project correctly" {
    # GIVEN: A Python project structure
    create_fake_project "python"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running lint script with detect mode
    run bash "$PROJECT_ROOT/scripts/build/20-ci-lint.sh" detect

    # THEN: Should detect Python project
    assert_success
    assert_output --partial "python"
}

@test "20-ci-lint.sh detects Go project correctly" {
    # GIVEN: A Go project structure
    create_fake_project "go"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running lint script with detect mode
    run bash "$PROJECT_ROOT/scripts/build/20-ci-lint.sh" detect

    # THEN: Should detect Go project
    assert_success
    assert_output --partial "go"
}

@test "20-ci-lint.sh detects Rust project correctly" {
    # GIVEN: A Rust project structure
    create_fake_project "rust"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running lint script with detect mode
    run bash "$PROJECT_ROOT/scripts/build/20-ci-lint.sh" detect

    # THEN: Should detect Rust project
    assert_success
    assert_output --partial "rust"
}

@test "20-ci-lint.sh handles DRY_RUN mode correctly" {
    # GIVEN: Test environment with DRY_RUN mode
    export CI_TEST_MODE="DRY_RUN"
    create_fake_project "nodejs"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running lint script
    run bash "$PROJECT_ROOT/scripts/build/20-ci-lint.sh"

    # THEN: Should perform dry run
    assert_success
    assert_output --partial "DRY RUN"
    assert_output --partial "Would lint project"
    assert_output --partial "Would run linters and generate report"
}

@test "20-ci-lint.sh handles PASS mode correctly" {
    # GIVEN: Test environment with PASS mode
    export CI_TEST_MODE="PASS"
    create_fake_project "nodejs"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running lint script
    run bash "$PROJECT_ROOT/scripts/build/20-ci-lint.sh"

    # THEN: Should simulate success
    assert_success
    assert_output --partial "PASS MODE"
    assert_output --partial "simulated successfully"
}

@test "20-ci-lint.sh handles FAIL mode correctly" {
    # GIVEN: Test environment with FAIL mode
    export CI_TEST_MODE="FAIL"
    create_fake_project "nodejs"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running lint script
    run bash "$PROJECT_ROOT/scripts/build/20-ci-lint.sh"

    # THEN: Should simulate failure
    assert_failure
    assert_output --partial "FAIL MODE"
    assert_output --partial "Simulating lint failure"
}

@test "20-ci-lint.sh handles SKIP mode correctly" {
    # GIVEN: Test environment with SKIP mode
    export CI_TEST_MODE="SKIP"
    create_fake_project "nodejs"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running lint script
    run bash "$PROJECT_ROOT/scripts/build/20-ci-lint.sh"

    # THEN: Should skip linting
    assert_success
    assert_output --partial "SKIP MODE"
    assert_output --partial "Lint skipped"
}

@test "20-ci-lint.sh lints Node.js project successfully" {
    # GIVEN: Node.js project with linting tools
    create_fake_project "nodejs"
    setup_nodejs_mocks
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running lint script
    run bash "$PROJECT_ROOT/scripts/build/20-ci-lint.sh" nodejs

    # THEN: Should lint Node.js project
    assert_success
    assert_output --partial "Linting Node.js project"
    assert_output --partial "Lint script completed successfully"
}

@test "20-ci-lint.sh lints Python project successfully" {
    # GIVEN: Python project with linting tools
    create_fake_project "python"
    setup_python_mocks
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running lint script
    run bash "$PROJECT_ROOT/scripts/build/20-ci-lint.sh" python

    # THEN: Should lint Python project
    assert_success
    assert_output --partial "Linting Python project"
    assert_output --partial "Lint script completed successfully"
}

@test "20-ci-lint.sh lints Go project successfully" {
    # GIVEN: Go project with linting tools
    create_fake_project "go"
    setup_go_mocks
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running lint script
    run bash "$PROJECT_ROOT/scripts/build/20-ci-lint.sh" go

    # THEN: Should lint Go project
    assert_success
    assert_output --partial "Linting Go project"
    assert_output --partial "Lint script completed successfully"
}

@test "20-ci-lint.sh lints Rust project successfully" {
    # GIVEN: Rust project with linting tools
    create_fake_project "rust"
    setup_rust_mocks
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running lint script
    run bash "$PROJECT_ROOT/scripts/build/20-ci-lint.sh" rust

    # THEN: Should lint Rust project
    assert_success
    assert_output --partial "Linting Rust project"
    assert_output --partial "Lint script completed successfully"
}

@test "20-ci-lint.sh lints generic project successfully" {
    # GIVEN: Generic project with shell scripts
    create_fake_project "generic"
    create_mock "shellcheck"
    set_mock_mode "shellcheck" "success"
    echo "#!/bin/bash" > "${FAKE_PROJECT_ROOT}/test.sh"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running lint script
    run bash "$PROJECT_ROOT/scripts/build/20-ci-lint.sh" generic

    # THEN: Should lint generic project
    assert_success
    assert_output --partial "Linting generic project"
    assert_output --partial "Lint script completed successfully"
}

@test "20-ci-lint.sh runs ESLint for Node.js projects" {
    # GIVEN: Node.js project with ESLint
    create_fake_project "nodejs"
    setup_nodejs_mocks
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running lint script
    run bash "$PROJECT_ROOT/scripts/build/20-ci-lint.sh" nodejs

    # THEN: Should run ESLint
    assert_success
    assert_output --partial "Running ESLint"
    assert_output --partial "ESLint passed"
}

@test "20-ci-lint.sh runs Prettier for Node.js projects" {
    # GIVEN: Node.js project with Prettier
    create_fake_project "nodejs"
    setup_nodejs_mocks
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running lint script
    run bash "$PROJECT_ROOT/scripts/build/20-ci-lint.sh" nodejs

    # THEN: Should run Prettier
    assert_success
    assert_output --partial "Running Prettier format check"
    assert_output --partial "Prettier check passed"
}

@test "20-ci-lint.sh runs Black for Python projects" {
    # GIVEN: Python project with Black
    create_fake_project "python"
    setup_python_mocks
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running lint script
    run bash "$PROJECT_ROOT/scripts/build/20-ci-lint.sh" python

    # THEN: Should run Black
    assert_success
    assert_output --partial "Running Black format check"
    assert_output --partial "Black check passed"
}

@test "20-ci-lint.sh runs Flake8 for Python projects" {
    # GIVEN: Python project with Flake8
    create_fake_project "python"
    setup_python_mocks
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running lint script
    run bash "$PROJECT_ROOT/scripts/build/20-ci-lint.sh" python

    # THEN: Should run Flake8
    assert_success
    assert_output --partial "Running Flake8"
    assert_output --partial "Flake8 passed"
}

@test "20-ci-lint.sh runs Pylint for Python projects" {
    # GIVEN: Python project with Pylint
    create_fake_project "python"
    setup_python_mocks
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running lint script
    run bash "$PROJECT_ROOT/scripts/build/20-ci-lint.sh" python

    # THEN: Should run Pylint
    assert_success
    assert_output --partial "Running Pylint"
    assert_output --partial "Pylint passed"
}

@test "20-ci-lint.sh runs gofmt for Go projects" {
    # GIVEN: Go project with gofmt
    create_fake_project "go"
    setup_go_mocks
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running lint script
    run bash "$PROJECT_ROOT/scripts/build/20-ci-lint.sh" go

    # THEN: Should run gofmt
    assert_success
    assert_output --partial "Running gofmt check"
    assert_output --partial "gofmt check passed"
}

@test "20-ci-lint.sh runs golangci-lint for Go projects" {
    # GIVEN: Go project with golangci-lint
    create_fake_project "go"
    setup_go_mocks
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running lint script
    run bash "$PROJECT_ROOT/scripts/build/20-ci-lint.sh" go

    # THEN: Should run golangci-lint
    assert_success
    assert_output --partial "Running golangci-lint"
    assert_output --partial "golangci-lint passed"
}

@test "20-ci-lint.sh runs cargo fmt for Rust projects" {
    # GIVEN: Rust project with cargo fmt
    create_fake_project "rust"
    setup_rust_mocks
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running lint script
    run bash "$PROJECT_ROOT/scripts/build/20-ci-lint.sh" rust

    # THEN: Should run cargo fmt
    assert_success
    assert_output --partial "Running cargo fmt check"
    assert_output --partial "cargo fmt check passed"
}

@test "20-ci-lint.sh runs cargo clippy for Rust projects" {
    # GIVEN: Rust project with cargo clippy
    create_fake_project "rust"
    setup_rust_mocks
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running lint script
    run bash "$PROJECT_ROOT/scripts/build/20-ci-lint.sh" rust

    # THEN: Should run cargo clippy
    assert_success
    assert_output --partial "Running cargo clippy"
    assert_output --partial "cargo clippy passed"
}

@test "20-ci-lint.sh generates lint report" {
    # GIVEN: Node.js project with linting tools
    create_fake_project "nodejs"
    setup_nodejs_mocks
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running lint script
    run bash "$PROJECT_ROOT/scripts/build/20-ci-lint.sh" nodejs

    # THEN: Should generate lint report
    assert_success
    assert_file_exists "${FAKE_PROJECT_ROOT}/lint-results/lint-report.json"
}

@test "20-ci-lint.sh creates lint results directory" {
    # GIVEN: Node.js project with linting tools
    create_fake_project "nodejs"
    setup_nodejs_mocks
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running lint script
    run bash "$PROJECT_ROOT/scripts/build/20-ci-lint.sh" nodejs

    # THEN: Should create lint results directory
    assert_success
    assert_dir_exists "${FAKE_PROJECT_ROOT}/lint-results"
}

@test "20-ci-lint.sh handles missing linting tools gracefully" {
    # GIVEN: Node.js project without npx
    create_fake_project "nodejs"
    remove_mock "npx"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running lint script
    run bash "$PROJECT_ROOT/scripts/build/20-ci-lint.sh" nodejs

    # THEN: Should fail gracefully
    assert_failure
    assert_output --partial "npx is not available"
}

@test "20-ci-lint.sh handles linting failures" {
    # GIVEN: Node.js project with ESLint failures
    create_fake_project "nodejs"
    setup_nodejs_mocks
    set_mock_mode "npx" "fail"
    set_mock_exit_code "npx" "1"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running lint script
    run bash "$PROJECT_ROOT/scripts/build/20-ci-lint.sh" nodejs

    # THEN: Should handle linting failures
    assert_failure
    assert_output --partial "Lint script failed"
}

@test "20-ci-lint.sh validates linting setup" {
    # GIVEN: Node.js project with linting tools
    create_fake_project "nodejs"
    setup_nodejs_mocks
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running lint script in validate mode
    run bash "$PROJECT_ROOT/scripts/build/20-ci-lint.sh" validate

    # THEN: Should validate setup
    assert_success
    assert_output --partial "Validating lint setup"
    assert_output --partial "Project type: nodejs"
    assert_output --partial "npx available"
}

@test "20-ci-lint.sh shows help information" {
    # GIVEN: CI lint script
    # WHEN: Running with help flag
    run bash "$PROJECT_ROOT/scripts/build/20-ci-lint.sh" help

    # THEN: Should show help information
    assert_success
    assert_output --partial "CI Lint Script"
    assert_output --partial "Usage:"
    assert_output --partial "Project Types:"
    assert_output --partial "Environment Variables:"
}

@test "20-ci-lint.sh supports hierarchical testability control" {
    # GIVEN: Pipeline-specific override
    export PIPELINE_LINT_MODE="PASS"
    create_fake_project "nodejs"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running lint script
    run bash "$PROJECT_ROOT/scripts/build/20-ci-lint.sh" nodejs

    # THEN: Should use pipeline override
    assert_success
    assert_output --partial "PASS MODE"
}

@test "20-ci-lint.sh supports script-specific testability control" {
    # GIVEN: Script-specific override
    export LINT_MODE="SKIP"
    create_fake_project "nodejs"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running lint script
    run bash "$PROJECT_ROOT/scripts/build/20-ci-lint.sh" nodejs

    # THEN: Should use script-specific override
    assert_success
    assert_output --partial "SKIP MODE"
}

@test "20-ci-lint.sh generates valid JSON lint report" {
    # GIVEN: Node.js project with linting tools
    create_fake_project "nodejs"
    setup_nodejs_mocks
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running lint script
    run bash "$PROJECT_ROOT/scripts/build/20-ci-lint.sh" nodejs

    # THEN: Should generate valid JSON metadata
    assert_success
    run cat "${FAKE_PROJECT_ROOT}/lint-results/lint-report.json"
    assert_success
    is_valid_json "$output"
}

@test "20-ci-lint.sh supports custom ESLint configuration" {
    # GIVEN: Node.js project with custom ESLint config
    create_fake_project "nodejs"
    setup_nodejs_mocks
    echo '{"extends": ["eslint:recommended"]}' > "${FAKE_PROJECT_ROOT}/.eslintrc.json"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running lint script with custom config
    export ESLINT_CONFIG=".eslintrc.json"
    run bash "$PROJECT_ROOT/scripts/build/20-ci-lint.sh" nodejs

    # THEN: Should use custom configuration
    assert_success
    assert_output --partial "Running ESLint"
}

@test "20-ci-lint.sh supports custom Prettier configuration" {
    # GIVEN: Node.js project with custom Prettier config
    create_fake_project "nodejs"
    setup_nodejs_mocks
    echo '{"tabWidth": 2}' > "${FAKE_PROJECT_ROOT}/.prettierrc"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running lint script with custom config
    export PRETTIER_CONFIG=".prettierrc"
    run bash "$PROJECT_ROOT/scripts/build/20-ci-lint.sh" nodejs

    # THEN: Should use custom configuration
    assert_success
    assert_output --partial "Running Prettier format check"
}

@test "20-ci-lint.sh handles missing Python tools gracefully" {
    # GIVEN: Python project with missing pylint
    create_fake_project "python"
    setup_python_mocks
    remove_mock "pylint"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running lint script
    run bash "$PROJECT_ROOT/scripts/build/20-ci-lint.sh" python

    # THEN: Should skip pylint and continue
    assert_success
    assert_output --partial "Pylint not available, skipping"
    assert_output --partial "Lint script completed successfully"
}

@test "20-ci-lint.sh handles missing Go tools gracefully" {
    # GIVEN: Go project with missing golangci-lint
    create_fake_project "go"
    setup_go_mocks
    remove_mock "golangci-lint"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running lint script
    run bash "$PROJECT_ROOT/scripts/build/20-ci-lint.sh" go

    # THEN: Should skip golangci-lint and continue
    assert_success
    assert_output --partial "golangci-lint not available, skipping"
    assert_output --partial "Lint script completed successfully"
}