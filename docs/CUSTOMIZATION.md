# Customization Guide

How to customize the CI/CD pipeline for your specific project needs.

## Table of Contents

- [Overview](#overview)
- [Choosing Your Stack](#choosing-your-stack)
- [Version Management](#version-management)
- [Publishing Customization](#publishing-customization)
- [Documentation Setup](#documentation-setup)
- [Notification Customization](#notification-customization)
- [Adding Custom Scripts](#adding-custom-scripts)

## Overview

All scripts in this project are **stubs** with commented examples. You need to customize them for your specific technology stack and requirements.

## Choosing Your Stack

### Node.js/TypeScript Projects

**Install Dependencies** - [`scripts/ci/setup/ci-20-install-dependencies.sh`](../scripts/ci/setup/ci-20-install-dependencies.sh):
```bash
#!/usr/bin/env bash
set -euo pipefail

# Install Node.js dependencies
npm ci
```

**Compile** - [`scripts/ci/build/ci-10-compile.sh`](../scripts/ci/build/ci-10-compile.sh):
```bash
#!/usr/bin/env bash
set -euo pipefail

# Compile TypeScript
npx tsc

# Or use your build script
npm run build
```

**Lint** - [`scripts/ci/build/ci-20-lint.sh`](../scripts/ci/build/ci-20-lint.sh):
```bash
#!/usr/bin/env bash
set -euo pipefail

# Run ESLint
npx eslint . --max-warnings 0

# Or use your lint script
npm run lint
```

**Unit Tests** - [`scripts/ci/test/ci-10-unit-tests.sh`](../scripts/ci/test/ci-10-unit-tests.sh):
```bash
#!/usr/bin/env bash
set -euo pipefail

# Run tests with coverage
npm test -- --coverage --coverageReporters=lcov

# Or use Jest directly
npx jest --coverage --coverageReporters=lcov
```

### Python Projects

**Install Dependencies** - [`scripts/ci/setup/ci-20-install-dependencies.sh`](../scripts/ci/setup/ci-20-install-dependencies.sh):
```bash
#!/usr/bin/env bash
set -euo pipefail

# Install Python dependencies
pip install -r requirements.txt

# Or use poetry
poetry install
```

**Lint** - [`scripts/ci/build/ci-20-lint.sh`](../scripts/ci/build/ci-20-lint.sh):
```bash
#!/usr/bin/env bash
set -euo pipefail

# Run flake8
flake8 .

# Run pylint
pylint **/*.py

# Run black (formatting check)
black --check .

# Or use ruff (modern, fast)
ruff check .
```

**Unit Tests** - [`scripts/ci/test/ci-10-unit-tests.sh`](../scripts/ci/test/ci-10-unit-tests.sh):
```bash
#!/usr/bin/env bash
set -euo pipefail

# Run pytest with coverage
pytest --cov --cov-report=xml --cov-report=term
```

### Go Projects

**Install Dependencies** - [`scripts/ci/setup/ci-20-install-dependencies.sh`](../scripts/ci/setup/ci-20-install-dependencies.sh):
```bash
#!/usr/bin/env bash
set -euo pipefail

# Download Go modules
go mod download
go mod verify
```

**Compile** - [`scripts/ci/build/ci-10-compile.sh`](../scripts/ci/build/ci-10-compile.sh):
```bash
#!/usr/bin/env bash
set -euo pipefail

# Build Go binary
go build -v ./...

# Or build with specific output
go build -o dist/app ./cmd/app
```

**Lint** - [`scripts/ci/build/ci-20-lint.sh`](../scripts/ci/build/ci-20-lint.sh):
```bash
#!/usr/bin/env bash
set -euo pipefail

# Run golangci-lint
golangci-lint run

# Run go vet
go vet ./...

# Run go fmt check
test -z "$(gofmt -l .)"
```

**Unit Tests** - [`scripts/ci/test/ci-10-unit-tests.sh`](../scripts/ci/test/ci-10-unit-tests.sh):
```bash
#!/usr/bin/env bash
set -euo pipefail

# Run tests with race detection and coverage
go test -v -race -coverprofile=coverage.out ./...

# Generate coverage report
go tool cover -html=coverage.out -o coverage.html
```

### Rust Projects

**Install Dependencies** - [`scripts/ci/setup/ci-20-install-dependencies.sh`](../scripts/ci/setup/ci-20-install-dependencies.sh):
```bash
#!/usr/bin/env bash
set -euo pipefail

# Update Cargo index
cargo fetch
```

**Compile** - [`scripts/ci/build/ci-10-compile.sh`](../scripts/ci/build/ci-10-compile.sh):
```bash
#!/usr/bin/env bash
set -euo pipefail

# Build in release mode
cargo build --release
```

**Lint** - [`scripts/ci/build/ci-20-lint.sh`](../scripts/ci/build/ci-20-lint.sh):
```bash
#!/usr/bin/env bash
set -euo pipefail

# Run clippy
cargo clippy -- -D warnings

# Check formatting
cargo fmt -- --check
```

**Unit Tests** - [`scripts/ci/test/ci-10-unit-tests.sh`](../scripts/ci/test/ci-10-unit-tests.sh):
```bash
#!/usr/bin/env bash
set -euo pipefail

# Run tests with coverage (using tarpaulin)
cargo tarpaulin --out Xml --output-dir coverage
```

## Version Management

Edit [`scripts/ci/release/ci-10-determine-version.sh`](../scripts/ci/release/ci-10-determine-version.sh) to read your version file:

### For package.json (Node.js)

```bash
#!/usr/bin/env bash
set -euo pipefail

# Read version from package.json
CURRENT_VERSION=$(jq -r '.version' package.json)

# Determine next version based on input
VERSION_TYPE="${1:-patch}"

# Calculate new version using semver
npm install -g semver
NEW_VERSION=$(semver -i "$VERSION_TYPE" "$CURRENT_VERSION")

echo "Current: $CURRENT_VERSION"
echo "New: $NEW_VERSION"
echo "NEW_VERSION=$NEW_VERSION" >> "$GITHUB_OUTPUT"
```

### For setup.py (Python)

```bash
#!/usr/bin/env bash
set -euo pipefail

# Read version from setup.py
CURRENT_VERSION=$(grep -oP 'version="\K[^"]+' setup.py)

# Or from __init__.py
CURRENT_VERSION=$(grep -oP '__version__ = "\K[^"]+' src/__init__.py)

# Calculate new version
# ... (use python semver package or manual calculation)
```

### For Cargo.toml (Rust)

```bash
#!/usr/bin/env bash
set -euo pipefail

# Read version from Cargo.toml
CURRENT_VERSION=$(grep -oP '^version = "\K[^"]+' Cargo.toml)

# Calculate new version using cargo-bump
cargo install cargo-bump
cargo bump "$VERSION_TYPE" --no-git-tag
NEW_VERSION=$(grep -oP '^version = "\K[^"]+' Cargo.toml)
```

### For Git Tags Only

```bash
#!/usr/bin/env bash
set -euo pipefail

# Get latest tag
CURRENT_VERSION=$(git describe --tags --abbrev=0 | sed 's/^v//')

# If no tags exist, start at 0.1.0
if [ -z "$CURRENT_VERSION" ]; then
    CURRENT_VERSION="0.1.0"
fi

# Calculate new version
# ... (use semver tool)
```

## Publishing Customization

### NPM Publishing

Edit [`scripts/ci/release/ci-65-publish-npm.sh`](../scripts/ci/release/ci-65-publish-npm.sh):

```bash
#!/usr/bin/env bash
set -euo pipefail

# Determine tag based on version
VERSION="${1:-}"
TAG="latest"

if [[ "$VERSION" =~ -alpha ]]; then
    TAG="alpha"
elif [[ "$VERSION" =~ -beta ]]; then
    TAG="beta"
elif [[ "$VERSION" =~ -rc ]]; then
    TAG="rc"
elif [[ "$VERSION" =~ - ]]; then
    TAG="next"
fi

# Publish to NPM
npm publish --tag "$TAG" --access public

echo "✅ Published to NPM with tag: $TAG"
```

**Required Secret:** `NPM_TOKEN`

### Docker Publishing

Edit [`scripts/ci/release/ci-80-publish-docker.sh`](../scripts/ci/release/ci-80-publish-docker.sh):

```bash
#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-latest}"
IMAGE_NAME="your-org/your-app"

# Login to Docker Hub
echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

# Build multi-platform image
docker buildx create --use --name multiarch || true
docker buildx build \
    --platform linux/amd64,linux/arm64 \
    --tag "$IMAGE_NAME:$VERSION" \
    --tag "$IMAGE_NAME:latest" \
    --push \
    .

echo "✅ Published Docker image: $IMAGE_NAME:$VERSION"
```

**Required Secrets:** `DOCKER_USERNAME`, `DOCKER_PASSWORD`

### GitHub Container Registry

```bash
#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-latest}"
IMAGE_NAME="ghcr.io/$GITHUB_REPOSITORY"

# Login to GHCR
echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$GITHUB_ACTOR" --password-stdin

# Build and push
docker build -t "$IMAGE_NAME:$VERSION" -t "$IMAGE_NAME:latest" .
docker push "$IMAGE_NAME:$VERSION"
docker push "$IMAGE_NAME:latest"

echo "✅ Published to GHCR: $IMAGE_NAME:$VERSION"
```

### PyPI Publishing (Python)

```bash
#!/usr/bin/env bash
set -euo pipefail

# Build distribution
python -m build

# Upload to PyPI
python -m twine upload dist/* --username __token__ --password "$PYPI_TOKEN"

echo "✅ Published to PyPI"
```

**Required Secret:** `PYPI_TOKEN`

### Crates.io Publishing (Rust)

```bash
#!/usr/bin/env bash
set -euo pipefail

# Login to crates.io
cargo login "$CARGO_TOKEN"

# Publish
cargo publish

echo "✅ Published to crates.io"
```

**Required Secret:** `CARGO_TOKEN`

## Documentation Setup

### For Sphinx (Python)

Edit [`scripts/ci/release/ci-50-build-docs.sh`](../scripts/ci/release/ci-50-build-docs.sh):

```bash
#!/usr/bin/env bash
set -euo pipefail

cd docs
make html

echo "✅ Documentation built in docs/_build/html"
```

Edit [`scripts/ci/release/ci-55-publish-docs.sh`](../scripts/ci/release/ci-55-publish-docs.sh):

```bash
#!/usr/bin/env bash
set -euo pipefail

# Install gh-pages
npm install -g gh-pages

# Publish to GitHub Pages
gh-pages -d docs/_build/html

echo "✅ Documentation published to GitHub Pages"
```

### For TypeDoc (TypeScript)

```bash
#!/usr/bin/env bash
set -euo pipefail

# Build TypeDoc
npx typedoc --out docs src

# Publish to GitHub Pages
npx gh-pages -d docs

echo "✅ Documentation published"
```

### For MkDocs

```bash
#!/usr/bin/env bash
set -euo pipefail

# Build MkDocs
mkdocs build

# Deploy to GitHub Pages
mkdocs gh-deploy --force

echo "✅ Documentation published"
```

## Notification Customization

See [NOTIFICATIONS.md](NOTIFICATIONS.md) for detailed notification setup.

Quick example for Slack:

```bash
# Set in GitHub Secrets
APPRISE_URLS=slack://T00/B00/XXXXX
```

Multiple services:

```bash
# Slack + Microsoft Teams + Discord
APPRISE_URLS=slack://T00/B00/XXX msteams://webhook teams://webhook discord://123/abc
```

## Adding Custom Scripts

### Script Numbering Convention

Scripts use **spaced intervals** (10, 20, 30...) to allow easy insertion:

- **Existing:** `ci-10-*.sh`, `ci-20-*.sh`, `ci-30-*.sh`
- **Add between:** Use `ci-15-*.sh` (between 10 and 20)
- **Add after:** Use `ci-40-*.sh`, `ci-50-*.sh`, etc.

### Script Template

```bash
#!/usr/bin/env bash
# Purpose: Brief description of what this script does
#
# Usage: ./ci-XX-script-name.sh [args]
#
# Environment variables:
#   - REQUIRED_VAR: Description
#   - OPTIONAL_VAR: Description (default: value)
#
# Exit codes:
#   0 - Success
#   1 - General error
#   2 - Specific error type

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Functions
log_info() {
    echo "ℹ️  $*"
}

log_success() {
    echo "✅ $*"
}

log_error() {
    echo "❌ $*" >&2
}

# Main logic
main() {
    log_info "Starting script..."

    # Your code here

    log_success "Script completed successfully"
}

# Run main function
main "$@"
```

### Adding to Workflows

Edit the relevant workflow file (e.g., [`.github/workflows/pre-release.yml`](../.github/workflows/pre-release.yml)):

```yaml
- name: Run Custom Step
  run: ./scripts/ci/build/ci-25-custom-step.sh
  env:
    CUSTOM_VAR: ${{ vars.CUSTOM_VAR }}
```

## Best Practices

1. **Keep Scripts Focused** - Each script should do one thing well
2. **Use Exit Codes** - Return proper exit codes for success/failure
3. **Log Clearly** - Use emojis and clear messages for visibility
4. **Handle Errors** - Use `set -euo pipefail` for fail-fast behavior
5. **Document** - Add comments explaining complex logic
6. **Test Locally** - Test scripts with mise before pushing
7. **Version Control** - Commit script changes with descriptive messages

## See Also

- [Workflows Documentation](WORKFLOWS.md) - Detailed workflow reference
- [Architecture](ARCHITECTURE.md) - System architecture overview
- [Troubleshooting](TROUBLESHOOTING.md) - Common issues and solutions
