# shellcheck shell=bash
Describe 'ci-30-deploy.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/ops/ci-30-deploy.sh"

  Describe 'staging deploy'
    It 'exits 0 for staging environment'
      export OPS_ENVIRONMENT=staging OPS_VERSION=1.0.0 OPS_CONFIRM=""
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The status should equal 0
      The stderr should include 'Deploy Done'
    End
  End

  Describe 'production without confirmation'
    It 'exits 1 when confirm is not yes'
      export OPS_ENVIRONMENT=production OPS_VERSION=1.0.0 OPS_CONFIRM=""
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The status should equal 1
      The stderr should include 'requires confirmation'
    End
  End

  Describe 'production with confirmation'
    It 'exits 0 when confirm is yes'
      export OPS_ENVIRONMENT=production OPS_VERSION=1.0.0 OPS_CONFIRM=yes
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The status should equal 0
      The stderr should include 'Deploy Done'
    End
  End
End
