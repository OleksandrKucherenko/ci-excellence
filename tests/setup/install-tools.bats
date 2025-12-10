#!/usr/bin/env bats

# BATS test for install-tools.sh
# Tests the tool installation script that uses mise

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

  # Create mock bin directory for PATH manipulation
  mkdir -p "$TEST_TEMP_DIR/bin"
  export PATH="$TEST_TEMP_DIR/bin:$PATH"

  # Create mock mise command
  create_mock_mise

  # Copy the script under test
  cp "$PROJECT_ROOT/scripts/setup/install-tools.sh" .
  chmod +x ./install-tools.sh

  # Set HOME to test directory for mise installation
  export HOME="$TEST_TEMP_DIR"
}

# Create mock mise command with different behaviors
create_mock_mise() {
  local mock_bin="$TEST_TEMP_DIR/bin"

  # Mock mise command that initially doesn't exist
  # This simulates mise not being installed initially

  # Mock curl for mise installation
  cat > "$mock_bin/curl" << 'EOF'
#!/bin/bash
if [[ "$1" == "https://mise.run" ]]; then
  # Simulate successful mise installation
  mkdir -p "$HOME/.local/bin"
  cat > "$HOME/.local/bin/mise" << 'MISE_EOF'
#!/bin/bash
case "$1" in
    "--version")
        echo "2025.1.1"
        ;;
    "install")
        echo "Installing tools from mise.toml..."
        if [[ "${FAIL_MISE_INSTALL:-false}" == "true" ]]; then
            echo "Failed to install some tools" >&2
            exit 1
        fi
        echo "✓ All tools installed successfully"
        ;;
    "list")
        echo "Tool    Version"
        echo "age     1.1.1"
        echo "sops    3.8.1"
        echo "node    18.17.0"
        ;;
    "x")
        shift
        if [[ "$1" == "--" ]]; then
            shift
        fi
        case "$1" in
            "gitleaks")
                echo "v8.18.2"
                ;;
            "trufflehog")
                echo "--version"
                echo "v3.68.0"
                ;;
            *)
                echo "mock mise x -- $*"
                ;;
        esac
        ;;
    *)
        echo "mock mise $*"
        ;;
esac
MISE_EOF
  chmod +x "$HOME/.local/bin/mise"
  else
    echo "curl $*"
  fi
EOF
  chmod +x "$mock_bin/curl"
}

teardown() {
  # Cleanup: Remove temporary directory
  rm -rf "$TEST_TEMP_DIR"
  unset HOME PATH FAIL_MISE_INSTALL
}

@test "install-tools.sh installs mise when not present" {
  # GIVEN: mise is not installed (not in PATH initially)

  # WHEN: The install-tools script is executed
  run ./install-tools.sh

  # THEN: Should install mise and tools successfully
  assert_success
  assert_output --partial "Installing mise..."
  assert_output --partial "mise installed: 2025.1.1"
  assert_output --partial "Installing tools from mise.toml..."
  assert_output --partial "All tools installed successfully"
  assert_output --partial "gitleaks: v8.18.2"
  assert_output --partial "trufflehog: v3.68.0"
}

@test "install-tools.sh uses existing mise if available" {
  # GIVEN: mise is already available in PATH
  cat > "$TEST_TEMP_DIR/bin/mise" << 'EOF'
#!/bin/bash
case "$1" in
    "--version")
        echo "2025.1.0"
        ;;
    "install")
        echo "Installing tools from mise.toml..."
        echo "✓ All tools installed successfully"
        ;;
    "list")
        echo "Tool    Version"
        echo "age     1.1.1"
        echo "sops    3.8.1"
        ;;
    "x")
        shift
        if [[ "$1" == "--" ]]; then
            shift
        fi
        case "$1" in
            "gitleaks")
                echo "v8.18.2"
                ;;
            "trufflehog")
                echo "--version"
                echo "v3.68.0"
                ;;
        esac
        ;;
    *)
        echo "mise $*"
        ;;
esac
EOF
  chmod +x "$TEST_TEMP_DIR/bin/mise"

  # WHEN: The install-tools script is executed
  run ./install-tools.sh

  # THEN: Should use existing mise without reinstalling
  assert_success
  assert_output --partial "mise already installed: 2025.1.0"
  refute_output --partial "Installing mise..."
}

@test "install-tools.sh fails when mise installation fails" {
  # GIVEN: mise installation would fail
  cat > "$TEST_TEMP_DIR/bin/curl" << 'EOF'
#!/bin/bash
echo "curl failed" >&2
exit 1
EOF
  chmod +x "$TEST_TEMP_DIR/bin/curl"

  # WHEN: The install-tools script is executed
  run ./install-tools.sh

  # THEN: Should fail with appropriate message
  assert_failure
  assert_output --partial "mise installation failed"
}

@test "install-tools.sh fails when mise install fails" {
  # GIVEN: mise install command will fail
  export FAIL_MISE_INSTALL=true

  # WHEN: The install-tools script is executed
  run ./install-tools.sh

  # THEN: Should fail with appropriate message
  assert_failure
  assert_output --partial "Failed to install some tools"
}

@test "install-tools.sh shows proper header and footer" {
  # GIVEN: No special conditions

  # WHEN: The install-tools script is executed
  run ./install-tools.sh

  # THEN: Should show proper structure
  assert_success
  assert_line --index 0 "========================================="
  assert_line --index 1 "Installing Required Tools"
  assert_line --index 2 "========================================="
  assert_line --index -2 "========================================="
  assert_line --index -1 "Tool Installation Complete"
}

@test "install-tools.sh displays tool installation progress" {
  # GIVEN: Normal execution conditions

  # WHEN: The install-tools script is executed
  run ./install-tools.sh

  # THEN: Should show progress messages
  assert_success
  assert_output --partial "Installing tools from mise.toml..."
  assert_output --partial "This includes: age, sops, gitleaks, trufflehog, lefthook, action-validator, apprise, bun"
}

@test "install-tools.sh verifies security tools installation" {
  # GIVEN: Normal execution conditions

  # WHEN: The install-tools script is executed
  run ./install-tools.sh

  # THEN: Should verify security tools
  assert_success
  assert_output --partial "Verifying security tools installation..."
  assert_output --partial "gitleaks: v8.18.2"
  assert_output --partial "trufflehog: v3.68.0"
}

@test "install-tools.sh fails if gitleaks verification fails" {
  # GIVEN: gitleaks verification will fail
  cat > "$TEST_TEMP_DIR/bin/mise" << 'EOF'
#!/bin/bash
case "$1" in
    "--version")
        echo "2025.1.1"
        ;;
    "install")
        echo "✓ All tools installed successfully"
        ;;
    "x")
        if [[ "$2" == "--" ]]; then
            shift 2
        fi
        case "$1" in
            "gitleaks")
                echo "gitleaks not found" >&2
                exit 1
                ;;
            "trufflehog")
                echo "--version"
                echo "v3.68.0"
                ;;
        esac
        ;;
    *)
        echo "mise $*"
        ;;
esac
EOF
  chmod +x "$TEST_TEMP_DIR/bin/mise"

  # WHEN: The install-tools script is executed
  run ./install-tools.sh

  # THEN: Should fail on gitleaks verification
  assert_failure
  assert_output --partial "gitleaks not found in mise"
}

@test "install-tools.sh fails if trufflehog verification fails" {
  # GIVEN: trufflehog verification will fail
  cat > "$TEST_TEMP_DIR/bin/mise" << 'EOF'
#!/bin/bash
case "$1" in
    "--version")
        echo "2025.1.1"
        ;;
    "install")
        echo "✓ All tools installed successfully"
        ;;
    "x")
        if [[ "$2" == "--" ]]; then
            shift 2
        fi
        case "$1" in
            "gitleaks")
                echo "v8.18.2"
                ;;
            "trufflehog")
                echo "trufflehog not found" >&2
                exit 1
                ;;
        esac
        ;;
    *)
        echo "mise $*"
        ;;
esac
EOF
  chmod +x "$TEST_TEMP_DIR/bin/mise"

  # WHEN: The install-tools script is executed
  run ./install-tools.sh

  # THEN: Should fail on trufflehog verification
  assert_failure
  assert_output --partial "trufflehog not found in mise"
}

@test "install-tools.sh shows installed tools list" {
  # GIVEN: Normal execution conditions

  # WHEN: The install-tools script is executed
  run ./install-tools.sh

  # THEN: Should show list of installed tools
  assert_success
  assert_output --partial "All installed tools:"
  assert_output --partial "Tool    Version"
}

@test "install-tools.sh handles PATH setup correctly" {
  # GIVEN: mise gets installed to ~/.local/bin

  # WHEN: The install-tools script is executed
  run ./install-tools.sh

  # THEN: Should add ~/.local/bin to PATH
  assert_success
  assert_output --partial "export PATH=\"$HOME/.local/bin:$PATH\""
}

@test "install-tools.sh works when mise is already in PATH" {
  # GIVEN: mise is already in PATH
  cat > "$TEST_TEMP_DIR/bin/mise" << 'EOF'
#!/bin/bash
case "$1" in
    "--version")
        echo "2025.1.1"
        ;;
    "install")
        echo "✓ All tools installed successfully"
        ;;
    "x")
        if [[ "$2" == "--" ]]; then
            shift 2
        fi
        case "$1" in
            "gitleaks")
                echo "v8.18.2"
                ;;
            "trufflehog")
                echo "--version"
                echo "v3.68.0"
                ;;
        esac
        ;;
    "list")
        echo "Tool    Version"
        ;;
    *)
        echo "mise $*"
        ;;
esac
EOF
  chmod +x "$TEST_TEMP_DIR/bin/mise"

  # WHEN: The install-tools script is executed
  run ./install-tools.sh

  # THEN: Should use existing mise
  assert_success
  assert_output --partial "mise already installed: 2025.1.1"
}

@test "install-tools.sh handles curl installation errors gracefully" {
  # GIVEN: curl exists but mise installation script fails
  cat > "$TEST_TEMP_DIR/bin/curl" << 'EOF'
#!/bin/bash
if [[ "$1" == "https://mise.run" ]]; then
  # Simulate installation that creates non-executable mise
  mkdir -p "$HOME/.local/bin"
  echo "echo 'This is not executable'" > "$HOME/.local/bin/mise"
  # Don't make it executable
else
  echo "curl $*"
fi
EOF
  chmod +x "$TEST_TEMP_DIR/bin/curl"

  # WHEN: The install-tools script is executed
  run ./install-tools.sh

  # THEN: Should fail with mise installation error
  assert_failure
  assert_output --partial "mise installation failed"
}

@test "install-tools.sh script exit status behavior" {
  # GIVEN: Normal execution conditions

  # WHEN: The install-tools script is executed successfully
  run ./install-tools.sh

  # THEN: Should exit with status 0
  assert_success
  assert_equal "$status" 0
}

@test "install-tools.sh works when HOME directory is unusual" {
  # GIVEN: HOME is set to unusual location
  export HOME="$TEST_TEMP_DIR/unusual_home"

  # WHEN: The install-tools script is executed
  run ./install-tools.sh

  # THEN: Should install mise to the unusual HOME location
  assert_success
  assert_output --partial "Installing mise..."
  test -f "$HOME/.local/bin/mise"
}

@test "install-tools.sh handles mise.x command variations" {
  # GIVEN: mise x command with different syntax variations
  cat > "$TEST_TEMP_DIR/bin/mise" << 'EOF'
#!/bin/bash
case "$1" in
    "--version")
        echo "2025.1.1"
        ;;
    "install")
        echo "✓ All tools installed successfully"
        ;;
    "x")
        shift
        # Handle both "mise x -- gitleaks" and "mise x gitleaks" formats
        if [[ "$1" == "--" ]]; then
            shift
        fi
        case "$1" in
            "gitleaks")
                echo "v8.18.2"
                ;;
            "trufflehog")
                echo "--version"
                echo "v3.68.0"
                ;;
        esac
        ;;
    "list")
        echo "Tool    Version"
        echo "age     1.1.1"
        ;;
    *)
        echo "mise $*"
        ;;
esac
EOF
  chmod +x "$TEST_TEMP_DIR/bin/mise"

  # WHEN: The install-tools script is executed
  run ./install-tools.sh

  # THEN: Should handle command variations correctly
  assert_success
  assert_output --partial "gitleaks: v8.18.2"
  assert_output --partial "trufflehog: v3.68.0"
}

@test "install-tools.sh handles script execution permissions" {
  # GIVEN: Script permissions are removed
  chmod -x ./install-tools.sh

  # WHEN: Script is executed with bash explicitly
  run bash ./install-tools.sh

  # THEN: Should still work
  assert_success

  # Restore permissions
  chmod +x ./install-tools.sh
}

@test "install-tools.sh handles mise list output variations" {
  # GIVEN: mise list command has different output format
  cat > "$TEST_TEMP_DIR/bin/mise" << 'EOF'
#!/bin/bash
case "$1" in
    "--version")
        echo "2025.1.1"
        ;;
    "install")
        echo "✓ All tools installed successfully"
        ;;
    "x")
        if [[ "$2" == "--" ]]; then
            shift 2
        fi
        case "$1" in
            "gitleaks")
                echo "v8.18.2"
                ;;
            "trufflehog")
                echo "--version"
                echo "v3.68.0"
                ;;
        esac
        ;;
    "list")
        echo "age      1.1.1    installed"
        echo "sops     3.8.1    installed"
        echo "gitleaks 8.18.2   installed"
        ;;
    *)
        echo "mise $*"
        ;;
esac
EOF
  chmod +x "$TEST_TEMP_DIR/bin/mise"

  # WHEN: The install-tools script is executed
  run ./install-tools.sh

  # THEN: Should handle different output format
  assert_success
  assert_output --partial "All installed tools:"
}