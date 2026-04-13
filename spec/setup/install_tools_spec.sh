# shellcheck shell=bash
Describe 'ci-10-install-tools.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/setup/ci-10-install-tools.sh"

  It 'starts and announces itself'
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The stderr should include 'Installing Required Tools'
  End
End
