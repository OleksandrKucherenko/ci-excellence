#!/usr/bin/env bash
set -euo pipefail

# Mise Setup: Pre-configure project folders
# Purpose: Create necessary directories for local development
# Called automatically when entering the project directory

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

echo "========================================="
echo "Setting up project folders"
echo "========================================="

# Create secrets directory if it doesn't exist
if [ ! -d ".secrets" ]; then
    echo "Creating .secrets directory..."
    mkdir -p .secrets
    chmod 700 .secrets
    echo "✓ Created .secrets directory (mode: 700)"
fi

# Create codex home directory if it doesn't exist
if [ ! -d ".codex" ]; then
    echo "Creating .codex directory..."
    mkdir -p .codex
    echo "✓ Created .codex directory"
fi

# Create dist/build directories if they don't exist
if [ ! -d "dist" ]; then
    echo "Creating dist directory..."
    mkdir -p dist
    echo "✓ Created dist directory"
fi

# Check if age key exists
if [ ! -f ".secrets/mise-age.txt" ]; then
    echo ""
    echo "⚠️  No age encryption key found!"
    echo ""
    echo "To set up secrets management:"
    echo "  1. Generate a new age key:"
    echo "     mise run generate-age-key"
    echo ""
    echo "  2. Or if you have an existing key, place it at:"
    echo "     .secrets/mise-age.txt"
    echo ""
    echo "  3. Then encrypt your secrets:"
    echo "     mise run encrypt-secrets"
    echo ""
fi

# Check if .env file exists, if not create from template
if [ ! -f ".env" ]; then
    if [ -f "config/.env.template" ]; then
        echo "Creating .env from template..."
        cp config/.env.template .env
        echo "✓ Created .env from template"
        echo "  Please review and update .env with your settings"
    fi
fi

# Check if .env.secrets.json exists
if [ ! -f ".env.secrets.json" ]; then
    if [ -f ".env.secrets.json.example" ]; then
        echo ""
        echo "⚠️  No encrypted secrets file found!"
        echo ""
        echo "To create encrypted secrets:"
        echo "  1. Copy the example file:"
        echo "     cp .env.secrets.json.example .env.secrets.json.tmp"
        echo ""
        echo "  2. Edit with your actual secrets:"
        echo "     vim .env.secrets.json.tmp"
        echo ""
        echo "  3. Encrypt it:"
        echo "     sops --encrypt --age \$(cat .secrets/mise-age-pub.txt) .env.secrets.json.tmp > .env.secrets.json"
        echo ""
        echo "  4. Remove the temporary file:"
        echo "     rm .env.secrets.json.tmp"
        echo ""
    fi
fi

echo "========================================="
echo "Project folders setup complete"
echo "========================================="
