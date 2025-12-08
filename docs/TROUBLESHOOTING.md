# Troubleshooting Guide

Common issues and their solutions.

## Table of Contents

- [Pipeline Issues](#pipeline-issues)
- [Mise Issues](#mise-issues)
- [Git Issues](#git-issues)
- [Secret Management Issues](#secret-management-issues)
- [Workflow Issues](#workflow-issues)
- [Platform-Specific Issues](#platform-specific-issues)

## Pipeline Issues

### Pipeline Not Running

**Symptoms:**
- Workflow doesn't appear in Actions tab
- No jobs triggered after push

**Solutions:**

1. **Check workflow file location:**
   ```bash
   ls -la .github/workflows/
   # Files should be in this directory
   ```

2. **Validate YAML syntax:**
   ```bash
   mise run validate-workflows
   # Or use action-validator directly
   action-validator .github/workflows/*.yml
   ```

3. **Check branch name matches triggers:**
   ```yaml
   # In workflow file
   on:
     push:
       branches:
         - main
         - develop  # Make sure your branch matches
   ```

4. **Verify workflow is enabled:**
   - Go to Actions tab
   - Find the workflow
   - Make sure it's not disabled

### Job Skipped

**This is normal behavior!** Jobs skip when their `ENABLE_*` variable is not set to `true`.

**To enable a job:**

1. Go to **Settings > Secrets and variables > Actions > Variables**
2. Click **"New repository variable"**
3. Name: `ENABLE_<JOB_NAME>` (e.g., `ENABLE_COMPILE`)
4. Value: `true`
5. Click **"Add variable"**

**Example:**
```
Name: ENABLE_UNIT_TESTS
Value: true
```

### Script Permission Denied

**Symptoms:**
```
Permission denied: ./scripts/ci/build/ci-10-compile.sh
```

**Solution:**

```bash
# Make all scripts executable
find scripts -type f -name "*.sh" -exec chmod +x {} \;

# Commit changes
git add scripts/
git commit -m "fix: make scripts executable"
git push
```

### NPM Publishing Fails

**Symptoms:**
```
npm ERR! 403 Forbidden
npm ERR! You cannot publish over the previously published versions
```

**Solutions:**

1. **Check NPM_TOKEN secret is set:**
   - Go to **Settings > Secrets and variables > Actions > Secrets**
   - Verify `NPM_TOKEN` exists

2. **Verify token has publish permissions:**
   - Go to npmjs.com
   - Settings > Access Tokens
   - Make sure token type is "Automation" or "Publish"

3. **Check package name availability:**
   ```bash
   npm view your-package-name
   # If it exists, choose a different name or scope it: @yourorg/package-name
   ```

4. **Version conflict:**
   - You're trying to republish the same version
   - Bump version in package.json before publishing

### Docker Build Fails

**Symptoms:**
```
Error: denied: permission_denied
```

**Solutions:**

1. **Check Docker secrets:**
   - `DOCKER_USERNAME` - Your Docker Hub username
   - `DOCKER_PASSWORD` - Your Docker Hub password or access token

2. **Verify Dockerfile exists:**
   ```bash
   ls -la Dockerfile
   ```

3. **Check image name format:**
   ```bash
   # Correct format: username/image-name
   IMAGE_NAME="myuser/myapp"

   # For organizations: org/image-name
   IMAGE_NAME="myorg/myapp"
   ```

4. **Test locally:**
   ```bash
   docker build -t test-image .
   docker run test-image
   ```

## Mise Issues

### Mise Command Not Found

**Symptoms:**
```bash
bash: mise: command not found
```

**Solutions:**

1. **Check mise is installed:**
   ```bash
   which mise
   # Should return path to mise
   ```

2. **Install mise if missing:**
   ```bash
   curl https://mise.run | sh
   ```

3. **Add mise activation to shell:**
   ```bash
   # For bash (~/.bashrc or ~/.bash_profile)
   echo 'eval "$(mise activate bash)"' >> ~/.bashrc
   source ~/.bashrc

   # For zsh (~/.zshrc)
   echo 'eval "$(mise activate zsh)"' >> ~/.zshrc
   source ~/.zshrc
   ```

4. **Check PATH:**
   ```bash
   echo $PATH | grep mise
   # Should contain mise directory
   ```

### Mise Tools Not Installing

**Symptoms:**
```
Failed to install tool: gitleaks
```

**Solutions:**

1. **Trust the project configuration:**
   ```bash
   mise trust
   ```

2. **Install tools manually:**
   ```bash
   mise install
   ```

3. **Check mise doctor:**
   ```bash
   mise doctor
   ```

4. **Update mise:**
   ```bash
   # Homebrew
   brew upgrade mise

   # Or curl
   curl https://mise.run | sh
   ```

### Git Hooks Not Running

**Symptoms:**
- Can commit without validation
- No secret scanning happening

**Solutions:**

1. **Reinstall hooks:**
   ```bash
   mise run install-hooks
   # Or directly
   lefthook install
   ```

2. **Check lefthook is installed:**
   ```bash
   which lefthook
   mise list
   ```

3. **Verify hook files exist:**
   ```bash
   ls -la .git/hooks/
   # Should see pre-commit, commit-msg, etc.
   ```

4. **Test hooks manually:**
   ```bash
   lefthook run pre-commit
   ```

## Git Issues

### Commit Message Rejected

**Symptoms:**
```
⧗ input: bad commit message
✖ subject may not be empty
✖ type may not be empty
```

**Solution:**

Your commit message doesn't follow [Conventional Commits](https://www.conventionalcommits.org/) format.

**Use commitizen for guided commits:**
```bash
git add .
cz commit
# Or
git cz
```

**Or format manually:**
```bash
git commit -m "feat: add new feature"
git commit -m "fix: resolve bug in authentication"
git commit -m "docs: update installation guide"
```

**Required format:**
```
<type>(<scope>): <subject>

[body]

[footer]
```

### SSH Key Permission Denied

**Symptoms:**
```
Permission denied (publickey)
```

**Solutions:**

1. **Check SSH key is added to GitHub:**
   ```bash
   cat ~/.ssh/id_ed25519.pub
   # Copy and add to: GitHub Settings > SSH and GPG keys
   ```

2. **Test SSH connection:**
   ```bash
   ssh -T git@github.com
   # Should see: "Hi username! You've successfully authenticated..."
   ```

3. **Add key to ssh-agent:**
   ```bash
   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/id_ed25519
   ```

4. **Check git remote:**
   ```bash
   git remote -v
   # Should use SSH: git@github.com:user/repo.git
   # Not HTTPS: https://github.com/user/repo.git
   ```

### Line Ending Issues (Windows/WSL)

**Symptoms:**
- Git shows all files as modified
- "CRLF will be replaced with LF" warnings

**Solutions:**

```bash
# Configure line endings for project
git config --local core.autocrlf false
git config --local core.eol lf

# Reset all files
git rm --cached -r .
git reset --hard
```

## Secret Management Issues

### Age Key Not Found

**Symptoms:**
```
⚠ Age encryption key not found
  Run: mise run generate-age-key
```

**Solution:**

```bash
# Generate new age key
mise run generate-age-key

# This creates: .secrets/mise-age.txt
# Keep this file safe and never commit it!
```

### Cannot Decrypt Secrets

**Symptoms:**
```
Error: failed to decrypt
```

**Solutions:**

1. **Verify age key exists:**
   ```bash
   ls -la .secrets/mise-age.txt
   ```

2. **Check SOPS configuration:**
   ```bash
   cat .sops.yaml
   ```

3. **Decrypt manually to test:**
   ```bash
   mise run decrypt-secrets
   ```

4. **Re-encrypt if needed:**
   ```bash
   cp .env.secrets.json.tmp .env.secrets.json
   mise run encrypt-secrets
   ```

### Secrets Not Loading in Scripts

**Symptoms:**
- Environment variables are empty
- Scripts can't access secrets

**Solutions:**

1. **Check secrets file exists:**
   ```bash
   ls -la .env.secrets.json
   ```

2. **Verify decryption works:**
   ```bash
   mise run decrypt-secrets
   ```

3. **Check mise configuration:**
   ```bash
   cat .config/mise/conf.d/00-secrets.toml
   ```

## Workflow Issues

### Workflow Validation Fails

**Symptoms:**
```
Error: workflow validation failed
```

**Solutions:**

1. **Run validator locally:**
   ```bash
   mise run validate-workflows
   ```

2. **Check YAML syntax:**
   ```bash
   # Use yamllint
   yamllint .github/workflows/*.yml
   ```

3. **Verify workflow structure:**
   - Check indentation (use spaces, not tabs)
   - Verify all required fields are present
   - Check for syntax errors

4. **Use GitHub's workflow editor:**
   - Edit file directly on GitHub
   - It provides real-time validation

### Notification Not Sending

**Symptoms:**
- Pipeline completes but no notification received

**Solutions:**

1. **Check ENABLE_NOTIFICATIONS:**
   ```bash
   # Should be set to 'true' in GitHub Variables
   ```

2. **Verify APPRISE_URLS secret:**
   - Go to **Settings > Secrets**
   - Check `APPRISE_URLS` is set

3. **Test notification URL:**
   ```bash
   # Install apprise locally
   pip install apprise

   # Test notification
   apprise -b "Test message" "your-notification-url"
   ```

4. **Check logs:**
   - Go to failed workflow run
   - Check notification step logs

## Platform-Specific Issues

### macOS Issues

**Homebrew Installation Fails:**
```bash
# Update Homebrew
brew update
brew doctor

# Reinstall mise
brew uninstall mise
brew install mise
```

**Permission Issues:**
```bash
# Fix Homebrew permissions
sudo chown -R $(whoami) $(brew --prefix)/*
```

### Linux Issues

**apt-get Update Fails:**
```bash
# Update package lists
sudo apt-get update
sudo apt-get upgrade

# If GPG errors occur
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys <KEY>
```

**Missing Dependencies:**
```bash
# Install build essentials
sudo apt-get install build-essential curl git
```

### WSL Issues

**Slow Performance:**

1. **Clone in WSL filesystem:**
   ```bash
   # Good: /home/user/projects
   # Bad:  /mnt/c/Users/user/projects
   ```

2. **Use Windows Terminal:**
   - Download from Microsoft Store
   - Better performance than CMD/PowerShell

3. **Increase WSL memory:**
   ```bash
   # Create/edit: %USERPROFILE%\.wslconfig
   [wsl2]
   memory=4GB
   processors=2
   ```

**chmod Not Working:**

This is a known WSL issue with NTFS filesystems.

**Solution:**
```bash
# Move files to WSL filesystem
mv /mnt/c/project ~/project
cd ~/project
```

**Or use symlinks** (see [INSTALLATION.md](INSTALLATION.md#wsl-specific-chmod-workaround-if-needed))

## Getting More Help

### Check Logs

**GitHub Actions Logs:**
1. Go to **Actions** tab
2. Click on failed workflow run
3. Click on failed job
4. Expand failed step to see logs

**Local Logs:**
```bash
# Mise logs
mise doctor

# Git hooks logs
lefthook run --verbose pre-commit

# Script logs (add -x for debugging)
bash -x scripts/ci/build/ci-10-compile.sh
```

### Enable Debug Mode

**In GitHub Actions:**

Set secrets:
```
ACTIONS_STEP_DEBUG=true
ACTIONS_RUNNER_DEBUG=true
```

**In Local Scripts:**

Add to script:
```bash
set -x  # Print each command
```

### Community Support

- **Issues:** [GitHub Issues](https://github.com/YOUR-USERNAME/ci-excellence/issues)
- **Discussions:** [GitHub Discussions](https://github.com/YOUR-USERNAME/ci-excellence/discussions)
- **Documentation:** Browse all [docs](.) for detailed information

## See Also

- [Installation Guide](INSTALLATION.md) - Platform-specific setup
- [Workflows](WORKFLOWS.md) - Workflow documentation
- [Customization](CUSTOMIZATION.md) - How to customize
- [Migration Guide](MIGRATION.md) - Upgrading from older versions
