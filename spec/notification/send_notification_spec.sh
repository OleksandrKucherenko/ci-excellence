# shellcheck shell=bash
Describe 'ci-30-send-notification.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/notification/ci-30-send-notification.sh"

  setup() {
    unset APPRISE_URLS 2>/dev/null || true
    export APPRISE_URLS=""
  }
  Before 'setup'

  It 'exits successfully when APPRISE_URLS is empty'
    When run bash "$RUN_SCRIPT" "$SCRIPT" "Test Title" "Test Message" "info"
    The status should equal 0
  End

  It 'announces itself'
    When run bash "$RUN_SCRIPT" "$SCRIPT" "Test Title" "Test Message" "info"
    The stderr should include 'Sending Notification'
  End

  It 'reports no notification URLs configured'
    When run bash "$RUN_SCRIPT" "$SCRIPT" "Test Title" "Test Message" "info"
    The stderr should include 'No notification URLs configured'
  End
End
