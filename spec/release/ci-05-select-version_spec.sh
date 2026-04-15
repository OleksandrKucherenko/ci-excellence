# shellcheck shell=bash
Describe 'ci-05-select-version.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-05-select-version.sh"

  It 'exits 0 and prints selection messages'
    export CI_EVENT_NAME=release CI_RELEASE_TAG=v2.1.0 CI_VERSION=""
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
    The stderr should include 'Selecting Version'
    The stderr should include 'Version Selected'
  End
End
