# Migration Guide

Guide for upgrading from older versions of CI Excellence.

## Table of Contents

- [Version 2.0](#version-20)
- [Breaking Changes](#breaking-changes)
- [Migration Steps](#migration-steps)
- [Rollback Procedure](#rollback-procedure)

## Version 2.0

### Overview

Version 2.0 introduces significant improvements to script organization, configuration management, and development workflows. This is a **major release** with breaking changes.

### What's New

**Script Organization:**
- ✨ Spaced numbering system (10, 20, 30...) instead of sequential (01, 02, 03...)
- 📁 Logical grouping of release scripts by function
- 🔄 Easier to insert new scripts between existing ones

**Development Quality:**
- 🔒 Enforced conventional commits with commitlint and commitizen
- 🛡️ Auto-fix security workflow for automatic vulnerability scanning
- 🎣 Lefthook-based git hooks (faster, more reliable)

**Configuration:**
- 🗂️ Modular mise configuration split into `.config/mise/conf.d/` files
- 📝 TOML format for lefthook (`.lefthook.toml`)
- 🎯 Better organized tool configurations

**Workflows:**
- 📊 Granular reporting with workflow-specific status scripts
- 🎯 Fine-grained release control scripts
- 🌍 Environment directory structure for multi-environment deployments

## Breaking Changes

### 1. Script Renumbering

**Old (v1.x):**
```
scripts/ci/build/ci-01-compile.sh
scripts/ci/build/ci-02-lint.sh
scripts/ci/build/ci-03-security-scan.sh
scripts/ci/build/ci-04-bundle.sh
```

**New (v2.0):**
```
scripts/ci/build/ci-10-compile.sh
scripts/ci/build/ci-20-lint.sh
scripts/ci/build/ci-30-security-scan.sh
scripts/ci/build/ci-40-bundle.sh
```

**Impact:** Any custom workflows or scripts referencing the old paths will break.

### 2. Configuration Files

**Changed:**
- `lefthook.yml` → `.lefthook.toml` (TOML format)
- `mise.toml` → Modular configs in `.config/mise/conf.d/`

**Added:**
- `.commitlintrc.yaml` - Commit message linting
- `.cz.yaml` - Commitizen configuration

### 3. Removed Files

**Deleted templates:**
- `config/package.json.template` - Use project-specific package.json
- `config/Dockerfile.template` - Use project-specific Dockerfile
- `config/docker-compose.yml.template` - Use project-specific compose file
- `scripts/notify/*.ts` - Replaced by shell-based notifications

**Reason:** These templates were rarely used and added maintenance burden.

### 4. Conventional Commits Required

Commits now **must** follow [Conventional Commits](https://www.conventionalcommits.org/) format:

```
<type>(<scope>): <subject>
```

**Enforced by:** Git hooks (pre-commit)

**Examples:**
```bash
feat: add new feature
fix: resolve bug
docs: update documentation
```

### 5. New Git Hooks

**Old:** Basic secret scanning
**New:** Comprehensive validation
- Secret scanning (gitleaks, trufflehog)
- Commit message validation (commitlint)
- Workflow file validation
- Branch protection

## Migration Steps

### Step 1: Backup Current State

```bash
# Create backup branch
git checkout -b backup-v1
git push origin backup-v1

# Return to main branch
git checkout main
```

### Step 2: Pull Latest Changes

```bash
# Fetch and merge v2.0
git pull origin main

# Or if you forked, fetch upstream
git fetch upstream
git merge upstream/main
```

### Step 3: Update Mise and Tools

```bash
# Let mise detect and install new tools
cd /path/to/project

# Mise will automatically:
# - Update configuration
# - Install new tools (commitizen, commitlint)
# - Install git hooks

# Verify installation
mise doctor
```

### Step 4: Update Custom Workflows

If you have custom workflows referencing CI scripts, update the paths:

```bash
# Find all references to old script paths
grep -r "ci-01-" .github/workflows/
grep -r "ci-02-" .github/workflows/
grep -r "ci-03-" .github/workflows/

# Replace with new paths:
# ci-01-* → ci-10-*
# ci-02-* → ci-20-*
# ci-03-* → ci-30-*
# etc.
```

**Example:**

```yaml
# Old
- name: Compile
  run: ./scripts/ci/build/ci-01-compile.sh

# New
- name: Compile
  run: ./scripts/ci/build/ci-10-compile.sh
```

### Step 5: Update Custom Scripts

If you have custom scripts calling CI scripts, update them:

```bash
# Find custom scripts
find scripts -type f -name "*.sh" | grep -v "ci/"

# Update any that reference old ci-XX-* paths
```

### Step 6: Migrate Configuration Files

**If you customized `lefthook.yml`:**

```bash
# Backup your customizations
cp lefthook.yml lefthook.yml.backup

# Review new .lefthook.toml
cat .lefthook.toml

# Migrate your customizations to TOML format
# See: https://github.com/evilmartians/lefthook/blob/master/docs/configuration.md
```

**If you customized `mise.toml`:**

```bash
# Backup your mise.toml
cp mise.toml mise.toml.backup

# Review new modular structure
ls -la .config/mise/conf.d/

# Migrate customizations to appropriate conf.d/*.toml files
```

### Step 7: Test Git Hooks

```bash
# Test commit message validation
echo "test" > test.txt
git add test.txt
git commit -m "bad message"
# Should fail with commit message error

# Use proper format
git commit -m "feat: add test file"
# Should succeed

# Or use commitizen
git cz
# Interactive prompt for conventional commit
```

### Step 8: Test Workflows

```bash
# Validate workflow files
mise run validate-workflows

# Or manually
action-validator .github/workflows/*.yml

# Make a test commit to trigger CI
git commit --allow-empty -m "ci: test v2.0 workflows"
git push
```

### Step 9: Update Documentation

If you have custom documentation:

```bash
# Update any references to:
# - Old script paths
# - Old configuration files
# - Removed templates
```

### Step 10: Clean Up

```bash
# Remove backup files
rm -f lefthook.yml.backup
rm -f mise.toml.backup

# Verify everything works
mise run validate-workflows
lefthook run pre-commit
```

## Rollback Procedure

If you need to roll back to v1.x:

### Option 1: Restore from Backup Branch

```bash
# Switch to backup branch
git checkout backup-v1

# Force push to main (DESTRUCTIVE!)
git push origin backup-v1:main --force
```

### Option 2: Revert the Merge

```bash
# Find the merge commit
git log --oneline --graph

# Revert the merge
git revert -m 1 <merge-commit-hash>

# Push
git push origin main
```

### Option 3: Cherry-pick Specific Changes

```bash
# Return to main
git checkout main

# Cherry-pick specific commits you want to keep
git cherry-pick <commit-hash>

# Reset to before migration
git reset --hard HEAD~5  # Adjust number as needed

# Force push (DESTRUCTIVE!)
git push --force
```

## Post-Migration Checklist

After migration, verify:

- [ ] Mise is working: `mise doctor`
- [ ] Git hooks are installed: `ls -la .git/hooks/`
- [ ] Workflows validate: `mise run validate-workflows`
- [ ] Commits require conventional format
- [ ] CI pipeline runs successfully
- [ ] All GitHub Variables are still set
- [ ] All GitHub Secrets are still set
- [ ] Notifications still work (if enabled)
- [ ] Custom scripts still work
- [ ] Documentation is updated

## Getting Help

If you encounter issues during migration:

1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. Review the [changelog](../CHANGELOG.md)
3. Open an [issue](https://github.com/YOUR-USERNAME/ci-excellence/issues)
4. Join [discussions](https://github.com/YOUR-USERNAME/ci-excellence/discussions)

## See Also

- [Installation Guide](INSTALLATION.md) - Fresh installation
- [Workflows](WORKFLOWS.md) - Workflow documentation
- [Customization](CUSTOMIZATION.md) - Customizing for your project
- [Troubleshooting](TROUBLESHOOTING.md) - Common issues
