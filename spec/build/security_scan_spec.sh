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
    sarif_file="$SHELLSPEC_PROJECT_ROOT/security-results.sarif"

    setup() { rm -f "$sarif_file"; }
    Before 'setup'
    cleanup() { rm -f "$sarif_file"; }
    After 'cleanup'

    It 'does not create SARIF file when mise is missing (exits before SARIF step)'
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The status should equal 1
      The file "$sarif_file" should not be exist
    End
  End
End
