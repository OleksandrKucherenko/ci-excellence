# Migration Guide: CI Excellence Framework

## 🎯 Overview

This guide helps you migrate your existing CI/CD pipelines to the CI Excellence Framework. Whether you're using GitHub Actions, GitLab CI, Jenkins, or another system, this guide provides step-by-step instructions for a smooth transition.

## 📋 Migration Planning

### Assessment Phase

Before migrating, assess your current setup:

```bash
# Inventory existing CI/CD components
find .github/workflows/ -name "*.yml" -o -name "*.yaml" | wc -l
find .gitlab-ci.yml -o -name "Jenkinsfile" -o -name "azure-pipelines.yml" | wc -l

# Check for existing security tools
command -v gitleaks >/dev/null && echo "✅ Gitleaks" || echo "❌ Gitleaks"
command -v trufflehog >/dev/null && echo "✅ Trufflehog" || echo "❌ Trufflehog"
```

### Migration Strategy

Choose your migration approach:

1. **Big Bang**: Complete migration in one go
2. **Phased**: Gradual migration by component
3. **Parallel**: Run new framework alongside existing system

## 🔄 Migration Paths

### From GitHub Actions

If you're already using GitHub Actions:

#### 1. Backup Existing Workflows
```bash
# Create backup of existing workflows
mkdir -p .github/workflows.backup
cp .github/workflows/*.yml .github/workflows.backup/ 2>/dev/null || true
cp .github/workflows/*.yaml .github/workflows.backup/ 2>/dev/null || true
```

#### 2. Key Workflow Mappings

| Existing Workflow | CI Excellence Framework Equivalent |
|-------------------|------------------------------------|
| `ci.yml` | `pre-release.yml` + `release.yml` |
| `deploy.yml` | `deployment-staging.yml` + `deployment-production.yml` |
| `security.yml` | Integrated into all workflows |
| `test.yml` | Integrated into `release.yml` |
| `build.yml` | `release.yml` build steps |

#### 3. Environment Variable Migration
```bash
# Common GitHub Actions variables to CI Excellence equivalents
# GITHUB_WORKSPACE → PROJECT_ROOT (set by framework)
# GITHUB_SHA → CI_COMMIT_SHA (set by framework)
# GITHUB_REF → CI_BRANCH (set by framework)
# GITHUB_TOKEN → GITHUB_TOKEN (same)
# AWS_SECRET_ACCESS_KEY → Same (environment-specific)
```

### From GitLab CI

#### 1. Variable Mapping
```bash
# GitLab CI to CI Excellence Framework variables
# CI_PROJECT_DIR → PROJECT_ROOT
# CI_COMMIT_SHA → CI_COMMIT_SHA
# CI_COMMIT_REF_NAME → CI_BRANCH
# CI_PIPELINE_SOURCE → CI_PIPELINE_SOURCE
# GIT_STRATEGY → Not needed (framework handles)
```

#### 2. Stage Migration
```yaml
# GitLab CI stages to framework workflows
# stages: [build, test, security, deploy]
# ↓
# Framework: pre-release → release → deployment workflows
```

### From Jenkins

#### 1. Pipeline Conversion
```groovy
// Jenkins pipeline stages to framework
pipeline {
    agent any
    stages {
        stage('Build') { /* → release.yml */ }
        stage('Test') { /* → release.yml test steps */ }
        stage('Security Scan') { /* → integrated security scanning */ }
        stage('Deploy') { /* → deployment workflows */ }
    }
}
```

#### 2. Credential Migration
```bash
# Jenkins credentials to environment secrets
# withCredentials([string(credentialsId: 'aws-key', variable: 'AWS_ACCESS_KEY_ID')])
# ↓
# Configure in environments/staging/secrets.enc or GitHub Secrets
```

## 🛠️ Step-by-Step Migration

### Step 1: Install Framework Prerequisites

```bash
# Install MISE (if not already installed)
curl https://mise.run | sh
eval "$(mise activate bash)"

# Clone or setup the framework
# (If starting from scratch)
git clone <ci-excellence-framework-repo>
cd ci-excellence

# Run setup
mise run dev-setup
```

### Step 2: Configure Project Structure

```bash
# Create necessary directories (if they don't exist)
mkdir -p environments/{staging,production,global}/regions
mkdir -p scripts/{build,ci,deployment,maintenance,security}
mkdir -p scripts/lib
mkdir -p .secrets
```

### Step 3: Migrate Environment Configuration

#### For Existing Environment Variables:

```bash
# Create staging configuration
cat > environments/staging/config.yml << EOF
# Migrated from [your previous system]
deployment:
  type: "staging"
  auto_approve: true

cloud:
  provider: "aws"  # or your provider
  region: "us-east-1"

# Migrate your existing environment variables
environment_variables:
  NODE_ENV: "staging"
  API_URL: "https://staging-api.example.com"
  # Add your existing variables here
EOF
```

#### For Production:

```bash
# Create production configuration
cat > environments/production/config.yml << EOF
# Migrated from production configuration
deployment:
  type: "production"
  auto_approve: false
  requires_approval: true

cloud:
  provider: "aws"
  region: "us-east-1"

environment_variables:
  NODE_ENV: "production"
  API_URL: "https://api.example.com"
  # Add production-specific variables
EOF
```

### Step 4: Migrate Secrets

#### Option A: Use Existing Secret Management
```bash
# If you have existing encrypted secrets
cp path/to/your/secrets.json environments/staging/secrets.enc
cp path/to/production/secrets.json environments/production/secrets.enc

# Update SOPS configuration for age keys
mise run generate-age-key
```

#### Option B: Fresh Secret Setup
```bash
# Generate new encryption key
mise run generate-age-key

# Create staging secrets
mise run decrypt-staging
# Add secrets to .env.secrets.json
mise run encrypt-staging
```

### Step 5: Migrate Build Scripts

#### For Node.js Projects:
```bash
# Your existing package.json scripts become framework-managed
# "build": "webpack" → scripts/build/10-ci-compile.sh handles this
# "test": "jest" → scripts/test/10-ci-unit-tests.sh handles this
# "lint": "eslint" → scripts/build/20-ci-lint.sh handles this
```

#### For Other Project Types:
The framework automatically detects your project type and runs appropriate commands.

### Step 6: Update GitHub Actions

#### Replace Existing Workflows:
```bash
# Remove old workflows
rm .github/workflows/ci.yml
rm .github/workflows/deploy.yml
rm .github/workflows/security.yml

# The framework provides comprehensive replacements
```

#### Configure New Workflows:
```bash
# The framework workflows are already configured
# Just customize them for your needs if necessary
```

## 📝 Configuration Templates

### Node.js Migration Template

```yaml
# environments/staging/config.yml
project:
  type: "nodejs"
  build_command: "npm run build"
  test_command: "npm test"
  lint_command: "npm run lint"

deployment:
  type: "staging"
  branch_pattern: "main|develop|staging*"

environment_variables:
  NODE_ENV: "staging"
  # Add your existing variables
```

### Python Migration Template

```yaml
# environments/staging/config.yml
project:
  type: "python"
  build_command: "python -m build"
  test_command: "pytest"
  lint_command: "flake8"

deployment:
  type: "staging"

environment_variables:
  PYTHON_ENV: "staging"
  # Add your existing variables
```

## ⚠️ Common Migration Issues

### Issue 1: Build Command Not Found
**Problem**: Framework can't find your build command
**Solution**: Specify it in environment config
```yaml
# environments/staging/config.yml
project:
  build_command: "your-build-command"
```

### Issue 2: Environment Variables Missing
**Problem**: Required variables not available
**Solution**: Add them to environment config or secrets
```yaml
# environments/staging/config.yml
environment_variables:
  YOUR_VAR: "value"
```

### Issue 3: Permissions Issues
**Problem**: Scripts not executable
**Solution**:
```bash
chmod +x scripts/**/*.sh
mise run install-hooks
```

### Issue 4: Secret Decryption Fails
**Problem**: Can't decrypt environment secrets
**Solution**: Check age key setup
```bash
ls -la .secrets/mise-age.txt
mise run generate-age-key  # if missing
```

## ✅ Validation Checklist

After migration, validate your setup:

```bash
# Check framework installation
mise --version
mise run verify-tools

# Validate configurations
mise run validate-config

# Test staging deployment (dry run)
CI_TEST_MODE=dry_run ./scripts/deployment/10-ci-deploy-staging.sh validate

# Test security scanning
CI_TEST_MODE=dry_run ./scripts/build/30-ci-security-scan.sh staging medium basic

# Check shell integration
./scripts/shell/setup-shell-integration.sh --status
```

## 🔄 Rollback Plan

If migration fails, rollback:

```bash
# Restore original workflows
cp .github/workflows.backup/*.yml .github/workflows/ 2>/dev/null || true

# Remove framework changes
git reset --hard HEAD~1  # If committed changes

# Revert to original tools
# uninstall mise if needed
```

## 📚 Additional Resources

- [Quick Start Guide](quickstart.md) - Basic setup instructions
- [Developer Guide](docs/developer-guide.md) - Detailed development workflow
- [Troubleshooting Guide](docs/troubleshooting.md) - Common issues and solutions
- [Security Guide](docs/security.md) - Security best practices

## 🆘 Getting Help

If you encounter issues during migration:

1. Check the troubleshooting guide
2. Review the validation checklist
3. Run diagnostic commands:
   ```bash
   ./scripts/shell/setup-shell-integration.sh --status
   mise run verify-tools
   mise profile status
   ```
4. Check logs in `.logs/` directory
5. Create an issue with detailed information about your setup

## 🎉 Migration Success

Once migration is complete:

1. ✅ All workflows pass in dry-run mode
2. ✅ Security scanning finds no issues
3. ✅ Environment configurations load correctly
4. ✅ Secrets are properly encrypted
5. ✅ Team members can use new workflows

Welcome to the CI Excellence Framework! 🚀