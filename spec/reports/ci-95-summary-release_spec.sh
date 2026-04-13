# shellcheck shell=bash
Describe 'ci-95-summary-release.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/reports/ci-95-summary-release.sh"

  setup() {
    : > "$GITHUB_STEP_SUMMARY"
    export GITHUB_SHA="${GITHUB_SHA:-abc1234567890}"
  }
  Before 'setup'

  It 'exits successfully'
    export CI_VERSION=1.0.0 CI_IS_PRERELEASE=false RESULT_PUBLISH_NPM=success RESULT_PUBLISH_GITHUB=success RESULT_PUBLISH_DOCKER=success RESULT_PUBLISH_DOCS=success
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
    The stderr should be present
  End

  It 'announces itself'
    export CI_VERSION=1.0.0 CI_IS_PRERELEASE=false RESULT_PUBLISH_NPM=success RESULT_PUBLISH_GITHUB=success RESULT_PUBLISH_DOCKER=success RESULT_PUBLISH_DOCS=success
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The stderr should include 'Generating Release Summary'
  End

  It 'writes to GITHUB_STEP_SUMMARY'
    export CI_VERSION=1.0.0 CI_IS_PRERELEASE=false RESULT_PUBLISH_NPM=success RESULT_PUBLISH_GITHUB=success RESULT_PUBLISH_DOCKER=success RESULT_PUBLISH_DOCS=success
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The contents of file "$GITHUB_STEP_SUMMARY" should include 'Release Summary'
    The status should equal 0
    The stderr should be present
  End
End
