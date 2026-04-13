# shellcheck shell=bash
Describe 'ci-30-github-actions-bot.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/setup/ci-30-github-actions-bot.sh"

  It 'exits 0 and announces itself'
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The status should equal 0
    The stderr should include 'Set GitHub Username and Email for Bot'
    The stderr should include 'GitHub Actions Bot Setup Completed'
  End
End
