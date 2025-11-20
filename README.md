# CI Excellence - Comprehensive CI/CD Pipeline Stubs

A production-ready, customizable CI/CD pipeline setup with stub implementations for long-term project excellence. This setup follows the philosophy of "reserve space, eliminate routine" - providing a complete pipeline framework that activates features through simple variable toggles.

## 🎯 Philosophy

- **Stub-based approach**: All scripts are stubs with commented examples, ready to be customized
- **Variable-driven activation**: Jobs skip gracefully when not enabled (no failures)
- **Zero routine tasks**: Major setup is done, you only provide specific configuration
- **Production-ready**: Based on real-world CI/CD best practices
- **Modular design**: Enable only what you need, when you need it

## 📋 Table of Contents

- [Quick Start](#quick-start)
- [Local Development Setup (Mise)](#local-development-setup-mise)
- [Architecture](#architecture)
- [Workflows](#workflows)
- [Configuration](#configuration)
- [Customization Guide](#customization-guide)
- [Notifications](#notifications)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## 🚀 Quick Start

### 1. Clone or Copy This Setup

```bash
# Copy the entire .github/workflows, scripts, and config directories to your project
cp -r .github scripts config /path/to/your/project/
```

### 2. Configure GitHub Variables

Go to your repository settings: **Settings > Secrets and variables > Actions**

Create these **Variables** (start with minimal setup):

```
ENABLE_COMPILE=true
ENABLE_LINT=true
ENABLE_UNIT_TESTS=true
ENABLE_GITHUB_RELEASE=true
```

### 3. Add Secrets (as needed)

Create these **Secrets**:

```
NPM_TOKEN=your_npm_token_here          # If publishing to NPM
DOCKER_USERNAME=your_username          # If publishing Docker images
DOCKER_PASSWORD=your_password          # If publishing Docker images
```

### 4. Customize Scripts

Edit the script stubs in `scripts/` to match your project:

```bash
# Example: Customize the build script
vim scripts/build/compile.sh

# Uncomment and modify the relevant sections for your stack
# e.g., for TypeScript project:
# npx tsc
```

### 5. Push and Watch It Work!

```bash
git add .
git commit -m "chore: add CI/CD pipeline"
git push
```

## 💻 Local Development Setup (Mise)

For local development, we provide [Mise](https://mise.jit.su) configuration for:
- **Automatic tool installation** (age, sops, gitleaks, trufflehog, lefthook)
- **Secret management** with SOPS and age encryption
- **Environment variables** loaded automatically
- **Pre-configured tasks** for common operations

### Quick Mise Setup

1. **Install mise:**
   ```bash
   curl https://mise.run | sh
   # Or: brew install mise
   ```

2. **Activate in your shell:**
   ```bash
   echo 'eval "$(mise activate bash)"' >> ~/.bashrc
   source ~/.bashrc
   ```

3. **Enter project directory:**
   ```bash
   cd ci-excellence
   ```
   Mise automatically installs tools and sets up directories!

4. **Generate encryption key:**
   ```bash
   mise run generate-age-key
   ```

5. **Create encrypted secrets:**
   ```bash
   cp .env.secrets.json.example .env.secrets.json.tmp
   vim .env.secrets.json.tmp  # Edit with your secrets
   mise run encrypt-secrets
   rm .env.secrets.json.tmp
   ```

### Available Tasks

```bash
mise tasks                    # List all tasks
mise run setup               # Setup project folders
mise run generate-age-key    # Generate encryption key
mise run encrypt-secrets     # Encrypt secrets file
mise run decrypt-secrets     # Decrypt secrets file
mise run edit-secrets        # Edit encrypted secrets
```

### Why Mise?

- ✅ **Consistent environment** across team members
- ✅ **Encrypted secrets** safe to commit to git
- ✅ **Auto-installs tools** (no manual setup)
- ✅ **Secret detection** with gitleaks/trufflehog
- ✅ **Git hooks** managed by lefthook

**Full documentation:** [docs/MISE-SETUP.md](docs/MISE-SETUP.md)

## 🏗️ Architecture

### Workflow Overview

```
┌─────────────────┐
│   Developer     │
└────────┬────────┘
         │
    ┌────▼────┐
    │   Push  │
    └────┬────┘
         │
    ┌────▼──────────────────────────────┐
    │   Pre-Release Pipeline            │
    │  ✓ Setup & Install Dependencies   │
    │  ✓ Compile/Build                  │
    │  ✓ Lint                           │
    │  ✓ Unit Tests                     │
    │  ✓ Integration Tests              │
    │  ✓ E2E Tests                      │
    │  ✓ Security Scan                  │
    │  ✓ Bundle/Package                 │
    └────┬──────────────────────────────┘
         │
    ┌────▼──────────────────────────────┐
    │   Release Pipeline                │
    │  ✓ Determine Version              │
    │  ✓ Update Version Files           │
    │  ✓ Generate Changelog             │
    │  ✓ Build Release Artifacts        │
    │  ✓ Test Release                   │
    │  ✓ Publish to NPM                 │
    │  ✓ Create GitHub Release          │
    │  ✓ Publish Docker Images          │
    │  ✓ Publish Documentation          │
    └────┬──────────────────────────────┘
         │
    ┌────▼──────────────────────────────┐
    │   Post-Release Pipeline           │
    │  ✓ Verify Deployment              │
    │  ✓ Tag Stable/Unstable            │
    │  ✓ Rollback (if needed)           │
    └────┬──────────────────────────────┘
         │
    ┌────▼──────────────────────────────┐
    │   Maintenance Pipeline (Cron)     │
    │  ✓ Cleanup Old Artifacts          │
    │  ✓ Sync Version Files             │
    │  ✓ Deprecate Old Versions         │
    │  ✓ Security Audit                 │
    │  ✓ Dependency Updates             │
    └───────────────────────────────────┘
```

### Directory Structure

```
.
├── .github/
│   └── workflows/
│       ├── pre-release.yml      # PR checks, builds, tests
│       ├── release.yml          # Version, publish, deploy
│       ├── post-release.yml     # Verification, rollback
│       └── maintenance.yml      # Cleanup, sync, security
│
├── scripts/
│   ├── setup/                   # Installation scripts
│   │   ├── install-tools.sh
│   │   └── install-dependencies.sh
│   │
│   ├── build/                   # Build scripts
│   │   ├── compile.sh
│   │   ├── lint.sh
│   │   ├── bundle.sh
│   │   └── security-scan.sh
│   │
│   ├── test/                    # Test scripts
│   │   ├── unit.sh
│   │   ├── integration.sh
│   │   ├── e2e.sh
│   │   └── smoke.sh
│   │
│   ├── release/                 # Release scripts
│   │   ├── determine-version.sh
│   │   ├── update-version.sh
│   │   ├── generate-changelog.sh
│   │   ├── generate-release-notes.sh
│   │   ├── publish-npm.sh
│   │   ├── publish-docker.sh
│   │   ├── build-docs.sh
│   │   ├── publish-docs.sh
│   │   ├── upload-assets.sh
│   │   ├── rollback-npm.sh
│   │   ├── rollback-github.sh
│   │   └── rollback-docker.sh
│   │
│   └── maintenance/             # Maintenance scripts
│       ├── cleanup-workflow-runs.sh
│       ├── cleanup-artifacts.sh
│       ├── cleanup-caches.sh
│       ├── sync-version-files.sh
│       ├── identify-deprecated-versions.sh
│       ├── deprecate-npm-versions.sh
│       ├── deprecate-github-releases.sh
│       ├── security-audit.sh
│       ├── update-dependencies.sh
│       ├── verify-npm-deployment.sh
│       ├── verify-github-release.sh
│       └── verify-docker-deployment.sh
│
└── config/                      # Configuration templates
    ├── package.json.template
    ├── .env.template
    ├── CHANGELOG.md.template
    ├── .gitignore.template
    ├── Dockerfile.template
    └── docker-compose.yml.template
```

## 📝 Workflows

### Pre-Release Pipeline (`pre-release.yml`)

**Triggers:**
- Pull requests to `main` or `develop`
- Pushes to `develop`, `feature/*`, `fix/*` branches

**Jobs:**
1. **Setup** - Install tools and dependencies (always runs)
2. **Compile** - Build the project
3. **Lint** - Run code linters
4. **Unit Tests** - Run unit tests with coverage
5. **Integration Tests** - Run integration tests
6. **E2E Tests** - Run end-to-end tests
7. **Security Scan** - Run vulnerability scans
8. **Bundle** - Create distribution packages
9. **Summary** - Display pipeline results

**Activation:**
```bash
# Enable jobs by setting GitHub Variables
ENABLE_COMPILE=true
ENABLE_LINT=true
ENABLE_UNIT_TESTS=true
ENABLE_INTEGRATION_TESTS=true
ENABLE_E2E_TESTS=true
ENABLE_SECURITY_SCAN=true
ENABLE_BUNDLE=true
```

### Release Pipeline (`release.yml`)

**Triggers:**
- Manual workflow dispatch with version type selection
- Push to tags matching `v*.*.*`

**Jobs:**
1. **Prepare** - Determine version, update files, generate changelog
2. **Build** - Build release artifacts
3. **Test** - Test release build
4. **Publish NPM** - Publish to NPM registry
5. **Publish GitHub** - Create GitHub release
6. **Publish Docker** - Build and push Docker images
7. **Publish Documentation** - Build and deploy docs
8. **Notify** - Send release notifications

**Usage:**
```bash
# Trigger from GitHub Actions tab:
# 1. Go to Actions > Release Pipeline
# 2. Click "Run workflow"
# 3. Select release type: major, minor, patch, etc.
# 4. Choose if it's a pre-release
# 5. Optionally enable dry-run
```

**Activation:**
```bash
ENABLE_NPM_PUBLISH=true
ENABLE_GITHUB_RELEASE=true
ENABLE_DOCKER_PUBLISH=true
ENABLE_DOCUMENTATION=true
```

### Post-Release Pipeline (`post-release.yml`)

**Triggers:**
- Automatically after GitHub release published
- Manual workflow dispatch for rollback or tagging

**Jobs:**
1. **Verify Deployment** - Check all deployment targets
2. **Tag Stable** - Mark version as stable
3. **Tag Unstable** - Mark version as unstable
4. **Rollback** - Rollback a failed release

**Usage:**
```bash
# For rollback:
# 1. Go to Actions > Post-Release Pipeline
# 2. Click "Run workflow"
# 3. Select action: rollback
# 4. Enter version to rollback
```

### Maintenance Pipeline (`maintenance.yml`)

**Triggers:**
- Scheduled: Daily at 2 AM UTC (cron)
- Manual workflow dispatch

**Jobs:**
1. **Cleanup** - Remove old workflows, artifacts, caches
2. **Sync Files** - Keep package.json and CHANGELOG.md in sync
3. **Deprecate Old Versions** - Mark old versions as deprecated
4. **Security Audit** - Run security audits
5. **Dependency Update** - Update dependencies automatically

**Activation:**
```bash
ENABLE_CLEANUP=true
ENABLE_FILE_SYNC=true
ENABLE_DEPRECATION=true
ENABLE_SECURITY_AUDIT=true
ENABLE_DEPENDENCY_UPDATE=true
```

## ⚙️ Configuration

### GitHub Variables

Set in: **Repository Settings > Secrets and variables > Actions > Variables**

| Variable | Default | Description |
|----------|---------|-------------|
| `ENABLE_COMPILE` | `false` | Enable build/compilation step |
| `ENABLE_LINT` | `false` | Enable linting |
| `ENABLE_UNIT_TESTS` | `false` | Enable unit tests |
| `ENABLE_INTEGRATION_TESTS` | `false` | Enable integration tests |
| `ENABLE_E2E_TESTS` | `false` | Enable end-to-end tests |
| `ENABLE_BUNDLE` | `false` | Enable bundling/packaging |
| `ENABLE_SECURITY_SCAN` | `false` | Enable security scanning |
| `ENABLE_NPM_PUBLISH` | `false` | Enable NPM publishing |
| `ENABLE_GITHUB_RELEASE` | `false` | Enable GitHub releases |
| `ENABLE_DOCKER_PUBLISH` | `false` | Enable Docker publishing |
| `ENABLE_DOCUMENTATION` | `false` | Enable documentation publishing |
| `ENABLE_ROLLBACK` | `false` | Enable rollback capability |
| `ENABLE_DEPLOYMENT_VERIFICATION` | `false` | Enable deployment verification |
| `ENABLE_STABILITY_TAGGING` | `false` | Enable stable/unstable tagging |
| `ENABLE_CLEANUP` | `false` | Enable artifact cleanup |
| `ENABLE_FILE_SYNC` | `false` | Enable version file sync |
| `ENABLE_DEPRECATION` | `false` | Enable version deprecation |
| `ENABLE_SECURITY_AUDIT` | `false` | Enable security audits |
| `ENABLE_DEPENDENCY_UPDATE` | `false` | Enable dependency updates |
| `ENABLE_NOTIFICATIONS` | `false` | Enable pipeline notifications (Slack, Teams, etc.) |

### GitHub Secrets

Set in: **Repository Settings > Secrets and variables > Actions > Secrets**

| Secret | Required For | Description |
|--------|-------------|-------------|
| `NPM_TOKEN` | NPM Publishing | NPM access token |
| `DOCKER_USERNAME` | Docker Publishing | Docker Hub username |
| `DOCKER_PASSWORD` | Docker Publishing | Docker Hub password/token |
| `APPRISE_URLS` | Notifications | Space-separated notification URLs (see [NOTIFICATIONS.md](docs/NOTIFICATIONS.md)) |
| `GITHUB_TOKEN` | All workflows | Auto-provided by GitHub |

## 🔧 Customization Guide

### Step 1: Choose Your Stack

Edit the relevant stub scripts based on your technology stack:

#### For Node.js/TypeScript Projects

```bash
# scripts/setup/install-dependencies.sh
npm ci

# scripts/build/compile.sh
npx tsc

# scripts/build/lint.sh
npx eslint .

# scripts/test/unit.sh
npm test -- --coverage
```

#### For Python Projects

```bash
# scripts/setup/install-dependencies.sh
pip install -r requirements.txt

# scripts/build/lint.sh
flake8 .
pylint **/*.py

# scripts/test/unit.sh
pytest --cov --cov-report=xml
```

#### For Go Projects

```bash
# scripts/setup/install-dependencies.sh
go mod download

# scripts/build/compile.sh
go build -v ./...

# scripts/test/unit.sh
go test -v -race -coverprofile=coverage.out ./...
```

### Step 2: Configure Version Management

Edit `scripts/release/determine-version.sh` to read your version file:

```bash
# For package.json
CURRENT_VERSION=$(jq -r '.version' package.json)

# For setup.py
CURRENT_VERSION=$(grep -oP 'version="\K[^"]+' setup.py)

# For Cargo.toml
CURRENT_VERSION=$(grep -oP '^version = "\K[^"]+' Cargo.toml)

# For git tags
CURRENT_VERSION=$(git describe --tags --abbrev=0 | sed 's/^v//')
```

### Step 3: Customize Publishing

#### NPM Publishing

Edit `scripts/release/publish-npm.sh`:

```bash
# Uncomment and customize
npm publish $TAG
```

Add `NPM_TOKEN` secret to repository.

#### Docker Publishing

Edit `scripts/release/publish-docker.sh`:

```bash
IMAGE_NAME="your-org/your-app"
docker build -t "$IMAGE_NAME:$VERSION" .
docker push "$IMAGE_NAME:$VERSION"
```

Add `DOCKER_USERNAME` and `DOCKER_PASSWORD` secrets.

### Step 4: Set Up Documentation

Edit `scripts/release/build-docs.sh` and `publish-docs.sh`:

```bash
# For Sphinx (Python)
cd docs && make html

# For TypeDoc (TypeScript)
npx typedoc

# For MkDocs
mkdocs build

# Publish to GitHub Pages
npx gh-pages -d docs/_build/html
```

## 📬 Notifications

Get real-time pipeline notifications in Slack, Teams, Discord, Telegram, Email, and 90+ other services!

### Quick Setup

1. **Enable notifications** (GitHub Variables):
   ```
   ENABLE_NOTIFICATIONS=true
   ```

2. **Add notification URL** (GitHub Secrets):
   ```
   APPRISE_URLS=slack://your/webhook/url
   ```

3. **Done!** You'll receive notifications for all pipeline events.

### Supported Services

- **Slack** - `slack://token_a/token_b/token_c`
- **Microsoft Teams** - `msteams://webhook_url`
- **Discord** - `discord://webhook_id/webhook_token`
- **Telegram** - `tgram://bot_token/chat_id`
- **Email** - `mailto://user:pass@domain.com`
- **90+ more services** - See [NOTIFICATIONS.md](docs/NOTIFICATIONS.md)

### Multiple Services

Send to multiple services by separating URLs with spaces:

```bash
APPRISE_URLS=slack://T00/B00/XXX msteams://webhook/url discord://123/abc
```

### What Gets Notified

- ✅ **Pre-Release**: Build/test pass/fail status
- 🚀 **Release**: New version published
- 🔄 **Post-Release**: Deployment verification, rollbacks
- 🔧 **Maintenance**: Security audits, dependency updates

**Full documentation**: [NOTIFICATIONS.md](docs/NOTIFICATIONS.md)

## 📚 Best Practices

### 1. Start Minimal, Scale Up

```bash
# Week 1: Basic CI
ENABLE_COMPILE=true
ENABLE_LINT=true
ENABLE_UNIT_TESTS=true

# Week 2: Add integration tests
ENABLE_INTEGRATION_TESTS=true

# Week 3: Add releases
ENABLE_GITHUB_RELEASE=true

# Week 4: Add publishing
ENABLE_NPM_PUBLISH=true

# Month 2: Add maintenance
ENABLE_CLEANUP=true
ENABLE_SECURITY_AUDIT=true

# Month 3: Add notifications
ENABLE_NOTIFICATIONS=true
```

### 2. Use Branch Protection Rules

Configure in: **Settings > Branches > Branch protection rules**

Required settings:
- ✅ Require status checks before merging
- ✅ Require branches to be up to date
- ✅ Required checks: `setup`, `compile`, `lint`, `unit-tests`

### 3. Semantic Versioning

Follow [SemVer](https://semver.org/):
- `MAJOR`: Breaking changes
- `MINOR`: New features, backwards compatible
- `PATCH`: Bug fixes

### 4. Conventional Commits

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add new feature
fix: resolve bug
docs: update documentation
chore: update dependencies
refactor: improve code structure
test: add tests
ci: update CI configuration
```

### 5. Security Best Practices

- ✅ Never commit secrets
- ✅ Use GitHub Secrets for sensitive data
- ✅ Enable security scanning
- ✅ Keep dependencies updated
- ✅ Review automated PRs carefully

## 🐛 Troubleshooting

### Pipeline Not Running

**Check:**
1. Workflows are in `.github/workflows/` directory
2. YAML syntax is valid (use a YAML validator)
3. Branch name matches workflow triggers

### Job Skipped

**This is normal!** Jobs skip when their `ENABLE_*` variable is not `true`.

**To enable:**
1. Go to Settings > Secrets and variables > Actions
2. Add Variable with name `ENABLE_<JOB_NAME>`
3. Set value to `true`

### Script Permission Denied

```bash
# Make scripts executable
chmod +x scripts/**/*.sh
git add scripts/
git commit -m "fix: make scripts executable"
git push
```

### NPM Publishing Fails

**Check:**
1. `NPM_TOKEN` secret is set
2. Token has publish permissions
3. Package name is available
4. You're not republishing same version

### Docker Build Fails

**Check:**
1. Dockerfile exists
2. `DOCKER_USERNAME` and `DOCKER_PASSWORD` secrets are set
3. Image name follows format: `org/name`

## 🎓 Learning Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Semantic Versioning](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [CI/CD Best Practices](https://docs.github.com/en/actions/guides)

## 📄 License

This CI/CD setup is provided as-is under the MIT License. Feel free to customize and use in your projects.

## 🤝 Contributing

Found a bug or have a suggestion? Please:
1. Check existing issues
2. Create a detailed issue
3. Submit a pull request

## 📞 Support

- Documentation: This README
- Examples: See `config/` directory for templates
- Scripts: All scripts have inline comments explaining their purpose

---

**Happy Building! 🚀**

Remember: Start simple, enable features as needed, and customize scripts for your specific use case.
