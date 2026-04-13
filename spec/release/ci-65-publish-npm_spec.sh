# shellcheck shell=bash
Describe 'ci-65-publish-npm.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-65-publish-npm.sh"

  It 'exits 0 and announces its title'
    export NODE_AUTH_TOKEN=fake-token
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
    The stderr should include 'Publishing to NPM'
    The stderr should include 'NPM Publishing Complete'
  End
End
