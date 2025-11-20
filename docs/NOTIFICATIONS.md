# Notification Setup Guide

Get real-time CI/CD pipeline notifications in Slack, Teams, Discord, Telegram, Email, and 90+ other services using [Apprise](https://github.com/caronc/apprise).

## 🎯 Overview

The CI/CD pipeline can send notifications for:
- ✅ **Pre-Release**: Build, test, and lint results
- 🚀 **Release**: New version published
- 🔄 **Post-Release**: Deployment verification, rollbacks
- 🔧 **Maintenance**: Security audits, dependency updates

## 🚀 Quick Setup (5 Minutes)

### Step 1: Enable Notifications

Add this variable in **Repository Settings > Secrets and variables > Actions > Variables**:

```
ENABLE_NOTIFICATIONS=true
```

### Step 2: Configure Notification URLs

Add this secret in **Repository Settings > Secrets and variables > Actions > Secrets**:

```
Secret name: APPRISE_URLS
Secret value: <your notification URLs - see examples below>
```

### Step 3: Done!

Your pipelines will now send notifications automatically!

## 📱 Supported Services

Apprise supports **90+ notification services**. Here are the most popular:

### Slack

**Setup:**
1. Create a Slack incoming webhook: https://api.slack.com/messaging/webhooks
2. Copy the webhook URL
3. Format: `slack://token_a/token_b/token_c`

**Example:**
```bash
# From webhook: https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX
# Use: slack://T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX

APPRISE_URLS=slack://T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX
```

**Advanced (with channel):**
```bash
APPRISE_URLS=slack://T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX/#ci-notifications
```

### Microsoft Teams

**Setup:**
1. In Teams, add "Incoming Webhook" connector to your channel
2. Copy the webhook URL
3. Format: `msteams://webhook_url`

**Example:**
```bash
# From webhook: https://outlook.office.com/webhook/xxxxx
# Use: msteams://outlook.office.com/webhook/xxxxx

APPRISE_URLS=msteams://outlook.office.com/webhook/xxxxx
```

### Discord

**Setup:**
1. In Discord server settings, create a webhook
2. Copy the webhook URL
3. Format: `discord://webhook_id/webhook_token`

**Example:**
```bash
# From webhook: https://discord.com/api/webhooks/123456/abcdef
# Use: discord://123456/abcdef

APPRISE_URLS=discord://123456/abcdef
```

### Telegram

**Setup:**
1. Create a bot with [@BotFather](https://t.me/botfather)
2. Get your chat ID from [@userinfobot](https://t.me/userinfobot)
3. Format: `tgram://bot_token/chat_id`

**Example:**
```bash
APPRISE_URLS=tgram://123456789:ABCdefGHIjklMNOpqrsTUVwxyz/123456789
```

### Email (SMTP)

**Format:** `mailto://user:password@domain.com`

**Gmail Example:**
```bash
APPRISE_URLS=mailto://myemail@gmail.com:app_password@gmail.com?to=team@company.com
```

**Custom SMTP:**
```bash
APPRISE_URLS=mailto://user:pass@mail.company.com:587?to=team@company.com
```

### Other Popular Services

| Service | Format Example |
|---------|----------------|
| **Google Chat** | `gchat://workspace/key/token` |
| **Pushover** | `pover://user@token` |
| **Pushbullet** | `pbul://access_token` |
| **IFTTT** | `ifttt://webhook_id/event` |
| **Matrix** | `matrix://user:token@host/#room` |
| **Rocket.Chat** | `rocket://user:password@host/room` |
| **Mattermost** | `mmost://host/token` |
| **Zulip** | `zulip://botname@organization/token` |

**Full list:** https://github.com/caronc/apprise/wiki

## 🔗 Multiple Services

Send to multiple services by separating URLs with spaces:

```bash
# Send to both Slack AND Teams
APPRISE_URLS=slack://T00000000/B00000000/XXX msteams://outlook.office.com/webhook/YYY

# Send to Slack, Teams, AND Discord
APPRISE_URLS=slack://T00000000/B00000000/XXX msteams://outlook.office.com/webhook/YYY discord://123456/abcdef
```

## 📋 Notification Content

Notifications include:

- **Title**: Pipeline name (e.g., "Pre-Release Pipeline", "Release Pipeline")
- **Message**: Status summary (e.g., "Build Passed ✅", "Release v1.2.3 Published ✅")
- **Repository**: GitHub repository name
- **Workflow**: Workflow name
- **Run URL**: Direct link to workflow run
- **Triggered by**: GitHub username

### Example Notification

```
✅ Pre-Release Pipeline Passed ✅

Repository: myorg/myproject
Workflow: Pre-Release Pipeline
Run: https://github.com/myorg/myproject/actions/runs/12345
Triggered by: johndoe
```

## 🎨 Customization

### Notification Levels

The script automatically determines notification type:

- ✅ **Success**: Green/success color - Pipeline passed
- ❌ **Failure**: Red/error color - Pipeline failed
- ⚠️ **Warning**: Yellow/warning color - Partial success or important action
- ℹ️ **Info**: Blue/info color - General information

### Custom Notifications

You can call the notification script directly in your own workflows:

```yaml
- name: Send custom notification
  env:
    APPRISE_URLS: ${{ secrets.APPRISE_URLS }}
  run: |
    ./scripts/setup/send-notification.sh \
      "Custom Title" \
      "Custom message here" \
      "success"  # success, failure, warning, or info
```

## 🔧 Advanced Configuration

### Environment Variables

| Variable | Purpose | Default |
|----------|---------|---------|
| `APPRISE_URLS` | Space-separated notification URLs | (required) |
| `ENABLE_NOTIFICATIONS` | Enable/disable notifications | `false` |

### Per-Service Configuration

#### Slack - Custom Username and Icon

```bash
slack://T00000000/B00000000/XXX?user=CI+Bot&avatar=🤖
```

#### Email - Multiple Recipients

```bash
mailto://user:pass@smtp.gmail.com?to=dev@company.com,ops@company.com
```

#### Discord - Custom Avatar

```bash
discord://webhook_id/webhook_token?avatar=No&username=CI+Bot
```

### Filtering Notifications

Only notify on failures:

```yaml
- name: Send notification on failure only
  if: failure() && vars.ENABLE_NOTIFICATIONS == 'true'
  env:
    APPRISE_URLS: ${{ secrets.APPRISE_URLS }}
  run: |
    ./scripts/setup/send-notification.sh \
      "Pipeline Failed" \
      "The pipeline has failed!" \
      "failure"
```

## 🧪 Testing Notifications

### Test Locally

```bash
# Install Apprise
pip install apprise

# Set your notification URL
export APPRISE_URLS="slack://your/webhook/url"

# Test notification
./scripts/setup/send-notification.sh \
  "Test Notification" \
  "This is a test message" \
  "info"
```

### Test in GitHub Actions

Create a manual workflow to test:

```yaml
name: Test Notifications

on:
  workflow_dispatch:

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Send test notification
        env:
          APPRISE_URLS: ${{ secrets.APPRISE_URLS }}
        run: |
          chmod +x scripts/setup/send-notification.sh
          ./scripts/setup/send-notification.sh \
            "Test Notification" \
            "Testing notification system ✅" \
            "success"
```

## ❓ Troubleshooting

### Notifications Not Received

1. **Check `ENABLE_NOTIFICATIONS` is set to `true`**
   - Go to Settings > Secrets and variables > Actions > Variables
   - Verify `ENABLE_NOTIFICATIONS=true` exists

2. **Check `APPRISE_URLS` secret is set**
   - Go to Settings > Secrets and variables > Actions > Secrets
   - Verify `APPRISE_URLS` exists and contains valid URLs

3. **Check workflow logs**
   - Go to Actions > Select your workflow run
   - Check the "Send notification" step
   - Look for error messages

### Invalid URL Format

Different services have different URL formats. Check:
- https://github.com/caronc/apprise/wiki

### Permission Issues

Some services require specific permissions:
- **Slack**: Webhook must have `chat:write` scope
- **Discord**: Webhook must have send message permissions
- **Teams**: Connector must be enabled in channel

### Rate Limiting

Some services have rate limits:
- **Slack**: 1 message per second
- **Discord**: 5 messages per 5 seconds
- Consider reducing notification frequency if hitting limits

## 📚 Examples

### Development Team Setup

```bash
# Slack for all notifications
APPRISE_URLS=slack://T00000000/B00000000/XXX/#ci-builds
```

### Multi-Team Setup

```bash
# Slack for devs, Email for managers, Teams for ops
APPRISE_URLS=slack://T00000000/B00000000/XXX/#dev discord://123456/abcdef msteams://outlook.office.com/webhook/YYY
```

### Critical Alerts Only

Modify workflows to only send on failure:

```yaml
if: failure() && vars.ENABLE_NOTIFICATIONS == 'true'
```

## 🔗 Resources

- **Apprise Documentation**: https://github.com/caronc/apprise
- **Supported Services**: https://github.com/caronc/apprise/wiki
- **URL Formatting Guide**: https://github.com/caronc/apprise/wiki#notification-services

## 💡 Best Practices

1. **Use separate channels** for different pipeline types
2. **Test notifications** before enabling for production
3. **Consider notification fatigue** - don't over-notify
4. **Use appropriate severity levels** - success/failure/warning/info
5. **Include context** in messages - repository, workflow, trigger
6. **Secure your webhook URLs** - always use GitHub Secrets
7. **Monitor rate limits** - some services have restrictions
8. **Have a backup** - configure multiple notification services

---

**Need help?** Check the [Apprise Wiki](https://github.com/caronc/apprise/wiki) or create an issue in this repository.
