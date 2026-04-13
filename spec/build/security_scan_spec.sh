# shellcheck shell=bash
Describe 'ci-30-security-scan.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/build/ci-30-security-scan.sh"

  Describe 'when mise is not available'
    It 'exits 1 with mise not found message'
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The status should equal 1
      The stderr should include 'mise not found'
    End
  End

  Describe 'SARIF file creation'
    setup() {
      MOCK_BIN="$(mktemp -d)"
      # Create a fake mise that succeeds for all sub-commands
      printf '#!/usr/bin/env bash\nexit 0\n' > "$MOCK_BIN/mise"
      chmod +x "$MOCK_BIN/mise"
      export PATH="$MOCK_BIN:$PATH"
    }
    cleanup() {
      rm -rf "$MOCK_BIN"
      rm -f security-results.sarif gitleaks-report.json trufflehog-report.json
    }
    BeforeEach 'setup'
    AfterEach 'cleanup'

    It 'creates security-results.sarif in the current directory'
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The status should equal 0
      The stderr should include 'Security Scan Complete'
      Path security-results-sarif="security-results.sarif"
      The path security-results-sarif should be file
    End
  End
End
