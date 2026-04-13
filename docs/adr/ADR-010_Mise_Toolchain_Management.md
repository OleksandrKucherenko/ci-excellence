# ADR-010: Mise as Local Development Toolchain

**Date**: 2025-12-10
**Status**: Accepted

## Context and Problem Statement

The framework depends on multiple CLI tools (lefthook, gitleaks, trufflehog, sops, age, shellspec, commitlint, shfmt, shellcheck) that must be installed at consistent versions across developer machines and CI environments. Without a toolchain manager, onboarding requires a manual multi-step installation process that varies by OS. We need a single tool that manages installations, environment variables, and task definitions.

## Decision Drivers

- Single `cd` into the project directory should install all tools automatically
- Support for macOS and Linux (CI runners)
- Modular configuration to avoid a monolithic config file
- Task runner capabilities (replace Makefile for common operations)
- Active development and community support

## Considered Options

1. **Mise** (formerly rtx) - polyglot tool manager with task runner
2. **asdf** - plugin-based version manager (no task runner)
3. **Nix/devenv** - reproducible environments (steep learning curve)
4. **Docker dev containers** - containerized dev environment (heavy, slow startup)
5. **Makefile + manual installs** - familiar but no version pinning

## Decision Outcome

**Chosen option**: "Mise", because it combines tool version management, environment variable configuration, and task running in a single binary. The modular `conf.d/` import system keeps the root `mise.toml` minimal while organizing concerns into focused config files.

Configuration split:
```
mise.toml                           # Root: minimal, imports conf.d/
.config/mise/conf.d/
  00-secrets.toml                   # SOPS, age
  10-githooks.toml                  # Lefthook
  15-validators.toml                # action-validator, commitlint
  16-commitizen.toml                # Conventional commit tooling
  17-testing.toml                   # ShellSpec
  20-notifications.toml             # Apprise
  30-profile.toml                   # Dev profile switching
  90-setup.toml                     # Setup tasks and hooks
```

## Consequences

### Positive
- First `cd` into the project triggers `mise install`, bootstrapping all tools automatically
- Version pinning in `mise.toml` ensures CI and local environments match exactly
- Task definitions (`mise run test`, `mise run scan-secrets`) replace ad-hoc scripts
- `conf.d/` split keeps each concern in a focused, readable file

### Negative
- Mise is a relatively young tool; breaking changes between versions are possible
- Developers must install mise itself (one prerequisite), though this is a single binary
- Some tools (e.g., Homebrew-installed binaries) require platform-specific handling in CI

## Related Decisions

- ADR-007: Multi-Layer Security -- mise installs and configures security tools
- ADR-011: ShellSpec Test Framework -- shellspec is managed as a mise tool
- ADR-012: Conventional Commits -- commitlint and commitizen are managed via mise
