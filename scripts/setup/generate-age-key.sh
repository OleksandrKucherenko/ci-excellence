#!/usr/bin/env bash
set -euo pipefail

# Mise Setup: Generate age encryption key
# Purpose: Generate a new age key pair for encrypting secrets with SOPS

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

echo "========================================="
echo "Generating age encryption key"
echo "========================================="

# Check if age is installed
if ! command -v age-keygen &> /dev/null; then
    echo "⚠️  age-keygen not found"
    echo "Installing age via mise..."
    mise install age
fi

# Create secrets directory if it doesn't exist
mkdir -p .secrets
chmod 700 .secrets

# Check if key already exists
if [ -f ".secrets/mise-age.txt" ]; then
    echo ""
    echo "⚠️  An age key already exists at .secrets/mise-age.txt"
    echo ""
    read -p "Do you want to overwrite it? (yes/no): " -r
    echo
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        echo "Aborted. Keeping existing key."
        exit 0
    fi
    echo "Backing up existing key to .secrets/mise-age.txt.backup"
    cp .secrets/mise-age.txt .secrets/mise-age.txt.backup
fi

# Generate new key
echo "Generating new age key pair..."
age-keygen -o .secrets/mise-age.txt

# Set proper permissions
chmod 600 .secrets/mise-age.txt

# Extract public key
PUBLIC_KEY=$(grep "public key:" .secrets/mise-age.txt | awk '{print $NF}')
echo "$PUBLIC_KEY" > .secrets/mise-age-pub.txt
chmod 644 .secrets/mise-age-pub.txt

echo ""
echo "✓ Age key pair generated successfully!"
echo ""
echo "Private key: .secrets/mise-age.txt (keep this SECRET!)"
echo "Public key:  .secrets/mise-age-pub.txt (safe to share)"
echo ""
echo "Public key: $PUBLIC_KEY"
echo ""
echo "========================================="
echo "Next steps:"
echo "========================================="
echo ""
echo "1. Add private key to your password manager or secure storage"
echo ""
echo "2. Share public key with team members (optional)"
echo ""
echo "3. Encrypt your secrets file:"
echo "   mise run encrypt-secrets"
echo ""
echo "4. Add encrypted secrets to git:"
echo "   git add .env.secrets.json"
echo ""
echo "========================================="
