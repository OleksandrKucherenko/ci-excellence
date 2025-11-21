# Data Model: CI Pipeline Comprehensive Update

**Feature**: CI Pipeline Comprehensive Update
**Date**: 2025-11-21
**Source**: Functional requirements and user stories

## Core Entities

### GitTag

Represents git metadata objects for deployment control and version management.

**Attributes**:
- `tagId`: string (unique identifier, format: `<subproject>/<type>/<value>`)
- `tagName`: string (git tag name)
- `tagType`: enum (VERSION, ENVIRONMENT, STATE)
- `subproject`: string (optional, path within monorepo)
- `commitSha`: string (git commit hash the tag points to)
- `createdAt`: datetime (tag creation timestamp)
- `createdBy`: string (creator identity)
- `isMovable`: boolean (true for environment tags, false for version/state tags)
- `isProtected`: boolean (true for environment tags requiring CI mediation)

**Validation Rules**:
- Version tags: `^(subproject/)?v\d+\.\d+\.\d+(-[\w.-]+)?$`
- Environment tags: `^(subproject/)?(production|staging|canary|sandbox|performance)$`
- State tags: `^(subproject/)?v\d+\.\d+\.\d+-(stable|unstable|deprecated)$`

**Relationships**:
- `belongsTo`: Subproject (optional)
- `pointsTo`: GitCommit
- `movesTo`: GitCommit (for environment tags)

### PipelineReport

Represents comprehensive pipeline completion reports with actionable links.

**Attributes**:
- `reportId`: string (unique identifier)
- `pipelineRunId`: string (GitHub Actions run identifier)
- `pipelineType`: enum (PRE_RELEASE, RELEASE, POST_RELEASE, MAINTENANCE, SELF_HEALING)
- `status`: enum (SUCCESS, FAILURE, CANCELLED, TIMEOUT)
- `completedAt`: datetime
- `duration`: integer (duration in seconds)
- `version`: string (associated version tag)
- `subproject`: string (optional, affected subproject)
- `environment`: string (optional, target environment)

**Embedded Collections**:
- `actionLinks`: Array[ActionLink]
- `summary`: PipelineSummary
- `logs`: PipelineLog

### ActionLink

Represents clickable links in pipeline reports for triggering actions.

**Attributes**:
- `linkId`: string (unique identifier)
- `linkType`: enum (PROMOTE_RELEASE, ROLLBACK, ASSIGN_STATE, MAINTENANCE, SELF_HEALING, WEBHOOK)
- `title`: string (display text)
- `url`: string (GitHub Actions dispatch URL)
- `parameters`: object (pre-filled parameters for the target workflow)
- `description`: string (hover text or description)

**Parameter Examples**:
```json
{
  "rollback": {
    "subproject": "api",
    "current_version": "v1.2.3",
    "target_environment": "production"
  }
}
```

### EnvironmentConfiguration

Represents hierarchical environment and region-specific configuration.

**Attributes**:
- `configId`: string (unique identifier)
- `environment`: string (production, staging, canary, sandbox, performance)
- `region`: string (optional, cloud-agnostic region name)
- `subproject`: string (optional, subproject-specific config)
- `configType`: enum (GLOBAL, ENVIRONMENT, REGION)
- `path`: string (filesystem path to configuration)
- `isEncrypted`: boolean (whether file is SOPS-encrypted)

**Validation Rules**:
- Environment must be one of: production, staging, canary, sandbox, performance
- Region names must be cloud-agnostic (e.g., "us-east", "eu-west")
- Configuration files must exist in `environments/` directory structure

**Structure**:
```
environments/
├── global/
│   ├── config.yml
│   └── secrets.enc
├── production/
│   ├── config.yml
│   ├── secrets.enc
│   └── regions/
│       ├── us-east/
│       └── eu-west/
└── staging/
    ├── config.yml
    ├── secrets.enc
    └── regions/
        ├── us-east/
        └── eu-west/
```

### CIScript

Represents standalone CI scripts with testability controls.

**Attributes**:
- `scriptId`: string (unique identifier, matches filename)
- `scriptName`: string (filename)
- `scriptPath`: string (relative path from repository root)
- `category`: enum (SETUP, BUILD, TEST, RELEASE, DEPLOYMENT, MAINTENANCE, HOOKS, CI)
- `order`: integer (execution order prefix, 00-99)
- `description`: string (purpose and usage)
- `testability`: TestabilityConfig
- `dependencies`: Array[string] (tools required)
- `lineCount`: integer (lines of code, excluding comments)

**TestabilityConfig**:
```json
{
  "modes": ["PASS", "FAIL", "SKIP", "TIMEOUT", "DRY_RUN", "EXECUTE"],
  "variables": {
    "hierarchical": true,
    "pattern": "CI_TEST_*",
    "scriptSpecific": "CI_{SCRIPT_NAME}_*"
  },
  "timeoutOverride": "CI_JOB_TIMEOUT_MINUTES"
}
```

### Deployment

Represents deployment operations with state management.

**Attributes**:
- `deploymentId`: string (unique identifier)
- `version`: string (version tag being deployed)
- `subproject`: string (optional, subproject being deployed)
- `environment`: string (target environment)
- `region`: string (optional, target region)
- `status`: enum (PENDING, RUNNING, SUCCESS, FAILED, CANCELLED)
- `startedAt`: datetime
- `completedAt`: datetime (optional)
- `triggeredBy`: string (who initiated deployment)
- `commitSha`: string (git commit being deployed)

**Conflict Management**:
- `concurrencyGroup`: string (GitHub Actions concurrency group)
- `queuePosition`: integer (if queued)
- `estimatedWaitTime`: integer (seconds)

### SecurityAudit

Represents security scan results and audit trail.

**Attributes**:
- `auditId`: string (unique identifier)
- `scanType`: enum (GITLEAKS, TRUFFLEHOG, CUSTOM)
- `pipelineRunId`: string (associated pipeline)
- `scannedAt`: datetime
- `findings`: Array[SecurityFinding]
- `summary`: SecuritySummary

**SecurityFinding**:
```json
{
  "severity": "CRITICAL|HIGH|MEDIUM|LOW",
  "type": "SECRET|VULNERABILITY|POLICY",
  "description": "string",
  "file": "string",
  "line": "integer",
  "commit": "string"
}
```

### Profile

Represents active environment context for local development.

**Attributes**:
- `profileId`: string (unique identifier)
- `name`: string (profile name: local, staging, production, etc.)
- `environment`: string (target environment)
- `region`: string (optional, target region)
- `context`: object (environment variables)
- `isActive`: boolean (currently active profile)
- `shellIntegration`: ShellConfig

**ShellConfig**:
```json
{
  "promptFormat": "[profile|environment]",
  "variables": {
    "DEPLOYMENT_PROFILE": "string",
    "DEPLOYMENT_REGION": "string",
    "ENVIRONMENT_CONTEXT": "string"
  }
}
```

## Entity Relationships

```
GitTag
├── belongsTo → Subproject (optional)
├── pointsTo → GitCommit
└── movesTo → GitCommit (environment tags only)

PipelineReport
├── contains → ActionLink[]
├── summarizes → PipelineLog[]
└── references → GitTag (version)

Deployment
├── uses → GitTag (version + environment)
├── reads → EnvironmentConfiguration
├── executes → CIScript[]
└── generates → PipelineReport

CIScript
├── requires → Tool[]
├── validates → SecurityAudit
└── generates → Deployment (if deployment script)

EnvironmentConfiguration
├── inherits → EnvironmentConfiguration (global → environment → region)
├── encryptedWith → AgeKey
└── accessedBy → Profile

Profile
├── activates → EnvironmentConfiguration
├── visualizes → ShellIntegration
└── switches → Profile
```

## State Transitions

### GitTag Lifecycle
```
Version Tag: Created → Immutable
Environment Tag: Created → Moved → Moved → ...
State Tag: Created → Immutable
```

### Deployment Lifecycle
```
PENDING → RUNNING → SUCCESS/FAILED/CANCELLED
```

### PipelineReport Lifecycle
```
Generated → Viewed → Action Triggered → Archived
```

## Data Constraints

### Constitutional Constraints
- All deployments must be stateless except for immutable git tags
- No external state stores or coordination databases
- Git tags are the single source of truth for deployment state

### Security Constraints
- All secrets must be SOPS-encrypted with age keys
- Security scans run unconditionally on all pipelines
- Audit trails retained for 30 days minimum

### Performance Constraints
- Scripts must be under 50 LOC (excluding comments)
- Pipeline completion within 5 minutes for tag assignment
- Profile switching within 2 seconds

### Scalability Constraints
- Support unlimited sub-projects within monorepo
- Support multiple regions per environment
- Handle concurrent deployments to different environments

## Validation Examples

### Git Tag Validation
```bash
# Valid version tags
v1.2.3
api/v2.1.0
frontend/v1.0.0-beta.1

# Valid environment tags
production
api/production
services/auth/staging

# Valid state tags
v1.2.3-stable
api/v2.1.0-unstable
frontend/v1.0.0-deprecated
```

### Configuration Validation
```bash
# Valid environment paths
environments/global/config.yml
environments/production/config.yml
environments/production/regions/us-east/config.yml

# Valid secret paths
environments/global/secrets.enc
environments/staging/secrets.enc
```

This data model provides the foundation for implementing the CI/CD pipeline upgrade while maintaining constitutional compliance and supporting all identified user stories.