#!/usr/bin/env bash
# ShellSpec tests for Pre-commit Format Hook
# Tests the shfmt formatting validation for bash scripts

set -euo pipefail

# Load the script under test
# shellcheck disable=SC1090,SC1091
. "$(dirname "$0")/../../../scripts/hooks/pre-commit-format.sh" 2>/dev/null || {
  echo "Failed to source pre-commit-format.sh" >&2
  exit 1
}

# Setup test environment
setup_test_environment() {
  # Create test directory
  mkdir -p "/tmp/format-test"
  cd "/tmp/format-test"

  # Create test bash scripts with various formatting issues
  mkdir -p scripts subproject

  # Well-formatted script
  cat > scripts/well-formatted.sh << 'EOF'
#!/bin/bash
# Well formatted script

set -euo pipefail

main() {
  echo "This is well formatted"
  if [[ "$1" == "test" ]]; then
    echo "Test mode"
  fi
}

main "$@"
EOF

  # Poorly formatted script (needs fixing)
  cat > scripts/poorly-formatted.sh << 'EOF'
#!/bin/bash
# Poorly formatted script

set -euo pipefail

main()
{
echo "This needs formatting"
if [ "$1" == "test" ]; then
echo "Test mode"
fi
}

main "$@"
EOF

  # Script with formatting issues
  cat > scripts/format-issues.sh << 'EOF'
#!/bin/bash
# Script with various formatting issues

set -euo pipefail

if [ -n "$VAR" ];then
echo "Missing spaces"
fi

case "$1" in
  test)
    echo "Inconsistent indentation"
    ;;
  prod)
    echo "Production mode"
    ;;
esac

# Redirection with spaces
cat file.txt >  output.txt

# Array declaration
files=(
"file1"
"file2"
)
EOF

  # Non-bash files (should be ignored)
  cat > scripts/python-script.py << 'EOF'
#!/usr/bin/env python
# Python script - should be ignored by shfmt

def main():
    print("This is Python")
    return 0

if __name__ == "__main__":
    main()
EOF

  # Make scripts executable
  chmod +x scripts/*.sh

  # Set test environment variables
  export FORMAT_MODE="${FORMAT_MODE:-EXECUTE}"
  export FIX_FORMAT="${FIX_FORMAT:-false}"
}

# Cleanup test environment
cleanup_test_environment() {
  cd - >/dev/null
  rm -rf "/tmp/format-test"
}

# Mock shfmt command
mock_shfmt() {
  local args=("$@")

  case "${args[0]}" in
    "-l"|"--list")
      # List mode - show files that need formatting
      if [[ "${args[*]}" =~ "poorly-formatted.sh" ]]; then
        echo "scripts/poorly-formatted.sh"
      fi
      if [[ "${args[*]}" =~ "format-issues.sh" ]]; then
        echo "scripts/format-issues.sh"
      fi
      return 0
      ;;
    "-w"|"--write")
      # Write mode - format files in place
      if [[ "${args[*]}" =~ "poorly-formatted.sh" ]]; then
        echo "Formatted scripts/poorly-formatted.sh"
      fi
      if [[ "${args[*]}" =~ "format-issues.sh" ]]; then
        echo "Formatted scripts/format-issues.sh"
      fi
      return 0
      ;;
    "-d"|"--diff")
      # Diff mode - show formatting differences
      if [[ "${args[*]}" =~ "poorly-formatted.sh" ]]; then
        echo "--- a/scripts/poorly-formatted.sh"
        echo "+++ b/scripts/poorly-formatted.sh"
        echo "@@ -1,10 +1,10 @@"
        echo " main()"
        echo "{"
        echo "-echo \"This needs formatting\""
        echo "+echo \"This needs formatting\""
      fi
      return 0
      ;;
    "--version")
      echo "shfmt v3.8.0"
      return 0
      ;;
    *)
      # Default formatting
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

Describe "Pre-commit Format Hook"
  BeforeEach "setup_test_environment"
  BeforeEach "mock_shfmt"
  BeforeEach "mock_logging_functions"
  AfterEach "cleanup_test_environment"

  Describe "shfmt availability validation"
    Context "when shfmt is available"
      It "should validate shfmt installation"
        When call check_shfmt_available
        The status should be success
        The output should include "shfmt is available"
      End

      It "should get shfmt version"
        When call get_shfmt_version
        The output should include "v3.8.0"
      End
    End

    Context "when shfmt is not available"
      BeforeEach "unset -f shfmt"

      It "should handle missing shfmt"
        When call check_shfmt_available
        The status should be failure
        The output should include "shfmt is not installed"
      End
    End
  End

  Describe "file pattern validation"
    Context "when finding bash scripts"
      It "should find bash script files"
        When call find_bash_scripts
        The output should include "scripts/well-formatted.sh"
        The output should include "scripts/poorly-formatted.sh"
        The output should include "scripts/format-issues.sh"
        The output should not include "python-script.py"
      End

      It "should find scripts with shebang"
        When call find_shebang_files
        The output should include "scripts/well-formatted.sh"
        The output should include "scripts/poorly-formatted.sh"
        The output should include "scripts/format-issues.sh"
      End

      It "should exclude non-bash files"
        When call filter_bash_files "scripts/python-script.py" "scripts/well-formatted.sh"
        The output should include "scripts/well-formatted.sh"
        The output should not include "scripts/python-script.py"
      End
    End
  End

  Describe "format checking"
    Context "when checking well-formatted files"
      It "should pass format check for well-formatted script"
        When call check_file_format "scripts/well-formatted.sh"
        The status should be success
        The output should include "✓ scripts/well-formatted.sh is properly formatted"
      End
    End

    Context "when checking poorly formatted files"
      It "should fail format check for poorly formatted script"
        When call check_file_format "scripts/poorly-formatted.sh"
        The status should be failure
        The output should include "✗ scripts/poorly-formatted.sh needs formatting"
      End

      It "should fail format check for script with issues"
        When call check_file_format "scripts/format-issues.sh"
        The status should be failure
        The output should include "✗ scripts/format-issues.sh needs formatting"
      End
    End

    Context "when checking non-existent files"
      It "should handle missing files gracefully"
        When call check_file_format "scripts/non-existent.sh"
        The status should be failure
        The output should include "File not found: scripts/non-existent.sh"
      End
    End
  End

  Describe "format fixing"
    Context "when fixing poorly formatted files"
      BeforeEach "export FIX_FORMAT=true"

      It "should fix formatting issues"
        When call fix_file_format "scripts/poorly-formatted.sh"
        The output should include "Formatted scripts/poorly-formatted.sh"
      End

      It "should report successful fixing"
        When call fix_file_format "scripts/format-issues.sh"
        The status should be success
        The output should include "✓ Fixed scripts/format-issues.sh"
      End

      It "should handle well-formatted files"
        When call fix_file_format "scripts/well-formatted.sh"
        The status should be success
        The output should include "✓ scripts/well-formatted.sh is already properly formatted"
      End
    End

    Context "when fix mode is disabled"
      BeforeEach "export FIX_FORMAT=false"

      It "should not fix formatting when disabled"
        When call fix_file_format "scripts/poorly-formatted.sh"
        The status should be failure
        The output should include "FIX_FORMAT is disabled"
      End
    End
  End

  Describe "batch format operations"
    Context "when checking multiple files"
      It "should check all bash scripts"
        When call check_files_format "scripts/well-formatted.sh" "scripts/poorly-formatted.sh" "scripts/format-issues.sh"
        The status should be failure
        The output should include "✓ scripts/well-formatted.sh is properly formatted"
        The output should include "✗ scripts/poorly-formatted.sh needs formatting"
        The output should include "✗ scripts/format-issues.sh needs formatting"
        The output should include "2 files need formatting"
      End

      It "should pass when all files are well formatted"
        When call check_files_format "scripts/well-formatted.sh"
        The status should be success
        The output should include "All files are properly formatted"
      End

      It "should handle empty file list"
        When call check_files_format
        The status should be success
        The output should include "No files to check"
      End
    End

    Context "when fixing multiple files"
      BeforeEach "export FIX_FORMAT=true"

      It "should fix all files that need formatting"
        When call fix_files_format "scripts/poorly-formatted.sh" "scripts/format-issues.sh"
        The status should be success
        The output should include "Fixed 2 files"
        The output should include "✓ Fixed scripts/poorly-formatted.sh"
        The output should include "✓ Fixed scripts/format-issues.sh"
      End

      It "should skip already formatted files"
        When call fix_files_format "scripts/well-formatted.sh" "scripts/poorly-formatted.sh"
        The status should be success
        The output should include "✓ scripts/well-formatted.sh is already properly formatted"
        The output should include "✓ Fixed scripts/poorly-formatted.sh"
      End
    End
  End

  Describe "diff generation"
    Context "when showing formatting differences"
      It "should generate diff for poorly formatted files"
        When call show_format_diff "scripts/poorly-formatted.sh"
        The status should be success
        The output should include "--- a/scripts/poorly-formatted.sh"
        The output should include "+++ b/scripts/poorly-formatted.sh"
      End

      It "should show no diff for well-formatted files"
        When call show_format_diff "scripts/well-formatted.sh"
        The status should be success
        The output should include "No formatting differences found"
      End
    End
  End

  Describe "behavior modes"
    Context "when in EXECUTE mode"
      BeforeEach "export FORMAT_MODE=EXECUTE"

      It "should execute format checks"
        When call run_format_check "scripts/poorly-formatted.sh"
        The status should be failure
        The output should not include "DRY RUN"
      End
    End

    Context "when in DRY_RUN mode"
      BeforeEach "export FORMAT_MODE=DRY_RUN"

      It "should simulate format checks"
        When call run_format_check "scripts/poorly-formatted.sh"
        The status should be success
        The output should include "🔍 DRY RUN: Would check format"
        The output should include "Would check: scripts/poorly-formatted.sh"
      End
    End

    Context "when in FAIL mode"
      BeforeEach "export FORMAT_MODE=FAIL"

      It "should simulate format check failure"
        When call run_format_check "scripts/well-formatted.sh"
        The status should be failure
        The output should include "FAIL MODE: Simulating format check failure"
      End
    End

    Context "when in SKIP mode"
      BeforeEach "export FORMAT_MODE=SKIP"

      It "should skip format checking"
        When call run_format_check "scripts/poorly-formatted.sh"
        The status should be success
        The output should include "SKIP MODE: Format check skipped"
      End
    End

    Context "when in TIMEOUT mode"
      BeforeEach "export FORMAT_MODE=TIMEOUT"

      It "should simulate format check timeout"
        When call run_format_check "scripts/well-formatted.sh"
        The status should equal 124  # TIMEOUT exit code
        The output should include "TIMEOUT MODE: Simulating format check timeout"
      End
    End
  End

  Describe "configuration and environment"
    Context "format mode configuration"
      It "should default to check mode when FIX_FORMAT is false"
        BeforeEach "export FIX_FORMAT=false"

        When call get_format_mode
        The output should equal "check"
      End

      It "should use fix mode when FIX_FORMAT is true"
        BeforeEach "export FIX_FORMAT=true"

        When call get_format_mode
        The output should equal "fix"
      End
    End

    Context "shfmt configuration"
      It "should use default shfmt options"
        When call get_shfmt_options
        The output should include "-i"  # indent
        The output should include "-bn" # binary-next-line
        The output should include "-ci" # case-indent
        The output should include "-sr" # space-redirects
      End

      It "should respect custom shfmt options"
        BeforeEach "export SHFMT_OPTIONS="-i 4 -bn"

        When call get_shfmt_options
        The output should include "-i 4"
        The output should include "-bn"
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
                  echo "scripts/well-formatted.sh"
                  echo "scripts/poorly-formatted.sh"
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
        The output should include "✓ scripts/well-formatted.sh is properly formatted"
        The output should include "✗ scripts/poorly-formatted.sh needs formatting"
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
        The output should include "2 files need formatting"
      End
    End
  End

  Describe "error handling and edge cases"
    Context "when handling errors"
      It "should handle shfmt command failure"
        # Mock shfmt failure
        shfmt() {
          return 1
        }

        When call check_file_format "scripts/well-formatted.sh"
        The status should be failure
        The output should include "Failed to check format"
      End

      It "should handle file read errors"
        When call check_file_format "/root/protected.sh"
        The status should be failure
        The output should include "Failed to read file"
      End
    End

    Context "when dealing with edge cases"
      It "should handle empty files"
        touch scripts/empty.sh
        When call check_file_format "scripts/empty.sh"
        The status should be success
        The output should include "✓ scripts/empty.sh is properly formatted"
      End

      It "should handle files without execute permission"
        chmod -x scripts/well-formatted.sh
        When call check_file_format "scripts/well-formatted.sh"
        The status should be success
        The output should include "✓ scripts/well-formatted.sh is properly formatted"
      End

      It "should handle binary files"
        echo -e '\x00\x01\x02\x03' > scripts/binary.sh
        When call check_file_format "scripts/binary.sh"
        The status should be success
        The output should include "Skipping binary file"
      End
    End
  End
End