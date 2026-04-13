# shellcheck shell=bash
Describe 'ci-09-parse-tag.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-09-parse-tag.sh"

  It 'exits 0 and prints parse messages'
    export CI_GIT_REF="refs/tags/v1.2.3"
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
    The stderr should include 'Parse Tag'
    The stderr should include 'Parse Tag Done'
  End

  It 'exits 1 when CI_GIT_REF is missing'
    export CI_GIT_REF=""
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 1
  End
End
