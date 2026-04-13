# shellcheck shell=bash
Describe 'ci-30-e2e-tests.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/test/ci-30-e2e-tests.sh"

  It 'exits 0 and prints e2e test messages'
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
    The stderr should include 'Running End-to-End Tests'
    The stderr should include 'E2E Tests Complete'
  End
End
