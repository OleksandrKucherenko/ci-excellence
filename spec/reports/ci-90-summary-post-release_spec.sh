# shellcheck shell=bash
Describe 'ci-90-summary-post-release.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/reports/ci-90-summary-post-release.sh"

  setup() { : > "$GITHUB_STEP_SUMMARY"; }
  Before 'setup'

  It 'exits successfully'
    export RESULT_VERIFY=success RESULT_TAG_STABLE=success RESULT_TAG_UNSTABLE=success RESULT_ROLLBACK=success
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
    The stderr should be present
  End

  It 'announces itself'
    export RESULT_VERIFY=success RESULT_TAG_STABLE=success RESULT_TAG_UNSTABLE=success RESULT_ROLLBACK=success
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The stderr should include 'Generating Post-Release Summary'
  End

  It 'writes to GITHUB_STEP_SUMMARY'
    export RESULT_VERIFY=success RESULT_TAG_STABLE=success RESULT_TAG_UNSTABLE=success RESULT_ROLLBACK=success
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The contents of file "$GITHUB_STEP_SUMMARY" should include 'Post-Release Actions Summary'
    The status should equal 0
    The stderr should be present
  End
End
