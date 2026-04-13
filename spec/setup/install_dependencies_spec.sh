# shellcheck shell=bash
Describe 'ci-20-install-dependencies.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/setup/ci-20-install-dependencies.sh"

  It 'exits 0 and prints dependency messages'
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
    The stderr should include 'Installing Project Dependencies'
    The stderr should include 'Dependency Installation Complete'
  End
End
