# Testing Guide for CI/CD Pipelines with ACT

This guide provides comprehensive instructions for testing all GitHub Actions workflows locally using the ACT (GitHub Actions CLI) tool.

## Table of Contents

- [Prerequisites](#prerequisites)
- [ACT Installation and Setup](#act-installation-and-setup)
- [Quick Start](#quick-start)
- [Pipeline Testing Instructions](#pipeline-testing-instructions)
- [Required Repository States](#required-repository-states)
- [Test Environment Setup](#test-environment-setup)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Tools

Ensure all tools are installed and configured:

```bash
# Install and verify all required tools
mise run verify-tools

# Install ACT (if not managed by MISE)
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
# OR using go
go install github.com/nektos/act@latest
```

### Environment Setup

```bash
# Clone and setup repository
git clone <repository-url>
cd ci-excellence

# Install dependencies and hooks
mise run dev-setup

# Create required directory structure
mise run setup
```

## ACT Installation and Setup

### Basic Setup

```bash
# Verify ACT installation
act version

# List available workflows
act -l

# Pull ACT images (one-time setup)
act --pull
```

### Configuration

Create `.actrc` file for default options:

```bash
# ACT configuration for this project
echo "-P ubuntu-latest=nektos/act-ubuntu:20.04" > .actrc
echo "-P ubuntu-22.04=nektos/act-ubuntu:22.04" >> .actrc
echo "-s GITHUB_TOKEN=${GITHUB_TOKEN:-dummy}" >> .actrc
echo "--secret-file .secrets/act-secrets" >> .actrc
echo "--env-file .secrets/act-env" >> .actrc
```

Create secrets file for testing:

```bash
# Create secrets directory
mkdir -p .secrets

# Create dummy secrets for testing
cat > .secrets/act-secrets << 'EOF'
# GitHub Repository Secrets (dummy values for testing)
GITHUB_TOKEN=dummy_token_for_testing
NPM_TOKEN=dummy_npm_token
DOCKER_USERNAME=docker_user
DOCKER_PASSWORD=docker_pass
TELEGRAM_BOT_TOKEN=dummy_telegram_token
TELEGRAM_CHAT_ID=dummy_chat_id
WEBHOOK_AUTH_TOKEN=dummy_webhook_token
APPRISE_URLS=dummy_apprise_url
EOF

# Create environment file
cat > .secrets/act-env << 'EOF'
# GitHub Repository Variables
ENABLE_COMPILE=true
ENABLE_LINT=true
ENABLE_UNIT_TESTS=true
ENABLE_INTEGRATION_TESTS=true
ENABLE_E2E_TESTS=false
ENABLE_BUNDLE=true
ENABLE_SECURITY_SCAN=true
ENABLE_NOTIFICATIONS=false
ENABLE_ENHANCED_SECURITY=true

# Release Pipeline Variables
ENABLE_NPM_PUBLISH=false
ENABLE_GITHUB_RELEASE=false
ENABLE_DOCKER_PUBLISH=false
ENABLE_DOCUMENTATION=false

# Tag Assignment Variables
TAG_ASSIGNMENT_MODE=DRY_RUN
TAG_WEBHOOK_ENABLED=false

# CI Test Configuration
COMPILE_MODE=DRY_RUN
LINT_MODE=DRY_RUN
UNIT_TESTS_MODE=DRY_RUN
INTEGRATION_TESTS_MODE=DRY_RUN
E2E_TESTS_MODE=DRY_RUN
SECURITY_SCAN_MODE=DRY_RUN

# Quality Gates
QUALITY_THRESHOLD_SCORE=80
CRITICAL_VULNERABILITY_LIMIT=0
HIGH_VULNERABILITY_LIMIT=5
REQUIRE_GDPR_COMPLIANCE=true
REQUIRE_SOC2_COMPLIANCE=false
REQUIRE_HIPAA_COMPLIANCE=false
EOF
```

## Quick Start

```bash
# Test all workflows in dry-run mode
mise run test-local-ci

# Or directly with ACT
act --dryrun

# Run specific workflow
act workflow_dispatch -j <job-name>

# List all available jobs and workflows
act -l
```

## Pipeline Testing Instructions

### 1. Pre-Release Pipeline

**Workflow File**: `.github/workflows/pre-release.yml`

**Triggers**: Pull requests to main/develop, pushes to develop/feature/fix branches

```bash
# Test complete pre-release pipeline
act pull_request

# Test specific jobs
act pull_request -j setup
act pull_request -j compile
act pull_request -j lint
act pull_request -j unit-tests
act pull_request -j integration-tests
act pull_request -j security-scan

# Test with environment variables
act pull_request -s ENABLE_COMPILE=true -s ENABLE_LINT=true
```

### 2. Release Pipeline

**Workflow File**: `.github/workflows/release.yml`

**Triggers**: Manual workflow_dispatch, version tags (v*)

**Required Repository State**:
- Clean working directory
- On main branch or with version tags
- Available release artifacts

```bash
# Test release preparation
act workflow_dispatch \
  -j prepare \
  -s release-type=patch \
  -s dryrun=true

# Test with different release types
act workflow_dispatch -j prepare -s release-type=major -s dryrun=true
act workflow_dispatch -j prepare -s release-type=minor -s dryrun=true
act workflow_dispatch -j prepare -s release-type=prerelease -s dryrun=true -s pre-release=true

# Test build and test jobs
act workflow_dispatch -j build -s dryrun=true
act workflow_dispatch -j test -s dryrun=true

# Test publishing jobs (will not actually publish with dry-run)
act workflow_dispatch -j publish-npm -s dryrun=true -s ENABLE_NPM_PUBLISH=false
act workflow_dispatch -j publish-github -s dryrun=true -s ENABLE_GITHUB_RELEASE=false
act workflow_dispatch -j publish-docker -s dryrun=true -s ENABLE_DOCKER_PUBLISH=false
```

### 3. Tag Assignment Pipeline

**Workflow File**: `.github/workflows/tag-assignment.yml`

**Triggers**: Manual workflow_dispatch

**Required Repository State**:
- Clean working directory
- Full git history available
- Proper git configuration

```bash
# Test version tag creation
act workflow_dispatch \
  -j validate-tag \
  -s tag_type=version \
  -s version=v1.2.3 \
  -s subproject=api

# Test environment tag creation
act workflow_dispatch \
  -j validate-tag \
  -s tag_type=environment \
  -s environment=production \
  -s subproject=frontend

# Test state tag creation
act workflow_dispatch \
  -j validate-tag \
  -s tag_type=state \
  -s version=v1.2.3 \
  -s state=stable

# Test tag creation with force move
act workflow_dispatch \
  -j create-or-move-tag \
  -s tag_type=environment \
  -s environment=staging \
  -s force_move=true

# Test complete tag assignment workflow
act workflow_dispatch \
  -s tag_type=version \
  -s version=v1.2.3 \
  -s commit_sha=abcdef123456
```

### 4. Deployment Pipeline

**Workflow File**: `.github/workflows/deployment.yml`

**Triggers**: Manual workflow_dispatch

**Required Repository State**:
- Environment tags present
- Environment configuration files exist
- Proper deployment setup

```bash
# Test staging deployment
act workflow_dispatch \
  -s environment=staging \
  -s subproject=api

# Test production deployment
act workflow_dispatch \
  -s environment=production \
  -s subproject=frontend

# Test with specific regions
act workflow_dispatch \
  -s environment=production \
  -s subproject=api \
  -s region=us-east
```

### 5. Rollback Pipeline

**Workflow File**: `.github/workflows/rollback.yml`

**Triggers**: Manual workflow_dispatch

**Required Repository State**:
- Previous deployment tags exist
- Environment is currently deployed

```bash
# Test rollback to previous version
act workflow_dispatch \
  -s environment=production \
  -s subproject=api \
  -s target_version=v1.1.0

# Test emergency rollback
act workflow_dispatch \
  -s environment=production \
  -s subproject=api \
  -s emergency=true
```

### 6. Maintenance Pipeline

**Workflow File**: `.github/workflows/maintenance.yml`

**Triggers**: Manual workflow_dispatch, cron schedule

**Required Repository State**:
- Repository with some artifacts
- Active deployments

```bash
# Test artifact cleanup
act workflow_dispatch \
  -j cleanup \
  -s cleanup_artifacts=true \
  -s retention_days=7

# Test security audit
act workflow_dispatch \
  -j security-audit \
  -s audit_scope=full

# Test dependency updates
act workflow_dispatch \
  -j dependency-update \
  -s update_type=patch

# Test version deprecation
act workflow_dispatch \
  -j deprecate-versions \
  -s deprecated_versions=v1.0.0,v1.1.0
```

### 7. Self-Healing Pipeline

**Workflow File**: `.github/workflows/self-healing.yml`

**Triggers**: Manual workflow_dispatch

**Required Repository State**:
- Repository with formatting/linting issues
- Uncommitted changes

```bash
# Test auto-format
act workflow_dispatch \
  -j auto-format \
  -s scope=all

# Test auto-lint-fix
act workflow_dispatch \
  -j auto-lint-fix \
  -s scope=scripts

# Test commit fixes (will create commits)
act workflow_dispatch \
  -j commit-fixes \
  -s auto_commit=true
```

### 8. Post-Release Pipeline

**Workflow File**: `.github/workflows/post-release.yml`

**Triggers**: Manual workflow_dispatch

**Required Repository State**:
- Recent release completed
- Release artifacts available

```bash
# Test deployment verification
act workflow_dispatch \
  -j verify-deployment \
  -s environment=production

# Test smoke tests
act workflow_dispatch \
  -j smoke-tests \
  -s environment=staging

# Test performance monitoring
act workflow_dispatch \
  -j performance-monitor \
  -s duration=30m
```

### 9. Gemini Integration Workflows

**Workflow Files**:
- `.github/workflows/gemini-dispatch.yml`
- `.github/workflows/gemini-invoke.yml`
- `.github/workflows/gemini-review.yml`
- `.github/workflows/gemini-triage.yml`
- `.github/workflows/gemini-scheduled-triage.yml`

**Required Repository State**:
- GitHub Issues available
- Gemini API credentials configured
- Repository with content to analyze

```bash
# Test Gemini dispatch
act workflow_dispatch \
  -s repository=ci-excellence \
  -s issue_number=123

# Test Gemini invoke
act workflow_dispatch \
  -s prompt="Review this code change" \
  -s context="security review"

# Test Gemini review
act workflow_dispatch -j review \
  -s review_scope=security \
  -s target_branch=main

# Test Gemini triage
act workflow_dispatch -j triage \
  -s scope=unassigned \
  -s limit=10

# Test scheduled triage
act schedule -j scheduled-triage
```

## Required Repository States

### 1. Pre-Release Pipeline Testing

**Required State**: Development branch with changes

```bash
# Create a feature branch for testing
git checkout -b test/pre-release-pipeline
echo "test change" >> README.md
git add README.md
git commit -m "test: add content for pre-release testing"

# Create and push a PR
git push origin test/pre-release-pipeline
# Create PR through GitHub UI or CLI
gh pr create --title "Test Pre-Release Pipeline" --body "Testing pipeline functionality"
```

### 2. Release Pipeline Testing

**Required State**: Main branch with release-ready code

```bash
# Ensure main is up to date
git checkout main
git pull origin main

# Create a version tag for testing
git tag v1.0.0-test
git push origin v1.0.0-test

# Or test with workflow_dispatch without tags
git checkout main
# Ensure clean working directory
git status
```

### 3. Tag Assignment Testing

**Required State**: Repository with commit history and existing tags

```bash
# Create test commits for tagging
echo "Version 1.0.0 content" > version.txt
git add version.txt
git commit -m "feat: version 1.0.0"
git tag v1.0.0

# Create another commit for environment tagging
echo "Production ready code" >> version.txt
git add version.txt
git commit -m "feat: production ready"
git tag -a v1.1.0 -m "Version 1.1.0"

# Push tags
git push origin --tags

# Test tag assignment workflow
git checkout main
```

### 4. Environment Configuration Testing

**Required State**: Environment folders with configuration

```bash
# Create test environment structure
mkdir -p environments/{staging,production,global}/{regions,config}

# Create test configs
cat > environments/global/config.yml << 'EOF'
global_setting: "global_value"
timezone: "UTC"
logging:
  level: "info"
  retention_days: 30
EOF

cat > environments/staging/config.yml << 'EOF'
extends: "global"
environment: "staging"
database:
  host: "staging-db.example.com"
  port: 5432
feature_flags:
  new_feature: true
EOF

cat > environments/production/config.yml << 'EOF'
extends: "global"
environment: "production"
database:
  host: "production-db.example.com"
  port: 5432
feature_flags:
  new_feature: false
EOF

# Create region configs
mkdir -p environments/{staging,production}/regions/{us-east,eu-west}
cat > environments/production/regions/us-east/config.yml << 'EOF'
region: "us-east"
cloud_provider: "aws"
cloud_region: "us-east-1"
EOF

# Create encrypted secrets (dummy files for testing)
mkdir -p environments/{staging,production,global}
echo '{"encrypted":"secrets"}' | sops --encrypt --input-type json --output-type json > environments/global/secrets.enc
echo '{"staging_secrets": true}' | sops --encrypt --input-type json --output-type json > environments/staging/secrets.enc
echo '{"production_secrets": true}' | sops --encrypt --input-type json --output-type json > environments/production/secrets.enc
```

### 5. Testing Dependencies Setup

**Required State**: Package files and test structure

```bash
# Create package.json for Node.js projects
cat > package.json << 'EOF'
{
  "name": "ci-excellence",
  "version": "1.0.0",
  "scripts": {
    "build": "echo 'Building project'",
    "test": "echo 'Running tests'",
    "lint": "echo 'Linting code'",
    "bundle": "echo 'Creating bundle'"
  },
  "devDependencies": {
    "eslint": "^8.0.0",
    "jest": "^29.0.0"
  }
}
EOF

# Create test structure
mkdir -p tests/{unit,integration,e2e}
cat > tests/unit/test-example.js << 'EOF'
test('example test', () => {
  expect(true).toBe(true);
});
EOF

# Create source code structure
mkdir -p src
echo 'console.log("Hello World");' > src/index.js
```

## Test Environment Setup

### 1. Initial Repository Setup

```bash
# Clone repository
git clone <repository-url>
cd ci-excellence

# Setup development environment
mise run dev-setup

# Create ACT secrets
mkdir -p .secrets
touch .secrets/act-secrets .secrets/act-env

# Populate with dummy values (see sections above)
```

### 2. Configure Git for Testing

```bash
# Configure git user for test commits
git config user.name "Test User"
git config user.email "test@example.com"

# Create test branch structure
git checkout main
git checkout -b test/pipeline-testing
```

### 3. Create Test Data

```bash
# Create test files that will be processed by pipelines
mkdir -p {src,tests,docs,dist}

# Create source code
echo 'export function hello() { return "Hello World"; }' > src/index.js

# Create test files
echo 'test("basic test", () => { expect(true).toBe(true); });' > tests/basic.test.js

# Create documentation
echo '# Test Documentation\nThis is a test.' > docs/README.md
```

### 4. Setup Environment Variables

```bash
# Create .env file for local testing
cat > .env << 'EOF'
# Local Testing Environment
NODE_ENV=test
CI=true
GITHUB_ACTIONS=true
GITHUB_REPOSITORY=ci-excellence
GITHUB_SERVER_URL=https://github.com
GITHUB_REF=refs/heads/test/pipeline-testing
GITHUB_SHA=$(git rev-parse HEAD)
GITHUB_RUN_ID=12345
GITHUB_RUN_NUMBER=123
GITHUB_ACTOR=test-user
EOF

# Source environment variables
source .env
```

### 5. Prepare Test Scenarios

```bash
# Scenario 1: Clean slate for basic testing
git clean -fd
git reset --hard HEAD

# Scenario 2: With changes for testing commit workflows
echo "test change for commit" > test-file.txt
git add test-file.txt
git commit -m "test: add file for commit testing"

# Scenario 3: With tags for testing release workflows
git tag -a v1.0.0-test -m "Test version 1.0.0"

# Scenario 4: With merge conflict simulation
git checkout -b test-conflict
echo "conflicting content" > test-conflict.txt
git add test-conflict.txt
git commit -m "test: conflicting change"
git checkout main
echo "different content" > test-conflict.txt
git add test-conflict.txt
git commit -m "test: main change"
git merge test-conflict  # This will create a conflict
```

## Troubleshooting

### Common Issues and Solutions

#### 1. ACT Image Pull Issues

```bash
# Pull specific images manually
act -P ubuntu-latest=nektos/act-ubuntu:20.04 --pull

# Use larger image
act -P ubuntu-latest=nektos/act-ubuntu:22.04 --pull
```

#### 2. Permission Issues

```bash
# Fix script permissions
find scripts -name "*.sh" -exec chmod +x {} \;

# Fix directory permissions
chmod 755 scripts
chmod 644 .secrets/act-secrets .secrets/act-env
```

#### 3. MISE Tool Not Found

```bash
# Install missing tools
mise install

# Verify all tools
mise run verify-tools

# Check specific tool
mise exec -- shellcheck --version
```

#### 4. Git History Issues

```bash
# Ensure full git history
git fetch --unshallow
git pull --all

# Check for necessary tags
git tag -l
```

#### 5. Missing Configuration Files

```bash
# Create missing configurations
mise run setup
mkdir -p environments/{staging,production,global}

# Create dummy configs for testing
echo '{}' > environments/global/config.yml
echo '{}' > environments/staging/config.yml
echo '{}' > environments/production/config.yml
```

#### 6. Secret/Environment Variable Issues

```bash
# Check ACT secrets file
cat .secrets/act-secrets

# Check environment file
cat .secrets/act-env

# Test with specific secrets
act -s GITHUB_TOKEN=dummy -s ENABLE_COMPILE=true
```

#### 7. Workflow Syntax Errors

```bash
# Validate workflow files
mise run validate-workflows

# Manual validation
action-validator .github/workflows/pre-release.yml
```

### Debug Mode

```bash
# Run ACT with verbose output
act -v -v -v pull_request

# Run with dry-run for safety
act --dryrun workflow_dispatch

# Run specific job with debug
act pull_request -j setup -v
```

### Clean Testing Environment

```bash
# Reset between test runs
git clean -fd
git reset --hard HEAD

# Remove ACT cache
rm -rf ./.act-cache/

# Clear MISE cache
mise cache clear
```

## Best Practices

1. **Always use dry-run mode** when first testing workflows
2. **Create dummy secrets and environment variables** for local testing
3. **Test individual jobs** before running complete workflows
4. **Maintain separate test branches** for different scenarios
5. **Clean between test runs** to avoid contamination
6. **Use verbose logging** when troubleshooting issues
7. **Validate workflow syntax** before running ACT
8. **Document test scenarios** for repeatability

## Integration with MISE

Use MISE tasks for common testing scenarios:

```bash
# Quick test of all workflows
mise run test-local-ci

# Run with specific environment
mise run switch-profile staging
mise run test-local-ci

# Reset to clean state
mise run dev-setup
```