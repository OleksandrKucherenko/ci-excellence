# CI Excellence Framework - Quick Start Guide

## 🎯 Overview

The CI Excellence Framework is a production-ready, comprehensive CI/CD pipeline solution with advanced deployment control, multi-environment management, and testable DRY scripts. This guide will help you get up and running quickly.

## 🚀 Quick Start

### Prerequisites

- **MISE**: Modern tool manager
- **Git**: Version control system
- **Shell**: Bash 5.x or ZSH
- **GitHub Actions**: For CI/CD workflows (if using GitHub)

### Step 1: Setup Development Environment

```bash
# Clone repository
git clone <repository-url>
cd ci-excellence

# Install MISE (if not already installed)
curl https://mise.run | sh
eval "$(mise activate bash)"

# Install all required tools and setup environment
mise run dev-setup
```

### Step 2: Configure Shell Integration

```bash
# Set up shell integration for enhanced experience
./scripts/shell/setup-shell-integration.sh zsh

# Or for Bash
./scripts/shell/setup-shell-integration.sh bash --prompt

# Reload your shell or run:
source ~/.zshrc  # or source ~/.bashrc
```

### Step 3: Initialize Project

```bash
# Initialize environment
mise run setup

# Create your first secret (optional)
mise run generate-age-key

# Edit encrypted secrets
mise run edit-secrets

# Validate workflows
mise run validate-workflows
```

### Step 4: Run Tests

```bash
# Run all tests
mise run test

# Run tests with coverage
mise run test-coverage

# Run specific test suites
mise run test:unit
mise run test:integration
```

### Step 5: Commit Your First Changes

```bash
# Make your changes
# ...

# Run pre-commit checks (automatically via git hooks)
git add .
git commit -m "feat: Add awesome new feature"

# Your commit will be validated automatically!
```

## 🛠️ Common Workflows

### Environment Management

```bash
# Switch to development profile
mise profile activate development

# Switch to staging profile
mise profile activate staging

# Switch to production profile (requires approval)
mise profile activate production

# View current profile
mise profile show
```

### Local Development

```bash
# Run local CI test
mise run test-local-ci

# Run security scan
mise run scan-secrets

# Run linting
mise run lint

# Format code
mise run format
```

### Deployment Testing

```bash
# Test staging deployment (dry run)
DRY_RUN=true ./scripts/deployment/10-ci-deploy-staging.sh validate

# Test production validation
FORCE_DEPLOY=true ./scripts/deployment/20-ci-deploy-production.sh validate
```

## 🔧 Configuration

### Environment Variables

Key environment variables you can set:

```bash
# Test modes
export CI_TEST_MODE=dry_run          # Simulate operations
export DRY_RUN=true                # Skip actual changes

# Logging
export LOG_LEVEL=debug             # Enable debug logging

# Production safety
export PRODUCTION_APPROVED=true    # Allow production operations
export CONFIRM_PRODUCTION_ROLLBACK=true  # Allow production rollback
```

### MISE Configuration

Edit `mise.toml` to customize:

```toml
[env]
# Enable specific CI features
ENABLE_COMPILE = true
ENABLE_TESTS = true
ENABLE_SECURITY_SCAN = true

# Custom tasks
[tasks.custom-task]
description = "Your custom task"
run = ["echo", "Hello from custom task!"]
```

### Environment Configuration

Configure environments in `environments/`:

```bash
# Staging configuration
environments/staging/config.yml

# Production configuration
environments/production/config.yml

# Global shared configuration
environments/global/config.yml

# Region-specific configuration
environments/staging/regions/us-east/config.yml
environments/production/regions/us-east/config.yml
```

## 🏷️ Tag System

### Version Tags (Immutable)

```bash
# Create version tag
./scripts/deployment/40-ci-atomic-tag-movement.sh create-version v1.2.3 abc123

# View version tags
./scripts/deployment/40-ci-atomic-tag-movement.sh status
```

### Environment Tags (Movable)

```bash
# Move production environment tag
./scripts/deployment/40-ci-atomic-tag-movement.sh move-environment production abc123 deploy-456

# View deployment history
./scripts/deployment/40-ci-atomic-tag-movement.sh history production
```

### State Tags (Immutable)

```bash
# Create success state tag
./scripts/deployment/40-ci-atomic-tag-movement.sh create-state production-success abc123 production deploy-456

# Validate tag consistency
./scripts/deployment/40-ci-atomic-tag-movement.sh validate
```

## 🔒 Security Features

### Secret Management

```bash
# Generate encryption key
mise run generate-age-key

# Edit encrypted secrets
mise run edit-secrets

# Decrypt staging secrets
mise run decrypt-staging

# Decrypt production secrets (requires access)
mise run decrypt-production
```

### Security Scanning

```bash
# Scan repository for secrets
mise run scan-secrets

# Scan git history
mise run scan-history

# Run comprehensive security scan
./scripts/build/30-ci-security-scan.sh production high all
```

### Compliance Validation

```bash
# Run security audit
./scripts/maintenance/20-ci-security-audit.sh

# Validate compliance requirements
./scripts/maintenance/20-ci-security-audit.sh --compliance
```

## 🚨 Deployment Operations

### Staging Deployment

```bash
# Deploy to staging (with validation)
./scripts/deployment/10-ci-deploy-staging.sh validate

# Deploy to staging
./scripts/deployment/10-ci-deploy-staging.sh deploy us-east

# Rollback staging deployment
./scripts/deployment/10-ci-deploy-staging.sh rollback deploy-123 previous_tag
```

### Production Deployment

```bash
# Validate production deployment prerequisites
./scripts/deployment/20-ci-deploy-production.sh validate

# Deploy to production (requires approval)
PRODUCTION_APPROVED=true ./scripts/deployment/20-ci-deploy-production.sh deploy us-east

# Rollback production deployment
CONFIRM_PRODUCTION_ROLLBACK=true ./scripts/deployment/20-ci-deploy-production.sh rollback deploy-456 blue_green_switchback
```

### Manual Rollback

```bash
# Manual rollback via GitHub Actions
# 1. Go to GitHub Actions tab
# 2. Run "Rollback Deployment" workflow
# 3. Select environment, region, and strategy
# 4. Confirm rollback operation

# Manual rollback via CLI
./scripts/deployment/30-ci-rollback.sh production deploy-123 previous_tag
```

## 🧹 Maintenance

### System Cleanup

```bash
# Run cleanup operations
./scripts/maintenance/10-ci-cleanup.sh

# Cleanup with custom retention
CLEANUP_DAYS=7 ./scripts/maintenance/10-ci-cleanup.sh

# Dry run cleanup
DRY_RUN=true ./scripts/maintenance/10-ci-cleanup.sh
```

### Security Auditing

```bash
# Run comprehensive security audit
./scripts/maintenance/20-ci-security-audit.sh

# Audit specific areas
./scripts/maintenance/20-ci-security-audit.sh --secrets --dependencies

# Generate detailed report
./scripts/maintenance/20-ci-security-audit.sh --verbose
```

## 📊 Monitoring and Reporting

### Build Status

```bash
# Check build status
./scripts/build/10-ci-compile.sh status

# Run comprehensive build
./scripts/build/10-ci-compile.sh

# Generate build report
./scripts/build/10-ci-compile.sh --report
```

### Deployment Status

```bash
# Check deployment status
./scripts/deployment/10-ci-deploy-staging.sh status us-east
./scripts/deployment/20-ci-deploy-production.sh status us-east

# View deployment history
./scripts/deployment/10-ci-deploy-staging.sh history staging 10
```

## 🐛 Troubleshooting

### Common Issues

1. **Permission Denied Errors**
   ```bash
   chmod +x scripts/**/*.sh
   ```

2. **Missing Tools**
   ```bash
   mise run verify-tools
   mise run install-hooks
   ```

3. **Secret Decryption Issues**
   ```bash
   # Check age key file
   ls -la .secrets/mise-age.txt

   # Regenerate if needed
   mise run generate-age-key
   ```

4. **Git Hook Issues**
   ```bash
   # Reinstall hooks
   mise run uninstall-hooks
   mise run install-hooks
   ```

5. **Profile Switching Issues**
   ```bash
   # Check available profiles
   mise profile list

   # Reset profile
   mise profile deactivate
   mise profile activate <profile>
   ```

### Debug Mode

Enable debug logging:

```bash
export LOG_LEVEL=debug
export CI_TEST_MODE=dry_run
```

### Getting Help

```bash
# Get help for specific scripts
./scripts/deployment/10-ci-deploy-staging.sh --help

# Check available tasks
mise run --help

# View script documentation
cat docs/script-development.md
```

## 📚 Documentation

- **[Architecture Guide](docs/architecture.md)** - System architecture and design
- **[Developer Guide](docs/developer-guide.md)** - Comprehensive development guide
- **[Script Development](docs/script-development.md)** - Script development guidelines
- **[Security Guide](docs/security.md)** - Security best practices
- **[Migration Guide](docs/migration.md)** - Migration from other CI systems

## 🎯 Next Steps

1. **Explore the Architecture**: Read the architecture guide to understand the system design
2. **Customize Configuration**: Modify configuration files to fit your needs
3. **Extend Functionality**: Use the script template to add custom features
4. **Integrate with Your Projects**: Adapt the framework for your specific use cases

## 🤝 Getting Support

If you encounter issues or have questions:

1. Check the troubleshooting section above
2. Review the documentation
3. Search existing issues in the repository
4. Create a new issue with detailed information

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.