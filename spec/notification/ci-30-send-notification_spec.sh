# shellcheck shell=bash
Describe 'ci-30-send-notification.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/notification/ci-30-send-notification.sh"

  setup() {
    unset APPRISE_URLS 2>/dev/null || true
    export APPRISE_URLS=""
  }
  Before 'setup'

  Describe 'when APPRISE_URLS is empty'
    It 'exits successfully with graceful skip'
      export NOTIFY_TITLE="Test Title" NOTIFY_MESSAGE="Test Message" NOTIFY_STATUS="info"
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The status should equal 0
      The stderr should include 'No notification URLs configured'
    End
  End

  It 'announces itself'
    When run bash "$RUN_SCRIPT" "$SCRIPT"
    The stderr should include 'Sending Notification'
  End
End
