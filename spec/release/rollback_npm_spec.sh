# shellcheck shell=bash
Describe 'ci-75-rollback-npm.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-75-rollback-npm.sh"

  It 'exits 1 when NODE_AUTH_TOKEN is not set'
    When run bash "$RUN_SCRIPT" "$SCRIPT" "1.0.0"
    The status should equal 1
    The stderr should include 'NODE_AUTH_TOKEN is not set'
  End

  It 'announces its title'
    When run bash -c "export NODE_AUTH_TOKEN=fake-token && bash '$RUN_SCRIPT' '$SCRIPT' 1.0.0"
    The stderr should include 'Rolling Back NPM'
  End

  It 'exits successfully when NODE_AUTH_TOKEN is set'
    When run bash -c "export NODE_AUTH_TOKEN=fake-token && bash '$RUN_SCRIPT' '$SCRIPT' 1.0.0"
    The status should equal 0
  End
End
