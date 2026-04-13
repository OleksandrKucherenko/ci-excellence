# shellcheck shell=bash
Describe 'ci-85-verify-docker-deployment.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-85-verify-docker-deployment.sh"

  It 'exits successfully'
    export CI_VERSION="1.0.0"
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
    The stderr should be present
  End

  It 'announces its title'
    export CI_VERSION="1.0.0"
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The stderr should include 'Verifying Docker Deployment'
  End

  It 'reports verification complete'
    export CI_VERSION="1.0.0"
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The stderr should include 'Docker Deployment Verification Complete'
  End
End
