# shellcheck shell=bash
Describe 'ci-80-summary-post-release-verify.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/reports/ci-80-summary-post-release-verify.sh"

  setup() { : > "$GITHUB_STEP_SUMMARY"; }
  Before 'setup'

  It 'exits successfully'
    export CI_VERSION=1.0.0
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
    The stderr should be present
  End

  It 'announces itself'
    export CI_VERSION=1.0.0
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The stderr should include 'Generating Post-Release Verification Summary'
  End

  It 'writes to GITHUB_STEP_SUMMARY'
    export CI_VERSION=1.0.0
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The contents of file "$GITHUB_STEP_SUMMARY" should include 'Deployment Verification Results'
    The status should equal 0
    The stderr should be present
  End
End
