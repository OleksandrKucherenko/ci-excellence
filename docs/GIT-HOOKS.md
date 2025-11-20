# Git Hooks and Secret Detection

This project uses automated git hooks and secret detection tools to prevent accidental commits of sensitive information.

## 🔒 Security Tools

### Lefthook
Git hooks manager that runs security checks automatically.

### Gitleaks
Detects hardcoded secrets, passwords, and API keys in your code.

### Trufflehog
Finds leaked credentials and verifies if they're still active.

## 🚀 Quick Setup

If you're using **mise**, hooks are installed automatically:
```bash
cd ci-excellence  # Hooks install automatically via mise
```

**Manual installation:**
```bash
lefthook install
```

## 🎯 What Gets Checked

### Pre-Commit (Before Each Commit)
- ✅ **Secret detection** on staged files (gitleaks)
- ✅ **Credential scanning** on staged files (trufflehog)
- ✅ **Branch protection** (prevents direct commits to main/master)

### Pre-Push (Before Each Push)
- ✅ **Full secret scan** of commits being pushed (gitleaks)
- ✅ **Full credential scan** (trufflehog)

### CI Pipeline
- ✅ **Repository-wide secret scan**
- ✅ **Historical commit scanning**
- ✅ **Dependency vulnerability checks**

## 📋 Common Scenarios

### Blocked Commit - Secret Detected

```bash
git commit -m "feat: add feature"

❌ Gitleaks found potential secrets!
   File: config.js
   Secret: GitHub token on line 42
```

**Solution:**
1. Remove the secret from the file
2. Use environment variables or encrypted secrets instead
3. Commit again

### Blocked Commit - Direct to Main

```bash
git commit -m "feat: add feature"

❌ Direct commits to main/master are not allowed!
   Create a feature branch instead:
   git checkout -b feature/your-feature-name
```

**Solution:**
```bash
git checkout -b feature/my-feature
git commit -m "feat: add feature"
```

### Accidentally Committed a Secret

If you already committed a secret:

1. **Don't push!** Remove it first:
   ```bash
   git reset HEAD~1  # Undo last commit
   # Remove secret from file
   git add .
   git commit -m "feat: add feature (without secret)"
   ```

2. **If already pushed:**
   - Rotate the secret immediately
   - Use `git filter-branch` or BFG Repo Cleaner to remove from history
   - Force push (⚠️ dangerous, coordinate with team)

## ⚙️ Configuration Files

### lefthook.yml
Main git hooks configuration. Defines what runs when.

**Customize:**
```yaml
pre-commit:
  commands:
    gitleaks-staged:
      run: gitleaks protect --staged --redact --verbose
```

### .gitleaks.toml
Gitleaks configuration with custom rules and allowlists.

**Add custom rule:**
```toml
[[rules]]
id = "my-custom-secret"
description = "My Custom Secret Pattern"
regex = '''my-secret-[0-9a-f]{32}'''
tags = ["key", "custom"]
```

**Allowlist path:**
```toml
[allowlist]
paths = [
    '''path/to/safe/file\.txt$''',
]
```

### .trufflehog.yaml
Trufflehog configuration for credential detection.

**Exclude paths:**
```yaml
exclude-paths:
  - "tests/**"
  - "docs/**"
```

## 🛠️ Manual Commands

### Scan for Secrets
```bash
# Scan staged files
gitleaks protect --staged --redact --verbose

# Scan entire repository
gitleaks detect --redact --verbose

# Using mise
mise run scan-secrets
```

### Scan for Credentials
```bash
# Scan with trufflehog
trufflehog git file://. --only-verified

# Using mise
mise run scan-history
```

### Skip Hooks (Use Carefully!)
```bash
# Skip pre-commit hook
git commit --no-verify -m "fix: urgent hotfix"

# Skip pre-push hook
git push --no-verify
```

**⚠️ Only use --no-verify for emergencies!**

## 🔧 Troubleshooting

### "lefthook: command not found"

**Solution:**
```bash
# Using mise (recommended)
mise install lefthook

# Or manually
brew install lefthook  # macOS
# Or download from: https://github.com/evilmartians/lefthook/releases
```

### "gitleaks: command not found"

**Solution:**
```bash
# Using mise (recommended)
mise install gitleaks

# Or manually
brew install gitleaks  # macOS
```

### Hooks Not Running

**Check installation:**
```bash
ls -la .git/hooks/
# Should see: pre-commit, pre-push files
```

**Reinstall hooks:**
```bash
lefthook install
```

**Check lefthook status:**
```bash
lefthook run --help
```

### False Positives

If gitleaks reports a false positive:

1. **Add to allowlist** in `.gitleaks.toml`:
   ```toml
   [allowlist]
   regexes = [
       '''your-false-positive-pattern''',
   ]
   ```

2. **Or exclude the file:**
   ```toml
   [allowlist]
   paths = [
       '''path/to/file\.txt$''',
   ]
   ```

### Disable Specific Hook Temporarily

**Edit lefthook.yml:**
```yaml
pre-commit:
  commands:
    gitleaks-staged:
      skip: true  # Temporarily disable
```

## 📚 Best Practices

### ✅ DO

- **Use environment variables** for secrets
- **Use encrypted secrets** (.env.secrets.json with SOPS)
- **Commit often** to catch secrets early
- **Review scan reports** and fix issues
- **Keep tools updated** (`mise upgrade`)

### ❌ DON'T

- Don't commit API keys, tokens, or passwords
- Don't use `--no-verify` regularly
- Don't ignore security warnings
- Don't commit `.env` files
- Don't hardcode credentials

## 🎓 How It Works

### Local Hooks (Lefthook)

1. **You commit** → Pre-commit hook runs
2. **Gitleaks scans** staged files
3. **Trufflehog scans** staged files
4. **If secrets found** → Commit blocked
5. **If clean** → Commit proceeds

### CI Pipeline

1. **Code pushed** → CI workflow triggers
2. **Security scan job** runs
3. **Gitleaks scans** entire repository
4. **Trufflehog scans** commit history
5. **Report generated** → Uploaded to GitHub Security

## 📖 Additional Resources

- **Lefthook**: https://github.com/evilmartians/lefthook
- **Gitleaks**: https://github.com/gitleaks/gitleaks
- **Trufflehog**: https://github.com/trufflesecurity/trufflehog
- **Git Hooks**: https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks

## 🆘 Getting Help

**Test hooks manually:**
```bash
lefthook run pre-commit
lefthook run pre-push
```

**Verbose mode:**
```bash
LEFTHOOK_VERBOSE=1 lefthook run pre-commit
```

**Check configuration:**
```bash
lefthook dump
```

---

**Questions?** Check the tool documentation or ask the team!
