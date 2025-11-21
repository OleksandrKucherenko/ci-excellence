# CI/CD Excellence Platform

A comprehensive, production-ready CI/CD platform with advanced deployment control, multi-environment management, and automated quality gates.

## 🚀 Features

### **Core Capabilities**
- **🏗️ Complete CI/CD Pipeline** - Automated building, testing, linting, and deployment
- **🌍 Multi-Environment Support** - Development, staging, and production configurations
- **🔒 Security-First Design** - Encrypted secrets, security scanning, and compliance
- **📊 Actionable Reports** - Pipeline success reports with one-click actions
- **🔄 Safe Rollbacks** - Automated rollback with full tracking and validation
- **🐛 Self-Healing** - Automatic code formatting and linting fixes
- **📋 Git Tag Control** - Version, environment, and state-based deployment tags

### **Technology Stack**
- **Runtime**: Bash 5.x, TypeScript/Bun
- **CI/CD**: GitHub Actions with stateless pipelines
- **Secret Management**: SOPS + age encryption
- **Tool Management**: MISE (cross-platform package management)
- **Git Hooks**: Lefthook for pre-commit quality gates
- **Commit Standards**: Commitizen for conventional commits
- **Security**: Gitleaks + Trufflehog for secret scanning
- **Notifications**: Apprise for multi-channel alerts

## 📁 Project Structure

```text
ci-excellence/
├── 📄 README.md                 # This file
├── 🔧 mise.toml                # Tool configuration and tasks
├── 🎣 .lefthook.yml            # Git hooks configuration
├── 📜 commitizen.json          # Commit message standards
├── 🔐 .sops.yaml               # SOPS encryption configuration
├──
├── 📁 scripts/                 # Core automation scripts
│   ├── 📁 lib/                 # Shared utility libraries
│   │   ├── common.sh           # Core functions and logging
│   │   ├── tag-utils.sh        # Git tag management
│   │   ├── secret-utils.sh     # SOPS secret handling
│   │   └── config-utils.sh     # Environment configuration
│   │
│   ├── 📁 setup/               # Project setup and installation
│   │   ├── 00-setup-folders.sh
│   │   ├── 10-ci-install-deps.sh
│   │   └── 20-ci-validate-env.sh
│   │
│   ├── 📁 build/               # Build and compilation
│   │   ├── 10-ci-deps-install.sh
│   │   ├── 20-ci-compile.sh
│   │   └── 30-ci-security-scan.sh
│   │
│   ├── 📁 ci/                  # CI/CD pipeline scripts
│   │   ├── 40-ci-lint.sh
│   │   ├── 50-ci-test.sh
│   │   ├── 60-ci-publish.sh
│   │   ├── report-generator.sh
│   │   ├── workflow-validator.sh
│   │   └── config-manager.sh
│   │
│   ├── 📁 release/             # Deployment and release management
│   │   ├── 50-ci-tag-assignment.sh
│   │   ├── 60-ci-deploy.sh
│   │   └── 70-ci-rollback.sh
│   │
│   └── 📁 hooks/               # Git hooks
│       ├── pre-push-tag-protection.sh
│       ├── pre-commit-format.sh
│       ├── pre-commit-lint.sh
│       ├── pre-commit-secret-scan.sh
│       └── pre-commit-message-check.sh
│
├── 📁 config/                  # Environment configurations
│   └── 📁 environments/
│       ├── development.json
│       ├── staging.json
│       └── production.json
│
├── 📁 secrets/                 # Encrypted secrets (SOPS)
│   ├── development.secrets.yaml
│   ├── staging.secrets.yaml
│   └── production.secrets.yaml
│
├── 📁 .github/                 # GitHub workflows
│   └── 📁 workflows/
│       ├── pre-release.yml
│       ├── tag-assignment.yml
│       └── self-healing.yml
│
└── 📁 spec/                    # Shell script tests
    └── (shellspec test files)
```

## 🛠️ Quick Start

### Prerequisites

1. **Install MISE** (cross-platform package manager):
   ```bash
   curl https://mise.run | sh
   ```

2. **Install Required Tools**:
   ```bash
   # MISE will automatically install tools when needed
   mise install
   ```

### Initial Setup

1. **Clone and Setup**:
   ```bash
   git clone <repository-url>
   cd ci-excellence
   mise run setup
   ```

2. **Generate Age Key** (for secrets encryption):
   ```bash
   mise run generate-age-key
   ```

3. **Install Git Hooks**:
   ```bash
   mise run install-hooks
   ```

4. **Validate Environment**:
   ```bash
   mise run config-validate
   ```

## 🌍 Environment Management

### Available Environments

| Environment | Purpose | Security Level | Auto-Deploy |
|-------------|---------|----------------|-------------|
| **development** | Local development & testing | Low | ✅ Yes |
| **staging** | Pre-production validation | Medium | ✅ Yes |
| **production** | Live production traffic | High | ❌ Manual |

### Environment Commands

```bash
# List all environments
mise run config-list

# Initialize specific environment
mise run config-init production

# Show environment configuration
./scripts/ci/config-manager.sh show staging

# Compare environments
./scripts/ci/config-manager.sh compare staging production

# Validate configuration
mise run config-validate production
```

## 🚀 Deployment

### Deployment Workflow

1. **Push to Branch** → Automated CI runs
2. **Create Tag** → Triggers deployment workflow
3. **Manual Approval** → For production deployments
4. **Deploy** → Automatic deployment with health checks
5. **Monitor** → Real-time status and rollback options

### Deployment Commands

```bash
# Deploy to staging (automatic)
mise run deploy-staging

# Deploy to production (requires approval)
mise run deploy-production

# Rollback deployment
mise run deploy-rollback production
```

### Git Tag Management

```bash
# Create version tag
./scripts/release/50-ci-tag-assignment.sh --type version --version 1.2.3

# Create environment tag
./scripts/release/50-ci-tag-assignment.sh --type environment --environment production --state deployed

# List deployment tags
git tag -l "env-*" | sort -V
```

## 🧪 Testing and Quality

### Run Tests

```bash
# Run all tests
mise run test

# Run tests with coverage
mise run test-coverage

# Run tests in watch mode
mise run test-watch
```

### Code Quality

```bash
# Run linting
mise run lint

# Format code
mise run format

# Check formatting without changes
mise run format-check
```

### Security Scanning

```bash
# Scan for secrets in current code
mise run scan-secrets

# Scan git history for leaked secrets
mise run scan-history
```

## 🔐 Secrets Management

### Encrypt Secrets

```bash
# Create new secrets file
cat > secrets/new-env.secrets.yaml <<EOF
database:
  host: ENC[...placeholder...]
  password: ENC[...placeholder...]
EOF

# Encrypt the file
./scripts/ci/config-manager.sh encrypt secrets/new-env.secrets.yaml

# Edit encrypted secrets
sops secrets/new-env.secrets.yaml
```

### Access Secrets

```bash
# Load and decrypt secrets for environment
./scripts/ci/config-manager.sh load production

# Get specific secret value
./scripts/ci/config-manager.sh get-secret ".database.password" production

# List all environments with secrets
mise run config-list
```

## 🐳 Docker Environments

### Local Development

```bash
# Start staging environment
mise run compose-staging-up

# Stop staging environment
mise run compose-staging-down

# Start production environment (for testing)
mise run compose-production-up

# View logs
docker-compose -f docker-compose.staging.yml logs -f
```

### Environment Configurations

- **Staging**: Moderate resources, monitoring, health checks
- **Production**: High availability, clustering, SSL, comprehensive logging

## 📊 Monitoring and Reporting

### Pipeline Reports

After each pipeline run, actionable reports are generated with:

- **Deployment Links** - One-click deployment to different environments
- **Rollback Options** - Instant rollback with version selection
- **Health Checks** - Live status monitoring
- **Troubleshooting** - Debug information and logs

### Access Reports

```bash
# Reports are generated in .reports/ directory
ls -la .reports/latest/

# View pipeline summary
cat .reports/latest/pipeline-summary.json
```

## 🔄 Self-Healing

The platform includes automatic code fixing:

```bash
# Trigger self-healing workflow
# (Available in GitHub Actions: .github/workflows/self-healing.yml)

# Manual trigger with specific scope
gh workflow run self-healing.yml -f scope=format
```

### Self-Healing Features

- **Automatic Formatting** - shellfmt for bash scripts
- **Linting Fixes** - shellcheck auto-fix where possible
- **Commit Creation** - Automatic commits with conventional message format
- **Rollback Support** - Auto-generated rollback points

## 📋 Git Workflow

### Branch Protection

```bash
# Production requires:
# - 2 reviewer approval
# - All status checks passing
# - Up-to-date branch
# - Code owner reviews

# Staging allows:
# - 1 reviewer approval
# - Most status checks
```

### Commit Message Format

```bash
# Use conventional commits
feat(pipeline): add automated deployment system
fix(security): resolve credential exposure vulnerability
docs(readme): update installation instructions

# Use commitizen for guided commits
git cz
```

### Pre-commit Hooks

Automatic checks run before each commit:

- **Secret Scanning** - Prevent committing sensitive data
- **Code Formatting** - Auto-format bash scripts
- **Linting** - shellcheck validation
- **Message Validation** - Enforce conventional commits

## 🔧 Configuration

### Environment Variables

```bash
# Test modes for all scripts
export CI_TEST_MODE=DRY_RUN      # Preview actions
export CI_TEST_MODE=SIMULATE     # Simulate execution
export CI_TEST_MODE=EXECUTE      # Actually run (default)

# Configuration override
export CONFIG_ENVIRONMENT=staging
export DEPLOY_ENVIRONMENT=production

# Feature flags
export ENABLE_NOTIFICATIONS=true
export AUTO_DEPLOY=false
```

### Custom Configuration

```bash
# Edit environment configuration
vim config/environments/staging.json

# Validate changes
mise run config-validate staging

# Compare with production
mise run config-compare staging production
```

## 🛠️ MISE Tasks

Complete list of available tasks:

```bash
# Configuration
mise run config-init <env>
mise run config-show <env>
mise run config-compare <env1> <env2>
mise run config-export-k8s <env>

# Deployment
mise run deploy-staging
mise run deploy-production
mise run deploy-rollback <env>

# Docker
mise run compose-staging-up
mise run compose-production-up

# Testing
mise run test
mise run test-coverage
mise run lint
mise run format

# Security
mise run scan-secrets
mise run encrypt-secrets
mise run edit-secrets

# CI/CD
mise run validate-workflows
mise run test-local-ci
```

## 📚 Troubleshooting

### Common Issues

**1. SOPS Decryption Failed**
```bash
# Check age key file
ls -la .secrets/mise-age.txt

# Regenerate if missing
mise run generate-age-key
```

**2. Git Hooks Not Working**
```bash
# Reinstall hooks
mise run uninstall-hooks
mise run install-hooks

# Check hook permissions
ls -la .git/hooks/
```

**3. Environment Validation Failed**
```bash
# Check configuration syntax
jq empty config/environments/production.json

# Validate all environments
for env in development staging production; do
  mise run config-validate $env
done
```

### Debug Mode

```bash
# Enable verbose logging
export VERBOSE=true
export DEBUG=true

# Run in dry-run mode
export CI_TEST_MODE=DRY_RUN

# Check configuration
./scripts/ci/config-manager.sh show production
```

## 🤝 Contributing

### Development Workflow

1. **Fork** the repository
2. **Create feature branch**: `git checkout -b feature/new-feature`
3. **Make changes** following the coding standards
4. **Test locally**: `mise run test && mise run lint`
5. **Commit**: `git cz` (use conventional commits)
6. **Push**: `git push origin feature/new-feature`
7. **Create Pull Request**

### Code Standards

- **Shell Scripts**: Follow bash best practices, use shellcheck
- **Configuration**: JSON format with proper validation
- **Documentation**: Update README and inline comments
- **Testing**: Write shellspec tests for new functionality
- **Security**: No hardcoded secrets, use SOPS encryption

### Testing Your Changes

```bash
# Run full test suite
mise run test

# Run security scan
mise run scan-secrets

# Validate workflows
mise run validate-workflows

# Test configuration changes
for env in development staging production; do
  mise run config-validate $env
done
```

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- **MISE** - Cross-platform package management
- **SOPS** - Secrets encryption
- **GitHub Actions** - CI/CD platform
- **Lefthook** - Git hooks management
- **Commitizen** - Conventional commits
- **ShellSpec** - Shell script testing
- **Gitleaks/Trufflehog** - Secret scanning

---

## 📞 Support

For questions, issues, or contributions:

1. **Check the documentation** in this README
2. **Search existing issues** in the repository
3. **Create a new issue** with detailed information
4. **Join our discussions** for community support

---

**Happy deploying! 🚀**