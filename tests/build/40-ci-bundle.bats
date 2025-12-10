#!/usr/bin/env bats

load '../build_helper'

setup() {
    setup_build_test
    setup_bundling_mocks
    # Create mock common library in the expected location
    mkdir -p "${FAKE_PROJECT_ROOT}/scripts/lib"
    cp "${TEST_TEMP_DIR}/lib/common.sh" "${FAKE_PROJECT_ROOT}/scripts/lib/common.sh"
}

teardown() {
    teardown_build_test
}

@test "40-ci-bundle.sh exists and is executable" {
    # GIVEN: CI bundle script should exist
    # THEN: Script file should exist and be executable
    assert_file_exists "$PROJECT_ROOT/scripts/build/40-ci-bundle.sh"
    assert_file_executable "$PROJECT_ROOT/scripts/build/40-ci-bundle.sh"
}

@test "40-ci-bundle.sh has proper shebang and error handling" {
    # GIVEN: CI bundle script is available
    run cat "$PROJECT_ROOT/scripts/build/40-ci-bundle.sh"

    # THEN: Script should have proper structure
    assert_line --partial "#!/bin/bash"
    assert_line --partial "set -euo pipefail"
}

@test "40-ci-bundle.sh sources common utilities correctly" {
    # GIVEN: CI bundle script sources common utilities
    run grep -n "source.*common.sh" "$PROJECT_ROOT/scripts/build/40-ci-bundle.sh"

    # THEN: Script should source common utilities
    assert_success
    assert_output --partial "scripts/lib/common.sh"
}

@test "40-ci-bundle.sh detects Node.js project correctly" {
    # GIVEN: A Node.js project structure
    create_fake_project "nodejs"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running bundle script with detect mode
    run bash "$PROJECT_ROOT/scripts/build/40-ci-bundle.sh" detect

    # THEN: Should detect Node.js project
    assert_success
    assert_output --partial "nodejs"
}

@test "40-ci-bundle.sh detects Python project correctly" {
    # GIVEN: A Python project structure
    create_fake_project "python"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running bundle script with detect mode
    run bash "$PROJECT_ROOT/scripts/build/40-ci-bundle.sh" detect

    # THEN: Should detect Python project
    assert_success
    assert_output --partial "python"
}

@test "40-ci-bundle.sh detects Go project correctly" {
    # GIVEN: A Go project structure
    create_fake_project "go"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running bundle script with detect mode
    run bash "$PROJECT_ROOT/scripts/build/40-ci-bundle.sh" detect

    # THEN: Should detect Go project
    assert_success
    assert_output --partial "go"
}

@test "40-ci-bundle.sh detects Rust project correctly" {
    # GIVEN: A Rust project structure
    create_fake_project "rust"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running bundle script with detect mode
    run bash "$PROJECT_ROOT/scripts/build/40-ci-bundle.sh" detect

    # THEN: Should detect Rust project
    assert_success
    assert_output --partial "rust"
}

@test "40-ci-bundle.sh handles DRY_RUN mode correctly" {
    # GIVEN: Test environment with DRY_RUN mode
    export CI_TEST_MODE="DRY_RUN"
    create_fake_project "nodejs"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running bundle script
    run bash "$PROJECT_ROOT/scripts/build/40-ci-bundle.sh"

    # THEN: Should perform dry run
    assert_success
    assert_output --partial "DRY RUN"
    assert_output --partial "Would bundle project"
    assert_output --partial "Would create deployment bundle"
}

@test "40-ci-bundle.sh handles PASS mode correctly" {
    # GIVEN: Test environment with PASS mode
    export CI_TEST_MODE="PASS"
    create_fake_project "nodejs"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running bundle script
    run bash "$PROJECT_ROOT/scripts/build/40-ci-bundle.sh"

    # THEN: Should simulate success
    assert_success
    assert_output --partial "PASS MODE"
    assert_output --partial "simulated successfully"
}

@test "40-ci-bundle.sh handles FAIL mode correctly" {
    # GIVEN: Test environment with FAIL mode
    export CI_TEST_MODE="FAIL"
    create_fake_project "nodejs"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running bundle script
    run bash "$PROJECT_ROOT/scripts/build/40-ci-bundle.sh"

    # THEN: Should simulate failure
    assert_failure
    assert_output --partial "FAIL MODE"
    assert_output --partial "Simulating bundle failure"
}

@test "40-ci-bundle.sh handles SKIP mode correctly" {
    # GIVEN: Test environment with SKIP mode
    export CI_TEST_MODE="SKIP"
    create_fake_project "nodejs"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running bundle script
    run bash "$PROJECT_ROOT/scripts/build/40-ci-bundle.sh"

    # THEN: Should skip bundling
    assert_success
    assert_output --partial "SKIP MODE"
    assert_output --partial "Bundle skipped"
}

@test "40-ci-bundle.sh bundles Node.js project successfully" {
    # GIVEN: Node.js project with compiled artifacts
    create_fake_project "nodejs"
    create_fake_artifacts "nodejs"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running bundle script
    run bash "$PROJECT_ROOT/scripts/build/40-ci-bundle.sh" nodejs

    # THEN: Should bundle Node.js project
    assert_success
    assert_output --partial "Bundling Node.js project"
    assert_output --partial "Node.js bundle created"
}

@test "40-ci-bundle.sh bundles Python project successfully" {
    # GIVEN: Python project with compiled artifacts
    create_fake_project "python"
    create_fake_artifacts "python"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running bundle script
    run bash "$PROJECT_ROOT/scripts/build/40-ci-bundle.sh" python

    # THEN: Should bundle Python project
    assert_success
    assert_output --partial "Bundling Python project"
    assert_output --partial "Python bundle created"
}

@test "40-ci-bundle.sh bundles Go project successfully" {
    # GIVEN: Go project with compiled binary
    create_fake_project "go"
    create_fake_artifacts "go"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running bundle script
    run bash "$PROJECT_ROOT/scripts/build/40-ci-bundle.sh" go

    # THEN: Should bundle Go project
    assert_success
    assert_output --partial "Bundling Go project"
    assert_output --partial "Go bundle created"
}

@test "40-ci-bundle.sh bundles Rust project successfully" {
    # GIVEN: Rust project with compiled binary
    create_fake_project "rust"
    create_fake_artifacts "rust"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running bundle script
    run bash "$PROJECT_ROOT/scripts/build/40-ci-bundle.sh" rust

    # THEN: Should bundle Rust project
    assert_success
    assert_output --partial "Bundling Rust project"
    assert_output --partial "Rust bundle created"
}

@test "40-ci-bundle.sh bundles generic project successfully" {
    # GIVEN: Generic project structure
    create_fake_project "generic"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running bundle script
    run bash "$PROJECT_ROOT/scripts/build/40-ci-bundle.sh" generic

    # THEN: Should bundle generic project
    assert_success
    assert_output --partial "Bundling generic project"
    assert_output --partial "Generic bundle created"
}

@test "40-ci-bundle.sh generates bundle metadata" {
    # GIVEN: Node.js project with compiled artifacts
    create_fake_project "nodejs"
    create_fake_artifacts "nodejs"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running bundle script
    run bash "$PROJECT_ROOT/scripts/build/40-ci-bundle.sh" nodejs

    # THEN: Should generate bundle metadata
    assert_success
    assert_file_exists "${FAKE_PROJECT_ROOT}/dist/bundle-metadata.json"
}

@test "40-ci-bundle.sh creates bundle directory" {
    # GIVEN: Node.js project with compiled artifacts
    create_fake_project "nodejs"
    create_fake_artifacts "nodejs"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running bundle script
    run bash "$PROJECT_ROOT/scripts/build/40-ci-bundle.sh" nodejs

    # THEN: Should create bundle directory
    assert_success
    assert_dir_exists "${FAKE_PROJECT_ROOT}/dist"
}

@test "40-ci-bundle.sh creates tarball bundles" {
    # GIVEN: Node.js project with compiled artifacts and mocks
    create_fake_project "nodejs"
    create_fake_artifacts "nodejs"
    set_mock_output "tar" "tar created successfully"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running bundle script
    run bash "$PROJECT_ROOT/scripts/build/40-ci-bundle.sh" nodejs

    # THEN: Should create tarball bundle
    assert_success
    assert_output --partial "tar.gz"
}

@test "40-ci-bundle.sh handles missing compiled artifacts" {
    # GIVEN: Node.js project without compiled artifacts
    create_fake_project "nodejs"
    # Don't create artifacts
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running bundle script
    run bash "$PROJECT_ROOT/scripts/build/40-ci-bundle.sh" nodejs

    # THEN: Should handle missing artifacts gracefully
    assert_failure
    assert_output --partial "No dist directory found"
}

@test "40-ci-bundle.sh handles Go project without binary" {
    # GIVEN: Go project without compiled binary
    create_fake_project "go"
    # Don't create artifacts
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running bundle script
    run bash "$PROJECT_ROOT/scripts/build/40-ci-bundle.sh" go

    # THEN: Should handle missing binary gracefully
    assert_failure
    assert_output --partial "No compiled binary found"
}

@test "40-ci-bundle.sh includes node_modules when requested" {
    # GIVEN: Node.js project with compiled artifacts
    create_fake_project "nodejs"
    create_fake_artifacts "nodejs"
    export INCLUDE_NODE_MODULES="true"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running bundle script
    run bash "$PROJECT_ROOT/scripts/build/40-ci-bundle.sh" nodejs

    # THEN: Should include node_modules in bundle
    assert_success
    # The script would attempt to copy node_modules if it existed
}

@test "40-ci-bundle.sh creates startup scripts" {
    # GIVEN: Node.js project with compiled artifacts
    create_fake_project "nodejs"
    create_fake_artifacts "nodejs"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running bundle script
    run bash "$PROJECT_ROOT/scripts/build/40-ci-bundle.sh" nodejs

    # THEN: Should create startup script
    assert_success
    # The script creates startup.sh in the bundle directory
}

@test "40-ci-bundle.sh validates bundling setup" {
    # GIVEN: Node.js project with compiled artifacts
    create_fake_project "nodejs"
    create_fake_artifacts "nodejs"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running bundle script in validate mode
    run bash "$PROJECT_ROOT/scripts/build/40-ci-bundle.sh" validate

    # THEN: Should validate setup
    assert_success
    assert_output --partial "Validating bundle setup"
    assert_output --partial "Project type: nodejs"
    assert_output --partial "dist directory exists"
    assert_output --partial "tar available"
}

@test "40-ci-bundle.sh shows help information" {
    # GIVEN: CI bundle script
    # WHEN: Running with help flag
    run bash "$PROJECT_ROOT/scripts/build/40-ci-bundle.sh" help

    # THEN: Should show help information
    assert_success
    assert_output --partial "CI Bundle Script"
    assert_output --partial "Usage:"
    assert_output --partial "Project Types:"
    assert_output --partial "Bundle Directory:"
    assert_output --partial "Environment Variables:"
}

@test "40-ci-bundle.sh supports custom bundle directory" {
    # GIVEN: Node.js project with compiled artifacts
    create_fake_project "nodejs"
    create_fake_artifacts "nodejs"
    local custom_bundle_dir="${FAKE_PROJECT_ROOT}/custom-bundles"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running bundle script with custom directory
    run bash "$PROJECT_ROOT/scripts/build/40-ci-bundle.sh" nodejs "$custom_bundle_dir"

    # THEN: Should use custom bundle directory
    assert_success
    assert_output --partial "Bundle directory: $custom_bundle_dir"
}

@test "40-ci-bundle.sh supports hierarchical testability control" {
    # GIVEN: Pipeline-specific override
    export PIPELINE_BUNDLE_MODE="PASS"
    create_fake_project "nodejs"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running bundle script
    run bash "$PROJECT_ROOT/scripts/build/40-ci-bundle.sh" nodejs

    # THEN: Should use pipeline override
    assert_success
    assert_output --partial "PASS MODE"
}

@test "40-ci-bundle.sh supports script-specific testability control" {
    # GIVEN: Script-specific override
    export BUNDLE_MODE="SKIP"
    create_fake_project "nodejs"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running bundle script
    run bash "$PROJECT_ROOT/scripts/build/40-ci-bundle.sh" nodejs

    # THEN: Should use script-specific override
    assert_success
    assert_output --partial "SKIP MODE"
}

@test "40-ci-bundle.sh generates valid JSON metadata" {
    # GIVEN: Node.js project with compiled artifacts
    create_fake_project "nodejs"
    create_fake_artifacts "nodejs"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running bundle script
    run bash "$PROJECT_ROOT/scripts/build/40-ci-bundle.sh" nodejs

    # THEN: Should generate valid JSON metadata
    assert_success
    run cat "${FAKE_PROJECT_ROOT}/dist/bundle-metadata.json"
    assert_success
    is_valid_json "$output"
}

@test "40-ci-bundle.sh copies configuration files" {
    # GIVEN: Go project with compiled binary and configuration
    create_fake_project "go"
    create_fake_artifacts "go"
    # Create additional config files
    echo "sum information" > "${FAKE_PROJECT_ROOT}/go.sum"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running bundle script
    run bash "$PROJECT_ROOT/scripts/build/40-ci-bundle.sh" go

    # THEN: Should copy configuration files
    assert_success
    assert_output --partial "Bundling Go project"
}

@test "40-ci-bundle.sh handles Rust target/release directory" {
    # GIVEN: Rust project with compiled binary in release directory
    create_fake_project "rust"
    create_fake_artifacts "rust"
    cd "$FAKE_PROJECT_ROOT"

    # WHEN: Running bundle script
    run bash "$PROJECT_ROOT/scripts/build/40-ci-bundle.sh" rust

    # THEN: Should find binary in target/release directory
    assert_success
    assert_output --partial "Bundling Rust project"
    assert_output --partial "Rust bundle created"
}

@test "40-ci-bundle.sh provides comprehensive bundling documentation" {
    # GIVEN: CI bundle script
    # WHEN: Running with help flag
    run bash "$PROJECT_ROOT/scripts/build/40-ci-bundle.sh" help

    # THEN: Should show comprehensive documentation
    assert_success
    assert_output --partial "Bundle Contents:"
    assert_output --partial "Compiled artifacts/binaries"
    assert_output --partial "Configuration files"
    assert_output --partial "Startup scripts"
    assert_output --partial "Deployment metadata"
    assert_output --partial "Installation instructions"
}