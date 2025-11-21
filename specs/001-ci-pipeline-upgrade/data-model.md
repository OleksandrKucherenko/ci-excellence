# Data Model: CI Pipeline Comprehensive Upgrade

**Feature**: 001-ci-pipeline-upgrade
**Date**: 2025-11-21
**Phase**: Phase 1 - Design

## Overview

This document defines the key entities, their attributes, relationships, and validation rules for the CI/CD pipeline upgrade. These entities represent the core domain concepts used throughout workflows, scripts, and configuration.

## Entity Definitions

### 1. Version

Represents a semantic version identifier for deployable artifacts.

**Attributes**:
- `full_version` (string, required): Complete version string including sub-project path (e.g., `api/v1.2.3`, `v2.0.0`)
- `sub_project_path` (string, optional): Path to sub-project within monorepo (empty for root project)
- `semver` (string, required): Semantic version following MAJOR.MINOR.PATCH format
- `major` (integer, required): Major version number
- `minor` (integer, required): Minor version number
- `patch` (integer, required): Patch version number
- `prerelease` (string, optional): Pre-release suffix (e.g., `alpha.1`, `beta.3`, `rc.1`)

**Validation Rules**:
- `semver` MUST match pattern: `v\d+\.\d+\.\d+(-[a-zA-Z0-9.-]+)?`
- `sub_project_path` MUST NOT start or end with `/`
- `major`, `minor`, `patch` MUST be non-negative integers
- If `prerelease` is present, it MUST follow semver pre-release conventions

**State Transitions**: N/A (immutable once created)

**Example**:
```json
{
  "full_version": "api/v1.2.3-beta.1",
  "sub_project_path": "api",
  "semver": "v1.2.3-beta.1",
  "major": 1,
  "minor": 2,
  "patch": 3,
  "prerelease": "beta.1"
}
```

### 2. VersionTag

Represents a git tag marking versions, deployments, or quality states.

**Attributes**:
- `tag_name` (string, required): Complete git tag string
- `tag_type` (enum, required): Type of tag - `version` | `environment` | `state`
- `sub_project_path` (string, optional): Path to sub-project within monorepo (empty for root)
- `version` (Version, optional): Parsed version information (only for version and state tags)
- `environment` (string, optional): Environment name (only for environment tags)
- `state` (string, optional): State name (only for state tags)
- `commit_sha` (string, required): Git commit SHA this tag points to
- `is_movable` (boolean, required): Whether tag can be moved to different commits
- `created_at` (timestamp, required): Tag creation timestamp
- `updated_at` (timestamp, optional): Tag last move timestamp (for movable tags)

**Validation Rules**:
- Version tags MUST match pattern: `(<path>/)?v\d+\.\d+\.\d+$` (e.g., `api/v1.2.3`, `v2.0.0`)
- Environment tags MUST match pattern: `(<path>/)?(production|staging|canary|sandbox|performance)$` (e.g., `api/production`, `staging`)
- State tags MUST match pattern: `(<path>/)?v\d+\.\d+\.\d+-(stable|unstable|deprecated)$` (e.g., `api/v1.2.3-stable`)
- `tag_type` = `version`: `version` MUST be set, `is_movable` MUST be false
- `tag_type` = `environment`: `environment` MUST be set, `is_movable` MUST be true
- `tag_type` = `state`: `version` and `state` MUST be set, `is_movable` MUST be false
- `commit_sha` MUST be valid 40-character hex string
- `updated_at` MUST only be set if `is_movable` is true

**State Transitions**:
- Version tags: Immutable once created (never moved or deleted)
- Environment tags: Movable (can be deleted and recreated on different commits)
- State tags: Immutable once created (never moved or deleted)
- Administrators can override immutability for emergency fixes

**Examples**:
```json
// Version tag
{
  "tag_name": "api/v1.2.3",
  "tag_type": "version",
  "sub_project_path": "api",
  "version": { "semver": "v1.2.3", "major": 1, "minor": 2, "patch": 3, ... },
  "environment": null,
  "state": null,
  "commit_sha": "abc123def456...",
  "is_movable": false,
  "created_at": "2025-11-21T10:30:00Z",
  "updated_at": null
}

// Environment tag (movable pointer)
{
  "tag_name": "api/production",
  "tag_type": "environment",
  "sub_project_path": "api",
  "version": null,
  "environment": "production",
  "state": null,
  "commit_sha": "abc123def456...",
  "is_movable": true,
  "created_at": "2025-11-21T10:30:00Z",
  "updated_at": "2025-11-21T14:00:00Z"
}

// State tag
{
  "tag_name": "api/v1.2.3-stable",
  "tag_type": "state",
  "sub_project_path": "api",
  "version": { "semver": "v1.2.3", "major": 1, "minor": 2, "patch": 3, ... },
  "environment": null,
  "state": "stable",
  "commit_sha": "abc123def456...",
  "is_movable": false,
  "created_at": "2025-11-21T15:00:00Z",
  "updated_at": null
}
```

### 3. Environment

Represents a deployment target environment with configuration.

**Attributes**:
- `name` (string, required): Environment identifier (e.g., `production`, `staging`)
- `config_path` (string, required): Path to environment configuration folder
- `regions` (array<Region>, optional): Regions within this environment
- `secrets_file` (string, required): Path to SOPS-encrypted secrets file
- `is_production` (boolean, required): Whether this is a production environment
- `requires_approval` (boolean, required): Whether deployments need manual approval

**Validation Rules**:
- `name` MUST match pattern: `[a-z][a-z0-9-]*`
- `config_path` MUST be relative path within `environments/` directory
- `secrets_file` MUST exist and be SOPS-encrypted
- `is_production` MUST be true if `name` is `production`
- `requires_approval` SHOULD be true if `is_production` is true

**State Transitions**: N/A (configuration, not stateful)

**Example**:
```json
{
  "name": "production",
  "config_path": "environments/production",
  "regions": [ { "name": "us-east", ... }, { "name": "eu-west", ... } ],
  "secrets_file": "environments/production/secrets.enc",
  "is_production": true,
  "requires_approval": true
}
```

### 4. Region

Represents a geographic region within an environment.

**Attributes**:
- `name` (string, required): Cloud-agnostic region name (e.g., `us-east`, `eu-west`)
- `config_path` (string, required): Path to region-specific configuration
- `cloud_mappings` (map<string, string>, required): Cloud-provider-specific region identifiers

**Validation Rules**:
- `name` MUST match pattern: `[a-z]{2}-[a-z]+`
- `config_path` MUST be relative path within environment's regions folder
- `cloud_mappings` MUST include at least one cloud provider

**State Transitions**: N/A (configuration, not stateful)

**Example**:
```json
{
  "name": "us-east",
  "config_path": "environments/production/regions/us-east",
  "cloud_mappings": {
    "aws": "us-east-1",
    "azure": "eastus",
    "gcp": "us-east1"
  }
}
```

### 5. Deployment

Represents a deployment operation to a specific environment.

**Attributes**:
- `deployment_id` (string, required): Unique identifier for this deployment
- `version` (Version, required): Version being deployed
- `environment` (Environment, required): Target environment
- `region` (Region, optional): Target region within environment
- `commit_sha` (string, required): Commit being deployed
- `will_move_env_tag` (boolean, required): Whether this deployment will move the environment tag
- `status` (enum, required): Current status - `queued` | `in_progress` | `succeeded` | `failed` | `cancelled`
- `queue_position` (integer, optional): Position in deployment queue (if queued)
- `estimated_wait_time` (integer, optional): Estimated wait time in seconds (if queued)
- `started_at` (timestamp, optional): When deployment started
- `completed_at` (timestamp, optional): When deployment finished
- `workflow_run_id` (string, required): GitHub Actions workflow run ID
- `triggered_by` (string, required): User or system that triggered deployment

**Validation Rules**:
- `deployment_id` MUST be unique across all deployments
- `status` MUST start as `queued` or `in_progress`
- `queue_position` MUST be set if status is `queued`
- `started_at` MUST be set when status changes to `in_progress`
- `completed_at` MUST be set when status changes to terminal state (`succeeded`, `failed`, `cancelled`)
- `workflow_run_id` MUST be valid GitHub Actions run ID
- `commit_sha` MUST have a corresponding version tag
- If deployment succeeds and `will_move_env_tag` is true, environment tag MUST be moved to `commit_sha`

**State Transitions**:
```
queued → in_progress → succeeded (moves env tag if will_move_env_tag=true)
                    ↘ failed (does not move env tag)
queued → cancelled
in_progress → cancelled
```

**Example**:
```json
{
  "deployment_id": "deploy-20251121-103045-abc123",
  "version": { "semver": "v1.2.3", "sub_project_path": "api", ... },
  "environment": { "name": "production", ... },
  "region": { "name": "us-east", ... },
  "commit_sha": "abc123def456...",
  "will_move_env_tag": true,
  "status": "in_progress",
  "queue_position": null,
  "estimated_wait_time": null,
  "started_at": "2025-11-21T10:30:45Z",
  "completed_at": null,
  "workflow_run_id": "1234567890",
  "triggered_by": "github-actions[bot]"
}
```

### 6. DeploymentQueue

Represents a FIFO queue of pending deployments for a specific environment.

**Attributes**:
- `environment` (string, required): Environment name this queue manages
- `queue` (array<Deployment>, required): Ordered list of queued deployments
- `current_deployment` (Deployment, optional): Currently executing deployment
- `locked_at` (timestamp, optional): When queue was locked for current deployment

**Validation Rules**:
- `environment` MUST be valid environment name
- All deployments in `queue` MUST have `status` = `queued`
- All deployments in `queue` MUST target the same environment
- `current_deployment` MUST have `status` = `in_progress` if present
- `locked_at` MUST be set if `current_deployment` is present

**State Transitions**:
- Add deployment: append to `queue` array
- Start deployment: pop from `queue`, set as `current_deployment`, set `locked_at`
- Complete deployment: clear `current_deployment`, clear `locked_at`

**Example**:
```json
{
  "environment": "production",
  "queue": [
    { "deployment_id": "deploy-002", "queue_position": 1, ... },
    { "deployment_id": "deploy-003", "queue_position": 2, ... }
  ],
  "current_deployment": { "deployment_id": "deploy-001", "status": "in_progress", ... },
  "locked_at": "2025-11-21T10:30:00Z"
}
```

### 7. MaintenanceTask

Represents an automated maintenance operation.

**Attributes**:
- `task_id` (string, required): Unique identifier for this task execution
- `task_type` (enum, required): Type of maintenance - `cleanup` | `sync-files` | `deprecate-old-versions` | `security-audit` | `dependency-update` | `all`
- `status` (enum, required): Current status - `pending` | `in_progress` | `succeeded` | `failed`
- `triggered_by` (string, required): User or system that triggered task
- `started_at` (timestamp, optional): When task started
- `completed_at` (timestamp, optional): When task finished
- `workflow_run_id` (string, required): GitHub Actions workflow run ID
- `result_summary` (string, optional): Summary of task results

**Validation Rules**:
- `task_id` MUST be unique across all maintenance tasks
- `status` MUST start as `pending` or `in_progress`
- `started_at` MUST be set when status changes to `in_progress`
- `completed_at` MUST be set when status changes to terminal state

**State Transitions**:
```
pending → in_progress → succeeded
                     ↘ failed
```

**Example**:
```json
{
  "task_id": "maint-20251121-140000-cleanup",
  "task_type": "cleanup",
  "status": "succeeded",
  "triggered_by": "github-actions[bot]",
  "started_at": "2025-11-21T14:00:00Z",
  "completed_at": "2025-11-21T14:05:30Z",
  "workflow_run_id": "9876543210",
  "result_summary": "Cleaned 250MB of old artifacts, removed 15 deprecated tags"
}
```

### 8. RollbackTarget

Represents the identified target version for a rollback operation.

**Attributes**:
- `current_version` (Version, required): Version currently deployed
- `target_version` (Version, required): Version to roll back to
- `environment` (string, required): Environment for rollback
- `selection_criteria` (object, required): Criteria used to select target
- `candidate_versions` (array<Version>, required): All versions considered
- `rejected_versions` (array<Version>, required): Versions excluded from selection

**Validation Rules**:
- `target_version` MUST be semantically lower than `current_version`
- `target_version` MUST NOT have `-deprecated` state tag
- `target_version` SHOULD have `-stable` state tag if available
- `candidate_versions` MUST include `target_version`
- `rejected_versions` MUST NOT include `target_version`

**State Transitions**: N/A (computed, not persisted)

**Example**:
```json
{
  "current_version": { "semver": "v1.2.3", ... },
  "target_version": { "semver": "v1.2.2", ... },
  "environment": "production",
  "selection_criteria": {
    "prioritize_stable": true,
    "exclude_deprecated": true,
    "exclude_unstable": false
  },
  "candidate_versions": [ { "semver": "v1.2.2", ... }, { "semver": "v1.2.1", ... }, { "semver": "v1.2.0", ... } ],
  "rejected_versions": [ { "semver": "v1.1.0", "reason": "deprecated" } ]
}
```

### 9. PipelineReport

Represents the actionable summary generated at pipeline completion.

**Attributes**:
- `workflow_run_id` (string, required): GitHub Actions workflow run ID
- `workflow_name` (string, required): Name of workflow that completed
- `status` (enum, required): Final status - `success` | `failure` | `cancelled`
- `version` (Version, optional): Version built/deployed (if applicable)
- `action_links` (array<ActionLink>, required): Actionable links for next steps
- `generated_at` (timestamp, required): When report was generated

**Validation Rules**:
- `workflow_run_id` MUST be valid GitHub Actions run ID
- `action_links` MUST NOT be empty
- `generated_at` MUST be within 10 seconds of workflow completion

**State Transitions**: N/A (immutable once generated)

**Example**:
```json
{
  "workflow_run_id": "1234567890",
  "workflow_name": "Pre-Release Pipeline",
  "status": "success",
  "version": { "semver": "v1.2.3-beta.1", ... },
  "action_links": [
    { "label": "Promote to Release", "url": "https://github.com/...", "icon": "rocket" },
    { "label": "Rollback", "url": "https://github.com/...", "icon": "revert" }
  ],
  "generated_at": "2025-11-21T10:35:02Z"
}
```

### 10. ActionLink

Represents a clickable action link in pipeline reports.

**Attributes**:
- `label` (string, required): Display text for the link
- `url` (string, required): Target URL (typically workflow dispatch with parameters)
- `description` (string, optional): Detailed description of what the link does
- `icon` (string, optional): Icon name for UI rendering
- `category` (enum, required): Link category - `deployment` | `release` | `maintenance` | `rollback` | `state`

**Validation Rules**:
- `label` MUST be between 5 and 50 characters
- `url` MUST be valid HTTPS URL pointing to GitHub Actions
- `category` MUST match the action's purpose

**State Transitions**: N/A (immutable once created)

**Example**:
```json
{
  "label": "Promote to Release",
  "url": "https://github.com/org/repo/actions/workflows/release.yml?inputs=version:v1.2.3",
  "description": "Trigger release pipeline for version v1.2.3",
  "icon": "rocket",
  "category": "release"
}
```

## Entity Relationships

```
Version 1─────┬──→ * VersionTag
              │
              └──→ * Deployment

VersionTag 1──┬──→ 1 Version
              │
              └──→ * Deployment

Environment 1─┬──→ * Region
              │
              ├──→ * Deployment
              │
              └──→ 1 DeploymentQueue

Deployment *──┬──→ 1 VersionTag
              │
              ├──→ 1 Environment
              │
              └──→ 0..1 Region

DeploymentQueue 1──┬──→ * Deployment (queued)
                   │
                   └──→ 0..1 Deployment (current)

RollbackTarget 1───┬──→ 1 Version (current)
                   │
                   ├──→ 1 Version (target)
                   │
                   └──→ * Version (candidates)

PipelineReport 1───┬──→ 0..1 Version
                   │
                   └──→ * ActionLink
```

## Persistence Strategy

### Design Principle: Stateless Pipelines

**Core Constraint**: Pipelines act independently without shared mutable state (except secrets). This ensures:
- **Concurrency safety**: Multiple pipeline runs execute simultaneously without race conditions
- **Reliability**: Deterministic behavior independent of execution order
- **Testability**: Each pipeline run is isolated and reproducible
- **Simplicity**: No external coordination infrastructure

### Git Tags (Single Source of Truth)
- **Version**: Derived from git tags (immutable)
- **VersionTag**: Directly maps to git tags
  - Version tags: Immutable once created
  - Environment tags: Movable atomically via `git tag -f && git push -f`
  - State tags: Immutable once created
- **RollbackTarget**: Computed from git tag enumeration (read-only query)

**Why Git Tags**:
- Atomic operations (no partial writes)
- Distributed (every clone has full history)
- Durable (replicated across GitHub infrastructure)
- Auditable (git log shows all tag movements)
- No external dependencies

### GitHub Actions Context (Ephemeral, Per-Run)
- **Deployment**: Stored in workflow run metadata and logs (read-only after completion)
- **DeploymentQueue**: Managed by GitHub Actions concurrency groups (implicit, no explicit state)
- **PipelineReport**: Stored in GitHub Actions job summary (per-run artifact)
- **MaintenanceTask**: Stored in workflow run metadata

**Concurrency Control**:
- GitHub Actions `concurrency` groups serialize deployments to same environment
- No external locks, semaphores, or coordination files
- FIFO queue behavior guaranteed by GitHub Actions

### File System (Read-Only Configuration)
- **Environment**: Defined by directory structure in `environments/` (committed to git)
- **Region**: Defined by subdirectories in `environments/<env>/regions/` (committed to git)
- **Secrets**: SOPS-encrypted files (read-only, decrypted per-run)

**Important**: Configuration files are read-only inputs, not mutable runtime state.

### Explicitly Excluded (Violates Stateless Principle)

**NOT ALLOWED**:
- ❌ Shared state files (e.g., `.deployment-lock`, `current-version.json`)
- ❌ External databases (Redis, PostgreSQL, DynamoDB)
- ❌ Message queues (RabbitMQ, SQS)
- ❌ GitHub Variables used for runtime coordination (Variables are for configuration only)
- ❌ GitHub Issues/Discussions used as state store
- ❌ Commit-during-pipeline patterns (creates git noise and race conditions)

**Why Excluded**: These introduce shared mutable state that breaks pipeline independence, creates race conditions, and adds external dependencies.

### State Computation Pattern

Pipelines compute current state from immutable/read-only sources on every run:

```bash
# Example: Determine currently deployed version
CURRENT_COMMIT=$(git rev-parse api/production)
CURRENT_VERSION=$(git tag --points-at "$CURRENT_COMMIT" | grep '^api/v')

# Example: Find rollback target
CANDIDATES=$(git tag -l 'api/v*' --sort=-version:refname)
# ... filter and select ...
```

**Key Point**: State is derived, not stored. Each pipeline run computes what it needs from git tags.

## Validation Rules Summary

### Cross-Entity Validations

1. **Tag-Environment Consistency**: A version tag with environment suffix (e.g., `-production`) MUST only exist if a corresponding environment configuration folder exists
2. **Deployment-Tag Consistency**: A deployment MUST reference a VersionTag that exists as a git tag at deployment time
3. **Queue-Environment Consistency**: A DeploymentQueue's environment MUST match all deployments in its queue
4. **Rollback-History Consistency**: A RollbackTarget MUST only select from versions that have been previously deployed to the target environment
5. **Report-Workflow Consistency**: A PipelineReport MUST correspond to a completed GitHub Actions workflow run

### Security Validations

1. **Secret Encryption**: All files in `environments/*/secrets.enc` MUST be SOPS-encrypted (not plaintext)
2. **No Hardcoded Credentials**: All CI scripts MUST pass secret scanning (Gitleaks + Trufflehog)
3. **Protected Tags**: Environment tags (`-production`, `-staging`, etc.) MUST only be created by CI pipeline (not manual push)
4. **Admin Override**: Administrator exemptions (e.g., `ALLOW_PROTECTED_TAG_PUSH`) MUST be logged and auditable

---

**Data Model Complete**: 2025-11-21
**Next Phase**: Generate API contracts
