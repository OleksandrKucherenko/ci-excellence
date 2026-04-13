# shellcheck shell=bash
Describe 'ci-30-github-actions-bot.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/setup/ci-30-github-actions-bot.sh"

  It 'exits 0 and configures git user'
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
    The stderr should include 'Set GitHub Username and Email for Bot'
  End

  It 'sets git user.name to github-actions[bot]'
    bash "$RUN_SCRIPT" "$SCRIPT" >/dev/null 2>&1
    When run command git config user.name
    The output should include 'github-actions[bot]'
  End
End
