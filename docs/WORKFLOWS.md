# Workflow Documentation

Complete reference for all CI/CD workflows in this project.

## Table of Contents

- [Overview](#overview)
- [Pre-Release Pipeline](#pre-release-pipeline)
- [Release Pipeline](#release-pipeline)
- [Post-Release Pipeline](#post-release-pipeline)
- [Maintenance Pipeline](#maintenance-pipeline)
- [Auto-Fix Quality Pipeline](#auto-fix-quality-pipeline)
- [Workflow Activation](#workflow-activation)

## Overview

This project includes 5 GitHub Actions workflows that handle different stages of the CI/CD lifecycle:

1. **Pre-Release** - Validates code quality before release
2. **Release** - Builds and publishes releases
3. **Post-Release** - Verifies deployments and handles rollbacks
4. **Maintenance** - Performs periodic cleanup and updates
5. **Auto-Fix Quality** - Automatically scans and fixes security issues

All workflows are **variable-driven** - they skip gracefully when not enabled (no failures).

## Pre-Release Pipeline

**File:** [`.github/workflows/pre-release.yml`](../.github/workflows/pre-release.yml)

### Triggers

- Pull requests to `main` or `develop` branches
- Push to `develop`, `feature/*`, `fix/*` branches

### Jobs

1. **Setup** - Install tools and dependencies (always runs)
2. **Compile** - Build the project
3. **Lint** - Run code linters
4. **Unit Tests** - Run unit tests with coverage
5. **Integration Tests** - Run integration tests
6. **E2E Tests** - Run end-to-end tests
7. **Security Scan** - Run vulnerability scans
8. **Bundle** - Create distribution packages
9. **Summary** - Display pipeline results

### Activation Variables

Set these in **Repository Settings > Secrets and variables > Actions > Variables**:

```bash
ENABLE_COMPILE=true
ENABLE_LINT=true
ENABLE_UNIT_TESTS=true
ENABLE_INTEGRATION_TESTS=true
ENABLE_E2E_TESTS=true
ENABLE_SECURITY_SCAN=true
ENABLE_BUNDLE=true
```

### Scripts Used

- Setup: [`scripts/ci/setup/ci-10-install-tools.sh`](../scripts/ci/setup/ci-10-install-tools.sh), [`ci-20-install-dependencies.sh`](../scripts/ci/setup/ci-20-install-dependencies.sh)
- Build: [`scripts/ci/build/ci-10-compile.sh`](../scripts/ci/build/ci-10-compile.sh), [`ci-20-lint.sh`](../scripts/ci/build/ci-20-lint.sh), [`ci-30-security-scan.sh`](../scripts/ci/build/ci-30-security-scan.sh), [`ci-40-bundle.sh`](../scripts/ci/build/ci-40-bundle.sh)
- Test: [`scripts/ci/test/ci-10-unit-tests.sh`](../scripts/ci/test/ci-10-unit-tests.sh), [`ci-20-integration-tests.sh`](../scripts/ci/test/ci-20-integration-tests.sh), [`ci-30-e2e-tests.sh`](../scripts/ci/test/ci-30-e2e-tests.sh)
- Reports: [`scripts/ci/reports/ci-10-summary-pre-release.sh`](../scripts/ci/reports/ci-10-summary-pre-release.sh)

## Release Pipeline

**File:** [`.github/workflows/release.yml`](../.github/workflows/release.yml)

### Triggers

- Manual workflow dispatch with version type selection
- Push to tags matching `v*.*.*`

### Jobs

1. **Prepare** - Determine version, update files, generate changelog
2. **Build** - Build release artifacts
3. **Test** - Test release build
4. **Publish NPM** - Publish to NPM registry
5. **Publish GitHub** - Create GitHub release
6. **Publish Docker** - Build and push Docker images
7. **Publish Documentation** - Build and deploy docs
8. **Notify** - Send release notifications

### Usage

Trigger manually from GitHub Actions tab:

1. Go to **Actions > Release Pipeline**
2. Click **"Run workflow"**
3. Select release type:
   - `major` - Breaking changes (1.0.0 → 2.0.0)
   - `minor` - New features (1.0.0 → 1.1.0)
   - `patch` - Bug fixes (1.0.0 → 1.0.1)
   - `premajor` - Pre-release major (1.0.0 → 2.0.0-0)
   - `preminor` - Pre-release minor (1.0.0 → 1.1.0-0)
   - `prepatch` - Pre-release patch (1.0.0 → 1.0.1-0)
   - `prerelease` - Increment pre-release (1.0.0-0 → 1.0.0-1)
4. Choose if it's a pre-release
5. Optionally enable dry-run mode

### Activation Variables

```bash
ENABLE_NPM_PUBLISH=true
ENABLE_GITHUB_RELEASE=true
ENABLE_DOCKER_PUBLISH=true
ENABLE_DOCUMENTATION=true
```

### Required Secrets

- `NPM_TOKEN` - NPM access token (for NPM publishing)
- `DOCKER_USERNAME` - Docker Hub username (for Docker publishing)
- `DOCKER_PASSWORD` - Docker Hub password/token (for Docker publishing)

### Scripts Used

- Version: [`scripts/ci/release/ci-05-select-version.sh`](../scripts/ci/release/ci-05-select-version.sh), [`ci-10-determine-version.sh`](../scripts/ci/release/ci-10-determine-version.sh), [`ci-15-update-version.sh`](../scripts/ci/release/ci-15-update-version.sh)
- Changelog: [`scripts/ci/release/ci-20-generate-changelog.sh`](../scripts/ci/release/ci-20-generate-changelog.sh), [`ci-25-generate-release-notes.sh`](../scripts/ci/release/ci-25-generate-release-notes.sh)
- GitHub: [`scripts/ci/release/ci-30-upload-assets.sh`](../scripts/ci/release/ci-30-upload-assets.sh), [`ci-35-verify-github-release.sh`](../scripts/ci/release/ci-35-verify-github-release.sh)
- Docs: [`scripts/ci/release/ci-50-build-docs.sh`](../scripts/ci/release/ci-50-build-docs.sh), [`ci-55-publish-docs.sh`](../scripts/ci/release/ci-55-publish-docs.sh)
- NPM: [`scripts/ci/release/ci-65-publish-npm.sh`](../scripts/ci/release/ci-65-publish-npm.sh), [`ci-70-verify-npm-deployment.sh`](../scripts/ci/release/ci-70-verify-npm-deployment.sh)
- Docker: [`scripts/ci/release/ci-80-publish-docker.sh`](../scripts/ci/release/ci-80-publish-docker.sh), [`ci-85-verify-docker-deployment.sh`](../scripts/ci/release/ci-85-verify-docker-deployment.sh)

## Post-Release Pipeline

**File:** [`.github/workflows/post-release.yml`](../.github/workflows/post-release.yml)

### Triggers

- Automatically after GitHub release published
- Manual workflow dispatch for rollback or tagging

### Jobs

1. **Verify Deployment** - Check all deployment targets
2. **Tag Stable** - Mark version as stable
3. **Tag Unstable** - Mark version as unstable
4. **Rollback** - Rollback a failed release

### Usage

**For Rollback:**

1. Go to **Actions > Post-Release Pipeline**
2. Click **"Run workflow"**
3. Select action: `rollback`
4. Enter version to rollback

### Activation Variables

```bash
ENABLE_ROLLBACK=true
ENABLE_DEPLOYMENT_VERIFICATION=true
ENABLE_STABILITY_TAGGING=true
```

### Scripts Used

- Verification: [`scripts/ci/release/ci-35-verify-github-release.sh`](../scripts/ci/release/ci-35-verify-github-release.sh), [`ci-70-verify-npm-deployment.sh`](../scripts/ci/release/ci-70-verify-npm-deployment.sh), [`ci-85-verify-docker-deployment.sh`](../scripts/ci/release/ci-85-verify-docker-deployment.sh)
- Rollback: [`scripts/ci/release/ci-40-rollback-github.sh`](../scripts/ci/release/ci-40-rollback-github.sh), [`ci-75-rollback-npm.sh`](../scripts/ci/release/ci-75-rollback-npm.sh), [`ci-90-rollback-docker.sh`](../scripts/ci/release/ci-90-rollback-docker.sh)
- Reports: [`scripts/ci/reports/ci-80-summary-post-release-verify.sh`](../scripts/ci/reports/ci-80-summary-post-release-verify.sh), [`ci-85-summary-rollback.sh`](../scripts/ci/reports/ci-85-summary-rollback.sh)

## Maintenance Pipeline

**File:** [`.github/workflows/maintenance.yml`](../.github/workflows/maintenance.yml)

### Triggers

- Scheduled: Daily at 2 AM UTC (cron: `0 2 * * *`)
- Manual workflow dispatch

### Jobs

1. **Cleanup** - Remove old workflows, artifacts, caches
2. **Sync Files** - Keep package.json and CHANGELOG.md in sync
3. **Deprecate Old Versions** - Mark old versions as deprecated
4. **Security Audit** - Run security audits
5. **Dependency Update** - Update dependencies automatically

### Activation Variables

```bash
ENABLE_CLEANUP=true
ENABLE_FILE_SYNC=true
ENABLE_DEPRECATION=true
ENABLE_SECURITY_AUDIT=true
ENABLE_DEPENDENCY_UPDATE=true
```

### Scripts Used

- Cleanup: [`scripts/ci/maintenance/ci-30-cleanup-workflow-runs.sh`](../scripts/ci/maintenance/ci-30-cleanup-workflow-runs.sh), [`ci-40-cleanup-artifacts.sh`](../scripts/ci/maintenance/ci-40-cleanup-artifacts.sh), [`ci-50-cleanup-caches.sh`](../scripts/ci/maintenance/ci-50-cleanup-caches.sh)
- Sync: [`scripts/ci/maintenance/ci-10-sync-files.sh`](../scripts/ci/maintenance/ci-10-sync-files.sh), [`ci-20-check-changes.sh`](../scripts/ci/maintenance/ci-20-check-changes.sh)
- Deprecation: [`scripts/ci/maintenance/ci-70-identify-deprecated-versions.sh`](../scripts/ci/maintenance/ci-70-identify-deprecated-versions.sh), [`ci-75-deprecate-npm-versions.sh`](../scripts/ci/maintenance/ci-75-deprecate-npm-versions.sh), [`ci-80-deprecate-github-releases.sh`](../scripts/ci/maintenance/ci-80-deprecate-github-releases.sh)
- Security: [`scripts/ci/maintenance/ci-60-security-audit.sh`](../scripts/ci/maintenance/ci-60-security-audit.sh)
- Updates: [`scripts/ci/maintenance/ci-90-update-dependencies.sh`](../scripts/ci/maintenance/ci-90-update-dependencies.sh)

## Auto-Fix Quality Pipeline

**File:** [`.github/workflows/auto-fix-quality.yml`](../.github/workflows/auto-fix-quality.yml)

### Triggers

- Push to `develop`, `feature/*`, `fix/*`, `claude/*` branches

### Purpose

Automatically scans for and optionally fixes security vulnerabilities and code quality issues during development. This workflow helps catch issues early without blocking development.

### Jobs

1. **Security Scan** - Run gitleaks and trufflehog vulnerability scans
2. **Upload Reports** - Store security reports as artifacts
3. **Upload SARIF** - Integrate with GitHub Security tab

### Features

- Runs security scans on every push to development branches
- Uploads results to GitHub Security tab for easy review
- Continues on error to avoid blocking development
- Retains security reports for 30 days

### Configuration Variables

```bash
AUTO_COMMIT=true              # Enable auto-commit of fixes (default: true)
AUTO_APPLY_FIXES=true         # Auto-apply fixes when found (default: true)
PUSH_CHANGES=false            # Auto-push fixes (default: false, use with caution)
```

### Viewing Security Reports

- **In Actions:** Go to workflow run → Artifacts → `security-reports`
- **In Security Tab:** Navigate to **Security > Code scanning alerts**

### Scripts Used

- Security: [`scripts/ci/build/ci-30-security-scan.sh`](../scripts/ci/build/ci-30-security-scan.sh)

## Workflow Activation

### Quick Start Recommendations

Enable workflows gradually:

**Week 1 - Basic CI:**

```bash
ENABLE_COMPILE=true
ENABLE_LINT=true
ENABLE_UNIT_TESTS=true
```

**Week 2 - Extended Testing:**

```bash
ENABLE_INTEGRATION_TESTS=true
ENABLE_SECURITY_SCAN=true
```

**Week 3 - Releases:**

```bash
ENABLE_GITHUB_RELEASE=true
ENABLE_NOTIFICATIONS=true
```

**Month 2 - Publishing:**

```bash
ENABLE_NPM_PUBLISH=true
ENABLE_DOCKER_PUBLISH=true
ENABLE_DOCUMENTATION=true
```

**Month 3 - Maintenance:**

```bash
ENABLE_CLEANUP=true
ENABLE_FILE_SYNC=true
ENABLE_SECURITY_AUDIT=true
ENABLE_DEPENDENCY_UPDATE=true
```

### Branch Protection Rules

Configure in: **Settings > Branches > Branch protection rules**

Recommended settings:

- ✅ Require status checks before merging
- ✅ Require branches to be up to date
- ✅ Required checks: `setup`, `compile`, `lint`, `unit-tests`
- ✅ Require pull request reviews
- ✅ Dismiss stale reviews
- ✅ Require review from Code Owners

## See Also

- [Architecture Documentation](ARCHITECTURE.md) - System architecture overview
- [Customization Guide](CUSTOMIZATION.md) - How to customize workflows
- [Notifications](NOTIFICATIONS.md) - Setting up pipeline notifications
- [Troubleshooting](TROUBLESHOOTING.md) - Common issues and solutions
