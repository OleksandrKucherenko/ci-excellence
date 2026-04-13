# shellcheck shell=bash
Describe 'ci-90-summary-post-release.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/reports/ci-90-summary-post-release.sh"

  setup() { : > "$GITHUB_STEP_SUMMARY"; }
  Before 'setup'

  It 'exits successfully'
    When run bash "$RUN_SCRIPT" "$SCRIPT" success success success success
    The status should equal 0
    The stderr should be present
  End

  It 'announces itself'
    When run bash "$RUN_SCRIPT" "$SCRIPT" success success success success
    The stderr should include 'Generating Post-Release Summary'
  End

  It 'writes to GITHUB_STEP_SUMMARY'
    When run bash "$RUN_SCRIPT" "$SCRIPT" success success success success
    The contents of file "$GITHUB_STEP_SUMMARY" should include 'Post-Release Actions Summary'
    The status should equal 0
    The stderr should be present
  End
End
