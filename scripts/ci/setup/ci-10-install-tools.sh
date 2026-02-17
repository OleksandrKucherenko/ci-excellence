#!/usr/bin/env bash
set -euo pipefail

# CI Script: Install Tools
# Purpose: Install required tools for the project using mise

echo "========================================="
echo "Installing Required Tools"
echo "========================================="

# Install mise if not already installed
if ! command -v mise &> /dev/null; then
    echo "Installing mise..."
    curl https://mise.run | sh

    # Add mise to PATH for this session
    export PATH="$HOME/.local/bin:$PATH"

    # Verify installation
    if command -v mise &> /dev/null; then
        echo "✓ mise installed: $(mise --version)"
    else
        echo "❌ mise installation failed"
        exit 1
    fi
else
    echo "✓ mise already installed: $(mise --version)"
fi

# Ensure mise is in PATH
export PATH="$HOME/.local/bin:$PATH"

# Install all tools from mise.toml
echo ""
# Useful for Node monorepos but remains tech-agnostic
echo "Installing tools from mise.toml..."
echo "This includes: age, sops, gitleaks, trufflehog, lefthook, action-validator, apprise, bun"
echo ""

# Ensure mise uses GITHUB_TOKEN for GitHub API calls (aqua attestation verification, etc.).
# Unauthenticated requests are limited to 60 req/hr per IP, which is easily exhausted on
# shared GitHub Actions runners. Authenticated requests get 1,000 req/hr per repository.
# ref: https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    export MISE_GITHUB_TOKEN="${GITHUB_TOKEN}"
fi

if mise install; then
    echo "✓ All tools installed successfully"
else
    echo "❌ Failed to install some tools"
    exit 1
fi

# Verify critical security tools are installed via mise
echo ""
echo "Verifying security tools installation..."

if mise x -- gitleaks version &> /dev/null; then
    echo "✓ gitleaks: $(mise x -- gitleaks version)"
else
    echo "❌ gitleaks not found in mise"
    exit 1
fi

if mise x -- trufflehog --version &> /dev/null; then
    echo "✓ trufflehog: $(mise x -- trufflehog --version 2>&1 | head -1)"
else
    echo "❌ trufflehog not found in mise"
    exit 1
fi

# Show all installed tools
echo ""
echo "All installed tools:"
mise list

echo ""
echo "========================================="
echo "Tool Installation Complete"
echo "========================================="
