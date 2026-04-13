# shellcheck shell=bash
Describe 'ci-10-validate-inputs.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/ops/ci-10-validate-inputs.sh"

  Describe 'valid inputs'
    It 'exits 0 when action and version are provided'
      export OPS_ACTION=promote OPS_VERSION=1.2.3
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The status should equal 0
      The stderr should include 'Validate Inputs Done'
    End
  End

  Describe 'empty version'
    It 'exits 1 with error when version is empty'
      export OPS_ACTION=promote OPS_VERSION=""
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The status should equal 1
      The stderr should include 'Version is required'
    End
  End
End
