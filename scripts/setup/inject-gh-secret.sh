#!/usr/bin/env bash
set -euo pipefail

# Script: Inject Secret into GitHub Actions
# Purpose: Add or update secrets in GitHub repository for use in CI/CD
#
# Usage:
#   ./scripts/setup/inject-gh-secret.sh KEY [VALUE]
#   mise run inject-gh-secret KEY [VALUE]
#
# Examples:
#   # Inject from .env.secrets.json (decrypts automatically)
#   mise run inject-gh-secret TELEGRAM_BOT_TOKEN
#
#   # Inject with explicit value
#   mise run inject-gh-secret TELEGRAM_BOT_TOKEN "123456:ABC..."
#
#   # Inject all secrets from .env.secrets.json
#   mise run inject-gh-secret --all
#

SECRETS_FILE=".env.secrets.json"

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed"
    echo ""
    echo "Install it with:"
    echo "  # macOS"
    echo "  brew install gh"
    echo ""
    echo "  # Linux"
    echo "  sudo apt install gh"
    echo ""
    echo "  # Or download from: https://cli.github.com/"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ Not authenticated with GitHub CLI"
    echo ""
    echo "Please authenticate first:"
    echo "  gh auth login"
    exit 1
fi

# Show usage
show_usage() {
    cat <<EOF
Usage: $0 KEY [VALUE]
       $0 --all

Inject secrets into GitHub Actions repository secrets.

Options:
  KEY                 Secret key name (required unless --all)
  VALUE               Secret value (optional - reads from .env.secrets.json if not provided)
  --all               Inject all secrets from .env.secrets.json
  --env NAME          Set secret for specific environment instead of repository
  --help              Show this help

Examples:
  # Inject from .env.secrets.json
  $0 TELEGRAM_BOT_TOKEN

  # Inject with explicit value
  $0 TELEGRAM_BOT_TOKEN "123456:ABC..."

  # Inject all secrets from .env.secrets.json
  $0 --all

  # Inject to specific environment
  $0 --env production TELEGRAM_BOT_TOKEN

Environment secrets require the environment to already exist in GitHub.
EOF
}

# Parse arguments
INJECT_ALL=false
ENVIRONMENT=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            show_usage
            exit 0
            ;;
        --all)
            INJECT_ALL=true
            shift
            ;;
        --env)
            ENVIRONMENT="$2"
            shift 2
            ;;
        *)
            break
            ;;
    esac
done

# Get repository info
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")
if [ -z "$REPO" ]; then
    echo "❌ Not in a git repository or repository not found on GitHub"
    exit 1
fi

echo "========================================="
echo "Injecting GitHub Actions Secrets"
echo "========================================="
echo "Repository: $REPO"
if [ -n "$ENVIRONMENT" ]; then
    echo "Environment: $ENVIRONMENT"
fi
echo ""

# Function to inject a single secret
inject_secret() {
    local key="$1"
    local value="$2"

    echo "📝 Injecting secret: $key"

    if [ -n "$ENVIRONMENT" ]; then
        # Inject to environment
        if echo "$value" | gh secret set "$key" --env "$ENVIRONMENT" 2>&1; then
            echo "✓ Secret '$key' set for environment '$ENVIRONMENT'"
        else
            echo "❌ Failed to set secret '$key' for environment '$ENVIRONMENT'"
            return 1
        fi
    else
        # Inject to repository
        if echo "$value" | gh secret set "$key" 2>&1; then
            echo "✓ Secret '$key' set for repository"
        else
            echo "❌ Failed to set secret '$key'"
            return 1
        fi
    fi
}

# Handle --all flag
if [ "$INJECT_ALL" = true ]; then
    if [ ! -f "$SECRETS_FILE" ]; then
        echo "❌ Secrets file not found: $SECRETS_FILE"
        exit 1
    fi

    echo "🔓 Decrypting $SECRETS_FILE..."

    # Get all keys from the encrypted file
    KEYS=$(sops --decrypt "$SECRETS_FILE" | jq -r 'keys[]' | grep -v '^_' || true)

    if [ -z "$KEYS" ]; then
        echo "❌ No secrets found in $SECRETS_FILE"
        exit 1
    fi

    echo "Found secrets to inject:"
    echo "$KEYS" | sed 's/^/  - /'
    echo ""

    read -p "Inject all these secrets to GitHub? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        echo "Aborted."
        exit 0
    fi

    echo ""

    # Inject each secret
    SUCCESS_COUNT=0
    FAIL_COUNT=0

    while IFS= read -r key; do
        value=$(sops --decrypt "$SECRETS_FILE" | jq -r --arg key "$key" '.[$key]')

        if inject_secret "$key" "$value"; then
            ((SUCCESS_COUNT++))
        else
            ((FAIL_COUNT++))
        fi
        echo ""
    done <<< "$KEYS"

    echo "========================================="
    echo "Injection complete"
    echo "  ✓ Success: $SUCCESS_COUNT"
    if [ $FAIL_COUNT -gt 0 ]; then
        echo "  ❌ Failed: $FAIL_COUNT"
    fi
    echo "========================================="

    exit 0
fi

# Handle single secret injection
if [ $# -lt 1 ]; then
    echo "❌ Missing required argument: KEY"
    echo ""
    show_usage
    exit 1
fi

KEY="$1"
VALUE="${2:-}"

# If no value provided, try to get it from .env.secrets.json
if [ -z "$VALUE" ]; then
    if [ ! -f "$SECRETS_FILE" ]; then
        echo "❌ No value provided and secrets file not found: $SECRETS_FILE"
        echo ""
        echo "Usage: $0 KEY VALUE"
        exit 1
    fi

    echo "🔓 Reading secret from $SECRETS_FILE..."

    # Get the value from encrypted file
    VALUE=$(sops --decrypt "$SECRETS_FILE" | jq -r --arg key "$KEY" '.[$key]' 2>/dev/null || echo "null")

    if [ "$VALUE" = "null" ] || [ -z "$VALUE" ]; then
        echo "❌ Secret '$KEY' not found in $SECRETS_FILE"
        echo ""
        echo "Available secrets:"
        sops --decrypt "$SECRETS_FILE" | jq -r 'keys[]' | grep -v '^_' | sed 's/^/  - /'
        exit 1
    fi

    echo "✓ Found secret in $SECRETS_FILE"
    echo ""
fi

# Inject the secret
inject_secret "$KEY" "$VALUE"

echo ""
echo "========================================="
echo "✅ Secret injected successfully"
echo "========================================="
echo ""
echo "The secret is now available in GitHub Actions workflows as:"
echo "  \${{ secrets.$KEY }}"
echo ""
