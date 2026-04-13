# shellcheck shell=bash
Describe 'ci-10-install-tools.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/setup/ci-10-install-tools.sh"

  It 'starts and announces itself'
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The stderr should include 'Installing Required Tools'
    The status should satisfy exit_0_or_1
  End
End

exit_0_or_1() {
  [ "$1" -eq 0 ] || [ "$1" -eq 1 ]
}
