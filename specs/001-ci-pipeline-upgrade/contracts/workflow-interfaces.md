# Workflow Interface Contracts

**Feature**: 001-ci-pipeline-upgrade
**Date**: 2025-11-21
**Type**: GitHub Actions Workflow Interfaces

## Overview

This document defines the interface contracts for all GitHub Actions workflows in the CI/CD pipeline. Each contract specifies inputs, outputs, triggers, and behavioral guarantees.

---

## Pre-Release Pipeline

**File**: `.github/workflows/pre-release.yml`

**Purpose**: Run comprehensive CI checks on pull requests and development branch pushes.

### Triggers

- `pull_request`: Any PR to main branch
- `push`: Commits to main branch
- `workflow_dispatch`: Manual trigger for testing

### Inputs (workflow_dispatch only)

| Input | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `enable_e2e` | boolean | No | false | Override ENABLE_E2E_TESTS variable |
| `test_mode` | choice | No | EXECUTE | CI_TEST_MODE override (EXECUTE, DRY_RUN, PASS, FAIL, SKIP) |

### Outputs

- **GitHub Job Summary**: Pipeline status, test results, actionable links
- **Artifacts** (7 day retention):
  - `build-outputs`: Compiled artifacts from compile job
  - `test-results`: Unit, integration, e2e test reports
  - `coverage-report`: Code coverage data
  - `security-scan-results`: Gitleaks and Trufflehog findings

### Jobs

1. **setup**: Install dependencies, validate environment (always runs)
2. **compile**: Build project artifacts (skips if not applicable)
3. **lint**: Run linting and formatting checks
4. **unit-tests**: Execute unit test suite
5. **integration-tests**: Execute integration test suite (if ENABLE_INTEGRATION_TESTS)
6. **e2e-tests**: Execute e2e test suite (if ENABLE_E2E_TESTS)
7. **security-scan**: Secret scanning, dependency audit (always runs, not guardable)
8. **bundle**: Create production bundles (if ENABLE_BUNDLING)
9. **package**: Package artifacts for distribution (if ENABLE_PACKAGING)
10. **notify-pre-release**: Send notifications, generate summary (always runs)

### Behavioral Guarantees

- Security scan MUST always run regardless of enable flags
- Pipeline MUST NOT fail due to disabled optional features
- Dependent jobs MUST handle skipped prerequisites gracefully
- Notification job MUST run even if previous jobs fail
- Artifacts MUST be uploaded before jobs exit

### Action Links Generated

- **Promote to Release**: Trigger release workflow with detected version
- **Self-Healing**: Trigger formatting/linting fix pipeline
- **Rollback**: Trigger rollback workflow (if version tag detected)
- **Maintenance Tasks**: Links to trigger each maintenance mode

---

## Release Pipeline

**File**: `.github/workflows/release.yml`

**Purpose**: Publish releases to npm, Docker, GitHub Releases, and documentation sites.

### Triggers

- `push.tags`: Version tags matching `v*.*.*` or `*/v*.*.*` pattern
- `workflow_dispatch`: Manual trigger with version parameter

### Inputs (workflow_dispatch)

| Input | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `version` | string | Yes | - | Version to release (e.g., `v1.2.3` or `api/v1.2.3`) |
| `skip_npm` | boolean | No | false | Skip npm publishing |
| `skip_docker` | boolean | No | false | Skip Docker publishing |
| `skip_docs` | boolean | No | false | Skip documentation deployment |

### Outputs

- **GitHub Job Summary**: Release status, published artifacts, download links
- **Artifacts** (90 day retention):
  - `release-artifacts`: Published packages and binaries
  - `changelog`: Generated changelog for this release
  - `release-notes`: Formatted release notes

### Jobs

1. **determine-version**: Parse version from tag or input
2. **changelog**: Generate changelog from conventional commits
3. **publish-npm**: Publish to npm registry (if ENABLE_NPM_PUBLISH)
4. **publish-github**: Create GitHub Release with artifacts
5. **publish-docker**: Build and push Docker images (if ENABLE_DOCKER_PUBLISH)
6. **deploy-docs**: Deploy documentation site (if ENABLE_DOCS_DEPLOY)
7. **notify-release**: Send release notifications, generate summary

### Behavioral Guarantees

- Version determination MUST validate semver format
- Changelog MUST be generated from conventional commits since last tag
- Publishing failures MUST NOT block GitHub Release creation
- Artifacts MUST be attached to GitHub Release
- Release notes MUST include contributor credits

### Action Links Generated

- **Deploy to Staging**: Trigger staging deployment
- **Deploy to Production**: Trigger production deployment
- **Tag as Stable**: Mark version as stable
- **Rollback**: Quick rollback to previous version

---

## Post-Release Pipeline

**File**: `.github/workflows/post-release.yml`

**Purpose**: Verify deployed releases with smoke tests and health checks.

### Triggers

- `workflow_run`: Triggered after successful release workflow
- `workflow_dispatch`: Manual trigger with deployment details

### Inputs (workflow_dispatch)

| Input | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `version` | string | Yes | - | Version to verify |
| `environment` | choice | Yes | - | Environment to check (staging, production) |
| `region` | string | No | all | Specific region or 'all' |

### Outputs

- **GitHub Job Summary**: Verification results, health check status
- **Artifacts** (30 day retention):
  - `smoke-test-results`: Smoke test execution results
  - `health-check-logs`: Health check responses

### Jobs

1. **smoke-tests**: Execute smoke tests against deployed version
2. **health-checks**: Verify all endpoints are responding
3. **performance-check**: Basic performance validation (if ENABLE_PERFORMANCE_CHECK)
4. **notify-post-release**: Report verification status

### Behavioral Guarantees

- Verification MUST wait for deployment to be fully complete
- Health checks MUST retry with exponential backoff
- Failures MUST trigger rollback notification
- Success MUST recommend marking version as stable

### Action Links Generated

- **Mark as Stable**: Assign stable state tag
- **Rollback**: Immediate rollback if issues detected
- **Open Incident**: Create incident issue if critical failure

---

## Maintenance Pipeline

**File**: `.github/workflows/maintenance.yml`

**Purpose**: Run scheduled and on-demand maintenance tasks.

### Triggers

- `schedule`: Cron expression for nightly maintenance (`0 2 * * *`)
- `workflow_dispatch`: Manual trigger with task selection

### Inputs (workflow_dispatch)

| Input | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `task_mode` | choice | Yes | all | Task to run: cleanup, sync-files, deprecate-old-versions, security-audit, dependency-update, all |
| `dry_run` | boolean | No | false | Run in dry-run mode (preview changes) |

### Outputs

- **GitHub Job Summary**: Task results, statistics, recommendations
- **Artifacts** (30 day retention):
  - `maintenance-report`: Detailed maintenance results
  - `dependency-updates`: Available dependency updates (if applicable)

### Jobs

1. **cleanup**: Remove old artifacts, caches, deprecated tags
2. **sync-files**: Synchronize shared files across sub-projects
3. **deprecate-old-versions**: Auto-mark old versions as deprecated
4. **security-audit**: Run comprehensive security audit
5. **dependency-update**: Check for and propose dependency updates
6. **notify-maintenance**: Report maintenance results

### Behavioral Guarantees

- Cleanup MUST preserve recent artifacts (last 30 days)
- Deprecation MUST NOT affect currently deployed versions
- Security audit MUST fail pipeline if critical vulnerabilities found
- Dependency updates MUST create PRs, not auto-commit

### Action Links Generated

- **Review Dependency PRs**: Links to created dependency update PRs
- **Security Dashboard**: Link to security findings (if applicable)
- **Manual Cleanup**: Trigger additional cleanup with custom retention

---

## Tag Assignment Workflow

**File**: `.github/workflows/tag-assignment.yml`

**Purpose**: Assign version, environment, and state tags to commits (controlled tag creation).

### Triggers

- `workflow_dispatch`: Manual trigger with tag parameters

### Inputs (workflow_dispatch)

| Input | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `tag_type` | choice | Yes | - | Type: version, environment, or state |
| `version` | string | Conditional | - | Version (e.g., `v1.2.3`) - required if tag_type=version or state |
| `commit_sha` | string | No | HEAD | Commit to tag (defaults to HEAD) |
| `environment` | choice | Conditional | - | Environment (if tag_type=environment): production, staging, canary, sandbox, performance |
| `state` | choice | Conditional | - | State (if tag_type=state): stable, unstable, deprecated |
| `sub_project` | string | No | - | Sub-project path (empty for root) |
| `force_move` | boolean | No | false | Force move existing environment tag (admin only, only for environment tags) |

### Outputs

- **GitHub Job Summary**: Tag creation/move result, deployment trigger status
- Tag created or moved in git repository
- Deployment workflow triggered (if environment tag)

### Jobs

1. **validate-tag**: Verify format, check immutability rules
2. **create-or-move-tag**: Create new tag or move existing environment tag
3. **trigger-deployment**: Trigger deployment workflow (if environment tag)
4. **notify-tag-assignment**: Report tag operation

### Behavioral Guarantees

**Version Tags** (`api/v1.2.3`):
- MUST validate that tag doesn't already exist
- MUST validate semver format
- MUST be immutable (never moved)
- Does NOT trigger deployment

**Environment Tags** (`api/production`):
- MAY move to new commit if `force_move=true`
- Uses `git tag -f <tag> <commit>` then `git push -f origin <tag>`
- MUST trigger deployment workflow after creation/move
- MUST log tag move with old and new commit SHAs

**State Tags** (`api/v1.2.3-stable`):
- MUST validate that corresponding version tag exists
- MUST be immutable (never moved)
- Does NOT trigger deployment
- Used for rollback prioritization

### Action Links Generated

- **View Deployment**: Link to triggered deployment workflow (environment tags only)
- **Assign State**: Assign stable/unstable state to version
- **Deploy to Other Environments**: Quick links to deploy same version elsewhere
- **Rollback**: Quick rollback link (shows previous version)

---

## Deployment Workflow

**File**: `.github/workflows/deployment.yml`

**Purpose**: Deploy to environment when environment tag is created/moved.

### Triggers

- `push.tags`: Environment tags matching pattern `*/(production|staging|canary|sandbox|performance)` or `(production|staging|canary|sandbox|performance)` (for root project)
- `workflow_dispatch`: Manual trigger with deployment parameters

### Inputs (workflow_dispatch)

| Input | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `environment` | choice | Yes | - | Target environment |
| `sub_project` | string | No | - | Sub-project path (empty for root) |
| `region` | string | No | all | Target region or 'all' |
| `skip_queue` | boolean | No | false | Skip queue (admin only) |

### Outputs

- **GitHub Job Summary**: Deployment status, deployed version, queue position, completion time
- **Artifacts** (30 day retention):
  - `deployment-logs`: Deployment execution logs
  - `deployment-manifest`: Manifest of what was deployed (commit SHA, version, timestamp)

### Jobs

1. **detect-version**: Determine version from commit (find version tag pointing to same commit as environment tag)
2. **queue-check**: Check deployment queue, assign position
3. **pre-deployment**: Validate environment, check prerequisites, decrypt secrets
4. **deploy**: Execute deployment scripts for target environment/region
5. **post-deployment**: Run smoke tests, update environment tag if not already updated
6. **notify-deployment**: Report deployment results

### Concurrency

```yaml
concurrency:
  group: deploy-${{ github.ref_name }}  # ref_name is the environment tag (e.g., "api/production")
  cancel-in-progress: false  # Queue, don't cancel
```

### Behavioral Guarantees

- MUST detect version by finding version tag on same commit as environment tag
- MUST respect deployment queue (same environment tag)
- MUST allow concurrent deployments to different environments
- MUST decrypt SOPS secrets before deployment
- MUST update deployment status in GitHub summary with version information
- MUST trigger post-release verification after success
- MUST provide rollback link if deployment fails
- MUST NOT deploy if no version tag found on commit

### Action Links Generated

- **Verify Deployment**: Link to post-release verification
- **Rollback**: Immediate rollback to previous version
- **Deploy to Next Region**: Deploy to next region (if multi-region)
- **Mark as Stable**: Assign stable state tag to deployed version

---

## Rollback Workflow

**File**: `.github/workflows/rollback.yml`

**Purpose**: Roll back deployment to previous version with automatic version detection.

### Triggers

- `workflow_dispatch`: Manual trigger with environment parameter

### Inputs (workflow_dispatch)

| Input | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `environment` | choice | Yes | - | Environment to roll back |
| `sub_project` | string | No | - | Sub-project path (empty for root) |
| `target_version` | string | No | auto | Specific version or 'auto' to detect |
| `region` | string | No | all | Target region or 'all' |

### Outputs

- **GitHub Job Summary**: Rollback status, current version, target version, completion time
- **Artifacts** (30 day retention):
  - `rollback-report`: Rollback execution details with version selection reasoning

### Jobs

1. **identify-current**: Find current version (check which version tag points to same commit as environment tag)
2. **identify-target**: Scan version tags, identify previous version using semver comparison
3. **validate-target**: Verify target version is valid rollback candidate
4. **execute-rollback**: Move environment tag to target version commit, trigger deployment
5. **verify-rollback**: Run smoke tests on rolled-back version
6. **notify-rollback**: Report rollback results

### Behavioral Guarantees

- MUST identify current version from environment tag commit
- MUST scan all version tags for sub-project to find candidates
- MUST identify highest previous version by semver comparison (excluding current)
- MUST prioritize versions with `-stable` state tag over those without
- MUST exclude versions with `-deprecated` state tag
- MUST fail if no valid rollback target exists
- MUST provide clear explanation of target selection with reasoning
- MUST move environment tag to rollback target commit (triggering deployment)
- MUST log rollback with current version, target version, and reason

### Rollback Target Selection Algorithm

```
1. Get current commit: git rev-parse <sub_project>/<environment>
2. Find current version: git tag --points-at <commit> | grep '^<sub_project>/v'
3. List all versions: git tag -l '<sub_project>/v*' | grep -vE '-(stable|unstable|deprecated)$'
4. Sort by semver: git tag --sort=-version:refname
5. Filter: exclude current version
6. Check state tags: for each candidate, check if <candidate>-stable exists
7. Prioritize: stable candidates first, then non-stable
8. Exclude deprecated: remove any with <candidate>-deprecated tag
9. Select: highest remaining version
10. Fail if none found
```

### Action Links Generated

- **Verify Rolled-Back Version**: Link to post-release verification
- **Re-Deploy Original**: Re-deploy the version we rolled back from (move environment tag back)
- **Mark as Unstable**: Assign unstable state tag to failed version
- **Open Incident**: Create incident issue for root cause analysis

---

## Self-Healing Workflow

**File**: `.github/workflows/self-healing.yml`

**Purpose**: Automatically format and lint code, then create fix commit.

### Triggers

- `workflow_dispatch`: Manual trigger (typically from link in failed pipeline)

### Inputs (workflow_dispatch)

| Input | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `branch` | string | No | current | Branch to fix (defaults to current branch) |
| `scope` | choice | No | all | What to fix: format, lint, all |

### Outputs

- **GitHub Job Summary**: Fix results, commit created
- Commit created with fixes (if any changes)

### Jobs

1. **auto-format**: Run code formatters (prettier, etc.)
2. **auto-lint-fix**: Run linters with auto-fix enabled
3. **commit-fixes**: Create and push commit with fixes
4. **notify-healing**: Report healing results

### Behavioral Guarantees

- MUST run formatters and linters with auto-fix enabled
- MUST create commit ONLY if changes were made
- MUST use conventional commit message: `chore: auto-fix formatting and linting [skip ci]`
- MUST NOT create commit if no changes
- MUST trigger pre-release pipeline after commit (without [skip ci])

### Action Links Generated

- **View Fix Commit**: Link to created commit
- **Run Pipeline**: Re-run pre-release pipeline to verify fixes

---

## Script Interface Contracts

All CI scripts follow a standard interface with hierarchical testability control.

### Environment Variables (Inputs)

| Variable | Purpose | Values | Precedence |
|----------|---------|--------|------------|
| `CI_TEST_<PIPELINE>_<SCRIPT>_BEHAVIOR` | Pipeline + script specific control | EXECUTE, DRY_RUN, PASS, FAIL, SKIP, TIMEOUT | 1 (highest) |
| `CI_TEST_<SCRIPT>_BEHAVIOR` | Script-level control (all pipelines) | Same as above | 2 |
| `CI_TEST_MODE` | Global default (all scripts) | Same as above | 3 |
| Default behavior | Hardcoded fallback | EXECUTE | 4 (lowest) |
| `CI_JOB_TIMEOUT_MINUTES` | Job timeout override | Integer (minutes) | N/A |
| `SOPS_AGE_KEY` | Age key for secret decryption | Base64-encoded age private key | N/A |

### Variable Naming Rules

**Pipeline Names**:
- Derived from `GITHUB_WORKFLOW` environment variable
- Transformed to uppercase, alphanumeric with underscores
- Examples:
  - `"Pre-Release Pipeline"` → `PRE_RELEASE`
  - `"Deployment - Production"` → `DEPLOYMENT_PRODUCTION`
  - `"Maintenance"` → `MAINTENANCE`

**Script Names**:
- Derived from script filename (basename without path)
- Numeric prefix removed, uppercase, hyphens become underscores
- Examples:
  - `10-ci-compile.sh` → `COMPILE`
  - `30-ci-publish-npm.sh` → `PUBLISH_NPM`
  - `ci-security-scan.sh` → `SECURITY_SCAN`

### Testability Examples

**Scenario 1: Test new deployment script in staging only**
```bash
# Set in GitHub Variables:
CI_TEST_DEPLOYMENT_STAGING_DEPLOY_BEHAVIOR=DRY_RUN

# Result:
# - Staging deployment: runs in DRY_RUN (safe testing)
# - Production deployment: runs in EXECUTE (normal)
```

**Scenario 2: Test npm publishing across all pipelines**
```bash
# Set in GitHub Variables:
CI_TEST_PUBLISH_NPM_BEHAVIOR=DRY_RUN

# Result:
# - All pipelines using publish-npm script: DRY_RUN
```

**Scenario 3: Run entire pre-release in DRY_RUN except security**
```bash
# Set in GitHub Variables:
CI_TEST_MODE=DRY_RUN
CI_TEST_SECURITY_SCAN_BEHAVIOR=EXECUTE

# Result:
# - All scripts: DRY_RUN
# - Security scan: EXECUTE (must always run for real)
```

**Scenario 4: Gradual rollout of script changes**
```bash
# Week 1: Test in pre-release only
CI_TEST_PRE_RELEASE_COMPILE_BEHAVIOR=DRY_RUN

# Week 2: Test in release pipeline
CI_TEST_RELEASE_COMPILE_BEHAVIOR=DRY_RUN

# Week 3: Full rollout (remove variables)
```

### Exit Codes (Outputs)

| Code | Meaning |
|------|---------|
| 0 | Success or skip |
| 1 | Failure |
| 124 | Timeout (if manually implemented) |

### Standard Output Format

Scripts MUST output structured logs:
```
[INFO] Starting <script-name>
[DEBUG] Environment: <details>
[INFO] Executing: <command>
[SUCCESS] Completed in <duration>
```

Or on failure:
```
[ERROR] Failed: <reason>
[DEBUG] Context: <details>
```

### Testability Contract

Every script MUST implement this pattern:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Derive script name from filename
SCRIPT_NAME=$(basename "$0" | sed 's/^[0-9]*-ci-//; s/\.sh$//; s/-/_/g' | tr '[:lower:]' '[:upper:]')

# Derive pipeline name from GitHub workflow
PIPELINE_NAME=$(echo "${GITHUB_WORKFLOW:-}" | tr '[:lower:]' '[:upper:]' | tr -c '[:alnum:]' '_' | sed 's/__*/_/g; s/^_//; s/_$//')

# Resolve test mode with precedence hierarchy
MODE="${!CI_TEST_${PIPELINE_NAME}_${SCRIPT_NAME}_BEHAVIOR:-}"
MODE="${MODE:-${!CI_TEST_${SCRIPT_NAME}_BEHAVIOR:-}}"
MODE="${MODE:-${CI_TEST_MODE:-EXECUTE}}"

# Log which variable source was used (for transparency)
if [ -n "${!CI_TEST_${PIPELINE_NAME}_${SCRIPT_NAME}_BEHAVIOR:-}" ]; then
  echo "[INFO] Test mode: $MODE (from CI_TEST_${PIPELINE_NAME}_${SCRIPT_NAME}_BEHAVIOR)"
elif [ -n "${!CI_TEST_${SCRIPT_NAME}_BEHAVIOR:-}" ]; then
  echo "[INFO] Test mode: $MODE (from CI_TEST_${SCRIPT_NAME}_BEHAVIOR)"
elif [ -n "${CI_TEST_MODE:-}" ]; then
  echo "[INFO] Test mode: $MODE (from CI_TEST_MODE)"
else
  echo "[INFO] Test mode: $MODE (default)"
fi

# Implement test mode handlers
case "$MODE" in
  DRY_RUN)
    echo "[DRY_RUN] Would execute: <command>"
    # Print commands without executing
    exit 0
    ;;
  PASS)
    echo "[PASS] Simulated success"
    exit 0
    ;;
  FAIL)
    echo "[FAIL] Simulated failure"
    exit 1
    ;;
  SKIP)
    echo "[SKIP] Step skipped"
    exit 0
    ;;
  TIMEOUT)
    echo "[TIMEOUT] Simulating hang (will timeout based on job limit)"
    sleep infinity
    ;;
  EXECUTE)
    # Normal execution
    echo "[INFO] Starting ${SCRIPT_NAME} (pipeline: ${PIPELINE_NAME:-UNKNOWN})"
    # ... actual script logic ...
    ;;
  *)
    echo "[ERROR] Unknown test mode: $MODE"
    exit 1
    ;;
esac
```

**Requirements**:
1. MUST implement hierarchical variable lookup (pipeline + script, script, global, default)
2. MUST support all test modes (EXECUTE, DRY_RUN, PASS, FAIL, SKIP, TIMEOUT)
3. MUST log which variable source was used for transparency
4. MUST derive script name from filename automatically
5. MUST derive pipeline name from `GITHUB_WORKFLOW` automatically
6. In DRY_RUN mode: MUST print commands without executing state changes
7. In PASS/FAIL/SKIP/TIMEOUT modes: MUST exit immediately with appropriate code

---

## Cross-Workflow Communication

### Workflow Dispatch URLs

All action links use this pattern:
```
https://github.com/{org}/{repo}/actions/workflows/{workflow}.yml?inputs={encoded_params}
```

Example:
```
https://github.com/myorg/myrepo/actions/workflows/tag-assignment.yml?inputs=version:v1.2.3,environment:production
```

### Workflow Run Metadata

Workflows share context via GitHub Actions context variables:
- `${{ github.sha }}`: Commit SHA
- `${{ github.ref }}`: Git ref (branch or tag)
- `${{ github.event.workflow_run.id }}`: Triggering workflow run ID
- `${{ github.actor }}`: User who triggered workflow

### Artifact Passing

Workflows pass artifacts using GitHub Actions artifacts:
```yaml
- uses: actions/upload-artifact@v4
  with:
    name: build-outputs
    path: dist/

- uses: actions/download-artifact@v4
  with:
    name: build-outputs
```

---

**Contracts Complete**: 2025-11-21
**Next Phase**: Generate quickstart.md
