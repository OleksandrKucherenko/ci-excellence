# shellcheck shell=bash
Describe 'ci-40-smoke-tests.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/test/ci-40-smoke-tests.sh"

  It 'exits 0 and prints smoke test messages'
    export CI_VERSION="1.0.0"
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
    The stderr should include 'Running Smoke Tests'
  End
End
