# shellcheck shell=bash
Describe 'ci-10-determine-version.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-10-determine-version.sh"

  It 'exits 0 and prints version messages'
    export CI_RELEASE_SCOPE=patch CI_PRE_RELEASE_TYPE=alpha
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
    The stderr should include 'Determining Next Version'
    The stderr should include 'Version Determination Complete'
  End
End
