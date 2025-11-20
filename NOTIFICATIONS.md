# Notifications Setup Guide

This guide covers setting up notifications using [Apprise](https://github.com/caronc/apprise), a universal notification tool that supports 100+ services.

## Table of Contents

- [Quick Start](#quick-start)
- [Service Setup](#service-setup)
  - [Telegram (Recommended)](#telegram-recommended)
  - [Discord](#discord)
  - [Slack](#slack)
- [Rich Formatting](#rich-formatting)
- [Advanced Usage](#advanced-usage)
- [CI/CD Integration](#cicd-integration)

## Quick Start

Apprise is installed via mise as part of this project:

```bash
# Install all tools including apprise
mise install

# Verify installation
apprise --version
```

## Service Setup

### Telegram (Recommended)

Telegram is the easiest to set up and works great for personal and team notifications.

#### Setup Steps

1. **Create a Bot**
   - Open Telegram and message [@BotFather](https://t.me/BotFather)
   - Send `/newbot` command
   - Follow the prompts to name your bot
   - Save the **bot token** (format: `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`)

2. **Get Your Chat ID**
   - Message [@userinfobot](https://t.me/userinfobot)
   - It will reply with your chat ID (a number)

3. **Start Chat with Your Bot**
   - Find your bot in Telegram (use the link from BotFather)
   - Click **Start** or send `/start`
   - This is required for the bot to send you messages

#### Usage

```bash
# Basic notification
apprise -t "Build Successful" -b "All tests passed!" \
  tgram://BOT_TOKEN/CHAT_ID

# With environment variables (recommended for CI/CD)
export TELEGRAM_BOT_TOKEN="123456789:ABCdefGHIjklMNOpqrsTUVwxyz"
export TELEGRAM_CHAT_ID="987654321"

apprise -t "Deployment Started" -b "Deploying to production..." \
  tgram://${TELEGRAM_BOT_TOKEN}/${TELEGRAM_CHAT_ID}
```

#### Telegram URL Format

```
tgram://BOT_TOKEN/CHAT_ID
tgram://BOT_TOKEN/CHAT_ID1/CHAT_ID2/CHAT_ID3  # Multiple recipients
```

### Discord

Great for team notifications if you already have a Discord server.

#### Setup Steps

1. **Create Webhook**
   - Open your Discord server
   - Go to **Server Settings** → **Integrations** → **Webhooks**
   - Click **New Webhook**
   - Choose the channel for notifications
   - Click **Copy Webhook URL**

2. **Extract Webhook Details**
   The URL looks like:
   ```
   https://discord.com/api/webhooks/{WEBHOOK_ID}/{WEBHOOK_TOKEN}
   ```

#### Usage

```bash
# Using full webhook URL
apprise -t "Build Status" -b "Tests completed successfully" \
  discord://WEBHOOK_ID/WEBHOOK_TOKEN

# With custom avatar and username
apprise -t "CI Bot" -b "Build #42 passed" \
  discord://WEBHOOK_ID/WEBHOOK_TOKEN/?avatar=No&tts=No
```

#### Discord URL Format

```
discord://WEBHOOK_ID/WEBHOOK_TOKEN
discord://WEBHOOK_ID/WEBHOOK_TOKEN/?avatar=No&tts=No&format=markdown
```

### Slack

Best for enterprise teams already using Slack.

#### Setup Steps

1. **Create Slack App**
   - Go to [api.slack.com/apps](https://api.slack.com/apps)
   - Click **Create New App** → **From scratch**
   - Name your app and select workspace

2. **Enable Incoming Webhooks**
   - In your app settings, go to **Incoming Webhooks**
   - Toggle **Activate Incoming Webhooks** to On
   - Click **Add New Webhook to Workspace**
   - Select a channel and authorize

3. **Copy Webhook URL**
   - Copy the webhook URL (starts with `https://hooks.slack.com/services/...`)

#### Usage

```bash
# Basic notification
apprise -t "Build Alert" -b "Production deployment completed" \
  slack://WORKSPACE_ID/TOKEN_A/TOKEN_B/TOKEN_C

# Simplified using full webhook URL
apprise -t "Alert" -b "Message" \
  https://hooks.slack.com/services/TOKEN_A/TOKEN_B/TOKEN_C
```

#### Slack URL Format

```
slack://WORKSPACE_ID/TOKEN_A/TOKEN_B/TOKEN_C
slack://WORKSPACE_ID/TOKEN_A/TOKEN_B/TOKEN_C/#channel
slack://botname@WORKSPACE_ID/TOKEN_A/TOKEN_B/TOKEN_C
```

## Rich Formatting

Apprise supports multiple formatting types for rich messages.

### Markdown Format

Most services support Markdown formatting:

```bash
apprise -t "Build Report" \
  --body-format=markdown \
  -b "
# Build Status: SUCCESS ✅

## Test Results
- **Unit Tests**: 150/150 passed
- **Integration Tests**: 45/45 passed
- **Code Coverage**: 87.5%

## Changes
- Fixed authentication bug
- Updated dependencies
- Improved error handling

[View Full Report](https://ci.example.com/builds/123)
" \
  tgram://BOT_TOKEN/CHAT_ID
```

### HTML Format

For services that support HTML:

```bash
apprise -t "Deployment Alert" \
  --body-format=html \
  -b "
<h2>🚀 Production Deployment</h2>
<p><strong>Status:</strong> <span style='color:green'>Successful</span></p>
<ul>
  <li>Build: #123</li>
  <li>Duration: 5m 32s</li>
  <li>Branch: main</li>
</ul>
<p><a href='https://app.example.com'>View Application</a></p>
" \
  tgram://BOT_TOKEN/CHAT_ID
```

### Text Format (Plain)

Simple text without formatting:

```bash
apprise -t "Simple Alert" \
  --body-format=text \
  -b "This is a plain text message without any formatting" \
  tgram://BOT_TOKEN/CHAT_ID
```

### Format Options

| Format | Telegram | Discord | Slack | Description |
|--------|----------|---------|-------|-------------|
| `markdown` | ✅ | ✅ | ✅ | GitHub-flavored Markdown |
| `html` | ✅ | ❌ | ❌ | HTML formatting |
| `text` | ✅ | ✅ | ✅ | Plain text only |

### Markdown Syntax Examples

```markdown
# Headers
## Headers work great for sections

**Bold text** and *italic text*

`inline code` for commands or file names

\`\`\`bash
# Code blocks with syntax highlighting
echo "Hello World"
\`\`\`

- Bullet lists
- Work well
- For status items

1. Numbered lists
2. Are also supported
3. Great for steps

[Links](https://example.com) can be embedded

> Blockquotes for important messages
```

## Advanced Usage

### Multiple Recipients

Send to multiple services at once:

```bash
apprise -t "Critical Alert" -b "Production server is down!" \
  tgram://BOT_TOKEN/CHAT_ID \
  discord://WEBHOOK_ID/TOKEN \
  slack://WORKSPACE/TOKEN_A/TOKEN_B/TOKEN_C
```

### Configuration File

Create an apprise configuration file for easier management:

```yaml
# .apprise.yml
version: 1
urls:
  - tgram://BOT_TOKEN/CHAT_ID:
      - tag: dev, all
  - discord://WEBHOOK_ID/TOKEN:
      - tag: team, all
  - slack://WORKSPACE/TOKENS:
      - tag: production, all
```

Usage:

```bash
# Send to all 'dev' tagged services
apprise --config=.apprise.yml --tag=dev -t "Dev Alert" -b "Message"

# Send to all services
apprise --config=.apprise.yml --tag=all -t "Global Alert" -b "Message"
```

### Environment Variables

Store credentials securely:

```bash
# In .env.secrets.json or .env file
export TELEGRAM_BOT_TOKEN="your_bot_token"
export TELEGRAM_CHAT_ID="your_chat_id"
export DISCORD_WEBHOOK_ID="webhook_id"
export DISCORD_WEBHOOK_TOKEN="webhook_token"

# Use in scripts
apprise -t "Test" -b "Message" \
  tgram://${TELEGRAM_BOT_TOKEN}/${TELEGRAM_CHAT_ID}
```

### Notification Types

Apprise supports different notification types with visual indicators:

```bash
# Info (default - blue)
apprise --notification-type=info -t "Info" -b "Build started" URL

# Success (green)
apprise --notification-type=success -t "Success" -b "Build passed" URL

# Warning (yellow/orange)
apprise --notification-type=warning -t "Warning" -b "Tests slow" URL

# Failure (red)
apprise --notification-type=failure -t "Failed" -b "Build failed" URL
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: CI Pipeline

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup mise
        uses: jdx/mise-action@v2

      - name: Install dependencies
        run: mise install

      - name: Run tests
        id: tests
        run: |
          # Your test commands here
          npm test

      - name: Notify Success
        if: success()
        run: |
          apprise -t "✅ Build Successful" \
            --body-format=markdown \
            -b "
          ## Build #${{ github.run_number }} Passed

          **Repository**: ${{ github.repository }}
          **Branch**: ${{ github.ref_name }}
          **Commit**: \`${{ github.sha }}\`
          **Author**: ${{ github.actor }}

          [View Run](https://github.com/${{ github.repository }}/actions/runs/${{ github.run_id }})
          " \
            tgram://${{ secrets.TELEGRAM_BOT_TOKEN }}/${{ secrets.TELEGRAM_CHAT_ID }}

      - name: Notify Failure
        if: failure()
        run: |
          apprise --notification-type=failure \
            -t "❌ Build Failed" \
            --body-format=markdown \
            -b "
          ## Build #${{ github.run_number }} Failed

          **Repository**: ${{ github.repository }}
          **Branch**: ${{ github.ref_name }}
          **Commit**: \`${{ github.sha }}\`
          **Author**: ${{ github.actor }}

          [View Run](https://github.com/${{ github.repository }}/actions/runs/${{ github.run_id }})
          " \
            tgram://${{ secrets.TELEGRAM_BOT_TOKEN }}/${{ secrets.TELEGRAM_CHAT_ID }}
```

### Shell Script Example

```bash
#!/bin/bash
# notify.sh - Send build notifications

set -e

NOTIFICATION_URL="${TELEGRAM_URL:-tgram://${TELEGRAM_BOT_TOKEN}/${TELEGRAM_CHAT_ID}}"
BUILD_STATUS="${1:-unknown}"
BUILD_MESSAGE="${2:-No message provided}"

case "$BUILD_STATUS" in
  success)
    NOTIFICATION_TYPE="success"
    EMOJI="✅"
    ;;
  failure)
    NOTIFICATION_TYPE="failure"
    EMOJI="❌"
    ;;
  warning)
    NOTIFICATION_TYPE="warning"
    EMOJI="⚠️"
    ;;
  *)
    NOTIFICATION_TYPE="info"
    EMOJI="ℹ️"
    ;;
esac

apprise \
  --notification-type="$NOTIFICATION_TYPE" \
  -t "$EMOJI Build $BUILD_STATUS" \
  --body-format=markdown \
  -b "
## Build Report

**Status**: $BUILD_STATUS
**Time**: $(date +'%Y-%m-%d %H:%M:%S')
**Host**: $(hostname)

### Details
$BUILD_MESSAGE
" \
  "$NOTIFICATION_URL"
```

Usage:

```bash
# Success notification
./notify.sh success "All tests passed with 95% coverage"

# Failure notification
./notify.sh failure "3 tests failed in authentication module"

# Warning notification
./notify.sh warning "Build succeeded but code coverage dropped below 80%"
```

## Best Practices

1. **Use Environment Variables**: Never commit tokens or credentials
2. **Tag Notifications**: Use tags to route messages to appropriate channels
3. **Rich Formatting**: Use Markdown for better readability
4. **Notification Types**: Use appropriate types (success, failure, warning, info)
5. **Include Context**: Add relevant information (build number, branch, commit)
6. **Link to Details**: Include URLs to CI runs, dashboards, or logs
7. **Keep It Concise**: Don't overload messages with too much information
8. **Test Locally**: Test notification formats before deploying to CI/CD

## Troubleshooting

### Telegram Not Receiving Messages

- Ensure you've started a chat with your bot (send `/start`)
- Verify the bot token is correct
- Check the chat ID is correct
- Make sure the bot isn't blocked

### Discord Webhook Issues

- Verify the webhook hasn't been deleted
- Check the webhook permissions for the channel
- Ensure the URL is complete and correct

### Slack Messages Not Appearing

- Confirm the webhook is still active
- Check the app has permissions for the channel
- Verify workspace settings allow incoming webhooks

## Additional Resources

- [Apprise Official Documentation](https://github.com/caronc/apprise)
- [Apprise Wiki - All Services](https://github.com/caronc/apprise/wiki)
- [Telegram Bot API](https://core.telegram.org/bots/api)
- [Discord Webhooks](https://discord.com/developers/docs/resources/webhook)
- [Slack Incoming Webhooks](https://api.slack.com/messaging/webhooks)

## Quick Reference

### Common Commands

```bash
# Simple notification
apprise -t "Title" -b "Body" SERVICE_URL

# Markdown notification
apprise -t "Title" --body-format=markdown -b "**Bold** message" URL

# Multiple services
apprise -t "Title" -b "Body" URL1 URL2 URL3

# With notification type
apprise --notification-type=success -t "Success" -b "Done" URL

# From file
apprise -t "Title" -b "$(cat message.txt)" URL

# From stdin
echo "Message" | apprise -t "Title" URL

# With config file
apprise --config=.apprise.yml --tag=production -t "Alert" -b "Message"

# Debug mode
apprise -vv -t "Debug" -b "Test" URL
```

### Service URL Quick Reference

| Service | URL Format | Example |
|---------|-----------|---------|
| Telegram | `tgram://BOT_TOKEN/CHAT_ID` | `tgram://123:ABC/456` |
| Discord | `discord://WEBHOOK_ID/TOKEN` | `discord://123/ABC...` |
| Slack | `slack://TOKEN_A/TOKEN_B/TOKEN_C` | `slack://T00/B00/Xx` |
| Email | `mailto://user:pass@domain` | `mailto://user:pass@gmail.com` |
| Generic Webhook | `json://webhook-url` | `json://example.com/hook` |

---

**Pro Tip**: For CI/CD pipelines, use Telegram for quick personal notifications and Slack/Discord for team-wide alerts. Configure both with different tags in your apprise configuration file.
