# Mise Local Development Setup

[Mise](https://mise.jit.su) is a polyglot tool version manager that helps set up your local development environment consistently across team members.

## 🎯 What Mise Provides

- **Tool Management**: Automatically installs required tools (age, sops, gitleaks, etc.)
- **Secret Management**: Encrypted secrets using SOPS and age
- **Environment Variables**: Automatic loading from `.env` and encrypted `.env.secrets.json`
- **Task Runner**: Common tasks like encrypting/decrypting secrets
- **Auto-Setup**: Runs setup scripts when entering the project directory

## 🚀 Quick Start

### 1. Install Mise

**macOS/Linux:**
```bash
curl https://mise.run | sh
```

**Or via package manager:**
```bash
# macOS
brew install mise

# Ubuntu/Debian
apt install mise

# Arch Linux
yay -S mise
```

**Activate mise in your shell:**
```bash
# Bash
echo 'eval "$(mise activate bash)"' >> ~/.bashrc

# Zsh
echo 'eval "$(mise activate zsh)"' >> ~/.zshrc

# Fish
echo 'mise activate fish | source' >> ~/.config/fish/config.fish
```

Restart your shell or run: `source ~/.bashrc` (or your shell's config)

### 2. Enter the Project Directory

```bash
cd ci-excellence
```

Mise will automatically:
- Install required tools (age, sops, gitleaks, trufflehog, lefthook)
- Create necessary directories (`.secrets`, `.codex`, `dist`)
- Run setup scripts

### 3. Generate Age Encryption Key

```bash
mise run generate-age-key
```

This creates:
- `.secrets/mise-age.txt` - Private key (KEEP SECRET!)
- `.secrets/mise-age-pub.txt` - Public key (safe to share)

**⚠️ IMPORTANT:** Back up your private key to a password manager!

### 4. Set Up Secrets

**Create secrets file:**
```bash
# Copy example
cp .env.secrets.json.example .env.secrets.json.tmp

# Edit with your actual secrets
vim .env.secrets.json.tmp

# Encrypt it
sops --encrypt --age $(cat .secrets/mise-age-pub.txt) .env.secrets.json.tmp > .env.secrets.json

# Remove temporary file
rm .env.secrets.json.tmp
```

**Or use the mise task:**
```bash
# Edit the example, then:
mise run encrypt-secrets
```

### 5. Configure Environment Variables

```bash
# Copy template
cp config/.env.template .env

# Edit with your settings (non-secret)
vim .env
```

## 📋 Available Tasks

View all tasks:
```bash
mise tasks
```

### Secret Management Tasks

**Generate age key:**
```bash
mise run generate-age-key
```

**Encrypt secrets file:**
```bash
mise run encrypt-secrets
```

**Decrypt secrets file:**
```bash
mise run decrypt-secrets
```

**Edit encrypted secrets:**
```bash
mise run edit-secrets
```

### Setup Tasks

**Run folder setup:**
```bash
mise run setup
```

## 🔐 Secret Management with SOPS

### What is SOPS?

[SOPS](https://github.com/mozilla/sops) (Secrets OPerationS) is a tool for encrypting files with multiple encryption backends. We use it with [age](https://github.com/FiloSottile/age) encryption.

### How It Works

1. **Encryption**: Secrets are encrypted with your public age key
2. **Storage**: Encrypted file is safe to commit to git
3. **Decryption**: Only users with the private key can decrypt
4. **Team Sharing**: Share public key with team, they decrypt with their own private key

### Encrypted File Format

The `.env.secrets.json` file is encrypted by SOPS:

```json
{
    "NPM_TOKEN": "ENC[AES256_GCM,data:...,iv:...,tag:...]",
    "DOCKER_PASSWORD": "ENC[AES256_GCM,data:...,iv:...,tag:...]",
    "sops": {
        "age": [{
            "recipient": "age1...",
            "enc": "..."
        }]
    }
}
```

### Manual Encryption/Decryption

**Encrypt:**
```bash
sops --encrypt --age $(cat .secrets/mise-age-pub.txt) secrets.json > secrets.enc.json
```

**Decrypt:**
```bash
sops --decrypt secrets.enc.json
```

**Edit in place:**
```bash
sops secrets.enc.json
```

## 🛠️ Installed Tools

Mise automatically installs these tools:

| Tool | Purpose | Version |
|------|---------|---------|
| **age** | Encryption for secrets | latest |
| **sops** | Secret encryption/decryption | latest |
| **gitleaks** | Detect secrets in git | latest |
| **trufflehog** | Find leaked credentials | latest |
| **lefthook** | Git hooks manager | latest |

Check installed tools:
```bash
mise list
```

Update tools:
```bash
mise upgrade
```

## 📁 Directory Structure

```
.
├── mise.toml                    # Mise configuration
├── .env                         # Local environment (not committed)
├── .env.secrets.json           # Encrypted secrets (safe to commit)
├── .env.secrets.json.example   # Example secrets file
├── .secrets/                   # Private keys directory
│   ├── .gitkeep               # Keeps directory in git
│   ├── mise-age.txt           # Private key (NEVER COMMIT!)
│   └── mise-age-pub.txt       # Public key (safe to share)
├── .codex/                     # Mise cache directory
└── scripts/setup/
    ├── 00-setup-folders.sh    # Auto-run setup script
    └── generate-age-key.sh    # Key generation script
```

## 🔄 Workflow

### Daily Development

1. **Enter project:**
   ```bash
   cd ci-excellence
   ```
   Mise automatically loads environment and secrets

2. **Work normally:**
   All environment variables are available

3. **Update secrets (if needed):**
   ```bash
   mise run edit-secrets
   ```

### Adding New Secrets

1. **Edit encrypted file:**
   ```bash
   mise run edit-secrets
   ```

2. **Add your secret:**
   ```json
   {
     "NEW_SECRET": "value"
   }
   ```

3. **Save and exit:** SOPS automatically re-encrypts

4. **Commit:**
   ```bash
   git add .env.secrets.json
   git commit -m "feat: add NEW_SECRET"
   ```

### Team Onboarding

**For new team member:**

1. **Install mise:**
   ```bash
   curl https://mise.run | sh
   ```

2. **Clone repository:**
   ```bash
   git clone <repo>
   cd ci-excellence
   ```

3. **Get private key from team:**
   - Ask a team member for the private key
   - Save to `.secrets/mise-age.txt`
   - Set permissions: `chmod 600 .secrets/mise-age.txt`

4. **Verify setup:**
   ```bash
   mise run decrypt-secrets
   ```

**Alternative: Generate own key**

If using individual keys:
1. Generate own key: `mise run generate-age-key`
2. Share public key with team
3. Team re-encrypts secrets with all public keys

## 🔒 Security Best Practices

### DO ✅

- **Keep private key secure** - Store in password manager
- **Commit encrypted secrets** - They're safe when encrypted
- **Share public key** - It's public, like an email address
- **Back up private key** - You'll need it on new machines
- **Use `.env` for local overrides** - It's in .gitignore

### DON'T ❌

- **Never commit `.env`** - It contains unencrypted values
- **Never commit private keys** - `.secrets/` is in .gitignore
- **Don't share private keys insecurely** - Use secure channels
- **Don't commit `.env.secrets.json.tmp`** - Temporary unencrypted file

## 🧪 Testing Secret Management

**Test encryption:**
```bash
echo '{"test": "secret"}' | sops --encrypt --age $(cat .secrets/mise-age-pub.txt) /dev/stdin
```

**Test decryption:**
```bash
mise run decrypt-secrets
```

**Test environment loading:**
```bash
cd .. && cd ci-excellence
echo $NPM_TOKEN  # Should be loaded from encrypted secrets
```

## 🐛 Troubleshooting

### "age key not found"

**Solution:**
```bash
mise run generate-age-key
```

### "sops: failed to decrypt"

**Causes:**
1. Private key missing or incorrect
2. File encrypted with different key
3. Corrupted encrypted file

**Solutions:**
```bash
# Check if private key exists
ls -la .secrets/mise-age.txt

# Verify key permissions
chmod 600 .secrets/mise-age.txt

# Try decrypting manually
sops --decrypt .env.secrets.json
```

### "mise command not found"

**Solution:**
```bash
# Ensure mise is activated in your shell
echo 'eval "$(mise activate bash)"' >> ~/.bashrc
source ~/.bashrc
```

### Environment variables not loading

**Solution:**
```bash
# Exit and re-enter directory
cd .. && cd ci-excellence

# Or manually trigger setup
mise run setup
```

## 📚 Additional Resources

- **Mise Documentation**: https://mise.jit.su
- **SOPS Documentation**: https://github.com/mozilla/sops
- **Age Documentation**: https://github.com/FiloSottile/age
- **Gitleaks**: https://github.com/gitleaks/gitleaks
- **Trufflehog**: https://github.com/trufflesecurity/trufflehog
- **Lefthook**: https://github.com/evilmartians/lefthook

## 🆘 Getting Help

**Check mise status:**
```bash
mise doctor
```

**View loaded environment:**
```bash
mise env
```

**Debug mode:**
```bash
mise --verbose run setup
```

**View configuration:**
```bash
cat mise.toml
```

---

**Questions?** Check the [mise documentation](https://mise.jit.su) or ask the team!
