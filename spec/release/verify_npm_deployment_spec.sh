# shellcheck shell=bash
Describe 'ci-70-verify-npm-deployment.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-70-verify-npm-deployment.sh"

  It 'exits successfully'
    When run bash "$RUN_SCRIPT" "$SCRIPT" "1.0.0"
    The status should equal 0
    The stderr should be present
  End

  It 'announces its title'
    When run bash "$RUN_SCRIPT" "$SCRIPT" "1.0.0"
    The stderr should include 'Verifying NPM Deployment'
  End

  It 'reports verification complete'
    When run bash "$RUN_SCRIPT" "$SCRIPT" "1.0.0"
    The stderr should include 'NPM Deployment Verification Complete'
  End
End
