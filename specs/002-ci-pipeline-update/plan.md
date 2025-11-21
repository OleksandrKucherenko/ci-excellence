# Implementation Plan: CI Pipeline Comprehensive Update

**Branch**: `002-ci-pipeline-update` | **Date**: 2025-11-21 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-ci-pipeline-update/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

This feature implements a comprehensive GitHub Actions CI/CD pipeline upgrade with advanced deployment control, multi-environment management, and testable DRY scripts. The system supports monorepo deployments with sub-project versioning, environment-specific git tags, deployment conflict management via GitHub Actions native concurrency, rollback capabilities, and SOPS-encrypted secrets managed via MISE. All pipeline logic is extracted into standalone testable scripts (Bash/TypeScript) with workflow-level timeout protection. Pipeline completion reports include actionable links for release promotion, rollback, state assignment, and maintenance tasks.

Based on research, the design uses GitHub Actions native concurrency for stateless pipeline compliance, MISE for hierarchical environment management, SOPS + age for encrypted secrets, and comprehensive git tagging strategies for deployment control.

## Technical Context

**Language/Version**: Bash 5.x, TypeScript/Bun (latest stable), GitHub Actions YAML
**Primary Dependencies**: GitHub Actions, MISE (tool management), SOPS + age (secret encryption), Lefthook (git hooks), Commitizen (commit enforcement), Gitleaks + Trufflehog (secret scanning), Apprise (notifications), ShellSpec (testing), ShellCheck (linting), ShellFormat (formatting), Act (local testing)
**Storage**: Git tags for deployment metadata, SOPS-encrypted files in repository for environment secrets, GitHub Secrets for CI credentials
**Testing**: ShellSpec for bash script testing, GitHub Actions workflow validation via action-validator, Act for local pipeline testing
**Target Platform**: GitHub Actions runners (ubuntu-latest), local development on Bash-compatible systems (Linux, macOS, WSL)
**Project Type**: CI/CD framework (infrastructure) supporting Node.js monorepo applications
**Performance Goals**: Pipeline completion reports with configurable timeout limits, deployment completion times configurable per project with safety timeout guards
**Constraints**: GitHub Actions timeout limits (6 hours max per job, overridable via CI_JOB_TIMEOUT_MINUTES), workflow-level timeout for hung script detection, 100% secret scanning coverage (no hardcoded credentials), 90% of scripts < 50 LOC
**Scale/Scope**: Support for monorepos with multiple sub-projects, 5+ environments (production, staging, canary, sandbox, performance), multi-region deployments (3+ regions), 10+ CI scripts across lifecycle phases

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

This implementation complies with all principles defined in `.specify/memory/constitution.md`:

- **Variable-Driven Activation**: ✅ Replaced ENABLE_* flags with hierarchical CI_TEST_* variables for script testability, while maintaining MISE environment variable control for features
- **Stub-Based Customization**: ✅ All CI scripts are transparent stubs with documented extension points and commented examples for multiple technology stacks
- **Security-First**: ✅ Security scanning runs unconditionally; secrets managed via SOPS + age with 30-day retention; comprehensive audit trails
- **Graceful Degradation**: ✅ Dependent jobs handle skipped prerequisites using `always()` patterns; scripts skip gracefully with informative messages
- **Monorepo-Ready Node.js/TypeScript Focus**: ✅ Workspace-aware with TypeScript-first support and Bash 5.x compatibility; sub-project path support
- **Stateless Pipeline Independence**: ✅ Uses GitHub Actions native concurrency for conflict management; no shared mutable state; git tags as single source of truth

*Refer to `.specify/memory/constitution.md` for complete principle definitions and requirements.*

**Post-Phase 1 Validation**: All design decisions maintain constitution compliance. No violations detected.

## Project Structure

### Documentation (this feature)

```text
specs/002-ci-pipeline-update/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   └── github-actions.yaml
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
.github/
├── workflows/
│   ├── pre-release.yml         # PR and dev branch CI
│   ├── release.yml             # Version tag triggered releases
│   ├── post-release.yml        # Post-deployment verification
│   ├── maintenance.yml         # Cron-based background tasks
│   ├── tag-assignment.yml      # Environment tag management
│   ├── deployment.yml          # Environment deployments with native concurrency
│   ├── rollback.yml            # Rollback workflows
│   └── self-healing.yml        # Code formatting and linting fixes
└── actions/                    # Reusable composite actions (if needed)

scripts/
├── setup/                      # Environment preparation
│   ├── 10-ci-install-deps.sh
│   └── 20-ci-validate-env.sh
├── build/                      # Compilation, linting, security
│   ├── 10-ci-compile.sh
│   ├── 20-ci-lint.sh
│   ├── 30-ci-security-scan.sh
│   └── 40-ci-bundle.sh
├── test/                       # Test execution
│   ├── 10-ci-unit-tests.sh
│   ├── 20-ci-integration-tests.sh
│   └── 30-ci-e2e-tests.sh
├── release/                    # Versioning and publishing
│   ├── 10-ci-determine-version.sh
│   ├── 20-ci-generate-changelog.sh
│   ├── 30-ci-publish-npm.sh
│   ├── 40-ci-publish-docker.sh
│   └── 50-ci-tag-assignment.sh
├── deployment/                 # Environment deployment
│   ├── 10-ci-deploy-staging.sh
│   ├── 20-ci-deploy-production.sh
│   ├── 30-ci-rollback.sh
│   └── 40-ci-atomic-tag-movement.sh
├── maintenance/                # Cleanup and audits
│   ├── 10-ci-cleanup.sh
│   ├── 20-ci-security-audit.sh
│   ├── 30-ci-dependency-update.sh
│   └── 40-ci-deprecate-versions.sh
├── hooks/                      # Git hooks for Lefthook
│   ├── pre-push-tag-protection.sh
│   ├── pre-commit-secret-scan.sh
│   ├── pre-commit-format.sh
│   ├── pre-commit-lint.sh
│   └── pre-commit-message-check.sh
├── ci/                         # CI utilities
│   ├── report-generator.sh     # Generate actionable links
│   ├── workflow-validator.sh   # Validate action syntax
│   └── cache-manager.sh        # Cache optimization
├── profile/                    # MISE profile management
│   ├── switch-profile.sh
│   └── show-profile.sh
├── secrets/                    # Secret management
│   ├── init-secrets.sh
│   ├── rotate-keys.sh
│   └── audit-secrets.sh
└── tools/                      # Tool verification and setup
    ├── verify-tools.sh
    └── setup-platform.sh

environments/
├── global/                     # Cross-environment resources
│   ├── config.yml              # Global configuration
│   └── secrets.enc             # SOPS-encrypted global secrets
├── staging/
│   ├── config.yml              # Staging-specific config
│   ├── secrets.enc             # SOPS-encrypted staging secrets
│   └── regions/
│       ├── us-east/
│       │   └── config.yml
│       └── eu-west/
│           └── config.yml
├── production/
│   ├── config.yml              # Production-specific config
│   ├── secrets.enc             # SOPS-encrypted production secrets
│   └── regions/
│       ├── us-east/
│       │   └── config.yml
│       └── eu-west/
│           └── config.yml
├── canary/                     # Optional environment
│   ├── config.yml
│   └── secrets.enc
├── sandbox/                    # Optional environment
│   ├── config.yml
│   └── secrets.enc
└── performance/                # Optional environment
    ├── config.yml
    └── secrets.enc

config/
├── .env.template               # Environment variable template
├── .env.local                  # Local development variables
└── .env.secrets.json           # CI/CD secrets (SOPS encrypted)

.secrets/
└── mise-age.txt                # Age key pair for SOPS encryption

.lefthook.yml                   # Git hooks configuration
mise.toml                       # Tool management and tasks
.sops.yaml                      # SOPS encryption rules
commitizen.json                 # Commit message enforcement
.shellspec.toml                 # ShellSpec configuration
.shfmt.toml                     # ShellFormat configuration
.shellcheckrc                   # ShellCheck configuration
```

**Structure Decision**: CI/CD framework structure supporting monorepo applications. The repository is organized around the four-stage pipeline architecture (pre-release, release, post-release, maintenance) with scripts grouped by lifecycle phase. Environment configuration uses folder hierarchy for multi-region support. All infrastructure code lives in `.github/workflows/` and `scripts/`, while environment-specific data lives in `environments/`.

## Complexity Tracking

> **No constitutional violations requiring justification**

All design decisions align with constitutional principles:

- **Stateless Pipeline Independence**: Using GitHub Actions native concurrency instead of queue management eliminates shared mutable state
- **Variable-Driven Activation**: Replaced complex ENABLE_* flag system with hierarchical CI_TEST_* variables for script testability
- **Stub-Based Customization**: All scripts are documented placeholders with clear extension points
- **Security-First**: Comprehensive security scanning with SOPS encryption and proper retention policies
- **Monorepo Support**: Sub-project path prefixes in git tags and environment configurations support complex monorepo structures

No complexity tracking entries required as implementation follows constitutional guidance without violations.