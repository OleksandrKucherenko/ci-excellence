# shellcheck shell=bash
Describe 'ci-09-parse-tag.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/release/ci-09-parse-tag.sh"

  # Reset GITHUB_OUTPUT before each example
  setup() { : > "$GITHUB_OUTPUT"; }
  Before 'setup'

  Describe 'standard release tag'
    It 'parses refs/tags/v1.2.3 and writes version=1.2.3 to GITHUB_OUTPUT'
      When run bash "$RUN_SCRIPT" "$SCRIPT" "refs/tags/v1.2.3"
      The contents of file "$GITHUB_OUTPUT" should include 'version=1.2.3'
      The status should equal 0
    End
  End

  Describe 'pre-release tag'
    It 'sets is-prerelease=true for refs/tags/v1.0.0-alpha'
      When run bash "$RUN_SCRIPT" "$SCRIPT" "refs/tags/v1.0.0-alpha"
      The contents of file "$GITHUB_OUTPUT" should include 'is-prerelease=true'
      The status should equal 0
    End
  End

  Describe 'stable release tag'
    It 'sets is-prerelease=false for refs/tags/v2.0.0'
      When run bash "$RUN_SCRIPT" "$SCRIPT" "refs/tags/v2.0.0"
      The contents of file "$GITHUB_OUTPUT" should include 'is-prerelease=false'
      The status should equal 0
    End
  End
End
