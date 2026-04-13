# shellcheck shell=bash
Describe 'ci-30-security-scan.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/build/ci-30-security-scan.sh"

  It 'exits 0 and prints security scan messages'
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
    The stderr should include 'Running Security Scans'
    The stderr should include 'Security Scan Complete'
  End
End
