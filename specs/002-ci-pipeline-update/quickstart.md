# CI Pipeline Excellence - Quick Start Guide

**Version**: 1.0.0
**Updated**: 2025-11-21
**Target Audience**: DevOps engineers, development teams, CI/CD administrators

## Prerequisites

### System Requirements
- **OS**: Linux, macOS, or Windows with WSL2
- **Git**: Version 2.30 or higher
- **GitHub**: Repository with GitHub Actions enabled
- **Shell**: Bash 5.x, ZSH, or Fish (for local development)

### Required Accounts
- **GitHub**: Personal access token with repository access
- **GitHub Actions**: Enabled for target repository
- **Admin access**: For initial setup and emergency overrides

## Installation Guide

### 1. Clone and Setup Repository
```bash
# Clone your repository
git clone https://github.com/your-org/ci-excellence.git
cd ci-excellence

# Switch to the feature branch
git checkout 002-ci-pipeline-update
```

### 2. Install MISE (Tool Management)
```bash
# Install MISE
curl https://mise.run | sh

# Initialize MISE for your shell
# For Bash
echo 'eval "$(mise activate bash)"' >> ~/.bashrc
source ~/.bashrc

# For ZSH
echo 'eval "$(mise activate zsh)"' >> ~/.zshrc
source ~/.zshrc

# Verify installation
mise --version
```

### 3. Initial Setup
```bash
# Install all required tools
mise install

# Verify tool installation
mise run verify-tools

# Setup development environment
mise run dev-setup

# Initialize git hooks
mise run install-hooks
```

### 4. Configure Environment
```bash
# Create local environment file
cp config/.env.template .env.local

# Initialize secrets for local development
mise run secrets-init local

# Edit secrets (encrypted with SOPS)
mise run edit-secrets

# Verify environment setup
mise run profile-status
```

## Basic Usage

### Environment Management

#### Switch Between Environments
```bash
# Switch to staging environment
mise run switch-profile staging

# Switch to production with region
mise run switch-profile production

# View current profile status
mise run profile-status

# Switch back to local development
mise run switch-profile local
```

#### Shell Integration (ZSH)
```bash
# Quick profile switching
mise_switch staging

# View profile information
mise_profile_status

# Show all available profiles
mise_switch --help
```

### Deployment Operations

#### Deploy to Staging
```bash
# Via GitHub Actions (recommended)
gh workflow run deployment.yml \
  --field environment=staging \
  --field version_tag=v1.0.0 \
  --field subproject=api

# Via CLI (advanced)
./scripts/deployment/deploy.sh api staging v1.0.0
```

#### Deploy to Production
```bash
# Deploy API to production
gh workflow run deployment.yml \
  --field environment=production \
  --field version_tag=v2.1.0 \
  --field subproject=api \
  --field region=us-east
```

#### Tag Management
```bash
# Create version tag
git tag -a v1.2.3 -m "Release version 1.2.3"
git push origin v1.2.3

# Assign environment tag via CI
gh workflow run tag-assignment.yml \
  --field tag_type=environment \
  --field subproject=api \
  --field version=v1.2.3 \
  --field environment=production

# Mark version as stable
gh workflow run tag-assignment.yml \
  --field tag_type=state \
  --field subproject=api \
  --field version=v1.2.3 \
  --field state=stable
```

### Local Development

#### Run Tests Locally
```bash
# Run all tests
mise run test

# Run specific test types
mise run test-unit
mise run test-integration
mise run test-e2e

# Test with coverage
mise run test:coverage
```

#### Lint and Format
```bash
# Lint all scripts
mise run lint

# Format all scripts
mise run format

# Check formatting without changing files
mise run format:check
```

#### Security Scanning
```bash
# Scan for secrets
mise run security-scan

# Audit dependencies
mise run security-audit

# Run full security check
mise run security:full
```

### Pipeline Testing

#### Test GitHub Actions Locally
```bash
# Run pre-release pipeline locally
act -j pre-release

# Test with specific inputs
act -j deployment \
  -s GITHUB_TOKEN=$GITHUB_TOKEN \
  -input environment=staging \
  -input version_tag=v1.0.0

# Dry run mode
act -j pre-release --dry-run
```

#### Test Scripts in Isolation
```bash
# Test script with different modes
CI_TEST_MODE=DRY_RUN ./scripts/build/10-ci-compile.sh

# Simulate failure
CI_TEST_MODE=EXECUTE CI_COMPILE_BEHAVIOR=FAIL ./scripts/build/10-ci-compile.sh

# Test timeout handling
timeout 10s ./scripts/test/20-ci-integration-tests.sh
```

## Configuration Guide

### Environment Configuration

#### Structure
```
environments/
├── global/
│   ├── config.yml          # Global settings
│   └── secrets.enc         # Global secrets (encrypted)
├── staging/
│   ├── config.yml          # Staging-specific settings
│   ├── secrets.enc         # Staging secrets
│   └── regions/
│       ├── us-east/
│       │   └── config.yml  # Region-specific settings
│       └── eu-west/
│           └── config.yml
└── production/
    ├── config.yml
    ├── secrets.enc
    └── regions/
        ├── us-east/
        └── eu-west/
```

#### Editing Configuration
```bash
# Edit staging configuration
mise run decrypt-staging
# Edit environments/staging/config.yml
mise run encrypt-staging

# Edit production secrets
mise run decrypt-production
# Edit environments/production/secrets.enc
mise run encrypt-production
```

### MISE Configuration

#### Tool Management (.mise.toml)
```toml
[tools]
# Core runtime
bun = "latest"
node = "lts/*"

# Security tools
gitleaks = "latest"
sops = "latest"
age = "latest"

# Shell tools
shellspec = "latest"
shellcheck = "latest"
shfmt = "latest"

[tasks]
# Custom tasks
deploy-staging = ["./scripts/deployment/deploy.sh", "staging"]
security-scan = ["gitleaks", "detect"]
```

### Git Hooks Configuration

#### Lefthook Configuration (.lefthook.yml)
```yaml
pre-commit:
  commands:
    format:
      run: shfmt -l -w .
      glob: "*.sh"
    lint:
      run: shellcheck **/*.sh
    security-scan:
      run: gitleaks protect --no-banner
      glob: "*.sh"

pre-push:
  commands:
    protected-tag-check:
      run: .git/hooks/pre-push-tag-protection.sh
      tags: security
```

## Common Workflows

### First-Time Setup
```bash
# 1. Clone and setup
git clone <repository>
cd <repository>
git checkout <feature-branch>

# 2. Install tools
mise install

# 3. Setup environment
mise run dev-setup

# 4. Configure secrets
mise run edit-secrets

# 5. Verify setup
mise run verify-tools
mise run test
```

### Daily Development
```bash
# 1. Switch to appropriate profile
mise_switch staging

# 2. Make changes
# ... edit files ...

# 3. Test changes
mise run test
mise run lint
mise run format

# 4. Commit changes (hooks will run automatically)
git add .
git commit -m "feat: implement new feature"

# 5. Push changes
git push origin feature-branch
```

### Deployment Process
```bash
# 1. Create and push version tag
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0

# 2. Deploy to staging first
gh workflow run deployment.yml \
  --field environment=staging \
  --field version_tag=v1.0.0

# 3. Verify staging deployment
# ... manual testing ...

# 4. Deploy to production
gh workflow run deployment.yml \
  --field environment=production \
  --field version_tag=v1.0.0

# 5. Monitor deployment
# Check GitHub Actions logs and pipeline reports
```

### Rollback Process
```bash
# 1. Identify rollback target
./scripts/deployment/select-rollback-target.sh api production

# 2. Execute rollback
gh workflow run rollback.yml \
  --field subproject=api \
  --field environment=production \
  --field current_version=v1.0.0

# 3. Verify rollback
# Check logs and application health
```

## Troubleshooting

### Common Issues

#### MISE Not Found
```bash
# Add to shell profile
echo 'eval "$(mise activate bash)"' >> ~/.bashrc
source ~/.bashrc

# Verify installation
mise --version
```

#### Tool Installation Fails
```bash
# Update MISE registry
mise update

# Clear cache and retry
mise cache clear
mise install

# Check for specific tool issues
mise list --missing
```

#### Permission Issues with Git Hooks
```bash
# Make hooks executable
chmod +x .git/hooks/*

# Reinstall hooks
mise run install-hooks

# Check Lefthook configuration
lefthook install
```

#### Secrets Decryption Fails
```bash
# Check age key configuration
cat .secrets/mise-age.txt

# Verify SOPS configuration
cat .sops.yaml

# Test decryption
sops --decrypt environments/staging/secrets.enc
```

### Getting Help

#### Documentation
- **Full documentation**: Check the `/docs` directory
- **API contracts**: See `/contracts` directory
- **Configuration examples**: Check `.examples` directory

#### Commands Reference
```bash
# Show all available commands
mise run --help

# Show available profiles
mise_switch --help

# Show security commands
mise run security:help

# Show deployment commands
./scripts/deployment/deploy.sh --help
```

#### Support
- **Issues**: Create GitHub issue with detailed error information
- **Logs**: Include relevant logs from GitHub Actions runs
- **Configuration**: Share relevant configuration files (redact secrets)

## Best Practices

### Security
- Always use `mise run edit-secrets` for editing encrypted files
- Never commit plaintext secrets to the repository
- Regularly rotate encryption keys using `mise run secrets-rotate`
- Enable all security scans in CI/CD pipelines

### Performance
- Use `DRY_RUN` mode for testing without side effects
- Monitor pipeline execution times and optimize long-running steps
- Use GitHub Actions caching for dependency management
- Regularly clean up old artifacts and logs

### Maintainability
- Keep scripts under 50 lines of code
- Use descriptive comments and clear variable names
- Test all scripts in different modes (PASS, FAIL, DRY_RUN, etc.)
- Follow conventional commit message format

This quick start guide provides everything needed to get up and running with the CI Pipeline Excellence system quickly and efficiently.