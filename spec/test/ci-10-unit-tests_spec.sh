# shellcheck shell=bash
Describe 'ci-10-unit-tests.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/test/ci-10-unit-tests.sh"

  It 'exits 0 and prints unit test messages'
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
    The stderr should include 'Running Unit Tests'
    The stderr should include 'Unit Tests Complete'
  End
End
