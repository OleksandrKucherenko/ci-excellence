# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

CI Excellence is a stub-based CI/CD pipeline framework (v2) for GitHub Actions. It ships 6 workflows (pre-release, release, post-release, maintenance, auto-fix-quality, ops) backed by numbered Bash stubs in `scripts/ci/`. Features are toggled via `ENABLE_*` GitHub Variables — disabled features skip silently without failure.

The only prerequisite is [Mise](https://mise.jdx.dev/) installed and activated in your shell.

## Common Commands

```bash
# Testing (ShellSpec BDD framework)
mise run test                    # Run all tests
mise run test:watch              # Watch mode
mise run test:coverage           # With coverage reports
shellspec spec/build/ci-10-compile_spec.sh   # Run a single test file

# Linting & formatting
mise run scan-scripts            # shellcheck all scripts
mise run format-scripts          # shfmt formatting
mise run check-workflows         # Validate GitHub Actions YAML

# Security
mise run scan-secrets            # gitleaks + trufflehog
mise run scan-history            # Scan git history for secrets

# Environment setup
mise run full-env-prepare        # Full environment init
mise run install-githooks        # Set up Lefthook hooks

# Commits (conventional commits enforced)
mise run cz                      # Interactive commitizen prompt
```

## Architecture

### Script Organization

CI scripts live in `scripts/ci/` grouped by domain: `setup/`, `build/`, `test/`, `release/`, `maintenance/`, `notification/`, `reports/`, and follow the naming convention `ci-{NN}-{purpose}.sh`. Steps use spaced numbering (10, 20, 30...) to allow insertion without renumbering. Paired actions (publish/verify/rollback) stay within +5 of each other. See `scripts/ci/README.md` for numbering block assignments.

### Bootstrap & Logger System

Every CI script sources `scripts/ci/_ci-common.sh`, which initializes:
- **e-bash logger** (`scripts/lib/_logger.sh`): Creates domain-specific colored log functions like `echo:Build`, `echo:Test`, `echo:Release`. Output controlled by `DEBUG` env var (e.g., `DEBUG=build,test`).
- **e-bash hooks** (`scripts/lib/_hooks.sh`): Per-script extension points. Consuming projects drop scripts in `ci-cd/{step_name}/` directories for auto-discovery.
- **Helper functions**: `ci:param` (log params), `ci:secret` (masked logging), `ci:output` (write to `$GITHUB_OUTPUT`), `ci:require` / `ci:optional` (env var validation).

The e-bash library in `scripts/lib/` is a git subtree — do not edit it directly.

### Workflow-to-Script Mapping

Workflows in `.github/workflows/` invoke scripts from `scripts/ci/` by domain. Each workflow has a corresponding report script in `scripts/ci/reports/` that generates pipeline summaries.

### Configuration Layers

- `mise.toml` — main entry point, sets `E_BASH` path and loads `.env` files
- `.config/mise/conf.d/` — tool definitions split by concern (secrets, hooks, validators, testing, notifications)
- `.lefthook.toml` — git hooks: pre-commit (gitleaks, branch protection), pre-push (gitleaks + trufflehog), commit-msg (commitlint)
- `.commitlintrc.yaml` / `.cz.yaml` — conventional commit enforcement and interactive commit config

## Coding Conventions

- All scripts: `#!/usr/bin/env bash` with `set -euo pipefail`
- Source `_ci-common.sh` as the first action in every CI script
- Use `echo:Tag` / `printf:Tag` (e.g., `echo:Build`, `printf:Release`) instead of plain `echo`
- Format with `shfmt`, lint with `shellcheck`
- Tests go in `spec/` mirroring the `scripts/ci/` directory structure as ShellSpec `*_spec.sh` files
