# Research: CI Pipeline Comprehensive Upgrade

**Feature**: 001-ci-pipeline-upgrade
**Date**: 2025-11-21
**Status**: Phase 0 Complete

## Overview

This document captures the technical research and decision-making process for implementing a comprehensive GitHub Actions CI/CD pipeline upgrade. All technical unknowns from the specification have been resolved through analysis of existing tools, best practices, and architectural patterns.

## Research Areas

### 1. GitHub Actions Timeout Management

**Question**: How to implement workflow-level timeout protection with override capability?

**Decision**: Use job-level `timeout-minutes` configuration with environment variable override

**Rationale**:
- GitHub Actions supports `timeout-minutes` at the job level (not step level)
- Default timeout is 360 minutes (6 hours) if not specified
- Can be overridden dynamically using expression: `timeout-minutes: ${{ vars.CI_JOB_TIMEOUT_MINUTES || 120 }}`
- When timeout expires, GitHub Actions terminates the entire job process tree
- Provides clear failure message indicating timeout was reached

**Alternatives Considered**:
- Step-level timeouts: Rejected because GitHub Actions doesn't support this natively, would require wrapper scripts with `timeout` command (adds complexity)
- External monitoring: Rejected because it requires additional infrastructure and doesn't integrate with GitHub's native job control
- No timeout override: Rejected because different jobs have different runtime characteristics (e2e tests may need longer timeouts)

**Implementation Notes**:
- Set sensible defaults per job type (setup: 10m, compile: 20m, tests: 30m, e2e: 60m)
- Document override mechanism in workflow comments
- Use GitHub Variables (not Secrets) for CI_JOB_TIMEOUT_MINUTES to maintain visibility

### 2. Git Tag Protection and Enforcement

**Question**: How to prevent manual tag assignment while allowing CI pipeline to create protected tags?

**Decision**: Use three-tier tag architecture with Lefthook pre-push hook enforcement

**Rationale**:
- **Version tags** (`api/v1.0.0`): Immutable, mark release versions, never moved
- **Environment tags** (`api/production`): Movable pointers, indicate currently deployed commit for an environment
- **State tags** (`api/v1.0.0-stable`): Immutable, mark version quality for rollback prioritization
- Environment tags act like symbolic links - can be deleted and recreated on new commits
- Separates concerns: version identification vs deployment tracking vs quality marking
- Lefthook (already adopted) enforces local pre-push validation for environment tags
- Pre-push hook blocks environment tag patterns (e.g., `production`, `staging`, `canary`)
- CI pipeline uses GitHub Actions service account which bypasses git hooks
- Easy to see current deployments: check where environment tags point

**Alternatives Considered**:
- Combined tags (e.g., `api/v1.0.0-production`): Rejected because creates new immutable tag per deployment, clutters tag history
- Branch protection rules: Rejected because they don't apply to tags
- GitHub Apps: Rejected because requires elevated permissions and external service setup
- Server-side hooks: Rejected because not available on GitHub.com (requires GitHub Enterprise Server)
- No enforcement: Rejected because manual tag manipulation can cause deployment inconsistencies

**Implementation Notes**:
- Add protected environment tag patterns to `.lefthook.yml` under `pre-push` hook
- Hook script checks `git push` ref patterns, blocks tags matching `*/(production|staging|canary|sandbox|performance)$`
- Allows version tags (`*/v*.*.*`) and state tags (`*/v*.*.*-(stable|unstable|deprecated)`)
- Provide exemption mechanism for administrators (environment variable `ALLOW_PROTECTED_TAG_PUSH=true`)
- Tag assignment workflow moves environment tags using: `git tag -f <env-tag> <commit>` then `git push -f origin <env-tag>`
- Document tag architecture and workflows in README

### 3. Deployment Conflict Management

**Question**: What mechanism should be used to handle concurrent deployments to the same environment while maintaining stateless pipeline principles?

**Decision**: Use GitHub Actions native concurrency groups with fail-fast approach

**Rationale**:
- **Constitution Compliance**: Stateless pipeline principles prohibit custom queue management with shared mutable state
- GitHub Actions native `concurrency` provides deployment protection without external state
- Syntax: `concurrency: { group: 'deploy-${{ inputs.environment }}', cancel-in-progress: false }`
- When deployment conflicts occur, jobs fail immediately with clear error messaging
- Report generator provides retry links with pre-filled parameters for manual resubmission
- No external infrastructure required (Redis, database, etc.)
- Supports constitution requirement for stateless, deterministic pipelines

**Alternatives Considered**:
- **Custom FIFO queue**: Rejected because violates stateless pipeline principles (requires shared mutable state)
- External queue (Redis/RabbitMQ): Rejected because requires additional infrastructure and violates statelessness
- File-based locking: Rejected because prone to race conditions and requires shared state
- Cancel-in-progress: Rejected because requirement specifies conflict detection with retry capability

**Implementation Notes**:
- Define concurrency group at workflow level for deployment jobs
- Use dynamic group name based on environment parameter
- Different environments use different groups (allows parallel deployments across environments)
- Conflict detection job provides retry links with pre-filled parameters
- Document conflict behavior in workflow comments

### 4. Rollback Version Selection Algorithm

**Question**: How to implement the "scan tags for previous version" rollback logic?

**Decision**: Git tag enumeration with semver comparison and state filtering

**Rationale**:
- Git tags are the source of truth for deployed versions
- Environment tags (e.g., `api/production`) point to currently deployed commit
- Find current version by checking which version tag points to same commit as environment tag
- Algorithm: `git tag -l '<path>/v*' | semver-sort | filter-deprecated | filter-current | select-highest-remaining`
- Prioritize versions with `-stable` state tags over those without
- Exclude versions with `-deprecated` state tags entirely
- Use semver comparison library (npm `semver` package available in Bun)

**Alternatives Considered**:
- Deployment metadata file: Rejected because requires maintaining separate state, can drift from reality
- GitHub Releases API: Rejected because releases may not match deployed versions exactly
- Manual rollback target specification: Rejected because requirement specifies automatic identification
- Database tracking: Rejected because requires external infrastructure

**Implementation Notes**:
- Create `scripts/deployment/30-ci-rollback.sh` with version selection logic
- Get current commit: `git rev-parse <path>/<environment>`
- Find current version: `git tag --points-at <commit> | grep -E '^<path>/v'`
- List all version tags: `git tag -l '<path>/v*' | grep -vE '-(stable|unstable|deprecated)$'`
- Use `git tag --list --sort=-version:refname` for semver sorting
- Check for `-stable` state tag for each version (prioritize if exists)
- Exclude current version and any with `-deprecated` state tags
- Fail explicitly with clear message if no valid rollback target exists
- Log the identified rollback target and reasoning before executing deployment

### 5. SOPS + MISE Secret Management Integration

**Question**: How should CI scripts access SOPS-encrypted secrets via MISE?

**Decision**: MISE tasks wrapper pattern with automatic decryption

**Rationale**:
- MISE can run tasks defined in `mise.toml` that execute SOPS decryption
- Pattern: `mise run decrypt-secrets <environment>` called by CI scripts before accessing files
- Decrypted secrets stored in job-local temp directory (auto-cleaned by GitHub Actions)
- Age keys for CI stored in GitHub Secrets, injected as environment variable
- Local development uses developer's personal age keys from `~/.config/sops/age/keys.txt`

**Alternatives Considered**:
- Direct SOPS calls in scripts: Rejected because duplicates decryption logic across scripts
- Pre-decrypt in workflow setup: Rejected because not all jobs need secrets (wastes time and exposes secrets to more steps)
- GitHub Secrets only: Rejected because requirement specifies git-committed SOPS files for environment configuration
- Plaintext storage: Rejected because violates security-first principle

**Implementation Notes**:
- Define MISE tasks: `decrypt-staging`, `decrypt-production`, etc.
- Tasks read `SOPS_AGE_KEY` from environment (GitHub Secret in CI, local file for developers)
- Scripts call `mise run decrypt-<env>` before reading environment config
- Document secret rotation procedure in SECURITY.md per script

### 6. Pipeline Summary Report Generation

**Question**: How to generate actionable links in GitHub Actions summary?

**Decision**: Use GitHub Actions Job Summary API with markdown links

**Rationale**:
- GitHub Actions provides `$GITHUB_STEP_SUMMARY` environment variable
- Write markdown to this file in job steps: `echo "content" >> $GITHUB_STEP_SUMMARY`
- Supports full markdown including links, tables, badges
- Links can point to workflow dispatch URLs with pre-filled parameters
- Visible in PR checks and workflow run summary

**Alternatives Considered**:
- Custom web dashboard: Rejected because requires separate hosting and authentication
- GitHub API comments: Rejected because clutters PR conversation, not suitable for all workflows
- Workflow artifacts: Rejected because requires downloading files (not actionable links)
- Email reports: Rejected because not immediate and requires notification configuration

**Implementation Notes**:
- Create `scripts/ci/report-generator.sh` to build summary markdown
- Include workflow dispatch URLs: `https://github.com/{org}/{repo}/actions/workflows/{workflow}.yml?inputs=...`
- Generate links for: promote-release, rollback, assign-state (stable/unstable), maintenance-tasks
- Call report generator as final step in notify jobs

### 7. Feature Activation Strategy

**Question**: How should features be activated without complex ENABLE_/DISABLE_ flag management?

**Decision**: Script-level configuration detection with testability logic

**Rationale**:
- **Simplified Architecture**: Removes complex variable-driven activation while maintaining control
- Scripts detect required configuration and skip gracefully with informative messages
- CI_TEST_* variables provide comprehensive testability without feature flags
- Reduces configuration burden - no need to maintain multiple ENABLE_* variables
- Scripts implement idempotent behavior that handles missing configuration without pipeline failures
- Aligns with clarifications to replace ENABLE_/DISABLE_ logic with testability logic

**Alternatives Considered**:
- **Variable-driven activation with ENABLE_* flags**: Rejected because adds complex flag management as identified in clarifications
- **Pure auto-activation**: Rejected because reduces explicit control and makes behavior less predictable
- **Hybrid approach with auto-setting flags**: Rejected because still complex and doesn't align with simplification goal

**Implementation Notes**:
- Scripts check for required prerequisites (credentials, configuration files, tools)
- Graceful skip with clear messaging when prerequisites not met
- CI_TEST_* variables override normal behavior for testing scenarios
- Document script prerequisites in header comments
- Use mise.toml for managing required tools and dependencies

### 8. CI Script Testability Framework

**Question**: What is the standard pattern for implementing testability in CI scripts?

**Decision**: Hierarchical environment variable system enabling per-pipeline, per-script control

**Rationale**:
- **Feature flags for CI/CD**: Enable testing scripts in production without affecting real operations
- **Selective testing**: Run most steps normally while testing one specific step in isolation
- **Pipeline-specific behavior**: Test script in staging (DRY_RUN) while executing normally in production
- **Gradual rollouts**: Test script changes in one pipeline before enabling in others
- **Script reusability**: Same script can behave differently based on pipeline context
- Supported modes: `EXECUTE` (normal), `DRY_RUN` (print commands), `PASS` (exit 0), `FAIL` (exit 1), `SKIP` (exit 0 with skip message), `TIMEOUT` (sleep indefinitely)

**Variable Precedence Hierarchy** (most specific wins):
1. `CI_TEST_<PIPELINE>_<SCRIPT>_BEHAVIOR` - pipeline + script specific
2. `CI_TEST_<SCRIPT>_BEHAVIOR` - script specific across all pipelines
3. `CI_TEST_MODE` - global default for all scripts
4. `EXECUTE` - hardcoded default

**Naming Conventions**:
- `<PIPELINE>`: Uppercase pipeline identifier (e.g., `PRE_RELEASE`, `RELEASE`, `DEPLOYMENT_PRODUCTION`, `MAINTENANCE`)
- `<SCRIPT>`: Uppercase script name without numeric prefix (e.g., `COMPILE`, `DEPLOY`, `PUBLISH_NPM`, `SECURITY_SCAN`)

**Examples**:

*Test compile script only in pre-release pipeline:*
```bash
CI_TEST_PRE_RELEASE_COMPILE_BEHAVIOR=DRY_RUN
# Pre-release: compile runs in DRY_RUN
# Release: compile runs in EXECUTE (normal)
```

*Test production deployment without affecting staging:*
```bash
CI_TEST_DEPLOYMENT_PRODUCTION_DEPLOY_BEHAVIOR=DRY_RUN
CI_TEST_DEPLOYMENT_STAGING_DEPLOY_BEHAVIOR=EXECUTE
# Production deploys in DRY_RUN (safe testing)
# Staging deploys in EXECUTE (normal)
```

*Test specific script across all pipelines:*
```bash
CI_TEST_PUBLISH_NPM_BEHAVIOR=DRY_RUN
# All pipelines: npm publishing runs in DRY_RUN
```

*Global DRY_RUN with one real execution:*
```bash
CI_TEST_MODE=DRY_RUN
CI_TEST_SECURITY_SCAN_BEHAVIOR=EXECUTE
# All scripts in DRY_RUN except security scan (runs normally)
```

**Alternatives Considered**:
- Single global variable: Rejected because can't test individual scripts or pipelines
- Separate test scripts: Rejected because creates duplication and drift between test and production code
- Docker-based testing: Rejected because adds container overhead and complexity
- Mock external services: Rejected because too complex and doesn't test actual integrations
- No testability: Rejected because requirement explicitly mandates production testing capability

**Implementation Notes**:
- Scripts detect pipeline name from `GITHUB_WORKFLOW` environment variable
- Transform pipeline name: `"Pre-Release Pipeline"` → `PRE_RELEASE_PIPELINE` → `PRE_RELEASE`
- Derive script name from `$0`: `10-ci-compile.sh` → `COMPILE`
- Variable lookup order:
  ```bash
  # Example for compile script in pre-release pipeline
  SCRIPT_NAME="COMPILE"
  PIPELINE_NAME="PRE_RELEASE"

  MODE="${CI_TEST_${PIPELINE_NAME}_${SCRIPT_NAME}_BEHAVIOR:-}"
  MODE="${MODE:-${CI_TEST_${SCRIPT_NAME}_BEHAVIOR:-}}"
  MODE="${MODE:-${CI_TEST_MODE:-EXECUTE}}"
  ```
- Implement mode handlers using case statement
- DRY_RUN mode: use `set -x` or `echo` before commands, avoid state modifications
- Document all test modes in script header comments
- Log which variable source was used for transparency

### 9. Monorepo Sub-Project Detection

**Question**: How to determine which sub-project is affected by a commit/tag?

**Decision**: Parse tag path prefix and use git diff for automatic detection

**Rationale**:
- Tag format `<path>/v<version>` encodes sub-project explicitly
- For automatic detection: `git diff --name-only` to find changed files
- Map file paths to sub-projects using directory structure
- Root project uses empty path prefix (tags like `v1.0.0`, not `/v1.0.0`)

**Alternatives Considered**:
- Monorepo tools (Nx, Turborepo): Rejected because adds heavy dependency just for path detection
- Configuration file mapping: Rejected because requires manual maintenance as projects added
- Changed file heuristic only: Rejected because can't handle explicit tag-based deployments
- Single project assumption: Rejected because requirement explicitly supports monorepos

**Implementation Notes**:
- Create helper function `detect_subproject()` in shared script utilities
- Support both explicit path (from tag) and automatic detection (from changed files)
- Default to root project when ambiguous
- Document sub-project detection logic in README

### 10. Pipeline Independence & State Management

**Question**: How should pipelines coordinate without shared mutable state?

**Decision**: Stateless pipeline architecture with git tags as single source of truth

**Rationale**:
- **Constitution Compliance**: Stateless pipeline principles prohibit shared mutable state and execution order dependencies
- **Concurrency safety**: Multiple pipeline runs execute simultaneously without race conditions
- **Reliability**: No external dependencies that can fail or become inconsistent
- **Reproducibility**: Re-running a pipeline produces the same result (given same commit and inputs)
- **Testability**: Each pipeline run can be tested in isolation
- **Simplicity**: No external state store to manage, secure, or back up
- Git tags provide atomic, durable state (environment tags moved with force-push)
- GitHub Actions concurrency groups handle deployment conflict protection natively
- GitHub Variables and Secrets are read-only configuration (not mutable runtime state)

**Alternatives Considered**:
- **Custom FIFO queue**: Rejected because violates stateless pipeline principles (requires shared mutable state and execution order dependencies)
- **Shared state files in repository**: Rejected because requires commit+push during pipeline (creates noise, race conditions, conflicts)
- **External database (Redis, PostgreSQL)**: Rejected because adds infrastructure dependency and violates statelessness
- **GitHub Actions artifacts**: Rejected because artifacts are scoped to single workflow run (not shared across workflows)
- **GitHub API (issues, discussions)**: Rejected because not designed for state coordination, rate limits apply

**Implementation Notes**:
- Deployment conflicts use GitHub Actions `concurrency` groups (native, no external state)
- Environment tags moved atomically with `git tag -f && git push -f` (last write wins, no locks needed)
- Version detection uses `git tag --points-at` (read-only, always current)
- Pipeline metadata stored in GitHub Actions workflow runs (read-only historical data)
- No coordination files (e.g., `.deployment-lock`, `current-version.txt`, queue state)
- Scripts compute state from git tags on every run (idempotent)
- Fail-fast approach with retry links instead of queued execution

**Concurrency Guarantees**:
- Same environment: Conflict detection with fail-fast and retry links
- Different environments: Fully concurrent (no blocking)
- Tag creation: Atomic git operation (no partial writes)
- Tag reading: Eventually consistent (git fetch may be stale by seconds)
- Pipeline behavior: Deterministic and reproducible regardless of execution order or timing

## Technology Stack Validation

### Core Tools

| Tool | Version | Purpose | Validation |
|------|---------|---------|------------|
| GitHub Actions | N/A | CI/CD platform | Native, no installation required |
| Bash | 5.x | Script runtime | Pre-installed on ubuntu-latest runners |
| Bun | Latest | TypeScript script runtime | Fast, single binary, npm-compatible |
| MISE | Latest | Tool management | Single binary, already adopted |
| SOPS | Latest | Secret encryption | Single binary, integrates with age/KMS |
| age | Latest | Encryption backend | Simple, modern, file-based keys |
| Lefthook | Latest | Git hooks manager | Already adopted, fast Go binary |
| Commitizen | Latest | Commit enforcement | npm package, widely used |
| Gitleaks | Latest | Secret scanning | Fast Go binary, actively maintained |
| Trufflehog | Latest | Secret scanning | Entropy detection, complements Gitleaks |
| Apprise | Latest | Notifications | Python package, 90+ service support |

### Best Practices Validation

**GitHub Actions**:
- ✅ Use specific action versions (not `@main` or `@latest`)
- ✅ Pin runner images to major version (`ubuntu-latest` is acceptable)
- ✅ Use caching for dependencies and build artifacts
- ✅ Minimize workflow YAML logic (extract to scripts)
- ✅ Use job concurrency for resource protection

**Secret Management**:
- ✅ SOPS + age is industry standard for git-committed secrets
- ✅ Age keys simpler than GPG (no key servers, expiration, web-of-trust)
- ✅ MISE tasks provide consistent interface across local/CI
- ✅ Never commit decrypted secrets or age private keys

**Script Organization**:
- ✅ Numbered prefix pattern (10, 20, 30) allows insertion without renaming
- ✅ Folder grouping by lifecycle phase improves discoverability
- ✅ Bash for CI (universal), TypeScript/Bun for complex logic (type safety)
- ✅ No Python (avoid language fragmentation in CI)

**Testing**:
- ✅ Environment variable driven testing is standard pattern
- ✅ DRY_RUN mode enables safe command preview
- ✅ Test mode enumeration covers all execution paths
- ✅ Matrix testing generates comprehensive coverage

## Dependencies and Integration Points

### GitHub Actions Integrations

- **Workflow Dispatch**: Manual workflow triggering with input parameters (used for tag assignment, rollback, maintenance tasks)
- **Workflow Call**: Reusable workflows (may use for shared deployment logic across environments)
- **Job Summary API**: Markdown reports in workflow UI
- **Concurrency Groups**: Deployment queue management
- **Artifacts API**: Build outputs, test results, coverage reports
- **Cache API**: Dependencies, build caches

### External Services (Optional)

- **Apprise Targets**: Slack, Teams, Discord, Telegram, Email (configured via APPRISE_URL secret)
- **Docker Registry**: GitHub Container Registry (ghcr.io) or Docker Hub
- **npm Registry**: npmjs.org or private registry
- **Cloud Providers**: AWS, Azure, GCP (for deployments, credentials via SOPS-encrypted files)

### Local Development Tools

- **MISE**: Automatically installs and manages all required tools
- **Lefthook**: Runs git hooks for secret scanning and commit validation
- **SOPS + age**: Encrypts/decrypts environment secrets
- **Commitizen**: Interactive commit message prompt

## Open Questions (Resolved)

All technical unknowns from the specification have been resolved. No blocking questions remain.

## Next Steps

Proceed to Phase 1:
1. Generate `data-model.md` with entity definitions
2. Create API contracts in `/contracts/` directory (GitHub Actions workflow interfaces)
3. Generate `quickstart.md` with setup instructions
4. Update agent context file with technology stack

---

**Research Complete**: 2025-11-21
**Approved By**: Initial planning phase
