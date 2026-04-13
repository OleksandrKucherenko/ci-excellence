# shellcheck shell=bash
Describe 'ci-20-lint.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/build/ci-20-lint.sh"

  It 'exits 0 and prints lint messages'
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
    The stderr should include 'Running Linters'
    The stderr should include 'Linting Complete'
  End
End
