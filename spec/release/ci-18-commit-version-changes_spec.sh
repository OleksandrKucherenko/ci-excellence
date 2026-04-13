# shellcheck shell=bash
Describe 'ci-18-commit-version-changes.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-18-commit-version-changes.sh"

  It 'exits 1 when version is missing'
    export CI_TARGET_BRANCH=main CI_VERSION=""
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The stderr should include 'Version is required'
    The status should equal 1
  End

  It 'announces its title'
    export CI_TARGET_BRANCH=main CI_VERSION=""
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The stderr should include 'Committing Version Changes'
  End
End
