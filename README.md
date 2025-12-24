# CI Excellence - Production-Ready CI/CD Pipeline

A customizable, stub-based CI/CD pipeline that follows the philosophy of "reserve space, eliminate routine." Activate features through simple variable toggles - no failures from disabled features.

## 🎯 Philosophy

- **Stub-based**: All scripts are customizable stubs with examples
- **Variable-driven**: Features skip gracefully when not enabled
- **Zero routine**: Setup is done, you only configure specifics
- **Production-ready**: Based on real-world best practices
- **Modular**: Enable only what you need

## 🚀 Quick Start

### 1. Install Mise (macOS)

```bash
# Using Homebrew (recommended)
brew install mise

# Or using curl
curl https://mise.run | sh
```

**Other platforms?** See [Installation Guide](docs/INSTALLATION.md)

### 2. Activate Mise in Your Shell

```bash
# For Zsh (~/.zshrc)
echo 'eval "$(mise activate zsh)"' >> ~/.zshrc
source ~/.zshrc

# For Bash (~/.bashrc or ~/.bash_profile)
echo 'eval "$(mise activate bash)"' >> ~/.bashrc
source ~/.bashrc
```

### 3. Clone and Setup

```bash
git clone git@github.com:YOUR-USERNAME/ci-excellence.git
cd ci-excellence

# Mise automatically installs everything needed!
# Wait for setup to complete...
```

### 4. Generate Encryption Key

```bash
mise run generate-age-key
```

### 5. Configure GitHub Repository

Go to **Settings > Secrets and variables > Actions**

**Create Variables:**
```
ENABLE_COMPILE=true
ENABLE_LINT=true
ENABLE_UNIT_TESTS=true
ENABLE_GITHUB_RELEASE=true
ENABLE_NOTIFICATIONS=true
```

**Create Secrets** (as needed):
```
NPM_TOKEN=your_token                  # For NPM publishing
DOCKER_USERNAME=your_username         # For Docker publishing
DOCKER_PASSWORD=your_password         # For Docker publishing
APPRISE_URLS=slack://token@channel    # For notifications
```

### 6. Customize for Your Stack

Edit the stub scripts in `scripts/ci/` to match your project:

```bash
# Example: Node.js/TypeScript project
vim scripts/ci/build/ci-10-compile.sh
# Add: npx tsc

vim scripts/ci/build/ci-20-lint.sh
# Add: npx eslint .

vim scripts/ci/test/ci-10-unit-tests.sh
# Add: npm test -- --coverage
```

**More examples:** [Customization Guide](docs/CUSTOMIZATION.md)

### 7. Start Developing!

```bash
git add .
git commit -m "feat: initial setup"
git push

# Git hooks automatically run:
# ✓ Secret detection
# ✓ Commit message validation
# ✓ Workflow validation
```

**That's it!** Your CI/CD pipeline is now active.

## 📚 Documentation

### Core Guides
- **[Installation](docs/INSTALLATION.md)** - Platform-specific installation instructions
- **[Quick Start](docs/QUICKSTART.md)** - Get started in 5 minutes
- **[Customization](docs/CUSTOMIZATION.md)** - Customize for your tech stack

### Advanced Topics
- **[Workflows](docs/WORKFLOWS.md)** - Detailed workflow documentation
- **[Architecture](docs/ARCHITECTURE.md)** - System architecture and design
- **[Notifications](docs/NOTIFICATIONS.md)** - Setup Slack, Teams, Discord, etc.

### Reference
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues and solutions
- **[Migration Guide](docs/MIGRATION.md)** - Upgrading from v1.x
- **[Mise Setup](docs/MISE-SETUP.md)** - Mise configuration details
- **[Git Hooks](docs/GIT-HOOKS.md)** - Git hooks documentation

## 🔧 What Mise Installs

Mise automatically installs and configures:
- **Secret Management**: age, sops
- **Security Scanning**: gitleaks, trufflehog
- **Git Hooks**: lefthook
- **Validation**: action-validator, commitlint
- **Utilities**: commitizen for conventional commits

Everything installs on first `cd` into the project!

## 🎨 Available Workflows

| Workflow | Triggers | Purpose |
|----------|----------|---------|
| **Pre-Release** | PRs, pushes to develop/feature branches | Build, lint, test, security scan |
| **Release** | Manual trigger or tag push | Version, build, publish to NPM/Docker/GitHub |
| **Post-Release** | After release published | Verify deployments, tag stability, rollback |
| **Maintenance** | Daily cron (2 AM UTC) | Cleanup, sync, security audit, dependency updates |
| **Auto-Fix Quality** | Push to development branches | Auto-scan and fix security issues |

**Detailed workflow docs:** [Workflows](docs/WORKFLOWS.md)

## ⚙️ Configuration

### Enable Features Gradually

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
```

**Full configuration reference:** [Workflows](docs/WORKFLOWS.md#workflow-activation)

## 🔒 Security Features

- **Pre-commit hooks**: Block commits containing secrets
- **Secret scanning**: gitleaks and trufflehog on every push
- **Encrypted secrets**: SOPS + age encryption for local secrets
- **Security tab integration**: Results appear in GitHub Security tab
- **Auto-fix workflow**: Automatically scan and fix vulnerabilities

## 🔄 Updating e-bash Library

This project uses the [e-bash](https://github.com/OleksandrKucherenko/e-bash) library for script utilities. To upgrade to the latest version:

```bash
# Download and run the latest installation script
curl -sSL https://git.new/e-bash | bash -s -- upgrade

# The script will:
# - Read .ebashrc configuration (custom directory: scripts/lib)
# - Upgrade e-bash to the latest master branch version
# - Preserve CI-specific customizations
# - Update mise.toml integration automatically
```

**What gets updated:**
- All library files in `scripts/lib/` (via git subtree)
- CI customizations are preserved (stderr suppression in colors)
- Version tracked in git commits for easy rollback

**Check current version:**
```bash
grep "Version:" scripts/lib/_hooks.sh
# Should show: ## Version: 1.12.6 (or later)
```

**Rollback if needed:**
```bash
# The installation script saves previous version for rollback
./install.e-bash.sh rollback
```

**Custom installation directory:**
- Configuration in `.ebashrc` specifies `E_BASH_INSTALL_DIR="scripts/lib"`
- Do not manually edit `.ebashrc` - it's auto-generated by the installer
- mise.toml uses `{{env.E_BASH_INSTALL_DIR}}` for dynamic path resolution

## 🆕 What's New in v2.0

**Script Organization:**
- Spaced numbering (10, 20, 30...) allows easy insertion of new scripts
- Logical grouping by function (GitHub ops, docs, registry publishing)
- Modular mise configuration in `.config/mise/conf.d/`

**Development Quality:**
- Enforced conventional commits with commitlint + commitizen
- Auto-fix security workflow for automatic vulnerability scanning
- Faster, more reliable git hooks using Lefthook

**Enhanced Workflows:**
- Granular reporting with workflow-specific status scripts
- Fine-grained release control (version selection, stability tagging, rollback)
- Environment directory structure for multi-environment deployments

**Upgrading from v1.x?** See [Migration Guide](docs/MIGRATION.md)

## 📖 Learning Resources

- [Semantic Versioning](https://semver.org/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Keep a Changelog](https://keepachangelog.com/)
- [GitHub Actions Docs](https://docs.github.com/en/actions)

## 🤝 Contributing

1. Check [existing issues](https://github.com/YOUR-USERNAME/ci-excellence/issues)
2. Create a detailed issue for bugs or feature requests
3. Submit pull requests with conventional commit messages

## 📄 License

MIT License - feel free to customize and use in your projects.

## 🆘 Need Help?

- **Common issues:** [Troubleshooting Guide](docs/TROUBLESHOOTING.md)
- **Questions:** [GitHub Discussions](https://github.com/YOUR-USERNAME/ci-excellence/discussions)
- **Bugs:** [GitHub Issues](https://github.com/YOUR-USERNAME/ci-excellence/issues)
- **Documentation:** Browse [docs/](docs/) for detailed information

---

**Happy Building! 🚀**

Start simple with basic CI, then progressively enable features as your project grows.
