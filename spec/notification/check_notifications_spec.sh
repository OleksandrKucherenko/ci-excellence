#!/usr/bin/env bash
# Tests for scripts/ci/notification/ci-10-check-notifications-enabled.sh

Describe 'ci-10-check-notifications-enabled.sh'
  SCRIPT="$SHELLSPEC_PROJECT_ROOT/scripts/ci/notification/ci-10-check-notifications-enabled.sh"

  # Reset notification-related env vars before each test
  setup_clean_env() {
    unset APPRISE_URLS TELEGRAM_BOT_TOKEN TELEGRAM_CHAT_ID ENABLE_NOTIFICATIONS 2>/dev/null || true
    export APPRISE_URLS=""
    export TELEGRAM_BOT_TOKEN=""
    export TELEGRAM_CHAT_ID=""
    export ENABLE_NOTIFICATIONS=""
  }
  BeforeEach 'setup_clean_env'

  Describe 'APPRISE_URLS set'
    It 'enables notifications and outputs apprise_urls'
      export APPRISE_URLS="slack://token@channel"
      When run bash "$SCRIPT"
      The contents of file "$GITHUB_OUTPUT" should include 'enabled=true'
      The contents of file "$GITHUB_OUTPUT" should include 'apprise_urls=slack://token@channel'
      The status should equal 0
    End
  End

  Describe 'Telegram credentials set'
    It 'enables notifications and converts to apprise format'
      export TELEGRAM_BOT_TOKEN="123456:ABC-DEF"
      export TELEGRAM_CHAT_ID="-100123"
      When run bash "$SCRIPT"
      The contents of file "$GITHUB_OUTPUT" should include 'enabled=true'
      The contents of file "$GITHUB_OUTPUT" should include 'apprise_urls=tgram://123456:ABC-DEF/-100123?format=html'
      The status should equal 0
    End
  End

  Describe 'ENABLE_NOTIFICATIONS=false'
    It 'disables notifications even when credentials exist'
      export APPRISE_URLS="slack://token@channel"
      export ENABLE_NOTIFICATIONS="false"
      When run bash "$SCRIPT"
      The contents of file "$GITHUB_OUTPUT" should include 'enabled=false'
      The status should equal 0
    End

    It 'disables notifications with uppercase FALSE'
      export ENABLE_NOTIFICATIONS="FALSE"
      When run bash "$SCRIPT"
      The contents of file "$GITHUB_OUTPUT" should include 'enabled=false'
      The status should equal 0
    End

    It 'disables notifications with "no"'
      export ENABLE_NOTIFICATIONS="no"
      When run bash "$SCRIPT"
      The contents of file "$GITHUB_OUTPUT" should include 'enabled=false'
      The status should equal 0
    End
  End

  Describe 'no credentials'
    It 'disables notifications when nothing is set'
      When run bash "$SCRIPT"
      The contents of file "$GITHUB_OUTPUT" should include 'enabled=false'
      The status should equal 0
    End
  End
End
