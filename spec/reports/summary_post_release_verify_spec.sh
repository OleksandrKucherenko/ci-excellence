# shellcheck shell=bash
Describe 'ci-80-summary-post-release-verify.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/reports/ci-80-summary-post-release-verify.sh"

  setup() { : > "$GITHUB_STEP_SUMMARY"; }
  Before 'setup'

  It 'exits successfully'
    When run bash "$RUN_SCRIPT" "$SCRIPT" "1.0.0"
    The status should equal 0
  End

  It 'announces itself'
    When run bash "$RUN_SCRIPT" "$SCRIPT" "1.0.0"
    The stderr should include 'Generating Post-Release Verification Summary'
  End

  It 'writes to GITHUB_STEP_SUMMARY'
    When run bash "$RUN_SCRIPT" "$SCRIPT" "1.0.0"
    The contents of file "$GITHUB_STEP_SUMMARY" should include 'Deployment Verification Results'
    The status should equal 0
  End
End
