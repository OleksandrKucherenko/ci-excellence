# shellcheck shell=bash
Describe 'ci-27-write-release-notes-output.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-27-write-release-notes-output.sh"

  It 'exits 0 and announces its title'
    export CI_VERSION=1.0.0
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
    The stderr should include 'Writing Release Notes Output'
    The stderr should include 'Release Notes Output Written'
  End

  It 'exits 1 when CI_VERSION is missing'
    export CI_VERSION=""
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 1
  End
End
