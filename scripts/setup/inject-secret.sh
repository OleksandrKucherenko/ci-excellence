#!/usr/bin/env bash
set -euo pipefail

# Script: Inject Secret into .env.secrets.json
# Purpose: Add or update a secret in the encrypted secrets file
#
# Usage:
#   ./scripts/setup/inject-secret.sh KEY VALUE
#   mise run inject-secret KEY VALUE
#
# Examples:
#   mise run inject-secret TELEGRAM_BOT_TOKEN "123456:ABC..."
#   mise run inject-secret DATABASE_PASSWORD "super-secret"
#

SECRETS_FILE=".env.secrets.json"
SECRETS_EXAMPLE=".env.secrets.json.example"
AGE_KEY_FILE=".secrets/mise-age.txt"
AGE_PUB_FILE=".secrets/mise-age-pub.txt"

# Check if key and value are provided
if [ $# -lt 2 ]; then
    echo "Usage: $0 KEY VALUE"
    echo ""
    echo "Examples:"
    echo "  $0 TELEGRAM_BOT_TOKEN '123456:ABC...'"
    echo "  $0 DATABASE_PASSWORD 'super-secret'"
    echo "  mise run inject-secret API_KEY 'sk-...'"
    exit 1
fi

KEY="$1"
VALUE="$2"

echo "========================================="
echo "Injecting Secret into $SECRETS_FILE"
echo "========================================="
echo "Key: $KEY"
echo "Value: ${VALUE:0:10}..." # Show only first 10 chars
echo ""

# Check if age key exists
if [ ! -f "$AGE_KEY_FILE" ]; then
    echo "⚠️  Age key not found at $AGE_KEY_FILE"
    echo "   Generating new age key pair..."
    ./scripts/setup/generate-age-key.sh
    echo ""
fi

# Check if secrets file exists
if [ ! -f "$SECRETS_FILE" ]; then
    echo "📝 Secrets file not found, creating new empty file..."
    echo "   Starting with empty JSON object: {}"

    # Always start with empty JSON object
    echo '{}' > "$SECRETS_FILE"

    # Encrypt the new file
    echo "   Encrypting with age..."
    sops --encrypt --age "$(cat $AGE_PUB_FILE)" "$SECRETS_FILE" > "${SECRETS_FILE}.tmp"
    mv "${SECRETS_FILE}.tmp" "$SECRETS_FILE"
    echo "✓ Created and encrypted $SECRETS_FILE"
    echo ""
fi

# Decrypt the file to a temporary location
TEMP_FILE=$(mktemp)
trap "rm -f $TEMP_FILE" EXIT

echo "🔓 Decrypting secrets file..."
if ! sops --decrypt "$SECRETS_FILE" > "$TEMP_FILE" 2>/dev/null; then
    echo "❌ Failed to decrypt $SECRETS_FILE"
    echo "   This might be because:"
    echo "   1. The file is not encrypted (trying to read as plain JSON)"
    echo "   2. You don't have the correct age key"
    echo ""
    # Try to read as plain JSON
    if jq empty "$SECRETS_FILE" 2>/dev/null; then
        echo "   File is plain JSON, copying..."
        cp "$SECRETS_FILE" "$TEMP_FILE"
    else
        echo "❌ Cannot read secrets file"
        exit 1
    fi
fi

# Check if the file is valid JSON
if ! jq empty "$TEMP_FILE" 2>/dev/null; then
    echo "❌ Decrypted file is not valid JSON"
    cat "$TEMP_FILE"
    exit 1
fi

# Update or add the key
echo "📝 Updating secret: $KEY"
jq --arg key "$KEY" --arg value "$VALUE" '.[$key] = $value' "$TEMP_FILE" > "${TEMP_FILE}.new"
mv "${TEMP_FILE}.new" "$TEMP_FILE"

# Verify the updated JSON is valid
if ! jq empty "$TEMP_FILE" 2>/dev/null; then
    echo "❌ Updated JSON is invalid"
    exit 1
fi

# Encrypt and save
echo "🔐 Encrypting and saving..."
if ! sops --encrypt --age "$(cat $AGE_PUB_FILE)" "$TEMP_FILE" > "${SECRETS_FILE}.tmp"; then
    echo "❌ Failed to encrypt secrets file"
    rm -f "${SECRETS_FILE}.tmp"
    exit 1
fi

mv "${SECRETS_FILE}.tmp" "$SECRETS_FILE"

echo ""
echo "✅ Secret injected successfully!"
echo ""
echo "Current secrets in file:"
sops --decrypt "$SECRETS_FILE" | jq -r 'keys[]' | sed 's/^/  - /'

echo ""
echo "========================================="
echo "To view all secrets:"
echo "  mise run decrypt-secrets"
echo ""
echo "To edit secrets interactively:"
echo "  mise run edit-secrets"
echo "========================================="
