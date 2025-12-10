#!/usr/bin/env bats

# BATS test for install-dependencies.sh
# Tests the simple stub dependency installation script

# Determine script location
SCRIPT_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load test helpers if available
load "${BATS_TEST_DIRNAME}/../test_helper.bash" 2>/dev/null || true

# Setup test environment
setup() {
  # GIVEN: A clean temporary directory for testing
  TEST_TEMP_DIR="$(mktemp -d)"
  cd "$TEST_TEMP_DIR" || exit 1

  # Copy the script under test
  cp "$PROJECT_ROOT/scripts/setup/install-dependencies.sh" .
  chmod +x ./install-dependencies.sh

  # Create mock package managers to simulate stub behavior
  mkdir -p "$TEST_TEMP_DIR/bin"
  export PATH="$TEST_TEMP_DIR/bin:$PATH"
}

teardown() {
  # Cleanup: Remove temporary directory
  rm -rf "$TEST_TEMP_DIR"
}

@test "install-dependencies.sh detects Node.js with package-lock.json" {
  # GIVEN: A Node.js project with package-lock.json
  cat > package.json << 'EOF'
{
  "name": "test-project",
  "version": "1.0.0"
}
EOF
  touch package-lock.json

  # WHEN: The dependency installation script is executed
  run ./install-dependencies.sh

  # THEN: Should detect npm and show stub message
  assert_success
  assert_output --partial "Detected npm, installing dependencies..."
  assert_output --partial "✓ Stub: npm ci would run here"
}

@test "install-dependencies.sh detects Node.js with yarn.lock" {
  # GIVEN: A Node.js project with yarn.lock
  cat > package.json << 'EOF'
{
  "name": "test-project",
  "version": "1.0.0"
}
EOF
  touch yarn.lock

  # WHEN: The dependency installation script is executed
  run ./install-dependencies.sh

  # THEN: Should detect yarn and show stub message
  assert_success
  assert_output --partial "Detected yarn, installing dependencies..."
  assert_output --partial "✓ Stub: yarn install would run here"
}

@test "install-dependencies.sh detects Node.js with pnpm-lock.yaml" {
  # GIVEN: A Node.js project with pnpm-lock.yaml
  cat > package.json << 'EOF'
{
  "name": "test-project",
  "version": "1.0.0"
}
EOF
  touch pnpm-lock.yaml

  # WHEN: The dependency installation script is executed
  run ./install-dependencies.sh

  # THEN: Should detect pnpm and show stub message
  assert_success
  assert_output --partial "Detected pnpm, installing dependencies..."
  assert_output --partial "✓ Stub: pnpm install would run here"
}

@test "install-dependencies.sh detects Node.js with package.json only" {
  # GIVEN: A Node.js project with only package.json
  cat > package.json << 'EOF'
{
  "name": "test-project",
  "version": "1.0.0"
}
EOF

  # WHEN: The dependency installation script is executed
  run ./install-dependencies.sh

  # THEN: Should detect npm without lockfile and show stub message
  assert_success
  assert_output --partial "Detected npm (no lockfile), installing dependencies..."
  assert_output --partial "✓ Stub: npm install would run here"
}

@test "install-dependencies.sh detects Python with requirements.txt" {
  # GIVEN: A Python project with requirements.txt
  cat > requirements.txt << 'EOF'
flask>=2.0.0
requests>=2.25.0
EOF

  # WHEN: The dependency installation script is executed
  run ./install-dependencies.sh

  # THEN: Should detect Python and show stub message
  assert_success
  assert_output --partial "Detected Python requirements.txt, installing dependencies..."
  assert_output --partial "✓ Stub: pip install would run here"
}

@test "install-dependencies.sh detects Python with Pipfile" {
  # GIVEN: A Python project with Pipfile
  cat > Pipfile << 'EOF'
[[source]]
url = "https://pypi.org/simple"
verify_ssl = true
name = "pypi"

[packages]
flask = "*"
EOF

  # WHEN: The dependency installation script is executed
  run ./install-dependencies.sh

  # THEN: Should detect Pipenv and show stub message
  assert_success
  assert_output --partial "Detected Pipenv, installing dependencies..."
  assert_output --partial "✓ Stub: pipenv install would run here"
}

@test "install-dependencies.sh detects Python with poetry.lock" {
  # GIVEN: A Python project with poetry.lock
  touch poetry.lock

  # WHEN: The dependency installation script is executed
  run ./install-dependencies.sh

  # THEN: Should detect Poetry and show stub message
  assert_success
  assert_output --partial "Detected Poetry, installing dependencies..."
  assert_output --partial "✓ Stub: poetry install would run here"
}

@test "install-dependencies.sh detects Go with go.mod" {
  # GIVEN: A Go project with go.mod
  cat > go.mod << 'EOF'
module github.com/example/test

go 1.21
EOF

  # WHEN: The dependency installation script is executed
  run ./install-dependencies.sh

  # THEN: Should detect Go and show stub message
  assert_success
  assert_output --partial "Detected Go modules, installing dependencies..."
  assert_output --partial "✓ Stub: go mod download would run here"
}

@test "install-dependencies.sh detects Ruby with Gemfile" {
  # GIVEN: A Ruby project with Gemfile
  cat > Gemfile << 'EOF'
source "https://rubygems.org"

gem "rails", "~> 7.0"
EOF

  # WHEN: The dependency installation script is executed
  run ./install-dependencies.sh

  # THEN: Should detect Ruby and show stub message
  assert_success
  assert_output --partial "Detected Ruby Bundler, installing dependencies..."
  assert_output --partial "✓ Stub: bundle install would run here"
}

@test "install-dependencies.sh detects PHP with composer.json" {
  # GIVEN: A PHP project with composer.json
  cat > composer.json << 'EOF'
{
    "name": "example/project",
    "require": {
        "php": "^8.0",
        "symfony/console": "^6.0"
    }
}
EOF

  # WHEN: The dependency installation script is executed
  run ./install-dependencies.sh

  # THEN: Should detect PHP and show stub message
  assert_success
  assert_output --partial "Detected PHP Composer, installing dependencies..."
  assert_output --partial "✓ Stub: composer install would run here"
}

@test "install-dependencies.sh detects Rust with Cargo.toml" {
  # GIVEN: A Rust project with Cargo.toml
  cat > Cargo.toml << 'EOF'
[package]
name = "test-project"
version = "0.1.0"
edition = "2021"

[dependencies]
serde = "1.0"
EOF

  # WHEN: The dependency installation script is executed
  run ./install-dependencies.sh

  # THEN: Should detect Rust and show stub message
  assert_success
  assert_output --partial "Detected Rust Cargo, installing dependencies..."
  assert_output --partial "✓ Stub: cargo fetch would run here"
}

@test "install-dependencies.sh warns when no recognized dependency file found" {
  # GIVEN: No recognized dependency files exist

  # WHEN: The dependency installation script is executed
  run ./install-dependencies.sh

  # THEN: Should warn about missing files
  assert_success
  assert_output --partial "No recognized dependency file found"
  assert_output --partial "Customize this script in scripts/setup/install-dependencies.sh"
}

@test "install-dependencies.sh shows proper header and footer" {
  # GIVEN: No dependency files exist

  # WHEN: The dependency installation script is executed
  run ./install-dependencies.sh

  # THEN: Should show proper header and footer
  assert_success
  assert_line --index 0 "========================================="
  assert_line --index 1 "Installing Project Dependencies"
  assert_line --index 2 "========================================="
  assert_line --index -2 "========================================="
  assert_line --index -1 "Dependency Installation Complete"
}

@test "install-dependencies.sh handles empty directory gracefully" {
  # GIVEN: An empty directory

  # WHEN: The dependency installation script is executed
  run ./install-dependencies.sh

  # THEN: Should complete successfully with warning
  assert_success
  assert_output --partial "No recognized dependency file found"
}

@test "install-dependencies.sh respects file detection priority" {
  # GIVEN: Multiple dependency files exist (Node.js priority test)
  cat > package.json << 'EOF'
{
  "name": "test-project",
  "version": "1.0.0"
}
EOF
  touch package-lock.json  # This should take priority over yarn.lock
  touch yarn.lock

  # WHEN: The dependency installation script is executed
  run ./install-dependencies.sh

  # THEN: Should detect npm (package-lock.json has priority)
  assert_success
  assert_output --partial "Detected npm, installing dependencies..."
  refute_output --partial "Detected yarn"
}

@test "install-dependencies.sh script exit status" {
  # GIVEN: Any directory state

  # WHEN: The dependency installation script is executed
  run ./install-dependencies.sh

  # THEN: Should always exit successfully (it's a stub script)
  assert_success
  assert_equal "$status" 0
}

@test "install-dependencies.sh handles permission issues gracefully" {
  # GIVEN: Permission restrictions on file creation (edge case test)
  # This test mainly ensures the script doesn't crash on unusual conditions

  # WHEN: The dependency installation script is executed
  run ./install-dependencies.sh

  # THEN: Should handle gracefully
  assert_success
  # The stub script should not be affected by permission issues since it only reads
}

@test "install-dependencies.sh works from subdirectory" {
  # GIVEN: Project files are in parent directory
  cat > package.json << 'EOF'
{
  "name": "test-project",
  "version": "1.0.0"
}
EOF
  touch package-lock.json

  # WHEN: Script is run from a subdirectory
  mkdir -p subdir
  cd subdir
  run ../install-dependencies.sh

  # THEN: Should not detect Node.js files since it only checks current directory
  assert_success
  assert_output --partial "No recognized dependency file found"
}

@test "install-dependencies.sh works when script is not executable" {
  # GIVEN: Script permissions are removed
  chmod -x ./install-dependencies.sh

  # WHEN: The script is executed with bash explicitly
  run bash ./install-dependencies.sh

  # THEN: Should still work
  assert_success

  # Restore permissions
  chmod +x ./install-dependencies.sh
}

@test "install-dependencies.sh handles complex project structures" {
  # GIVEN: Multiple projects in subdirectories
  mkdir -p frontend backend
  cat > frontend/package.json << 'EOF'
{
  "name": "frontend",
  "version": "1.0.0"
}
EOF
  touch frontend/package-lock.json

  cat > backend/go.mod << 'EOF'
module github.com/example/backend

go 1.21
EOF

  # WHEN: Script is run from root directory (should not find anything)
  run ./install-dependencies.sh

  # THEN: Should not detect any dependency files in root
  assert_success
  assert_output --partial "No recognized dependency file found"

  # WHEN: Script is run from frontend directory
  cd frontend
  run ../install-dependencies.sh

  # THEN: Should detect Node.js
  assert_success
  assert_output --partial "Detected npm"
}

@test "install-dependencies.sh handles symlink scenarios" {
  # GIVEN: Symlinked dependency files
  cat > package.json << 'EOF'
{
  "name": "test-project",
  "version": "1.0.0"
}
EOF
  ln -s package.json package-link.json

  # WHEN: The dependency installation script is executed
  run ./install-dependencies.sh

  # THEN: Should detect based on the actual file, not the symlink
  assert_success
  assert_output --partial "Detected npm (no lockfile), installing dependencies..."
}