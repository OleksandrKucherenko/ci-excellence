# shellcheck shell=bash
Describe 'ci-15-update-version.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-15-update-version.sh"

  It 'exits successfully'
    export CI_VERSION="1.2.3"
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
    The stderr should be present
  End

  It 'announces its title'
    export CI_VERSION="1.2.3"
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The stderr should include 'Updating Version Files'
  End

  It 'reports version files updated'
    export CI_VERSION="1.2.3"
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The stderr should include 'Version Files Updated'
  End
End
