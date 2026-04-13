# shellcheck shell=bash
Describe 'ci-18-commit-version-changes.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-18-commit-version-changes.sh"

  It 'exits 0 and announces its title'
    export CI_TARGET_BRANCH=main CI_VERSION=1.0.0
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
    The stderr should include 'Committing Version Changes'
    The stderr should include 'Version Changes Committed'
  End
End
