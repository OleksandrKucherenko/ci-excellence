# shellcheck shell=bash
Describe 'ci-12-set-version-outputs.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-12-set-version-outputs.sh"

  It 'exits 0 and announces its title'
    export CI_RELEASE_SCOPE=patch CI_PRE_RELEASE_TYPE=false
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
    The stderr should include 'Setting Version Outputs'
    The stderr should include 'Version Outputs Set'
  End
End
