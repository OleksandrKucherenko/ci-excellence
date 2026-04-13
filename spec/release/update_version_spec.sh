# shellcheck shell=bash
Describe 'ci-15-update-version.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-15-update-version.sh"

  It 'exits successfully'
    When run bash "$RUN_SCRIPT" "$SCRIPT" "1.2.3"
    The status should equal 0
  End

  It 'announces its title'
    When run bash "$RUN_SCRIPT" "$SCRIPT" "1.2.3"
    The stderr should include 'Updating Version Files'
  End

  It 'reports version files updated'
    When run bash "$RUN_SCRIPT" "$SCRIPT" "1.2.3"
    The stderr should include 'Version Files Updated'
  End
End
