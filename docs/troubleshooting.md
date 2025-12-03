# CI Excellence Framework - Troubleshooting Guide

## 📋 Table of Contents

- [Common Issues](#common-issues)
- [Setup Problems](#setup-problems)
- [Build Issues](#build-issues)
- [Deployment Issues](#deployment-issues)
- [Security Issues](#security-issues)
- [Performance Issues](#performance-issues)
- [Debug Mode](#debug-mode)
- [Getting Help](#getting-help)

## 🔧 Common Issues

### Script Permission Errors

**Problem**: Permission denied when running scripts

```bash
$ ./scripts/build/10-ci-compile.sh
bash: ./scripts/build/10-ci-compile.sh: Permission denied
```

**Solution**:
```bash
# Make all scripts executable
chmod +x scripts/**/*.sh

# Or recursively fix permissions
find scripts/ -name "*.sh" -exec chmod +x {} \;
```

**Prevention**:
- Add `chmod +x scripts/**/*.sh` to setup scripts
- Include in `mise run dev-setup` task

### Git Hook Issues

**Problem**: Pre-commit hooks failing or not running

```bash
$ git commit
husky - pre-commit
Error: Hook 'pre-commit' is not a git command.
```

**Solution**:
```bash
# Reinstall git hooks
mise run uninstall-hooks
mise run install-hooks

# Check hook status
cat .git/hooks/pre-commit
```

**Problem**: `lefthook install` fails with `/dev/null/commit-msg: not a directory`

```bash
$ lefthook install
sync hooks: ❌
│  Error: could not replace the hook: stat /dev/null/commit-msg: not a directory
```

**Root cause**: `core.hooksPath` is pointed at `/dev/null` (often from disabling hooks in another repo), so lefthook cannot write into the hooks directory.

**Solution**:
```bash
# Confirm the misconfiguration and its source
git config --show-origin --get core.hooksPath

# Unset the value and reinstall hooks
git config --unset core.hooksPath
lefthook install
```

**Verification**:
```bash
git config --get core.hooksPath   # should be empty (defaults to .git/hooks)
lefthook list                     # shows installed hooks without errors
```

### Missing Tools

**Problem**: Required tools not found

```bash
$ mise run verify-tools
❌ Error: gitleaks not found
```

**Solution**:
```bash
# Run full setup to install all tools
mise run dev-setup

# Install specific tool
mise install gitleaks
```

### Secret Decryption Issues

**Problem**: Cannot decrypt encrypted files

```bash
$ mise run decrypt-production
Error: SOPS decryption failed
```

**Solution**:
```bash
# Check age key file
ls -la .secrets/mise-age.txt

# Regenerate if missing
mise run generate-age-key

# Verify file permissions
chmod 600 .secrets/mise-age.txt
```

## 🛠️ Setup Problems

### MISE Installation

**Problem**: MISE installation fails

```bash
$ curl https://mise.run | sh
Error: curl command not found
```

**Solution**:
```bash
# Install curl first
sudo apt update && sudo apt install -y curl

# Then install MISE
curl https://mise.run | sh

# Alternative installation
curl --proto '=https' --tlsv1.2 -sSf https://mise.run | sh
```

### Shell Integration Issues

**Problem**: Shell integration not working

```bash
$ ./scripts/shell/setup-shell-integration.sh zsh
Plugin not found
```

**Solution**:
```bash
# Check shell type
echo $SHELL

# Use correct shell name
./scripts/shell/setup-shell-integration.sh bash

# Install dependencies
mise run verify-tools
```

### Environment Variables

**Problem**: Environment variables not loaded

```bash
$ echo $CI_COMMIT_SHA
(empty)
```

**Solution**:
```bash
# Check environment setup
mise profile status

# Reload shell configuration
source ~/.zshrc

# Check mise activation
mise exec zsh
```

## 🔨 Build Issues

### Build Failures

**Problem**: Build script fails

```bash
$ ./scripts/build/10-ci-compile.sh
❌ Build failed with exit code 1
```

**Solution**:
```bash
# Enable debug logging
export LOG_LEVEL=debug
./scripts/build/10-ci-compile.sh

# Check build prerequisites
./scripts/build/10-ci-compile.sh validate

# Run dry run
DRY_RUN=true ./scripts/build/10-ci-compile.sh
```

### Linting Errors

**Problem**: ShellCheck finds issues

```bash
$ mise run lint
❌ ShellCheck found issues in scripts/ci/50-ci-auto-format.sh
```

**Solution**:
```bash
# Auto-fix formatting issues
./scripts/ci/60-ci-auto-lint-fix.sh

# Manual review
shellcheck scripts/**/*.sh

# Run after fixes
mise run lint
```

### Test Failures

**Problem**: Tests failing

```bash
$ mise run test
❌ Test suite failed
```

**Solution**:
```bash
# Run specific test file
shellspec spec/scripts/failing_script_spec.sh

# Run with verbose output
shellspec spec/scripts/failing_script_spec.sh --verbose

# Check test environment
export CI_TEST_MODE=test
mise run test
```

## 🚀 Deployment Issues

### Staging Deployment Failures

**Problem**: Staging deployment fails validation

```bash
$ ./scripts/deployment/10-ci-deploy-staging.sh deploy
❌ Deployment validation failed
```

**Solution**:
```bash
# Check validation errors
./scripts/deployment/10-ci-deploy-staging.sh validate --verbose

# Force deploy (not recommended for production)
FORCE_DEPLOY=true ./scripts/deployment/10-ci-deploy-staging.sh deploy

# Check environment setup
mise profile status
```

### Production Deployment Issues

**Problem**: Production deployment requires approval

```bash
$ ./scripts/deployment/20-ci-deploy-production.sh deploy
❌ Production deployment requires approval
```

**Solution**:
```bash
# Add production approval
export PRODUCTION_APPROVED=true
./scripts/deployment/20-ci-deploy-production.sh deploy

# Or use GitHub Actions for approval workflow
```

### Rollback Failures

**Problem**: Rollback operation fails

```bash
$ ./scripts/deployment/30-ci-rollback.sh production deploy-123
❌ Rollback validation failed
```

**Solution**:
```bash
# Add rollback confirmation
export CONFIRM_PRODUCTION_ROLLBACK=true
./scripts/deployment/30-ci-rollback.sh production deploy-123

# Use safer rollback strategy
./scripts/deployment/30-ci-rollback.sh production deploy-123 previous_tag
```

## 🔒 Security Issues

### Secret Detection

**Problem**: Secrets found in code

```bash
$ mise run scan-secrets
❌ Secrets detected in repository
```

**Solution**:
```bash
# Review detected secrets
cat .security/gitleaks-report.json

# Remove secrets from code
# Use environment variables instead
# Rotate any committed secrets immediately
```

### Permission Issues

**Problem**: File permission errors

```bash
Error: Permission denied accessing config file
```

**Solution**:
```bash
# Check file permissions
ls -la environments/production/config.yml

# Fix permissions if needed
chmod 600 environments/production/config.yml

# Check ownership
ls -la environments/
```

### Authentication Issues

**Problem**: AWS credentials not working

```bash
$ aws s3 ls
Unable to locate credentials
```

**Solution**:
```bash
# Check AWS credentials
aws configure list

# Set up credentials
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"

# Use MISE profiles for environment-specific credentials
mise profile activate production
```

## ⚡ Performance Issues

### Slow Pipeline Execution

**Problem**: CI pipeline taking too long

```bash
Pipeline completed in 15 minutes
```

**Solution**:
```bash
# Enable performance monitoring
export CI_PERFORMANCE_MONITORING=true

# Optimize caching
export CI_CACHE_ENABLED=true

# Use parallel execution
export CI_PARALLEL_JOBS=4
```

### Memory Issues

**Problem**: Out of memory errors

```bash
Killed signal 9 (SIGKILL)
```

**Solution**:
```bash
# Reduce memory usage
export CI_MEMORY_LIMIT="2GB"

# Optimize script memory usage
# Check for memory leaks in long-running processes

# Use streaming for large files
# Process data in chunks
```

### Disk Space Issues

**Problem**: Out of disk space

```bash
No space left on device
```

**Solution**:
```bash
# Run cleanup
./scripts/maintenance/10-ci-cleanup.sh

# Reduce cleanup retention
export CLEANUP_DAYS=7
./scripts/maintenance/10-ci-cleanup.sh

# Clear caches
mise cache clear
```

## 🐛 Debug Mode

### Enabling Debug Mode

```bash
# Global debug mode
export LOG_LEVEL=debug

# Test mode
export CI_TEST_MODE=dry_run

# Script-specific debug mode
export SCRIPT_DEBUG=true
```

### Debug Output

```bash
# Verbose logging
./scripts/your-script.sh --verbose

# Debug mode
./scripts/your-script.sh --debug

# Dry run mode
DRY_RUN=true ./scripts/your-script.sh
```

### Environment Debugging

```bash
# Show current environment
mise profile show

# Show loaded configurations
env | grep CI_

# Check active hooks
lefthook list
```

### Error Tracing

```bash
# Enable shell tracing
set -x

# Enable function tracing
set -x && ./scripts/your-script.sh

# Use bash debug mode
bash -x ./scripts/your-script.sh
```

## 🆘 Getting Help

### Script Help

```bash
# Get help for specific script
./scripts/deployment/10-ci-deploy-staging.sh --help

# Show usage examples
./scripts/deployment/10-ci-deploy-staging.sh --examples
```

### Framework Help

```bash
# Show available tasks
mise run --help

# Show task descriptions
mise run --list

# Get help for commands
mise run help <command>
```

### Documentation

```bash
# Read comprehensive guides
cat docs/developer-guide.md
cat docs/script-development.md

# Check quick start
cat quickstart.md

# Check troubleshooting
cat docs/troubleshooting.md  # This file!
```

### Community Support

```bash
# Check for issues
gh issue list

# Search existing issues
gh issue search "deployment failure"

# Create new issue
gh issue create --title "Problem description" --body "Detailed description"
```

### Monitoring and Alerts

```bash
# Check system health
./scripts/maintenance/50-ci-health-check.sh

# Run security audit
./scripts/maintenance/20-ci-security-audit.sh

# Generate status report
./scripts/deployment/10-ci-deploy-staging.sh status
```

## 🔧 Advanced Troubleshooting

### Diagnostic Commands

```bash
# System diagnostics
echo "=== System Diagnostics ==="
echo "OS: $(uname -s)"
echo "Shell: $SHELL"
echo "MISE Version: $(mise --version)"
echo "Git Version: $(git --version)"

# CI/CD diagnostics
echo -e "\n=== CI/CD Diagnostics ==="
echo "Current Profile: $(mise profile current 2>/dev/null || echo 'None')"
echo "Available Profiles: $(mise profile list | head -10)"
echo "Hooks Status: $(lefthook list 2>/dev/null | grep -c 'pre-\w+')"

# Environment diagnostics
echo -e "\n=== Environment Diagnostics ==="
echo "Working Directory: $(pwd)"
echo "Git Repository: $(git rev-parse --show-toplevel 2>/dev/null || echo 'Not a git repo')"
echo "Git Branch: $(git branch --show-current 2>/dev/null || echo 'Not on any branch')"
echo "Git Commit: $(git rev-parse HEAD 2>/dev/null || echo 'No commits')"
echo "Git Status: $(git status --porcelain 2>/dev/null | wc -l) modified files"
```

### Log Analysis

```bash
# Check recent logs
echo "=== Recent Logs ==="
find .logs -name "*.log" -mtime -7 -exec echo "=== {} ===" \; -exec tail -20 {} \;

# Check error logs
echo -e "\n=== Error Logs ==="
grep -r "ERROR" .logs/ 2>/dev/null | tail -20

# Check security logs
echo -e "\n=== Security Logs ==="
grep -r "security" .logs/ 2>/dev/null | tail -20
```

### Performance Analysis

```bash
# Check script performance
time ./scripts/build/10-ci-compile.sh

# Check memory usage
/usr/bin/time -v ./scripts/build/10-ci-compile.sh

# Profile script execution
bash -x ./scripts/build/10-ci-compile.sh 2>&1 | time -p
```

This comprehensive troubleshooting guide should help you resolve most common issues and get help when needed. Remember that debug mode and verbose logging are your best friends when troubleshooting complex issues.
