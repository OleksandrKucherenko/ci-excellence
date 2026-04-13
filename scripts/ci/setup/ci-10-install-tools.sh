#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Install Tools
# Purpose: Install required tools for the project using mise

echo:Setup "Installing Required Tools"
ci:secret setup "GITHUB_TOKEN" "${GITHUB_TOKEN:-}"

# Install mise if not already installed
if ! command -v mise &> /dev/null; then
    echo:Setup "Installing mise..."
    curl https://mise.run | sh

    # Add mise to PATH for this session
    export PATH="$HOME/.local/bin:$PATH"

    # Verify installation
    if command -v mise &> /dev/null; then
        echo:Setup "✓ mise installed: $(mise --version)"
    else
        echo:Setup "❌ mise installation failed"
        exit 1
    fi
else
    echo:Setup "✓ mise already installed: $(mise --version)"
fi

# Ensure mise is in PATH
export PATH="$HOME/.local/bin:$PATH"

# Install all tools from mise.toml
echo:Setup ""
# Useful for Node monorepos but remains tech-agnostic
echo:Setup "Installing tools from mise.toml..."
echo:Setup "This includes: age, sops, gitleaks, trufflehog, lefthook, action-validator, apprise, bun"
echo:Setup ""

# Ensure mise uses GITHUB_TOKEN for GitHub API calls (aqua attestation verification, etc.).
# Unauthenticated requests are limited to 60 req/hr per IP, which is easily exhausted on
# shared GitHub Actions runners. Authenticated requests get 1,000 req/hr per repository.
# ref: https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    export MISE_GITHUB_TOKEN="${GITHUB_TOKEN}"
fi

if mise install; then
    echo:Setup "✓ All tools installed successfully"
else
    echo:Setup "❌ Failed to install some tools"
    exit 1
fi

# Verify critical security tools are installed via mise
echo:Setup ""
echo:Setup "Verifying security tools installation..."

if mise x -- gitleaks version &> /dev/null; then
    echo:Setup "✓ gitleaks: $(mise x -- gitleaks version)"
else
    echo:Setup "❌ gitleaks not found in mise"
    exit 1
fi

if mise x -- trufflehog --version &> /dev/null; then
    echo:Setup "✓ trufflehog: $(mise x -- trufflehog --version 2>&1 | head -1)"
else
    echo:Setup "❌ trufflehog not found in mise"
    exit 1
fi

# Show all installed tools
echo:Setup ""
echo:Setup "All installed tools:"
mise list

echo:Setup ""
echo:Setup "Tool Installation Complete"
