# shellcheck shell=bash
Describe 'ci-30-github-actions-bot.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/setup/ci-30-github-actions-bot.sh"

  It 'exits 0 and configures git bot identity'
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
  End

  Describe 'git config after run'
    setup() { bash "$RUN_SCRIPT" "$SCRIPT" >/dev/null 2>&1; }
    Before 'setup'

    It 'sets git user.name to github-actions[bot]'
      When run command git config user.name
      The output should include 'github-actions[bot]'
    End
  End
End
