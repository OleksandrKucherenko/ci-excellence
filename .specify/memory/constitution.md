<!--
SYNC IMPACT REPORT
==================
Version Change: Initial → 1.0.0
Created: 2025-11-21

Added Sections:
- Core Principles (5 principles established)
  I. Variable-Driven Activation
  II. Stub-Based Customization
  III. Security-First (NON-NEGOTIABLE)
  IV. Graceful Degradation
  V. Monorepo-Ready Node.js/TypeScript Focus
- Pipeline Architecture & Standards (4-stage workflow, script organization, caching)
- Development Workflow (Mise setup, secret management, git hooks, testing, versioning)
- Governance (amendment process, compliance review, runtime guidance)

Templates Validated for Consistency:
- ✅ .specify/templates/plan-template.md
  - Constitution Check section present (line 30-34)
  - Complexity Tracking table for justified violations (line 97-104)
  - Aligned with security-first and stub-based principles
- ✅ .specify/templates/spec-template.md
  - User scenarios prioritized (P1, P2, P3) aligns with graceful degradation
  - Functional requirements structure supports variable-driven activation
  - No conflicts detected
- ✅ .specify/templates/tasks-template.md
  - User story organization enables independent testing (aligned with graceful degradation)
  - Test-first approach (OPTIONAL) respects testing philosophy
  - Phase structure supports progressive feature enablement
- ✅ .claude/commands/speckit.plan.md
  - References constitution.md for Constitution Check generation (line 25, 29)
  - Agent context update process documented (line 77-83)
  - No agent-specific naming conflicts (generic guidance maintained)
- ✅ .claude/commands/speckit.analyze.md
  - Declares constitution as "non-negotiable" authority (line 21)
  - Constitution conflicts flagged as CRITICAL (line 21)
  - Read-only analysis respects governance process
- ✅ README.md
  - Extensively documents all 5 core principles (81 references to key terms)
  - Variable-driven activation explained in Philosophy and Configuration sections
  - Stub-based approach detailed in Customization Guide
  - Security-first with Mise setup and git hooks
  - Monorepo focus with Node.js/TypeScript examples throughout

Follow-up TODOs: None - All templates and documentation are consistent with constitution v1.0.0
-->

# CI Excellence Constitution

## Core Principles

### I. Variable-Driven Activation

**Principle**: All pipeline features MUST be activated through GitHub Variables (not Secrets)
using `ENABLE_*` boolean flags. Jobs MUST skip gracefully when flags are not set to 'true',
with no pipeline failures from disabled features.

**Rationale**: This principle ensures teams can progressively enable features as needed without
maintaining complex configuration files or risking pipeline failures from incomplete setup.
Variable-driven design makes the pipeline self-documenting and removes accidental complexity.

**Requirements**:
- Every optional job in workflows MUST check its corresponding `ENABLE_*` variable
- Jobs MUST use `if: vars.ENABLE_FEATURE_NAME == 'true'` pattern
- Disabled jobs MUST result in 'skipped' status, never 'failed'
- Dependent jobs MUST handle skipped prerequisites using `always()` or `success() || skipped()`
- Documentation MUST list all available `ENABLE_*` flags with clear descriptions

### II. Stub-Based Customization

**Principle**: All implementation scripts MUST be stubs containing commented examples and clear
extension points. No "magic" behavior is allowed - all pipeline actions MUST be transparent,
editable, and understandable by reading the script files.

**Rationale**: Teams need to understand and customize CI/CD behavior for their specific
requirements. Hiding implementation in abstractions or external dependencies creates maintenance
burden and prevents teams from learning how their pipelines work.

**Requirements**:
- Scripts in `/scripts/` MUST be stubs with inline documentation
- Each stub MUST include commented examples for common tech stacks (Node.js, Python, Go)
- Scripts MUST NOT contain hard-coded assumptions about project structure beyond documented conventions
- Custom implementations MUST be copy-paste-ready, requiring only uncommenting and adjustment
- All external tools used MUST be documented with installation and configuration guidance

### III. Security-First (NON-NEGOTIABLE)

**Principle**: Security scanning MUST always run regardless of `ENABLE_*` flags. Secret scanning
MUST be enforced both locally (git hooks) and in CI. Secrets MUST be encrypted at rest using
age/SOPS.

**Rationale**: Security vulnerabilities and leaked secrets cannot be optional checks. Every
commit must be scanned before it reaches the repository, and every push must be re-verified in
CI to catch locally-bypassed hooks or configuration drift.

**Requirements**:
- Security-scan job in `pre-release.yml` MUST NOT be guarded by enable flags
- Local git hooks MUST run gitleaks and trufflehog on pre-commit
- Sensitive configuration files MUST use SOPS encryption with age keys
- Secrets MUST NEVER be stored in GitHub Variables (use GitHub Secrets only)
- Workflows MUST validate action syntax with action-validator
- Security findings MUST block PR merges (enforced via branch protection rules)

### IV. Graceful Degradation

**Principle**: Pipeline workflows MUST handle partial feature enablement without cascading
failures. Dependent jobs MUST proceed when prerequisites are skipped intentionally (via
disabled features), but MUST fail when prerequisites fail due to errors.

**Rationale**: Teams start with minimal setup (compile + tests) and progressively enable
advanced features (e2e, bundling, Docker). The pipeline must support this journey without
requiring complex conditional logic in every job definition.

**Requirements**:
- Use `if: always() && needs.PREREQ.result != 'failure'` pattern for jobs with optional prerequisites
- Document job dependency chains clearly in workflow files
- Setup job MUST always run (never skipped) as the foundation for all other jobs
- Test jobs MUST treat skipped compile job as success (TypeScript-only projects may skip compile)
- Notification job MUST run on all outcomes (`if: always()`) to report actual pipeline status

### V. Monorepo-Ready Node.js/TypeScript Focus

**Principle**: All pipeline components MUST support Node.js monorepos with workspace awareness.
Primary support is for npm/yarn/pnpm package managers and TypeScript compilation. Other
languages and stacks are supported through stub customization but not prioritized in defaults.

**Rationale**: The project explicitly targets Node.js monorepo teams seeking production-ready
CI/CD without reinventing common patterns. TypeScript is the dominant language in modern
Node.js projects and requires special handling for compilation and type checking.

**Requirements**:
- Caching strategies MUST hash `**/package*.json`, `**/yarn.lock`, `**/pnpm-lock.yaml`
- Scripts MUST support workspace-scoped operations (e.g., `npm run build --workspaces`)
- Version determination MUST read from `package.json` by default
- Artifact collection MUST include common TypeScript output directories: `dist/`, `build/`, `out/`
- Documentation MUST provide TypeScript-specific examples for all customization points
- Support for other languages MUST be via clearly documented stub customization, not default behavior

## Pipeline Architecture & Standards

### Four-Stage Workflow Design

The pipeline MUST be organized into four distinct workflows:

1. **Pre-Release Pipeline** (`pre-release.yml`): Runs on PRs and development branch pushes.
   Contains: setup, compile, lint, unit-tests, integration-tests, e2e-tests, security-scan,
   bundle, package, notify-pre-release.

2. **Release Pipeline** (`release.yml`): Triggered by manual dispatch or version tags.
   Contains: determine-version, changelog, publish-npm, publish-github, publish-docker,
   deploy-docs, notify-release.

3. **Post-Release Pipeline** (`post-release.yml`): Triggered after successful releases.
   Contains: deployment verification, smoke tests, rollback capability.

4. **Maintenance Pipeline** (`maintenance.yml`): Cron-based background tasks.
   Contains: dependency updates, security audits, cache cleanup, stale issue management.

### Script Organization

Scripts MUST be organized in `/scripts/` by lifecycle phase:

- `setup/`: Environment preparation, dependency installation
- `build/`: Compilation, linting, security scanning, asset bundling
- `test/`: Unit, integration, e2e test execution
- `release/`: Version management, changelog generation, publishing
- `maintenance/`: Cleanup, audits, automated updates
- `ci/`: CI-specific utilities (workflow validation, cache management)

### Artifact & Caching Strategy

- **Build Artifacts**: Retain for 7 days (compile outputs, test results, coverage)
- **Release Artifacts**: Retain for 90 days (published packages, Docker images, release notes)
- **Dependency Cache**: Key on `${{ runner.os }}-deps-${{ hashFiles('**/package*.json', '**/yarn.lock', '**/pnpm-lock.yaml') }}`
- **Compiled Cache**: Key on `${{ runner.os }}-build-${{ hashFiles('src/**', 'tsconfig*.json') }}`

### Notification Standards

- Apprise integration provides 90+ notification targets (Slack, Teams, Discord, Telegram, Email)
- Notifications MUST include: pipeline status, commit info, job durations, failure logs
- Notification job MUST be guardable via `ENABLE_NOTIFICATIONS` flag
- Templates MUST use structured formats for machine-parseable alerts

## Development Workflow

### Local Development Setup

Teams MUST use Mise for local environment automation:

1. Install Mise (`curl https://mise.run | sh`)
2. Activate in shell (`eval "$(mise activate bash)"`)
3. Enter project directory (auto-installs all tools via `mise.toml`)
4. Run `mise run setup` to configure git hooks and secrets encryption

### Secret Management

1. Secrets MUST be stored in `.env.encrypted` using SOPS + age
2. Edit secrets with `mise run edit-secrets` (auto-decrypts, opens editor, re-encrypts)
3. Age keys MUST be stored in `~/.config/sops/age/keys.txt` (never committed)
4. CI MUST access secrets via GitHub Secrets, not encrypted files

### Git Hooks

Pre-commit hooks MUST run:
- `gitleaks protect` - Detect hardcoded secrets
- `trufflehog git` - Detect high-entropy strings
- `action-validator` - Validate GitHub Actions syntax

Hooks managed via Lefthook (configured in `.lefthook.yml`).

### Testing Philosophy

- **Unit Tests**: MUST be fast (<1s each), isolated, no external dependencies
- **Integration Tests**: MUST verify contract boundaries between components
- **E2E Tests**: SHOULD use real services when possible, MUST be guardable via `ENABLE_E2E_TESTS`
- **Coverage**: SHOULD aim for >80%, MUST track trend over time (no hard gate)

### Version Management

- **Format**: MAJOR.MINOR.PATCH (semantic versioning)
- **Pre-releases**: Append `-alpha.N`, `-beta.N`, `-rc.N` suffixes
- **Branching**: Development → `main`, releases via tags `v*.*.*`
- **Changelog**: Auto-generated from conventional commits (feat:, fix:, BREAKING CHANGE:)

## Governance

This constitution supersedes all other project practices and documentation in case of conflict.
All contributors MUST comply with these principles in code reviews, design discussions, and
feature development.

### Amendment Process

1. Propose amendment via GitHub Issue with `[CONSTITUTION]` prefix
2. Document rationale and migration plan for existing implementations
3. Require approval from at least 2 maintainers
4. Update constitution version following semantic versioning:
   - **MAJOR**: Backward-incompatible principle removals or redefinitions
   - **MINOR**: New principles added or materially expanded guidance
   - **PATCH**: Clarifications, wording fixes, non-semantic refinements
5. Propagate changes to all dependent templates and documentation
6. Create migration guide if breaking changes affect existing adopters

### Compliance Review

- All PRs MUST verify compliance with constitution principles
- Violations MUST be flagged and corrected before merge
- Complexity additions MUST be explicitly justified against "stub-based customization" principle
- New features MUST default to disabled (via `ENABLE_*` flag) unless security-critical

### Runtime Development Guidance

For Claude Code or other AI agents assisting with this project, refer to
`.specify/memory/constitution.md` (this file) as the authoritative source of project governance.
All planning, specification, and implementation tasks MUST align with the principles defined
herein.

**Version**: 1.0.0 | **Ratified**: 2025-11-21 | **Last Amended**: 2025-11-21
