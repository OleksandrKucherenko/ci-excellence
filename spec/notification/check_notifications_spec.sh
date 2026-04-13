# shellcheck shell=bash
Describe 'ci-10-check-notifications-enabled.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/notification/ci-10-check-notifications-enabled.sh"

  # Reset env vars and GITHUB_OUTPUT before each test
  setup_clean_env() {
    : > "$GITHUB_OUTPUT"
    unset APPRISE_URLS TELEGRAM_BOT_TOKEN TELEGRAM_CHAT_ID ENABLE_NOTIFICATIONS 2>/dev/null || true
    export APPRISE_URLS=""
    export TELEGRAM_BOT_TOKEN=""
    export TELEGRAM_CHAT_ID=""
    export ENABLE_NOTIFICATIONS=""
  }
  Before 'setup_clean_env'

  Describe 'APPRISE_URLS set'
    It 'enables notifications and outputs apprise_urls'
      export APPRISE_URLS="slack://token@channel"
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The contents of file "$GITHUB_OUTPUT" should include 'enabled=true'
      The contents of file "$GITHUB_OUTPUT" should include 'apprise_urls=slack://token@channel'
      The status should equal 0
      The stderr should be present
    End
  End

  Describe 'Telegram credentials set'
    It 'enables notifications and converts to apprise format'
      export TELEGRAM_BOT_TOKEN="123456:ABC-DEF"
      export TELEGRAM_CHAT_ID="-100123"
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The contents of file "$GITHUB_OUTPUT" should include 'enabled=true'
      The contents of file "$GITHUB_OUTPUT" should include 'apprise_urls=tgram://123456:ABC-DEF/-100123?format=html'
      The status should equal 0
      The stderr should be present
    End
  End

  Describe 'ENABLE_NOTIFICATIONS=false'
    It 'disables notifications even when credentials exist'
      export APPRISE_URLS="slack://token@channel"
      export ENABLE_NOTIFICATIONS="false"
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The contents of file "$GITHUB_OUTPUT" should include 'enabled=false'
      The status should equal 0
      The stderr should be present
    End

    It 'disables notifications with uppercase FALSE'
      export ENABLE_NOTIFICATIONS="FALSE"
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The contents of file "$GITHUB_OUTPUT" should include 'enabled=false'
      The status should equal 0
      The stderr should be present
    End

    It 'disables notifications with "no"'
      export ENABLE_NOTIFICATIONS="no"
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The contents of file "$GITHUB_OUTPUT" should include 'enabled=false'
      The status should equal 0
      The stderr should be present
    End
  End

  Describe 'no credentials'
    It 'disables notifications when nothing is set'
      When run bash "$RUN_SCRIPT" "$SCRIPT"
      The contents of file "$GITHUB_OUTPUT" should include 'enabled=false'
      The status should equal 0
      The stderr should be present
    End
  End
End
