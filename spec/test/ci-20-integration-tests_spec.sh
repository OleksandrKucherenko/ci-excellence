# shellcheck shell=bash
Describe 'ci-20-integration-tests.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/test/ci-20-integration-tests.sh"

  It 'exits 0 and prints integration test messages'
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
    The stderr should include 'Running Integration Tests'
    The stderr should include 'Integration Tests Complete'
  End
End
