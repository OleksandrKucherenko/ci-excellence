# shellcheck shell=bash
Describe 'ci-75-rollback-npm.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-75-rollback-npm.sh"

  It 'exits 1 when NODE_AUTH_TOKEN is not set'
    export CI_VERSION="1.0.0"
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 1
    The stderr should include 'NODE_AUTH_TOKEN is not set'
  End

  It 'announces its title'
    export CI_VERSION="1.0.0" NODE_AUTH_TOKEN=fake-token
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The stderr should include 'Rolling Back NPM'
  End

  It 'exits successfully when NODE_AUTH_TOKEN is set'
    export CI_VERSION="1.0.0" NODE_AUTH_TOKEN=fake-token
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
    The stderr should be present
  End
End
