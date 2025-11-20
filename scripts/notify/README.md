# Notification Scripts

TypeScript/Bun utilities for sending thread-based notifications to Telegram (and other services).

## Quick Start

```bash
# Install dependencies (via mise)
mise install

# Set environment variables
export TELEGRAM_BOT_TOKEN="your_bot_token"
export TELEGRAM_CHAT_ID="your_chat_id"

# Send a notification
bun scripts/notify/telegram.ts \
  --title "Test" \
  --body "Hello from CI!"
```

## Files

| File | Description |
|------|-------------|
| `types.ts` | TypeScript type definitions |
| `telegram.ts` | Main Telegram notification utility with thread support |
| `ci-notify.sh` | Shell wrapper for easy CI/CD integration |
| `example-ci-pipeline.ts` | Complete example of a CI pipeline with notifications |

## Usage Patterns

### Pattern 1: Direct TypeScript/Bun

```bash
# Start new thread
bun telegram.ts --new-thread --title "Build #123" --body "Starting..."

# Continue thread
bun telegram.ts --thread --body "Running tests..."
bun telegram.ts --thread --type success --body "Tests passed!"
```

### Pattern 2: Shell Script Helper

```bash
source ci-notify.sh

notify_start "Build #123" "Starting CI"
notify_info "Running tests..."
notify_success "All tests passed!"
notify_end "Build complete"
```

### Pattern 3: Programmatic (TypeScript)

```typescript
import TelegramNotifier from "./telegram.ts";

const notifier = new TelegramNotifier({
  botToken: process.env.TELEGRAM_BOT_TOKEN!,
  chatId: process.env.TELEGRAM_CHAT_ID!,
});

await notifier.send({
  title: "Build Started",
  body: "Running CI pipeline...",
  type: "info",
});

await notifier.send({
  body: "Build completed!",
  type: "success",
});
```

## Thread Conversations

The utility automatically creates thread conversations by:
1. Storing the last message ID in `~/.cache/ci-notify/thread-context.json`
2. Using `reply_to_message_id` in subsequent messages
3. Creating a visual conversation in Telegram

This makes it easy to track multi-step processes like CI/CD pipelines.

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `TELEGRAM_BOT_TOKEN` | Yes | Your Telegram bot token from @BotFather |
| `TELEGRAM_CHAT_ID` | Yes | Your Telegram chat ID (get from @userinfobot) |

## Examples

Run the example CI pipeline simulation:

```bash
bun example-ci-pipeline.ts
```

This will send a complete build notification thread to your Telegram chat.

## Integration with CI/CD

### GitHub Actions

```yaml
- name: Notify build start
  run: |
    bun scripts/notify/telegram.ts \
      --new-thread \
      --title "Build #${{ github.run_number }}" \
      --body "Starting CI pipeline"
  env:
    TELEGRAM_BOT_TOKEN: ${{ secrets.TELEGRAM_BOT_TOKEN }}
    TELEGRAM_CHAT_ID: ${{ secrets.TELEGRAM_CHAT_ID }}
```

### GitLab CI

```yaml
notify:
  script:
    - source scripts/notify/ci-notify.sh
    - notify_start "Build #${CI_PIPELINE_ID}" "Starting..."
```

### Jenkins

```groovy
sh '''
  source scripts/notify/ci-notify.sh
  notify_start "Build ${BUILD_NUMBER}" "Jenkins pipeline started"
'''
```

## See Also

- [../../NOTIFICATIONS.md](../../NOTIFICATIONS.md) - Complete notification setup guide
- [Telegram Bot API](https://core.telegram.org/bots/api)
