# shellcheck shell=bash
Describe 'ci-66-publish-npm-release.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-66-publish-npm-release.sh"

  It 'exits 0 and announces its title'
    export CI_IS_PRERELEASE=false
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
    The stderr should include 'Publish NPM Release'
    The stderr should include 'Publish NPM Release Done'
  End
End
