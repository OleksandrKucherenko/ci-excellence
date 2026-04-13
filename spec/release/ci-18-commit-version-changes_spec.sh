# shellcheck shell=bash
Describe 'ci-18-commit-version-changes.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-18-commit-version-changes.sh"

  It 'exits 1 when version is missing'
    When run bash "$RUN_SCRIPT" "$SCRIPT" main ""
    The stderr should include 'Version is required'
    The status should equal 1
  End

  It 'announces its title'
    When run bash "$RUN_SCRIPT" "$SCRIPT" main ""
    The stderr should include 'Committing Version Changes'
  End
End
