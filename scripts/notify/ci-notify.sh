#!/bin/bash
#
# CI Notification Helper Script
#
# Wrapper around the Bun/TypeScript notification utility
# for easy use in shell-based CI/CD pipelines.
#
# Usage:
#   source scripts/notify/ci-notify.sh
#   notify_start "Build #123" "Starting CI pipeline"
#   notify_info "Running tests..."
#   notify_success "All tests passed!"
#   notify_end "Build completed"
#
# Or use directly:
#   ./scripts/notify/ci-notify.sh start "Build started"
#   ./scripts/notify/ci-notify.sh info "Running..."
#   ./scripts/notify/ci-notify.sh success "Done!"
#

set -eo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOTIFY_CMD="bun ${SCRIPT_DIR}/telegram.ts"

# Validate environment
check_env() {
  if [[ -z "${TELEGRAM_BOT_TOKEN}" ]] || [[ -z "${TELEGRAM_CHAT_ID}" ]]; then
    echo "Error: TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID must be set" >&2
    return 1
  fi
}

# Start a new notification thread
notify_start() {
  check_env || return 1
  local title="$1"
  local body="$2"

  ${NOTIFY_CMD} \
    --new-thread \
    --title "${title}" \
    --body "${body}" \
    --type info
}

# Send info notification (continues thread)
notify_info() {
  check_env || return 1
  local body="$1"
  local title="${2:-}"

  local args=(--body "${body}" --type info --thread)
  [[ -n "${title}" ]] && args+=(--title "${title}")

  ${NOTIFY_CMD} "${args[@]}"
}

# Send success notification (continues thread)
notify_success() {
  check_env || return 1
  local body="$1"
  local title="${2:-}"

  local args=(--body "${body}" --type success --thread)
  [[ -n "${title}" ]] && args+=(--title "${title}")

  ${NOTIFY_CMD} "${args[@]}"
}

# Send warning notification (continues thread)
notify_warning() {
  check_env || return 1
  local body="$1"
  local title="${2:-}"

  local args=(--body "${body}" --type warning --thread)
  [[ -n "${title}" ]] && args+=(--title "${title}")

  ${NOTIFY_CMD} "${args[@]}"
}

# Send failure notification (continues thread)
notify_failure() {
  check_env || return 1
  local body="$1"
  local title="${2:-}"

  local args=(--body "${body}" --type failure --thread)
  [[ -n "${title}" ]] && args+=(--title "${title}")

  ${NOTIFY_CMD} "${args[@]}"
}

# End notification thread
notify_end() {
  check_env || return 1
  local body="$1"
  local title="${2:-Build Complete}"

  ${NOTIFY_CMD} \
    --title "${title}" \
    --body "${body}" \
    --type success \
    --thread
}

# CLI mode when executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  case "${1:-}" in
    start)
      notify_start "${2:-Build Started}" "${3:-Starting build process...}"
      ;;
    info)
      notify_info "${2:-Info message}"
      ;;
    success)
      notify_success "${2:-Success message}"
      ;;
    warning)
      notify_warning "${2:-Warning message}"
      ;;
    failure)
      notify_failure "${2:-Failure message}"
      ;;
    end)
      notify_end "${2:-Build complete}"
      ;;
    *)
      cat <<EOF
Usage: $0 <command> <message> [title]

Commands:
  start <title> <body>    Start new notification thread
  info <body> [title]     Send info notification
  success <body> [title]  Send success notification
  warning <body> [title]  Send warning notification
  failure <body> [title]  Send failure notification
  end <body> [title]      End notification thread

Environment Variables:
  TELEGRAM_BOT_TOKEN      Telegram bot token (required)
  TELEGRAM_CHAT_ID        Telegram chat ID (required)

Examples:
  # Start a build notification thread
  $0 start "Build #123" "Starting CI pipeline"

  # Send progress updates
  $0 info "Running tests..."
  $0 success "All tests passed!"

  # End the thread
  $0 end "Build completed successfully"

  # Or source and use as functions:
  source $0
  notify_start "Build Started" "Running CI..."
  notify_info "Tests in progress"
  notify_success "Tests passed"
EOF
      exit 1
      ;;
  esac
fi
