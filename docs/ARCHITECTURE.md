# Architecture Documentation

System architecture and design principles.

## Table of Contents

- [Overview](#overview)
- [Design Principles](#design-principles)
- [Pipeline Flow](#pipeline-flow)
- [Directory Structure](#directory-structure)
- [Script Organization](#script-organization)
- [Configuration Management](#configuration-management)
- [Security Architecture](#security-architecture)

## Overview

CI Excellence is a **stub-based CI/CD pipeline framework** designed for long-term project maintenance. It follows the philosophy of "reserve space, eliminate routine" by providing a complete pipeline structure that activates features through variable toggles.

### Core Concepts

1. **Stub-based Approach** - All scripts are stubs with examples, ready to customize
2. **Variable-driven Activation** - Jobs skip gracefully when not enabled
3. **Modular Design** - Enable only what you need
4. **Spaced Numbering** - Easy to insert new scripts
5. **Production-ready** - Based on real-world CI/CD best practices

## Design Principles

### 1. Zero Failures from Disabled Features

Jobs that aren't enabled should skip, not fail. This prevents:
- Red pipelines from features you don't use
- Notification fatigue from irrelevant failures
- Confusion about actual problems

**Implementation:**
```yaml
compile:
  if: vars.ENABLE_COMPILE == 'true'
  # Only runs when explicitly enabled
```

### 2. Progressive Enhancement

Start simple, add complexity as needed:

```
Week 1:  Basic CI (compile, lint, test)
Week 2:  Integration tests
Week 3:  Releases
Month 2: Publishing (NPM, Docker)
Month 3: Maintenance automation
```

### 3. Reserve Space for Growth

Use spaced numbering (10, 20, 30...) so you can add scripts between existing ones:

```bash
# Existing
ci-10-compile.sh
ci-20-lint.sh

# Add between them
ci-15-type-check.sh  # New script!
```

### 4. Separation of Concerns

**Operational scripts** (do work):
- `scripts/ci/setup/`
- `scripts/ci/build/`
- `scripts/ci/test/`
- `scripts/ci/release/`
- `scripts/ci/maintenance/`
- `scripts/ci/notification/`

**Reporting scripts** (summarize results):
- `scripts/ci/reports/`

### 5. Convention over Configuration

Follow conventions to reduce explicit configuration:
- Script numbering indicates execution order
- Directory structure indicates purpose
- Naming patterns indicate function

## Pipeline Flow

### Pre-Release Pipeline

```
┌─────────────────────────────────────────────┐
│            Developer Push/PR                │
└─────────────┬───────────────────────────────┘
              │
    ┌─────────▼─────────┐
    │   Setup (Always)  │
    │  - Install tools  │
    │  - Install deps   │
    └─────────┬─────────┘
              │
    ┌─────────▼─────────┐
    │   Build Pipeline  │
    │  - Compile        │
    │  - Lint           │
    │  - Security scan  │
    │  - Bundle         │
    └─────────┬─────────┘
              │
    ┌─────────▼─────────┐
    │   Test Pipeline   │
    │  - Unit tests     │
    │  - Integration    │
    │  - E2E tests      │
    └─────────┬─────────┘
              │
    ┌─────────▼─────────┐
    │   Summary Report  │
    │  - Results        │
    │  - Coverage       │
    │  - Notify         │
    └───────────────────┘
```

### Release Pipeline

```
┌─────────────────────────────────────────────┐
│        Manual Trigger or Tag Push           │
└─────────────┬───────────────────────────────┘
              │
    ┌─────────▼─────────┐
    │  Prepare Release  │
    │  - Select version │
    │  - Update files   │
    │  - Generate notes │
    └─────────┬─────────┘
              │
    ┌─────────▼─────────┐
    │  Build & Test     │
    │  - Build artifacts│
    │  - Test release   │
    └─────────┬─────────┘
              │
    ┌─────────▼─────────┐
    │  Publish Parallel │
    ├───────────────────┤
    │ GitHub │ NPM      │
    │ Docker │ Docs     │
    └─────────┬─────────┘
              │
    ┌─────────▼─────────┐
    │  Verify & Notify  │
    │  - Check deploys  │
    │  - Send notifs    │
    └───────────────────┘
```

### Post-Release Pipeline

```
┌─────────────────────────────────────────────┐
│      Triggered by Release Published         │
└─────────────┬───────────────────────────────┘
              │
    ┌─────────▼─────────┐
    │ Verify Deployment │
    │  - Check NPM      │
    │  - Check Docker   │
    │  - Check docs     │
    └─────────┬─────────┘
              │
         ┌────▼────┐
         │ Success?│
         └────┬────┘
              │
      ┌───────┴───────┐
      │               │
  ┌───▼───┐      ┌────▼────┐
  │ Stable│      │ Rollback│
  │  Tag  │      │ Process │
  └───────┘      └─────────┘
```

### Maintenance Pipeline

```
┌─────────────────────────────────────────────┐
│         Cron: Daily at 2 AM UTC             │
└─────────────┬───────────────────────────────┘
              │
    ┌─────────▼─────────┐
    │  Cleanup Tasks    │
    │  - Workflows      │
    │  - Artifacts      │
    │  - Caches         │
    └─────────┬─────────┘
              │
    ┌─────────▼─────────┐
    │  Sync & Deprecate │
    │  - Version files  │
    │  - Old releases   │
    └─────────┬─────────┘
              │
    ┌─────────▼─────────┐
    │  Security & Deps  │
    │  - Audit          │
    │  - Updates        │
    └─────────┬─────────┘
              │
    ┌─────────▼─────────┐
    │  Report & Notify  │
    └───────────────────┘
```

## Directory Structure

### High-Level Organization

```
ci-excellence/
├── .github/workflows/      # GitHub Actions workflows
├── .config/mise/          # Mise configuration
│   └── conf.d/            # Modular tool configs
├── scripts/               # Executable scripts
│   ├── ci/                # CI pipeline scripts
│   └── setup/             # Local development helpers
├── environments/          # Environment configs
├── config/                # Configuration templates
└── docs/                  # Documentation
```

### Script Organization

```
scripts/ci/
├── setup/                 # Environment setup
│   ├── ci-10-*           # Tool installation
│   ├── ci-20-*           # Dependency installation
│   └── ci-30-*           # Bot configuration
│
├── build/                 # Build pipeline
│   ├── ci-10-*           # Compilation
│   ├── ci-20-*           # Linting
│   ├── ci-30-*           # Security scanning
│   └── ci-40-*           # Bundling
│
├── test/                  # Test pipeline
│   ├── ci-10-*           # Unit tests
│   ├── ci-20-*           # Integration tests
│   ├── ci-30-*           # E2E tests
│   └── ci-40-*           # Smoke tests
│
├── release/               # Release pipeline
│   ├── ci-05-ci-40       # GitHub release ops
│   ├── ci-50-ci-60       # Documentation
│   └── ci-65-ci-90       # Registry publishing
│
├── maintenance/           # Maintenance tasks
│   ├── ci-10-*           # File sync
│   ├── ci-30-ci-50       # Cleanup
│   ├── ci-60-*           # Security audit
│   ├── ci-70-ci-80       # Deprecation
│   └── ci-90-*           # Dependency updates
│
├── notification/          # Notification system
│   ├── ci-10-*           # Enable check
│   ├── ci-20-*           # Status determination
│   ├── ci-30-*           # Send notification
│   └── ci-40-ci-60       # Workflow-specific status
│
└── reports/               # Summary reports
    ├── ci-10-*           # Pre-release summary
    ├── ci-20-ci-30       # Maintenance summaries
    └── ci-40-ci-95       # Pipeline-specific summaries
```

### Numbering Ranges

**Release Scripts:**
- **05-40**: GitHub release operations
  - 05: Version selection
  - 10: Version determination
  - 15: Version update
  - 20: Changelog generation
  - 25: Release notes
  - 30: Asset upload
  - 35: Verification
  - 40: Rollback
- **50-60**: Documentation
  - 50: Build docs
  - 55: Publish docs
- **65-90**: Registry publishing
  - 65-75: NPM (publish, verify, rollback)
  - 80-90: Docker (publish, verify, rollback)

**Reports Scripts:**
- **10-30**: Core reports
- **40-95**: Workflow-specific summaries (aligned with workflow order)

## Configuration Management

### Mise Configuration Layers

```
mise.toml                          # Main config (minimal)
└── imports from:
    .config/mise/conf.d/
    ├── 00-secrets.toml           # Secrets (age, sops)
    ├── 10-githooks.toml          # Git hooks (lefthook)
    ├── 15-validators.toml        # Validation tools
    ├── 16-commitizen.toml        # Commit tools
    ├── 17-testing.toml           # Test tools
    ├── 20-notifications.toml     # Notification tools
    ├── 30-profile.toml           # Dev profile
    └── 90-setup.toml             # Setup tasks
```

### GitHub Variables (Public)

Stored in: **Settings > Secrets and variables > Actions > Variables**

```
ENABLE_*=true                      # Feature flags
AUTO_COMMIT=true                   # Auto-commit fixes
AUTO_APPLY_FIXES=true             # Auto-apply fixes
PUSH_CHANGES=false                # Auto-push changes
```

### GitHub Secrets (Private)

Stored in: **Settings > Secrets and variables > Actions > Secrets**

```
NPM_TOKEN                         # NPM publishing
DOCKER_USERNAME                   # Docker publishing
DOCKER_PASSWORD                   # Docker publishing
APPRISE_URLS                      # Notifications
```

### Environment Hierarchy

```
1. GitHub Secrets (highest priority)
2. GitHub Variables
3. .env.secrets.json (local, encrypted)
4. .env (local, plaintext)
5. Mise config defaults
6. Script defaults (lowest priority)
```

## Script Organization

### Script Template Structure

All CI scripts source the e-bash logger via `_ci-common.sh`. Instead of plain `echo`, scripts use
`echo:Tag` (e.g. `echo:Build`, `echo:Test`) which routes output through the e-bash logger system.
This allows controlling verbosity via the `DEBUG` environment variable and makes it trivial to
rollback to plain bash by string-replacing `echo:Tag` back to `echo`.

```bash
#!/usr/bin/env bash
# Purpose: [What this script does]
# Usage: ./ci-XX-name.sh [args]
# Environment: [Required variables]
# Exit codes: [Success/failure codes]

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# Main
main() {
    echo:Build "========================================="
    echo:Build "Starting [task name]..."
    echo:Build "========================================="

    # Logic here

    echo:Build "✓ [task] complete"
    echo:Build "========================================="
}

main "$@"
```

**Logger tags by domain:**
- `echo:Build` / `echo:Security` — build pipeline scripts
- `echo:Test` — test pipeline scripts
- `echo:Release` — release pipeline scripts
- `echo:Setup` — environment setup scripts
- `echo:Maint` — maintenance scripts
- `echo:Notify` — notification scripts
- `echo:Report` — report/summary scripts
- `echo:Ops` — operations scripts

**Controlling output:** `DEBUG=build,test ./script.sh` (see [e-bash logger docs](https://github.com/OleksandrKucherenko/e-bash))

### Execution Flow

```
Workflow YAML
    ↓
Calls script: ./scripts/ci/category/ci-XX-name.sh
    ↓
Script sources _ci-common.sh (e-bash logger)
    ↓
Script performs action (logs via echo:Tag)
    ↓
Script exits with code:
    - 0: Success
    - 1: Error
    - 2: Skipped (feature not enabled)
```

## Security Architecture

### Secret Management

```
Developer                     CI Pipeline
    │                             │
    ▼                             ▼
.env.secrets.json ──────→ GitHub Secrets
    │                             │
    │ (encrypted)                 │
    ▼                             ▼
SOPS + age              Environment Variables
    │                             │
    ▼                             ▼
Local Scripts              CI Scripts
```

### Secret Scanning

**Pre-commit:**
1. Gitleaks scans staged files
2. Trufflehog scans staged files
3. Commit blocked if secrets found

**CI Pipeline:**
1. Full repository scan
2. Results uploaded to Security tab
3. SARIF format for GitHub integration

### Security Layers

1. **Local Prevention** - Git hooks prevent commits
2. **CI Detection** - Workflows scan on push
3. **Periodic Audit** - Maintenance workflow audits
4. **Encrypted Storage** - SOPS/age for local secrets
5. **GitHub Secrets** - Encrypted secret storage

## Performance Considerations

### Parallel Execution

Jobs run in parallel when possible:

```yaml
jobs:
  compile:   # Can run independently
  lint:      # Can run independently
  test:      # Depends on compile
```

### Caching Strategy

```yaml
- uses: actions/cache@v4
  with:
    path:
      - ~/.mise
      - node_modules/
      - ~/.cargo/
    key: ${{ runner.os }}-${{ hashFiles('**/lockfile') }}
```

### Conditional Execution

```yaml
if: |
  vars.ENABLE_FEATURE == 'true' &&
  (github.event_name == 'push' || github.event_name == 'pull_request')
```

## See Also

- [Workflows](WORKFLOWS.md) - Detailed workflow documentation
- [Customization](CUSTOMIZATION.md) - How to customize
- [Installation](INSTALLATION.md) - Setup guide
- [Troubleshooting](TROUBLESHOOTING.md) - Common issues
