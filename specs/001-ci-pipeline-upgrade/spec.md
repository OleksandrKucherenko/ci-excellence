# Feature Specification: CI Pipeline Comprehensive Upgrade

**Feature Branch**: `001-ci-pipeline-upgrade`
**Created**: 2025-11-21
**Status**: Draft
**Input**: User description: "solution need a significant upgrade before it become usable, i collect the list of required changes in document @2025-11-21-planning.md"

## Clarifications

### Session 2025-11-21

- Q: How should sensitive credentials (API keys, cloud provider credentials, database passwords) be managed across environments? → A: Store all environment credentials in git-committed SOPS-encrypted files within each environment folder, using MISE for controlling the secrets
- Q: How does the system identify which version is "previous" when rolling back with multiple tags, branches, and sub-projects? → A: Scan git tags matching version pattern, compare semver to find highest previous version, with respect to stable, unstable and deprecated states
- Q: What is the actual mechanism to detect and handle hung scripts during real pipeline execution? → A: Workflow-level timeout configured in GitHub Actions job definitions with process termination, with ability to override timeout via global environment variable
- Q: What triggers the "self-healing" pipeline and what scope of changes can it make? → A: Triggered manually via one-click link provided in logs and summary (not automatic)
- Q: Can deployments run concurrently across environments and within the same environment? → A: Allowed to different environments; same environment blocks with queue

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Pipeline Success Reports with Action Links (Priority: P1)

As a CI/CD user, when my pipeline completes successfully, I want to see a comprehensive report with actionable links so I can quickly promote releases, trigger rollbacks, or perform maintenance tasks without navigating through multiple UI screens.

**Why this priority**: This provides immediate value by reducing the time and cognitive load for common post-pipeline actions. Teams can act on pipeline results instantly through direct links rather than hunting through UI menus.

**Independent Test**: Can be fully tested by running any CI pipeline to success and verifying that the logs and GitHub summary contain all required links (promote to release, rollback, state assignment, maintenance triggers) with correct parameters.

**Acceptance Scenarios**:

1. **Given** a pre-release pipeline completes successfully, **When** I view the pipeline logs and GitHub summary, **Then** I see a clickable link that triggers the release pipeline with the current version
2. **Given** a release pipeline completes successfully, **When** I view the pipeline summary, **Then** I see links to rollback to the previous version determined by scanning git tags, prioritizing stable versions, and excluding deprecated versions, with clear messaging showing which version will be restored
3. **Given** any pipeline completes, **When** I view the summary, **Then** I see links to manually mark the version as stable or unstable
4. **Given** pipeline completion, **When** I view the summary, **Then** I see links to trigger maintenance tasks in different modes (cleanup, sync-files, deprecate-old-versions, security-audit, dependency-update, all)
5. **Given** any pipeline completes, **When** I view the summary, **Then** I see a one-click link to manually trigger the self-healing pipeline for formatting and linting fixes

---

### User Story 2 - Advanced Git Tags for Deployment Control (Priority: P1)

As a deployment manager working with a monorepo containing multiple sub-projects, I want to control deployments to different environments using a standardized git tagging system so I can deploy specific versions of specific sub-projects to specific environments without complex configuration files.

**Why this priority**: This is the foundation for controlled, auditable deployments in monorepo environments. Without this, teams cannot safely manage multi-project deployments or rollbacks.

**Independent Test**: Can be tested by assigning environment tags (production, staging, etc.) to commits via CI pipeline and verifying that deployments trigger only for the tagged sub-project and environment combination, with enforcement preventing manual tag assignment.

**Acceptance Scenarios**:

1. **Given** I want to deploy version v1.0.0 of sub-project "api" to production, **When** I trigger the tag assignment pipeline with parameters (sub-project=api, version=v1.0.0, environment=production), **Then** the system creates or moves tag "api/production" to the commit tagged "api/v1.0.0" and triggers production deployment for api only
2. **Given** I want to deploy the root project v2.0.0 to staging, **When** I assign environment tag "staging" to the commit tagged "v2.0.0" via pipeline, **Then** the root project deploys to staging environment
3. **Given** I attempt to manually create an environment tag (production, staging, etc.), **When** I try to push the tag, **Then** git hooks prevent the push with a message directing me to use the CI pipeline
4. **Given** I need to deploy the same version to multiple environments, **When** I assign environment tags "api/production", "api/staging", "api/canary" to the same commit (which has version tag "api/v1.0.0"), **Then** all three environment deployments trigger concurrently without blocking each other
5. **Given** a deployment to production is in progress, **When** I trigger another deployment to production, **Then** the second deployment is queued and shows its queue position and estimated wait time
6. **Given** a version is deployed and tested, **When** I assign a state tag "api/v1.0.0-stable" to the commit, **Then** the version is marked as stable and prioritized for rollback operations

---

### User Story 3 - Multi-Environment Configuration Management (Priority: P2)

As a DevOps engineer, I want to manage environment-specific configuration (staging, production, sandbox, etc.) in organized sub-folders with support for regions and global scopes so I can maintain deployment parameters for different environments and geographic regions without configuration conflicts.

**Why this priority**: Essential for production readiness, but can be implemented after deployment control is established. Teams need this to manage real-world multi-region deployments.

**Independent Test**: Can be tested by creating environment-specific folders, adding region sub-folders, verifying that deployments read the correct configuration based on environment and region selection, and using profile switching to change active environment context.

**Acceptance Scenarios**:

1. **Given** I need environment-specific settings, **When** I create folders "environments/staging/" and "environments/production/", **Then** deployment pipelines read configuration from the folder matching the target environment
2. **Given** I deploy to multiple regions within an environment, **When** I create "environments/production/regions/us-east/" and "environments/production/regions/eu-west/", **Then** deployments use region-specific parameters based on deployment target
3. **Given** I have cross-environment resources, **When** I place configuration in "environments/global/", **Then** all environment deployments can access these global settings
4. **Given** I'm working locally and need to test staging configuration, **When** I switch profile to "staging:us-east" using environment tooling, **Then** my local environment uses staging configuration for the us-east region
5. **Given** I use cloud-agnostic region names, **When** I define region mapping (e.g., "us-east" → AWS "us-east-1", Azure "eastus"), **Then** deployment scripts translate generic names to cloud-specific values

---

### User Story 4 - DRY CI Scripts with Testability (Priority: P2)

As a CI/CD maintainer, I want all pipeline logic extracted into standalone, testable script files with clear naming conventions so I can test pipeline behavior locally, debug failures quickly, and maintain scripts without editing workflow YAML.

**Why this priority**: Improves maintainability and debuggability significantly, but doesn't block basic pipeline functionality. Critical for long-term sustainability.

**Independent Test**: Can be tested by executing any pipeline step script locally with test environment variables, verifying it produces expected behavior (PASS, FAIL, SKIP, TIMEOUT, DRY_RUN modes), and confirming all workflow steps call external scripts rather than containing inline logic.

**Acceptance Scenarios**:

1. **Given** a pipeline step needs to compile code, **When** the workflow executes, **Then** it calls "scripts/compile/01-ci-compile-step.sh" instead of containing inline bash commands with workflow-level timeout protection
2. **Given** I want to test the compile script locally, **When** I set environment variable "CI_TEST_MODE=DRY_RUN" and run the script, **Then** it prints planned commands without executing them
3. **Given** I'm debugging a test failure, **When** I set "CI_TEST_MODE=EXECUTE" and "CI_TEST_COMPILE_BEHAVIOR=FAIL", **Then** the compile script exits with failure code and appropriate error message
4. **Given** scripts need logical ordering, **When** I add a new build step between existing steps 10 and 20, **Then** I can name it "15-ci-new-step.sh" without renaming other files
5. **Given** I need to verify tool availability, **When** the script runs, **Then** it assumes all tools listed in mise.toml are available without redundant checks
6. **Given** I need a longer timeout for a specific job, **When** I set CI_JOB_TIMEOUT_MINUTES environment variable, **Then** the workflow uses the custom timeout value instead of the default

---

### User Story 5 - Script Placeholders with Implementation Guidance (Priority: P3)

As a developer adopting this CI/CD framework, I want all scripts to be well-documented placeholders with inline examples so I can understand what each script should do and fill in project-specific logic without starting from scratch.

**Why this priority**: Enhances developer experience and reduces onboarding time, but doesn't block core functionality. Can be improved iteratively.

**Independent Test**: Can be tested by reading any CI script file and verifying it contains clear comments explaining purpose, usage examples for common scenarios, and testability environment variables.

**Acceptance Scenarios**:

1. **Given** I open any CI script, **When** I read the header comments, **Then** I see a description of what the script does and how to customize it
2. **Given** I need to implement compilation, **When** I open "ci-compile.sh", **Then** I see commented examples for Node.js/TypeScript (npm run build, tsc), with instructions on uncommenting and adapting
3. **Given** I want to test the script, **When** I read the documentation, **Then** I see a list of supported CI_TEST_* environment variables and their behaviors
4. **Given** I implement script logic, **When** I follow the placeholder pattern, **Then** the script listens to CI_TEST_MODE and responds to PASS, FAIL, SKIP, TIMEOUT, DRY_RUN, EXECUTE modes appropriately

---

### User Story 6 - Minimalistic Auto-Activation Configuration (Priority: P3)

As a team using this CI framework, I want features to auto-enable when sufficient configuration is provided so I don't have to maintain complex feature flags for simple integrations like notifications.

**Why this priority**: Quality-of-life improvement that reduces configuration burden but doesn't block functionality. Can be added after core features are stable.

**Independent Test**: Can be tested by adding a notification token to CI secrets and verifying that the next pipeline run automatically sends notifications without manually enabling a feature flag.

**Acceptance Scenarios**:

1. **Given** I add APPRISE_URL to GitHub Secrets, **When** the next pipeline runs, **Then** notifications are automatically sent without setting ENABLE_NOTIFICATIONS=true
2. **Given** notification credentials are not configured, **When** pipeline runs, **Then** the notification step skips gracefully with a log message indicating missing configuration
3. **Given** I want to explicitly disable a feature despite having credentials, **When** I set DISABLE_NOTIFICATIONS=true, **Then** notifications are skipped even with valid credentials

---

### User Story 7 - Enhanced Quality Gates and Security (Priority: P2)

As a security-conscious team, I want all CI scripts to follow quality gates including secret rotation mechanisms, minimal dependencies, small focused scripts, stable versioning, and commit message enforcement so we maintain security and code quality standards.

**Why this priority**: Security and quality are critical but some elements (like commit message enforcement) can be added progressively after core deployment functionality works.

**Independent Test**: Can be tested by running security scans on scripts, verifying no credentials are hardcoded, checking script line counts, confirming no "latest" tags in dependencies, and attempting commits with non-standard messages (should be blocked by commitizen).

**Acceptance Scenarios**:

1. **Given** any CI script is executed, **When** I scan for hardcoded secrets, **Then** no credentials, tokens, or API keys are found in the code
2. **Given** I review SECURITY.md, **When** I look for secret rotation documentation, **Then** each script that uses secrets has a documented rotation procedure
3. **Given** I audit script complexity, **When** I count lines of code per script, **Then** most scripts are under 50 lines of code (excluding comments)
4. **Given** I check dependencies in mise.toml, **When** I review version tags, **Then** all tools use specific version numbers (no "latest", "next", or untagged)
5. **Given** I try to commit code, **When** my commit message doesn't follow conventional commits format, **Then** git hooks block the commit and prompt me to use commitizen
6. **Given** code has formatting or linting issues, **When** I view the pipeline summary, **Then** I see a one-click link to trigger the self-healing pipeline which formats the code and creates a follow-up commit

---

### Edge Cases

- What happens when a tag assignment request specifies a non-existent sub-project path?
- How does the system handle simultaneous tag assignments to the same commit for the same environment?
- What happens when a queued deployment becomes invalid (e.g., newer version deployed while waiting in queue)?
- How does the system handle deployment queue when a deployment fails or is cancelled?
- What occurs when deployment pipeline triggers but environment-specific configuration folder is missing?
- How does rollback behave when no stable previous version exists (all prior versions are unstable or deprecated)?
- How does rollback behave when the identified previous version's tag has been manually deleted?
- What happens when a CI script exceeds the workflow-level timeout configured for its job?
- How does the system handle custom timeout overrides via CI_JOB_TIMEOUT_MINUTES that exceed GitHub Actions maximum limits?
- How does the system handle secret rotation during an active pipeline run?
- What occurs when a monorepo sub-project is renamed or moved?
- How do git hooks behave when working offline or when CI pipeline service is unavailable?
- What happens when regional configuration conflicts with global configuration?
- How does the system handle deployment to a region that doesn't exist in cloud provider mapping?
- What happens when SOPS decryption fails due to missing or incorrect decryption keys?
- How does the system handle SOPS-encrypted files that become corrupted or have invalid format?

## Requirements *(mandatory)*

### Functional Requirements

#### Pipeline Reporting & Control

- **FR-001**: System MUST display actionable links in pipeline logs and GitHub summary upon completion
- **FR-002**: Pipeline summary MUST include links to promote current version to next release stage
- **FR-003**: Pipeline summary MUST include links to rollback to previous version with clear version identification
- **FR-004**: Pipeline summary MUST include links to manually assign version states (stable, unstable)
- **FR-005**: Pipeline summary MUST include links to trigger maintenance tasks in specific modes (cleanup, sync-files, deprecate-old-versions, security-audit, dependency-update, all)
- **FR-005a**: Pipeline summary MUST include one-click link to manually trigger self-healing pipeline for formatting and linting fixes
- **FR-006**: System MUST support multiple release states: initial release, pre-release, release, hotfix, stable, unstable, deprecated

#### Git Tags & Deployment Control

- **FR-007**: System MUST support monorepo deployments with multiple sub-projects
- **FR-008**: System MUST use three types of git tags:
  - **Version tags**: `<path>/v<semver>` (e.g., `api/v1.0.0`, `v2.0.0`) - immutable version markers
  - **Environment tags**: `<path>/<environment>` (e.g., `api/production`, `staging`) - movable pointers indicating deployed commit
  - **State tags**: `<path>/v<semver>-<state>` (e.g., `api/v1.0.0-stable`) - mark version stability for rollback prioritization
- **FR-009**: Environment tags MUST be movable (can be deleted and recreated on different commits) to track current deployment
- **FR-010**: Version tags and state tags MUST be immutable once created (never moved or deleted except by administrators)
- **FR-011**: System MUST allow tag assignment only through CI pipeline (not manual git commands)
- **FR-012**: Git hooks MUST prevent developers from manually creating protected environment tags
- **FR-013**: CI pipeline MUST validate and reject protected tag creation attempts
- **FR-014**: System MUST allow tag assignment to commits in non-main branches
- **FR-015**: System MUST allow administrators to modify tags directly when necessary

#### Deployment Concurrency

- **FR-067**: System MUST allow deployments to different environments to run concurrently
- **FR-068**: System MUST queue deployments when multiple deployments target the same environment
- **FR-069**: System MUST process queued deployments for the same environment sequentially in FIFO order
- **FR-070**: System MUST display queue position and estimated wait time for queued deployments

#### Rollback Mechanism

- **FR-058**: System MUST identify previous version by scanning git tags matching the version pattern for the target sub-project and environment
- **FR-059**: System MUST compare versions using semantic versioning rules to determine the highest previous version
- **FR-060**: System MUST prioritize stable-tagged versions over unstable versions when selecting rollback target
- **FR-061**: System MUST exclude deprecated-tagged versions from rollback target selection
- **FR-062**: System MUST fail rollback operation with clear error message if no valid previous version exists

#### Environment & Region Management

- **FR-016**: System MUST support multiple deployment environments (staging, production) with optional environments (performance, sandbox, canary)
- **FR-017**: System MUST organize environment configuration in dedicated sub-folders per environment
- **FR-018**: System MUST support region-specific configuration within each environment
- **FR-019**: System MUST support global-scope configuration accessible across all environments
- **FR-020**: System MUST support cross-region global configuration
- **FR-021**: System MUST use cloud-agnostic region names with mappings to cloud-specific identifiers
- **FR-022**: Environment tooling MUST support profile switching to activate specific environment and region contexts
- **FR-023**: Profile visualization MUST be available for shell prompt (ZSH/oh-my-zsh plugin installable via tooling tasks)

#### Secret Management

- **FR-055**: System MUST store all environment credentials in SOPS-encrypted files within environment-specific folders
- **FR-056**: System MUST use MISE for controlling secret access and decryption operations
- **FR-057**: CI scripts MUST decrypt SOPS-encrypted secrets via MISE tasks during pipeline execution

#### Pipeline Independence & Concurrency

- **FR-071**: All pipeline workflows MUST act independently without shared mutable state
- **FR-072**: Pipelines MUST NOT read or write shared state files, databases, or external state stores
- **FR-073**: Pipelines MUST NOT use GitHub Variables for mutable runtime state coordination (Variables are for configuration only)
- **FR-074**: Git tags are the ONLY permitted shared state mechanism (immutable once created, except environment tags moved atomically)
- **FR-075**: Each pipeline run MUST be deterministic and reproducible given the same git commit and inputs
- **FR-076**: Pipeline behavior MUST NOT depend on the execution order or timing of concurrent pipeline runs
- **FR-077**: Deployment queue management MUST use GitHub Actions native concurrency groups (not external coordination)
- **FR-078**: Secrets and configuration variables are read-only inputs (not mutable shared state)

#### CI Scripts Organization

- **FR-024**: Pipeline workflows MUST remain DRY with minimal inline logic
- **FR-025**: All pipeline steps MUST execute standalone script files (Bash or TypeScript/Bun)
- **FR-026**: Tooling automation MUST guarantee required tool availability (no redundant checks in scripts)
- **FR-027**: CI script files MUST follow naming pattern `ci-<script-name>.sh`
- **FR-028**: Ordered scripts MUST use prefix pattern `<NN>-ci-<script-name>.sh` where NN is 00-99 with recommended step of 10
- **FR-029**: Scripts MAY be organized in sub-folders using folder name as logical scope
- **FR-030**: Python MUST NOT be used for CI scripting (Bash or TypeScript/Bun only)

#### Script Testability

- **FR-031**: All CI scripts MUST support testability through hierarchical environment variables
- **FR-032**: Scripts MUST implement variable precedence hierarchy (most specific to least specific):
  1. `CI_TEST_<PIPELINE>_<SCRIPT>_BEHAVIOR` (pipeline + script specific)
  2. `CI_TEST_<SCRIPT>_BEHAVIOR` (script specific)
  3. `CI_TEST_MODE` (global default)
  4. `EXECUTE` (hardcoded default)
- **FR-033**: Scripts MUST support test behaviors: FAIL, PASS, SKIP, TIMEOUT, DRY_RUN, EXECUTE
- **FR-034**: Scripts in DRY_RUN mode MUST print planned commands without executing state modifications
- **FR-035**: Scripts in DRY_RUN mode MAY read data but MUST NOT modify state
- **FR-036**: Pipeline name in variable MUST be uppercase, alphanumeric with underscores (e.g., `PRE_RELEASE`, `DEPLOYMENT_PRODUCTION`)
- **FR-037**: Script name in variable MUST be uppercase, derived from script filename without prefix (e.g., `COMPILE`, `DEPLOY`, `PUBLISH_NPM`)
- **FR-038**: System MUST enable testing individual scripts in production pipelines without affecting other scripts
- **FR-039**: System MUST enable testing same script differently across different pipelines (e.g., DRY_RUN in staging, EXECUTE in production)
- **FR-040**: System MUST enable pipeline testing via configuration matrices covering all execution paths
- **FR-041**: System MUST support manual and webhook-triggered pipeline execution with optional access restrictions

#### Timeout Management

- **FR-063**: GitHub Actions workflow jobs MUST define timeout values at the job level
- **FR-064**: System MUST support global environment variable CI_JOB_TIMEOUT_MINUTES to override default timeout values
- **FR-065**: Workflow timeout MUST terminate hung processes when time limit is exceeded
- **FR-066**: Timeout expiration MUST fail the pipeline job with clear timeout error message

#### Script Placeholders & Documentation

- **FR-039**: All CI scripts MUST be provided as placeholders with clear inline documentation
- **FR-040**: Script headers MUST explain script purpose and usage instructions
- **FR-041**: Scripts MUST include commented examples for common scenarios
- **FR-042**: Scripts MUST document all supported CI_TEST_* environment variables and their behaviors

#### Minimalistic Configuration

- **FR-043**: Features MUST auto-enable when sufficient configuration is detected
- **FR-044**: Features MUST skip gracefully when required configuration is missing
- **FR-045**: Users MUST be able to explicitly disable auto-enabled features via DISABLE_* flags

#### Quality Gates

- **FR-046**: CI scripts MUST NOT contain hardcoded credentials, tokens, or secrets
- **FR-047**: System MUST provide secret rotation mechanisms documented per script in SECURITY.md
- **FR-048**: CI scripts SHOULD be under 50 lines of code (excluding comments)
- **FR-049**: Scripts MUST have minimal dependencies with clear purpose
- **FR-050**: All tool dependencies MUST use specific version tags (no "latest" or untagged versions)
- **FR-051**: Git hooks MUST enforce linting, formatting, unit tests, security scans, and performance tests
- **FR-052**: System MUST support manually-triggered "self-healing" pipeline that formats and lints code, then creates a follow-up commit with fixes
- **FR-053**: System MUST enforce conventional commit message format using commitizen
- **FR-054**: Git hooks MUST prevent commits with non-standard message formats

### Key Entities

- **Release State**: Represents the lifecycle state of a version (initial release, pre-release, release, hotfix, stable, unstable, deprecated)
- **Environment Tag**: Represents deployment target environment attached to a version (production, staging, canary, sandbox, performance)
- **Version Tag**: Represents semantic version identifier with optional sub-project path (format: `<path>/<version>`)
- **Sub-Project**: Represents an independent deployable unit within the monorepo with its own versioning
- **Environment Configuration**: Represents environment-specific deployment parameters organized in folder structure
- **Region Mapping**: Represents cloud-agnostic region names mapped to cloud-provider-specific identifiers
- **Profile**: Represents active environment and region context for local development
- **CI Script**: Represents executable pipeline step with testability support
- **Maintenance Task**: Represents automated maintenance operation (cleanup, sync-files, deprecate-old-versions, security-audit, dependency-update)
- **Encrypted Secret**: Represents SOPS-encrypted credential file stored in environment-specific folders, decrypted via MISE during pipeline execution
- **Deployment Queue**: Represents FIFO queue of pending deployments for a specific environment, with position tracking and wait time estimation

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Pipeline completion reports display all required action links within 5 seconds of completion
- **SC-002**: Teams can promote a version from pre-release to release in under 30 seconds using direct links
- **SC-003**: Deployment to any environment completes within 10 minutes for standard-sized projects
- **SC-004**: 100% of protected tag creation attempts via manual git commands are blocked by hooks
- **SC-005**: Environment profile switching completes in under 2 seconds
- **SC-006**: All CI scripts execute in DRY_RUN mode without errors, producing readable command previews
- **SC-007**: 90% of CI scripts stay under 50 lines of code (excluding comments)
- **SC-008**: Zero hardcoded secrets detected in any CI script file
- **SC-009**: Teams can test any pipeline step locally without full CI environment setup
- **SC-010**: New developers can understand and customize a CI script within 15 minutes using inline documentation
- **SC-011**: Notification features auto-enable within one pipeline run after credentials are configured
- **SC-012**: 100% of non-conventional commits are blocked by git hooks before reaching repository
- **SC-013**: Secret rotation procedures are documented for 100% of scripts using secrets
- **SC-014**: Multi-region deployments to 3+ regions complete within 15 minutes in parallel
- **SC-015**: Rollback to previous version completes within 5 minutes with automatic version identification

## Assumptions

- GitHub Actions is the CI/CD platform in use (workflow syntax, GitHub summary API)
- Mise is already adopted for tool management and local automation
- SOPS is available for encrypting/decrypting secrets stored in git
- Mise is configured to control secret access and decryption operations
- Git hooks management is via Lefthook (already configured)
- Bun is available and acceptable for TypeScript script execution
- Monorepo structure allows independent versioning per sub-project
- Cloud provider CLI tools are pre-installed and configured for deployments
- Teams have appropriate key management infrastructure for SOPS (age keys, KMS, etc.)
- Semantic versioning (MAJOR.MINOR.PATCH) is the standard version format
- Conventional Commits specification is acceptable for commit message enforcement
- Shell environment is Bash-compatible (for CI scripts) and supports ZSH for local development prompt plugins
