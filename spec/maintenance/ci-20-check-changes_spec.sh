# shellcheck shell=bash
Describe 'ci-20-check-changes.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/maintenance/ci-20-check-changes.sh"

  setup() { : > "$GITHUB_OUTPUT"; }
  Before 'setup'

  It 'exits successfully'
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
    The stderr should be present
  End

  It 'announces itself'
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The stderr should include 'Checking for Changes'
  End

  It 'writes has-changes to GITHUB_OUTPUT'
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The contents of file "$GITHUB_OUTPUT" should include 'has-changes'
    The status should equal 0
    The stderr should be present
  End
End
