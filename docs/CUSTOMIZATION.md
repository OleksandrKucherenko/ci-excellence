# Customization Guide

How to customize the CI/CD pipeline for your specific project needs.

## Table of Contents

- [Overview](#overview)
- [Script Implementation Status](#script-implementation-status)
- [Choosing Your Stack](#choosing-your-stack)
- [Version Management](#version-management)
- [Publishing Customization](#publishing-customization)
- [Documentation Setup](#documentation-setup)
- [Notification Customization](#notification-customization)
- [Adding Custom Scripts](#adding-custom-scripts)

## Overview

All scripts in this project are **stubs** with commented examples. You need to customize them for your specific technology stack and requirements. See the [Script Implementation Status](#script-implementation-status) table below to identify which scripts need customization and which work out of the box.

## Script Implementation Status

Of the 69 CI step scripts, **19 are real implementations** that work without modification, **39 are stubs** with commented examples for common tech stacks, and **11 are validation/reporting** scripts that require no customization.

**Legend:** Real = works out of the box | Stub = needs your implementation | Validation = checks/reports only

### Setup (`scripts/ci/setup/`)

| Script | Status | Customization Required |
|--------|--------|----------------------|
| `ci-10-install-tools.sh` | Real | No -- installs mise and verifies tools |
| `ci-20-install-dependencies.sh` | Stub | Yes -- uncomment your package manager (npm, pip, go mod, cargo) |
| `ci-30-github-actions-bot.sh` | Real | No -- configures git bot identity |

### Build (`scripts/ci/build/`)

| Script | Status | Customization Required |
|--------|--------|----------------------|
| `ci-10-compile.sh` | Stub | Yes -- uncomment your build command (tsc, go build, cargo build) |
| `ci-20-lint.sh` | Stub | Yes -- uncomment your linter (eslint, flake8, golangci-lint, clippy) |
| `ci-30-security-scan.sh` | Real | No -- runs gitleaks and trufflehog |
| `ci-40-bundle.sh` | Stub | Yes -- uncomment your packaging (npm pack, docker build, tarball) |
| `ci-60-check-failures.sh` | Validation | No -- checks RESULT_* env vars for failures |

### Test (`scripts/ci/test/`)

| Script | Status | Customization Required |
|--------|--------|----------------------|
| `ci-10-unit-tests.sh` | Stub | Yes -- uncomment your test runner (jest, pytest, go test, cargo test) |
| `ci-20-integration-tests.sh` | Stub | Yes -- uncomment your integration test setup |
| `ci-30-e2e-tests.sh` | Stub | Yes -- uncomment your E2E framework (playwright, cypress) |
| `ci-40-smoke-tests.sh` | Stub | Yes -- uncomment your health check commands |
| `verify-semver.sh` | Real | No -- tests the semver library |

### Release (`scripts/ci/release/`)

| Script | Status | Customization Required |
|--------|--------|----------------------|
| `ci-05-select-version.sh` | Validation | No -- selects version from inputs |
| `ci-07-apply-stability-tag.sh` | Real | No -- creates git stability tags |
| `ci-08-create-tag.sh` | Real | No -- creates and pushes git tags |
| `ci-09-parse-tag.sh` | Real | No -- parses git tag refs |
| `ci-10-determine-version.sh` | Real | No -- calculates next semver |
| `ci-12-set-version-outputs.sh` | Real | No -- orchestrates version outputs |
| `ci-15-update-version.sh` | Stub | Yes -- uncomment your version file update (package.json, setup.py, Cargo.toml) |
| `ci-18-commit-version-changes.sh` | Real | No -- git commit/push version changes |
| `ci-20-generate-changelog.sh` | Stub | Yes -- uncomment your changelog tool (git-cliff, conventional-changelog) |
| `ci-25-generate-release-notes.sh` | Stub | Optional -- generates template; customize for richer notes |
| `ci-27-write-release-notes-output.sh` | Real | No -- writes notes to GITHUB_OUTPUT |
| `ci-30-upload-assets.sh` | Stub | Yes -- uncomment gh release upload commands |
| `ci-35-verify-github-release.sh` | Stub | Yes -- uncomment gh release verification |
| `ci-40-rollback-github.sh` | Stub | Yes -- uncomment GitHub rollback commands |
| `ci-50-build-docs.sh` | Stub | Yes -- uncomment your doc builder (sphinx, typedoc, mkdocs) |
| `ci-55-publish-docs.sh` | Stub | Yes -- uncomment your doc publisher (gh-pages, netlify) |
| `ci-65-publish-npm.sh` | Real | No -- validates token and conditions |
| `ci-66-publish-npm-release.sh` | Real | No -- orchestrates NPM publishing |
| `ci-70-verify-npm-deployment.sh` | Stub | Yes -- uncomment npm verification commands |
| `ci-75-rollback-npm.sh` | Real | No -- validates token and conditions |
| `ci-77-confirm-rollback.sh` | Validation | No -- prints rollback warning |
| `ci-80-publish-docker.sh` | Stub | Yes -- uncomment Docker build/push |
| `ci-85-verify-docker-deployment.sh` | Stub | Yes -- uncomment Docker verification |
| `ci-90-rollback-docker.sh` | Stub | Yes -- uncomment Docker rollback |

### Maintenance (`scripts/ci/maintenance/`)

| Script | Status | Customization Required |
|--------|--------|----------------------|
| `ci-10-sync-files.sh` | Stub | Yes -- uncomment file sync logic |
| `ci-20-check-changes.sh` | Real | No -- runs git diff to detect changes |
| `ci-30-cleanup-workflow-runs.sh` | Stub | Yes -- uncomment gh run delete commands |
| `ci-40-cleanup-artifacts.sh` | Stub | Yes -- uncomment artifact deletion |
| `ci-50-cleanup-caches.sh` | Stub | Yes -- uncomment cache deletion |
| `ci-60-security-audit.sh` | Stub | Yes -- uncomment your audit tool (npm audit, pip-audit, cargo audit) |
| `ci-70-identify-deprecated-versions.sh` | Stub | Yes -- uncomment version identification |
| `ci-75-deprecate-npm-versions.sh` | Real | No -- validates NPM token |
| `ci-80-deprecate-github-releases.sh` | Stub | Yes -- uncomment GitHub deprecation |
| `ci-90-update-dependencies.sh` | Stub | Yes -- uncomment dependency update commands |
| `ci-91-test-after-update.sh` | Real | No -- runs unit tests after updates |

### Notification (`scripts/ci/notification/`)

| Script | Status | Customization Required |
|--------|--------|----------------------|
| `ci-10-check-notifications-enabled.sh` | Real | No -- validates Apprise/Telegram config |
| `ci-20-determine-status.sh` | Real | No -- determines pipeline status |
| `ci-30-send-notification.sh` | Real | No -- sends via Apprise |
| `ci-40-maintenance-status.sh` | Real | No -- maintenance status logic |
| `ci-50-post-release-status.sh` | Real | No -- post-release status logic |
| `ci-60-release-status.sh` | Real | No -- release status logic |

### Ops (`scripts/ci/ops/`)

| Script | Status | Customization Required |
|--------|--------|----------------------|
| `ci-10-validate-inputs.sh` | Validation | No -- checks VERSION is set |
| `ci-20-promote-release.sh` | Stub | Yes -- implement promotion logic |
| `ci-30-deploy.sh` | Stub | Yes -- implement deployment commands |
| `ci-40-mark-stability.sh` | Real | No -- calls stability tag script |

### Reports (`scripts/ci/reports/`)

| Script | Status | Customization Required |
|--------|--------|----------------------|
| `ci-10-summary-pre-release.sh` | Real | No -- generates pre-release summary |
| `ci-20-summary-sync.sh` | Real | No -- generates sync summary |
| `ci-30-summary-cleanup.sh` | Validation | No -- static cleanup summary |
| `ci-40-summary-deprecations.sh` | Validation | No -- static deprecation summary |
| `ci-50-summary-security-audit.sh` | Validation | No -- static audit summary |
| `ci-60-summary-dependency-update.sh` | Real | No -- conditional update summary |
| `ci-70-summary-maintenance.sh` | Real | No -- maintenance summary table |
| `ci-80-summary-post-release-verify.sh` | Real | No -- verification summary |
| `ci-85-summary-rollback.sh` | Real | No -- rollback summary |
| `ci-90-summary-post-release.sh` | Real | No -- post-release actions table |
| `ci-95-summary-release.sh` | Real | No -- release summary with ops links |

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
