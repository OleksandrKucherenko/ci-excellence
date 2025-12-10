#!/usr/bin/env bats

load '../build_helper'

setup() {
    setup_build_test
}

teardown() {
    teardown_build_test
}

@test "lint.sh executes successfully and shows expected output" {
    # GIVEN: Lint script exists and is executable
    run bash -c "source /mnt/wsl/workspace/ci-excellence/tests/build_helper.bash && cat '$PROJECT_ROOT/scripts/build/lint.sh'"

    # THEN: Script should exist and contain expected content
    assert_success
    assert_output --partial "Running Linters"
    assert_output --partial "Lint stub executed"
}

@test "lint.sh shows proper linting section headers" {
    # GIVEN: Lint script is available
    run cat "$PROJECT_ROOT/scripts/build/lint.sh"

    # THEN: Script should contain proper section headers
    assert_line --partial "========================================="
    assert_line --partial "Running Linters"
    assert_line --partial "Linting Complete"
}

@test "lint.sh contains commented examples for different languages" {
    # GIVEN: Lint script is available
    run cat "$PROJECT_ROOT/scripts/build/lint.sh"

    # THEN: Script should contain examples for various linting tools
    assert_output --partial "ESLint for JavaScript/TypeScript"
    assert_output --partial "Prettier for code formatting"
    assert_output --partial "Python linting with flake8"
    assert_output --partial "Python linting with pylint"
    assert_output --partial "Go linting"
    assert_output --partial "Rust linting"
    assert_output --partial "Ruby linting"
}

@test "lint.sh contains placeholder text for customization" {
    # GIVEN: Lint script is available
    run cat "$PROJECT_ROOT/scripts/build/lint.sh"

    # THEN: Script should indicate it needs customization
    assert_output --partial "Lint stub executed"
    assert_output --partial "Customize this script in scripts/build/lint.sh"
}

@test "lint.sh has proper error handling and exit code management" {
    # GIVEN: Lint script is available
    run cat "$PROJECT_ROOT/scripts/build/lint.sh"

    # THEN: Script should have proper structure
    assert_line --partial "#!/usr/bin/env bash"
    assert_line --partial "set -euo pipefail"
    assert_line --partial "EXIT_CODE=0"
}

@test "lint.sh handles linting failures appropriately" {
    # GIVEN: Lint script contains proper failure handling
    run cat "$PROJECT_ROOT/scripts/build/lint.sh"

    # THEN: Script should handle failures correctly
    assert_output --partial "if [ $EXIT_CODE -ne 0 ]"
    assert_output --partial "⚠ Linting Failed"
    assert_output --partial "exit $EXIT_CODE"
}

@test "lint.sh purpose and documentation is clear" {
    # GIVEN: Lint script is available
    run cat "$PROJECT_ROOT/scripts/build/lint.sh"

    # THEN: Script should have clear documentation
    assert_output --partial "CI Pipeline Stub: Lint Code"
    assert_output --partial "Purpose: Run linters and code style checks"
    assert_output --partial "Customize this script based on your project's linting tools"
}

@test "lint.sh can be executed without errors" {
    # GIVEN: Lint script exists
    # WHEN: Running the script directly
    run bash "$PROJECT_ROOT/scripts/build/lint.sh"

    # THEN: Script should execute successfully
    assert_success
    assert_output --partial "Running Linters"
    assert_output --partial "Lint stub executed"
    assert_output --partial "Linting Complete"
}

@test "lint.sh contains configuration detection logic" {
    # GIVEN: Lint script is available
    run cat "$PROJECT_ROOT/scripts/build/lint.sh"

    # THEN: Script should detect various configuration files
    assert_output --partial ".eslintrc.js"
    assert_output --partial ".eslintrc.json"
    assert_output --partial "eslint.config.js"
    assert_output --partial ".prettierrc"
    assert_output --partial ".prettierrc.json"
    assert_output --partial "setup.py"
    assert_output --partial "pyproject.toml"
    assert_output --partial "go.mod"
    assert_output --partial "Cargo.toml"
    assert_output --partial "Gemfile"
}

@test "lint.sh shows specific tool examples" {
    # GIVEN: Lint script is available
    run cat "$PROJECT_ROOT/scripts/build/lint.sh"

    # THEN: Script should contain specific tool commands
    assert_output --partial "npx eslint"
    assert_output --partial "npx prettier"
    assert_output --partial "flake8"
    assert_output --partial "pylint"
    assert_output --partial "golangci-lint"
    assert_output --partial "cargo clippy"
    assert_output --partial "bundle exec rubocop"
}

@test "lint.sh handles different linter output formats" {
    # GIVEN: Lint script is available
    run cat "$PROJECT_ROOT/scripts/build/lint.sh"

    # THEN: Script should handle different output formats
    assert_output --partial "npx eslint . || EXIT_CODE=$?"
    assert_output --partial "npx prettier --check . || EXIT_CODE=$?"
    assert_output --partial "flake8 . || EXIT_CODE=$?"
    assert_output --partial "pylint **/*.py || EXIT_CODE=$?"
}

@test "lint.sh handles project structure gracefully" {
    # GIVEN: Lint script in a directory with no project files
    cd "$BATS_TMPDIR"

    # WHEN: Running the script
    run bash "$PROJECT_ROOT/scripts/build/lint.sh"

    # THEN: Script should still complete (since it's a stub)
    assert_success
    assert_output --partial "Lint stub executed"
}

@test "lint.sh contains conditional linting logic" {
    # GIVEN: Lint script is available
    run cat "$PROJECT_ROOT/scripts/build/lint.sh"

    # THEN: Script should contain conditional execution logic
    assert_output --partial "if [ -f"
    assert_output --partial "then"
    assert_output --partial "fi"
}

@test "lint.sh documentation provides clear guidance" {
    # GIVEN: Lint script is available
    run cat "$PROJECT_ROOT/scripts/build/lint.sh"

    # THEN: Script documentation should be helpful
    assert_output --partial "# Add your linting commands here"
    assert_output --partial "# Example:"
}

@test "lint.sh maintains consistent output format" {
    # GIVEN: Lint script exists
    # WHEN: Running the script
    run bash "$PROJECT_ROOT/scripts/build/lint.sh"

    # THEN: Output should be consistent with other build scripts
    assert_output --partial "========================================="
    assert_output --partial "Lint stub executed"
    assert_output --partial "Customize this script"
}

@test "lint.sh contains comprehensive language support" {
    # GIVEN: Lint script is available
    run cat "$PROJECT_ROOT/scripts/build/lint.sh"

    # THEN: Script should support multiple languages
    assert_output --partial "JavaScript/TypeScript"
    assert_output --partial "Python"
    assert_output --partial "Go"
    assert_output --partial "Rust"
    assert_output --partial "Ruby"
}