#!/usr/bin/env bash
# ShellSpec tests for Pre-commit Lint Hook
# Tests the shellcheck linting validation for bash scripts

set -euo pipefail

# Load the script under test
# shellcheck disable=SC1090,SC1091
. "$(dirname "$0")/../../../scripts/hooks/pre-commit-lint.sh" 2>/dev/null || {
  echo "Failed to source pre-commit-lint.sh" >&2
  exit 1
}

# Setup test environment
setup_test_environment() {
  # Create test directory
  mkdir -p "/tmp/lint-test"
  cd "/tmp/lint-test"

  # Create test bash scripts with various linting issues
  mkdir -p scripts subproject

  # Clean script - should pass linting
  cat > scripts/clean.sh << 'EOF'
#!/bin/bash
# Clean script that passes linting

set -euo pipefail

# Function with proper quoting
handle_input() {
  local input="$1"
  echo "Processing: $input"
}

# Proper array handling
files=(
  "file1.txt"
  "file2.txt"
  "file3.txt"
)

# Proper variable expansion
if [[ -n "${VAR:-}" ]]; then
  echo "Variable is set: $VAR"
fi

# Safe command substitution
output=$(find . -type f -name "*.sh")
echo "Found shell files: $output"

main() {
  handle_input "test"
  printf '%s\n' "${files[@]}"
}

main "$@"
EOF

  # Script with linting issues
  cat > scripts/lint-issues.sh << 'EOF'
#!/bin/bash
# Script with various shellcheck issues

# Issue: Unquoted variables
echo $VAR

# Issue: Missing quotes around array expansion
files=(
  "file1"
  "file2"
)
echo ${files[@]}

# Issue: Use of [ instead of [[
if [ "$VAR" == "test" ]; then
  echo "Old-style test"
fi

# Issue: Word splitting
command_with_args="ls -la"
$command_with_args

# Issue: Backticks instead of $()
output=`cat file.txt`

# Issue: Unused variable
UNUSED_VAR="This is not used"

# Issue: Error handling without set -e
risky_command

# Issue: Global variable in function
bad_function() {
  GLOBAL_VAR="bad practice"
}

# Issue: Not checking command success
mkdir /tmp/test

# Issue: eval usage
user_input="ls -la"
eval $user_input
EOF

  # Script with warning-level issues
  cat > scripts/warnings.sh << 'EOF'
#!/bin/bash
# Script with warning-level issues

# Issue: Source with untrusted file
source "$1"

# Issue: Using printf -v (available in bash 4+)
printf -v result "value"

# Issue: Dynamic variable names
var_name="TEST_VAR"
printf '%s\n' "${!var_name}"

# Issue: Indirect expansion
indirect="$var_name"

# Issue: Complex regex
[[ "$input" =~ ^[a-zA-Z0-9]+$ ]]
EOF

  # Make scripts executable
  chmod +x scripts/*.sh

  # Create .shellcheckrc for configuration
  cat > .shellcheckrc << 'EOF'
# Shellcheck configuration
disable=SC1090
disable=SC1091
enable=SC2086
enable=SC2155

# Bash dialect
shell=bash

# Severity
severity=style
EOF

  # Set test environment variables
  export LINT_MODE="${LINT_MODE:-EXECUTE}"
  export FIX_LINT="${FIX_LINT:-false}"
  export SHELLCHECK_SEVERITY="${SHELLCHECK_SEVERITY:-style}"
}

# Cleanup test environment
cleanup_test_environment() {
  cd - >/dev/null
  rm -rf "/tmp/lint-test"
}

# Mock shellcheck command
mock_shellcheck() {
  local args=("$@")
  local file="${args[-1]}"

  case "$file" in
    "scripts/clean.sh")
      # Clean script - no issues
      return 0
      ;;
    "scripts/lint-issues.sh")
      # Script with multiple issues
      if [[ "${args[*]}" =~ "--severity=error" ]]; then
        echo "scripts/lint-issues.sh:3:6: SC2086: Double quote to prevent globbing and word splitting"
        echo "scripts/lint-issues.sh:13:15: SC2086: Double quote to prevent globbing and word splitting"
        echo "scripts/lint-issues.sh:18:8: SC2166: Use [[ ... ]] instead of [ ... ]"
        echo "scripts/lint-issues.sh:23:1:SC2048: Use '$(find . -type f -name '*.sh')' instead of unsafe output"
        echo "scripts/lint-issues.sh:25:14:SC2006: Use $(...) notation instead of legacy backticks"
        echo "scripts/lint-issues.sh:28:7:SC2034: UNUSED_VAR appears unused"
        echo "scripts/lint-issues.sh:35:1:SC2086: Double quote to prevent globbing and word splitting"
        echo "scripts/lint-issues.sh:39:2:SC2164: Use 'mkdir -p /tmp/test || exit' if $1 may be non-empty"
        echo "scripts/lint-issues.sh:43:1:SC2048: Use 'eval \"$user_input\"' if variable contains only safe characters"
      fi
      return 1  # Exit with error code for issues
      ;;
    "scripts/warnings.sh")
      # Script with warning-level issues
      if [[ "${args[*]}" =~ "--severity=style" ]]; then
        echo "scripts/warnings.sh:6:7: SC1090: Can't follow non-constant source"
        echo "scripts/warnings.sh:9:8: SC2039: In POSIX sh, 'printf -v' is undefined"
        echo "scripts/warnings.sh:14:14:SC3054: In POSIX sh, array indices are strings"
        echo "scripts/warnings.sh:16:13:SC3054: In POSIX sh, array indices are strings"
        echo "scripts/warnings.sh:19:14: SC2039: In POSIX sh, =~ operator is undefined"
      fi
      return 0  # Exit with success for warnings
      ;;
    *)
      # Default - no issues
      return 0
      ;;
  esac
}

# Mock logging functions
mock_logging_functions() {
  log_info() {
    echo "[INFO] $*"
  }

  log_success() {
    echo "[SUCCESS] $*"
  }

  log_error() {
    echo "[ERROR] $*"
  }

  log_warn() {
    echo "[WARN] $*"
  }

  log_debug() {
    echo "[DEBUG] $*"
  }
}

Describe "Pre-commit Lint Hook"
  BeforeEach "setup_test_environment"
  BeforeEach "mock_shellcheck"
  BeforeEach "mock_logging_functions"
  AfterEach "cleanup_test_environment"

  Describe "shellcheck availability validation"
    Context "when shellcheck is available"
      It "should validate shellcheck installation"
        When call check_shellcheck_available
        The status should be success
        The output should include "shellcheck is available"
      End

      It "should get shellcheck version"
        When call get_shellcheck_version
        The output should include "shellcheck version"
      End
    End

    Context "when shellcheck is not available"
      BeforeEach "unset -f shellcheck"

      It "should handle missing shellcheck"
        When call check_shellcheck_available
        The status should be failure
        The output should include "shellcheck is not installed"
      End
    End
  End

  Describe "shellcheck configuration"
    Context "when loading configuration"
      It "should load default configuration"
        When call load_shellcheck_config
        The output should include "Loaded shellcheck configuration"
        The output should include "Shell: bash"
      End

      It "should read .shellcheckrc file"
        When call get_shellcheck_config_file
        The output should equal "/tmp/lint-test/.shellcheckrc"
      End

      It "should handle missing configuration file"
        BeforeEach "rm -f .shellcheckrc"

        When call get_shellcheck_config_file
        The status should be failure
        The output should include "No .shellcheckrc file found"
      End
    End

    Context "when using custom severity"
      It "should validate error severity"
        When call validate_severity "error"
        The status should be success
        The output should include "Valid severity level: error"
      End

      It "should validate warning severity"
        When call validate_severity "warning"
        The status should be success
        The output should include "Valid severity level: warning"
      End

      It "should validate style severity"
        When call validate_severity "style"
        The status should be success
        The output should include "Valid severity level: style"
      End

      It "should validate info severity"
        When call validate_severity "info"
        The status should be success
        The output should include "Valid severity level: info"
      End

      It "should reject invalid severity"
        When call validate_severity "invalid"
        The status should be failure
        The output should include "Invalid severity level: invalid"
      End
    End
  End

  Describe "lint checking"
    Context "when checking clean scripts"
      It "should pass lint check for clean script"
        When call check_file_lint "scripts/clean.sh"
        The status should be success
        The output should include "✓ scripts/clean.sh passed linting"
      End

      It "should check script with custom severity"
        When call check_file_lint "scripts/clean.sh" "error"
        The status should be success
        The output should include "Checking scripts/clean.sh with severity: error"
      End
    End

    Context "when checking scripts with linting issues"
      It "should fail lint check for script with error issues"
        When call check_file_lint "scripts/lint-issues.sh"
        The status should be failure
        The output should include "✗ scripts/lint-issues.sh has linting issues"
        The output should include "Errors found"
      End

      It "should pass lint check for script with only warning issues"
        When call check_file_lint "scripts/warnings.sh" "warning"
        The status should be success
        The output should include "✓ scripts/warnings.sh passed linting"
        The output should include "Warnings found"
      End

      It "should show linting details"
        When call show_lint_details "scripts/lint-issues.sh" "error"
        The output should include "SC2086: Double quote to prevent globbing"
        The output should include "SC2166: Use [[ ... ]] instead of [ ... ]"
        The output should include "SC2048: Use \$(...) notation instead of legacy backticks"
      End
    End

    Context "when checking non-existent files"
      It "should handle missing files gracefully"
        When call check_file_lint "scripts/non-existent.sh"
        The status should be failure
        The output should include "File not found: scripts/non-existent.sh"
      End

      It "should handle non-bash files"
        When call check_file_lint "scripts/python-script.py"
        The status should be failure
        The output should include "Not a bash script: scripts/python-script.py"
      End
    End
  End

  Describe "lint fixing"
    Context "when attempting to fix linting issues"
      BeforeEach "export FIX_LINT=true"

      It "should explain that shellcheck doesn't support auto-fix"
        When call fix_file_lint "scripts/lint-issues.sh"
        The status should be success
        The output should include "shellcheck does not support auto-fix"
        The output should include "Manual fixing required"
      End

      It "should show linting issues to fix"
        When call fix_file_lint "scripts/lint-issues.sh"
        The output should include "Issues to fix:"
        The output should include "SC2086: Double quote to prevent globbing"
      End

      It "should provide fixing suggestions"
        When call suggest_fixes "scripts/lint-issues.sh"
        The output should include "Fixing suggestions for scripts/lint-issues.sh:"
        The output should include "Line 3: Double quote VAR to prevent globbing"
      End
    End

    Context "when fix mode is disabled"
      BeforeEach "export FIX_LINT=false"

      It "should not attempt fixing when disabled"
        When call fix_file_lint "scripts/lint-issues.sh"
        The status should be failure
        The output should include "FIX_LINT is disabled"
      End
    End
  End

  Describe "batch lint operations"
    Context "when checking multiple files"
      It "should check all bash scripts"
        When call check_files_lint "scripts/clean.sh" "scripts/lint-issues.sh" "scripts/warnings.sh"
        The status should be failure
        The output should include "Checking 3 files with severity: style"
        The output should include "✓ scripts/clean.sh passed linting"
        The output should include "✗ scripts/lint-issues.sh has linting issues"
        The output should include "✓ scripts/warnings.sh passed linting"
        The output should include "1 file failed linting"
      End

      It "should pass when all files pass linting"
        When call check_files_lint "scripts/clean.sh" "scripts/warnings.sh"
        The status should be success
        The output should include "All files passed linting"
      End

      It "should handle empty file list"
        When call check_files_lint
        The status should be success
        The output should include "No files to check"
      End

      It "should check files with custom severity"
        When call check_files_lint "scripts/clean.sh" "scripts/lint-issues.sh" "scripts/warnings.sh" "error"
        The status should be failure
        The output should include "1 file failed linting"
      End
    End

    Context "when generating reports"
      It "should generate detailed linting report"
        When call generate_lint_report "scripts/lint-issues.sh" "scripts/warnings.sh"
        The file "/tmp/lint-test/lint-report.md" should exist
        The contents of file "/tmp/lint-test/lint-report.md" should include "# 🔍 Shellcheck Linting Report"
        The contents of file "/tmp/lint-test/lint-report.md" should include "scripts/lint-issues.sh"
        The contents of file "/tmp/lint-test/lint-report.md" should include "scripts/warnings.sh"
      End

      It "should include statistics in report"
        When call generate_lint_report "scripts/clean.sh" "scripts/lint-issues.sh" "scripts/warnings.sh"
        The contents of file "/tmp/lint-test/lint-report.md" should include "## Summary"
        The contents of file "/tmp/lint-test/lint-report.md" should include "Total Files"
        The contents of file "/tmp/lint-test/lint-report.md" should include "Files Passed"
        The contents of file "/tmp/lint-test/lint-report.md" should include "Files Failed"
      End

      It "should categorize issues in report"
        When call generate_lint_report "scripts/lint-issues.sh"
        The contents of file "/tmp/lint-test/lint-report.md" should include "## Issues by Category"
        The contents of file "/tmp/lint-test/lint-report.md" should include "Quoting"
        The contents of file "/tmp/lint-test/lint-report.md" should include "Scripting Best Practices"
      End
    End
  End

  Describe "file filtering and discovery"
    Context "when finding bash scripts"
      It "should find bash script files"
        When call find_bash_scripts
        The output should include "scripts/clean.sh"
        The output should include "scripts/lint-issues.sh"
        The output should include "scripts/warnings.sh"
      End

      It "should filter files by extension"
        When call filter_shell_files "script.sh" "script.py" "script.bash" "README.md"
        The output should include "script.sh"
        The output should include "script.bash"
        The output should not include "script.py"
        The output should not include "README.md"
      End

      It "should validate bash shebang"
        When call has_bash_shebang "scripts/clean.sh"
        The status should be success
      End

      It "should reject non-bash shebang"
        When call has_bash_shebang "script.py"
        The status should be failure
      End

      It "should handle missing shebang"
        BeforeEach "echo 'echo test' > script_no_shebang.sh"

        When call has_bash_shebang "script_no_shebang.sh"
        The status should be failure
      End
    End
  End

  Describe "behavior modes"
    Context "when in EXECUTE mode"
      BeforeEach "export LINT_MODE=EXECUTE"

      It "should execute lint checks"
        When call run_lint_check "scripts/lint-issues.sh"
        The status should be failure
        The output should not include "DRY RUN"
      End
    End

    Context "when in DRY_RUN mode"
      BeforeEach "export LINT_MODE=DRY_RUN"

      It "should simulate lint checks"
        When call run_lint_check "scripts/lint-issues.sh"
        The status should be success
        The output should include "🔍 DRY RUN: Would check lint"
        The output should include "Would check: scripts/lint-issues.sh"
      End
    End

    Context "when in FAIL mode"
      BeforeEach "export LINT_MODE=FAIL"

      It "should simulate lint check failure"
        When call run_lint_check "scripts/clean.sh"
        The status should be failure
        The output should include "FAIL MODE: Simulating lint check failure"
      End
    End

    Context "when in SKIP mode"
      BeforeEach "export LINT_MODE=SKIP"

      It "should skip lint checking"
        When call run_lint_check "scripts/lint-issues.sh"
        The status should be success
        The output should include "SKIP MODE: Lint check skipped"
      End
    End

    Context "when in TIMEOUT mode"
      BeforeEach "export LINT_MODE=TIMEOUT"

      It "should simulate lint check timeout"
        When call run_lint_check "scripts/clean.sh"
        The status should equal 124  # TIMEOUT exit code
        The output should include "TIMEOUT MODE: Simulating lint check timeout"
      End
    End
  End

  Describe "severity level handling"
    Context "when using different severity levels"
      It "should check for error-level issues only"
        When call check_files_lint "scripts/lint-issues.sh" "error"
        The status should be failure
        The output should include "Checking with severity: error"
        The output should include "1 file failed linting"
      End

      It "should check for warning-level issues only"
        When call check_files_lint "scripts/warnings.sh" "warning"
        The status should be success
        The output should include "Checking with severity: warning"
        The output should include "All files passed linting"
      End

      It "should check for style-level issues"
        When call check_files_lint "scripts/lint-issues.sh" "style"
        The status should be success
        The output should include "Checking with severity: style"
        The output should include "Warnings found"
      End
    End
  End

  Describe "pre-commit hook integration"
    Context "when processing staged files"
      It "should process staged bash files"
        # Mock git staged files
        git() {
          case "$1" in
            "diff")
              case "$2" in
                "--cached"|"--name-only")
                  echo "scripts/clean.sh"
                  echo "scripts/lint-issues.sh"
                  echo "README.md"
                  ;;
              esac
              ;;
            *)
              echo "git $*"
              ;;
          esac
        }

        When call process_staged_files
        The status should be failure
        The output should include "Checking 2 bash files"
        The output should include "✓ scripts/clean.sh passed linting"
        The output should include "✗ scripts/lint-issues.sh has linting issues"
      End

      It "should skip non-bash files"
        # Mock git staged files
        git() {
          case "$1" in
            "diff")
              case "$2" in
                "--cached"|"--name-only")
                  echo "README.md"
                  echo "docs/api.md"
                  echo "config.json"
                  ;;
              esac
              ;;
            *)
              echo "git $*"
              ;;
          esac
        }

        When call process_staged_files
        The status should be success
        The output should include "No bash files in staged changes"
      End
    End

    Context "when processing commit message hook"
      It "should validate all bash files in repository"
        When call validate_all_bash_files
        The status should be failure
        The output should include "Found 3 bash files"
        The output should include "1 file failed linting"
      End
    End
  End

  Describe "error handling and edge cases"
    Context "when handling errors"
      It "should handle shellcheck command failure"
        # Mock shellcheck failure
        shellcheck() {
          return 1
        }

        When call check_file_lint "scripts/clean.sh"
        The status should be failure
        The output should include "Failed to check linting"
      End

      It "should handle file read errors"
        When call check_file_lint "/root/protected.sh"
        The status should be failure
        The output should include "Failed to read file"
      End

      It "should handle shellcheck not finding file"
        shellcheck() {
          echo "shellcheck: scripts/non-existent.sh: No such file or directory" >&2
          return 2
        }

        When call check_file_lint "scripts/non-existent.sh"
        The status should be failure
        The output should include "shellcheck failed"
      End
    End

    Context "when dealing with edge cases"
      It "should handle empty files"
        touch scripts/empty.sh
        When call check_file_lint "scripts/empty.sh"
        The status should be success
        The output should include "✓ scripts/empty.sh passed linting"
      End

      It "should handle binary files"
        echo -e '\x00\x01\x02\x03' > scripts/binary.sh
        When call check_file_lint "scripts/binary.sh"
        The status should be success
        The output should include "Skipping binary file"
      End

      It "should handle very large files"
        dd if=/dev/zero of=scripts/large.sh bs=1M count=10 >/dev/null 2>&1
        When call check_file_lint "scripts/large.sh"
        The status should be success
        The output should include "Skipping large file"
      End
    End
  End
End