# shellcheck shell=bash
Describe 'ci-27-write-release-notes-output.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-27-write-release-notes-output.sh"

  setup() { : > "$GITHUB_OUTPUT"; }
  Before 'setup'

  It 'exits successfully'
    When run bash "$RUN_SCRIPT" "$SCRIPT" "1.0.0"
    The status should equal 0
  End

  It 'writes notes to GITHUB_OUTPUT'
    When run bash "$RUN_SCRIPT" "$SCRIPT" "1.0.0"
    The contents of file "$GITHUB_OUTPUT" should include 'notes'
  End

  It 'announces its title'
    When run bash "$RUN_SCRIPT" "$SCRIPT" "1.0.0"
    The stderr should include 'Writing Release Notes Output'
  End
End
