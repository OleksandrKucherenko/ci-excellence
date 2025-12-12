# Installation Guide

Complete installation instructions for all platforms.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installing Mise](#installing-mise)
  - [macOS](#macos)
  - [Linux](#linux)
  - [Windows (WSL)](#windows-wsl)
  - [Using Package Managers](#using-package-managers)
- [Shell Activation](#shell-activation)
- [Git Configuration](#git-configuration)
- [Verification](#verification)

## Prerequisites

The **ONLY** requirement is [Mise](https://mise.jit.su) - everything else installs automatically!

## Installing Mise

### macOS

**Recommended: Using Homebrew**
```bash
brew install mise
```

**Alternative: Using curl**
```bash
curl https://mise.run | sh
```

### Linux

**Using curl (Universal)**
```bash
curl https://mise.run | sh
```

**Debian/Ubuntu**
```bash
apt update -y && apt install -y gpg sudo wget curl
sudo install -dm 755 /etc/apt/keyrings
wget -qO - https://mise.jdx.dev/gpg-key.pub | gpg --dearmor | sudo tee /etc/apt/keyrings/mise-archive-keyring.gpg 1> /dev/null
echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=amd64] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list
sudo apt update
sudo apt install -y mise
```

**Fedora/RHEL/CentOS**
```bash
dnf install -y dnf-plugins-core
dnf config-manager --add-repo https://mise.jdx.dev/rpm/mise.repo
dnf install -y mise
```

**Arch Linux**
```bash
pacman -S mise
```

### Windows (WSL)

First, install WSL2 if you haven't already:
```powershell
# In PowerShell as Administrator
wsl --install
```

Then follow the [Linux](#linux) instructions inside your WSL terminal.

### Using Package Managers

**Cargo (Rust)**
```bash
cargo install mise
```

**npm**
```bash
npm install -g @jdxcode/mise
```

## Shell Activation

After installing mise, activate it in your shell configuration:

### Bash

Add to `~/.bashrc` or `~/.bash_profile`:
```bash
eval "$(mise activate bash)"
```

### Zsh

Add to `~/.zshrc`:
```bash
eval "$(mise activate zsh)"
```

### Fish

Add to `~/.config/fish/config.fish`:
```fish
mise activate fish | source
```

### PowerShell

Add to your PowerShell profile (`$PROFILE`):
```powershell
Invoke-Expression "$(mise activate powershell)"
```

### Reload Your Shell

After adding the activation command:
```bash
# For bash/zsh
source ~/.bashrc  # or ~/.zshrc

# For fish
source ~/.config/fish/config.fish

# For PowerShell
. $PROFILE
```

## Git Configuration

### Configure Git with Custom SSH Key (Optional)

If you use a custom SSH key for this repository:

#### 1. Generate SSH Key (if needed)

```bash
ssh-keygen -t ed25519 -C "your_email@example.com" -f ~/.ssh/id_ed25519_ci_excellence
```

#### 2. Add SSH Key to ssh-agent

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519_ci_excellence
```

#### 3. Add Public Key to GitHub

```bash
cat ~/.ssh/id_ed25519_ci_excellence.pub
# Copy output and add to: GitHub Settings > SSH and GPG keys > New SSH key
```

#### 4. Configure Git to Use Specific Key

**Option A: Using ~/.ssh/config (Global Approach)**

```bash
# Add to ~/.ssh/config
cat >> ~/.ssh/config <<EOF

Host github.com-ci-excellence
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_ci_excellence
  IdentitiesOnly yes
EOF

# Clone using custom host
git clone git@github.com-ci-excellence:YOUR-USERNAME/ci-excellence.git
cd ci-excellence
```

**Option B: Using Local Git Config (Project-Specific)**

```bash
# Clone repository first
git clone git@github.com:YOUR-USERNAME/ci-excellence.git
cd ci-excellence

# Configure line endings
git config --local core.autocrlf false
git config --local core.eol lf

# Configure user identity for this project
git config --local user.name "Your Name"
git config --local user.email "your.email@example.com"

# Configure project-specific SSH key
# Place your SSH key in .secrets/ directory
cp ~/.ssh/id_ed25519_ci_excellence .secrets/github-ssh-key
chmod 400 .secrets/github-ssh-key

# Configure git to use this key (auto-detects project path)
git config --local core.sshCommand "ssh -o IdentitiesOnly=yes -i $(printf "%q\n" "$(pwd)")/.secrets/github-ssh-key -F /dev/null"
```

#### WSL-Specific chmod Workaround (if needed)

If WSL has chmod issues with files in the project directory:

```bash
# Copy key to home directory and symlink
cp .secrets/github-ssh-key ~/
rm .secrets/github-ssh-key
chmod 400 ~/github-ssh-key
ln --symbolic ~/github-ssh-key .secrets/github-ssh-key

# Update git config to use symlink
git config --local core.sshCommand "ssh -o IdentitiesOnly=yes -i $(printf "%q\n" "$(pwd)")/.secrets/github-ssh-key -F /dev/null"
```

## Verification

Verify your installation:

```bash
# Check mise version
mise --version

# Check mise is activated (should show mise in PATH)
which mise

# Test mise doctor
mise doctor
```

## Next Steps

After installation, return to the main [README](../README.md) for the Quick Start guide.

## Troubleshooting

### Mise Command Not Found

If `mise` command is not found after installation:

1. Ensure you've added the activation line to your shell config
2. Reload your shell configuration
3. Check that mise is in your PATH: `echo $PATH | grep mise`

### Permission Denied Errors

If you get permission errors:

```bash
# Make sure your user owns the mise directory
sudo chown -R $USER:$USER ~/.local/share/mise
```

### WSL-Specific Issues

For WSL users experiencing slow performance:

1. Clone the repository in WSL filesystem (not /mnt/c/)
2. Use Windows Terminal for better performance
3. Consider using Docker Desktop with WSL2 integration

For more troubleshooting, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).
