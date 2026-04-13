# shellcheck shell=bash
Describe 'ci-75-rollback-npm.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-75-rollback-npm.sh"

  It 'exits 0 and announces its title'
    export CI_VERSION="1.0.0" NODE_AUTH_TOKEN=fake-token
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
    The stderr should include 'Rolling Back NPM'
    The stderr should include 'NPM Rollback Complete'
  End

  It 'exits 1 when CI_VERSION is missing'
    export CI_VERSION="" NODE_AUTH_TOKEN=fake-token
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 1
  End
End
