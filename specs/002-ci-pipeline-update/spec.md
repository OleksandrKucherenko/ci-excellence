# Feature Specification: CI Pipeline Comprehensive Update

**Feature Branch**: `002-ci-pipeline-update`
**Created**: 2025-11-21
**Status**: Draft
**Input**: User description: "update current specification from latest version of the @2025-11-21-planning.md planning document"

## Clarifications

### Session 2025-11-21

- Q: How should the system handle concurrent deployments to the same environment with different git tags? → A: Use GitHub Actions native concurrency groups to prevent simultaneous deployments; provide retry mechanism with clear conflict messaging
- Q: What authentication mechanism should be used for webhook-based pipeline execution? → A: Use Basic Auth with configurable credentials stored in GitHub Secrets, with IP allowlist support
- Q: How should the ZSH plugin integrate with MISE profile switching? → A: MISE tasks will handle profile switching while ZSH plugin provides visual indication in prompt, communicating via environment file
- Q: What should happen when script execution timeout is reached? → A: Workflow-level timeout should terminate the job cleanly, log the timeout, and provide retry links in pipeline summary
- Q: How should emergency admin overrides work for tag operations? → A: Admins can bypass CI restrictions via signed commits or special approval workflow, with post-incident review requirements
- Q: What are the security retention and audit requirements? → A: Security logs and audit trails retained for 30 days, pipeline artifacts for 14 days, with automatic cleanup

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
6. **Given** pipeline completion, **When** I view the summary, **Then** I see links to execute any pipeline manually or via webhook with authentication options

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
5. **Given** a deployment to production is in progress, **When** I trigger another deployment to production, **Then** the second deployment fails immediately with a conflict error and provides a retry link with pre-filled parameters
6. **Given** a version is deployed and tested, **When** I assign a state tag "api/v1.0.0-stable" to the commit, **Then** the version is marked as stable and prioritized for rollback operations
7. **Given** an admin needs emergency override, **When** they use admin approval workflow or signed commit, **Then** they can bypass CI tag restrictions with proper audit trail
8. **Given** tags need to be assigned to commits in branches not merged to main, **When** I trigger tag assignment pipeline, **Then** the system correctly handles cross-branch tag operations

---

### User Story 3 - Multi-Environment Configuration Management (Priority: P2)

As a DevOps engineer, I want to manage environment-specific configuration (staging, production, sandbox, canary, performance) in organized sub-folders with support for regions and global scopes so I can maintain deployment parameters for different environments and geographic regions without configuration conflicts.

**Why this priority**: Essential for production readiness, but can be implemented after deployment control is established. Teams need this to manage real-world multi-region deployments.

**Independent Test**: Can be tested by creating environment-specific folders, adding region sub-folders, verifying that deployments read the correct configuration based on environment and region selection, and using profile switching to change active environment context.

**Acceptance Scenarios**:

1. **Given** I need environment-specific settings, **When** I create folders "environments/staging/" and "environments/production/", **Then** deployment pipelines read configuration from the folder matching the target environment
2. **Given** I deploy to multiple regions within an environment, **When** I create "environments/production/regions/us-east/" and "environments/production/regions/eu-west/", **Then** deployments use region-specific parameters based on deployment target
3. **Given** I have cross-environment resources, **When** I place configuration in "environments/global/", **Then** all environment deployments can access these global settings
4. **Given** I'm working locally and need to test staging configuration, **When** I switch profile to "staging:us-east" using environment tooling, **Then** my local environment uses staging configuration for the us-east region with visual confirmation in shell prompt
5. **Given** I use cloud-agnostic region names, **When** I define region mapping (e.g., "us-east" → AWS "us-east-1", Azure "eastus"), **Then** deployment scripts translate generic names to cloud-specific values
6. **Given** I need to manage encrypted secrets, **When** I place SOPS-encrypted files in environment folders, **Then** MISE tasks can decrypt them for the active profile and scripts can access them as environment variables

---

### User Story 4 - DRY CI Scripts with Testability (Priority: P2)

As a CI/CD maintainer, I want all pipeline logic extracted into standalone, testable script files with hierarchical testability control and clear naming conventions so I can test pipeline behavior locally, debug failures quickly, and maintain scripts without editing workflow YAML.

**Why this priority**: Improves maintainability and debuggability significantly, but doesn't block basic pipeline functionality. Critical for long-term sustainability.

**Independent Test**: Can be tested by executing any pipeline step script locally with test environment variables, verifying it produces expected behavior (PASS, FAIL, SKIP, TIMEOUT, DRY_RUN, EXECUTE), and confirming all workflow steps call external scripts rather than containing inline logic.

**Acceptance Scenarios**:

1. **Given** a pipeline step needs to compile code, **When** the workflow executes, **Then** it calls "scripts/compile/01-ci-compile-step.sh" instead of containing inline bash commands with workflow-level timeout protection
2. **Given** I want to test the compile script locally, **When** I set environment variable "CI_TEST_MODE=DRY_RUN" and run the script, **Then** it prints planned commands without executing them
3. **Given** I'm debugging a test failure, **When** I set "CI_TEST_MODE=EXECUTE" and "CI_TEST_COMPILE_BEHAVIOR=FAIL", **Then** the compile script exits with failure code and appropriate error message
4. **Given** scripts need logical ordering, **When** I add a new build step between existing steps 10 and 20, **Then** I can name it "15-ci-new-step.sh" without renaming other files
5. **Given** I need to verify tool availability, **When** the script runs, **Then** it assumes all tools listed in mise.toml are available without redundant checks
6. **Given** I need a longer timeout for a specific job, **When** I set CI_JOB_TIMEOUT_MINUTES environment variable, **Then** the workflow uses the custom timeout value instead of the default
7. **Given** each script needs unique testability control, **When** I use hierarchical variables (PIPELINE_SCRIPT_COMPILE_BEHAVIOR, CI_COMPILE_BEHAVIOR, CI_TEST_MODE), **Then** script respects the most specific variable defined
8. **Given** scripts need to handle concurrent execution safely, **When** multiple pipeline runs execute simultaneously, **Then** each script instance operates independently without shared state

---

### User Story 5 - Script Placeholders with Implementation Guidance (Priority: P3)

As a developer adopting this CI/CD framework, I want all scripts to be well-documented placeholders with inline examples and clear extension points so I can understand what each script should do and fill in project-specific logic without starting from scratch.

**Why this priority**: Enhances developer experience and reduces onboarding time, but doesn't block core functionality. Can be improved iteratively.

**Independent Test**: Can be tested by reading any CI script file and verifying it contains clear comments explaining purpose, usage examples for common scenarios, testability environment variables, and extension points.

**Acceptance Scenarios**:

1. **Given** I open any CI script, **When** I read the header comments, **Then** I see a description of what the script does, how to customize it, and what tools it expects
2. **Given** I need to implement compilation, **When** I open "01-ci-compile-step.sh", **Then** I see commented examples for Node.js/TypeScript (npm run build, tsc), Python (python -m build), Go (go build), with instructions on uncommenting and adapting
3. **Given** I want to test the script, **When** I read the documentation, **Then** I see a list of supported CI_TEST_* environment variables and their behaviors (PASS, FAIL, SKIP, TIMEOUT, DRY_RUN, EXECUTE)
4. **Given** I implement script logic, **When** I follow the placeholder pattern, **Then** the script listens to CI_TEST_MODE and responds to different modes appropriately with clear logging
5. **Given** I need to extend a script for my project, **When** I read the extension points section, **Then** I see clear guidance on where to add project-specific logic without breaking the framework
6. **Given** scripts must stay under 50 LOC, **When** I implement complex logic, **Then** I see guidance on when to extract helpers or external utilities

---

### User Story 6 - Enhanced Quality Gates and Security (Priority: P2)

As a security-conscious team, I want all CI scripts to follow quality gates including secret scanning, minimal dependencies, small focused scripts, stable versioning, and commit message enforcement so we maintain security and code quality standards.

**Why this priority**: Security and quality are critical but some elements (like commit message enforcement) can be added progressively after core deployment functionality works.

**Independent Test**: Can be tested by running security scans on scripts, verifying no credentials are hardcoded, checking script line counts, confirming no "latest" tags in dependencies, and attempting commits with non-standard messages (should be blocked by commitizen).

**Acceptance Scenarios**:

1. **Given** any CI script is executed, **When** I scan for hardcoded secrets, **Then** no credentials, tokens, or API keys are found in the code
2. **Given** I review SECURITY.md, **When** I look for secret rotation documentation, **Then** each script that uses secrets has a documented rotation procedure with one secret per script focus
3. **Given** I audit script complexity, **When** I count lines of code per script, **Then** most scripts are under 50 lines of code (excluding comments)
4. **Given** I check dependencies in mise.toml, **When** I review version tags, **Then** all tools use specific version numbers (no "latest", "next", or untagged)
5. **Given** I try to commit code, **When** my commit message doesn't follow conventional commits format, **Then** git hooks block the commit and prompt me to use commitizen
6. **Given** code has formatting or linting issues, **When** I view the pipeline summary, **Then** I see a one-click link to trigger the self-healing pipeline which formats the code and creates a follow-up commit
7. **Given** security scans run in CI, **When** any secrets are detected, **Then** the pipeline fails immediately and blocks the commit with clear remediation instructions
8. **Given** all quality tools are configured, **When** I run the full test suite, **Then** ShellSpec, ShellCheck, ShellFormat, and Act all validate scripts and workflows correctly

---

### Edge Cases

- What happens when a tag assignment request specifies a non-existent sub-project path?
- How does the system handle simultaneous tag assignments to the same commit for the same environment?
- What happens when deployment pipeline triggers but environment-specific configuration folder is missing?
- How does rollback behave when no stable previous version exists (all prior versions are unstable or deprecated)?
- How does rollback behave when the identified previous version's tag has been manually deleted?
- What happens when a CI script exceeds the workflow-level timeout configured for its job?
- How does the system handle custom timeout overrides via CI_JOB_TIMEOUT_MINUTES that exceed GitHub Actions maximum limits?
- What occurs when a monorepo sub-project is renamed or moved?
- How do git hooks behave when working offline or when CI pipeline service is unavailable?
- What happens when regional configuration conflicts with global configuration?
- How does the system handle deployment to a region that doesn't exist in cloud provider mapping?
- How should the system handle webhook authentication failures or malformed requests?
- What happens when MISE profile switching fails due to missing configuration files?
- How does the ZSH plugin behave when MISE is not installed or unavailable?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: All CI pipelines MUST generate comprehensive success reports with clickable action links for release promotion, rollback, state assignment, and maintenance tasks
- **FR-002**: System MUST support advanced git tagging system with version tags (<path>/<version>), environment tags (<path>/<environment>), and state tags (<path>/<version>-<state>)
- **FR-003**: System MUST support monorepo deployments with multiple sub-projects, each independently deployable to multiple environments
- **FR-004**: Environment tags MUST only be assignable via specific CI pipelines, with git hooks preventing manual direct assignment
- **FR-005**: System MUST support multiple environments (staging, production, optional: canary, sandbox, performance) with region-specific configurations
- **FR-006**: System MUST provide cloud-agnostic region name mapping to cloud-specific provider values
- **FR-007**: All CI pipeline logic MUST be extracted into standalone BASH or TypeScript/Bun scripts with hierarchical testability control
- **FR-008**: Scripts MUST follow naming convention <NN>-ci-<script-name>.sh with ordered prefixes (00-99) and logical grouping in sub-folders
- **FR-009**: Every CI script MUST support testability modes: FAIL, PASS, SKIP, TIMEOUT, DRY_RUN, EXECUTE via hierarchical environment variables
- **FR-010**: All scripts MUST be well-documented placeholders with commented examples for common technology stacks
- **FR-011**: System MUST enforce security gates including secret scanning, credential leak prevention, and SOPS-encrypted secret management
- **FR-012**: Scripts MUST maintain size under 50 lines of code with clear extension points for complex logic
- **FR-013**: System MUST use specific version tags for all dependencies, avoiding "latest" or "next" tags
- **FR-014**: System MUST enforce conventional commit messages via commitizen and git hooks
- **FR-015**: Deployment conflicts for same environment MUST be prevented using GitHub Actions native concurrency groups
- **FR-016**: System MUST support webhook-based pipeline execution with authentication and IP allowlist support
- **FR-017**: MISE MUST support profile switching for environment/region context with ZSH shell prompt integration
- **FR-018**: Admins MUST have emergency override capability for tag operations with audit trail and post-incident review requirements
- **FR-019**: System MUST provide one-click self-healing pipeline for code formatting and linting fixes
- **FR-020**: Quality tools (ShellSpec, ShellCheck, ShellFormat, Act) MUST be integrated for testing and validation
- **FR-021**: Security logs and audit trails MUST be retained for 30 days, pipeline artifacts for 14 days, with automatic cleanup processes

### Key Entities *(include if feature involves data)*

- **Git Tag**: Immutable metadata objects representing version (<path>/<version>), environment (<path>/<environment>), and state (<path>/<version>-<state>) information
- **Environment Configuration**: Hierarchical folder structure containing environment and region-specific deployment parameters and encrypted secrets
- **CI Script**: Standalone executable files with testability controls and documented extension points
- **Deployment Queue**: Conflict management system using GitHub Actions native concurrency groups
- **Profile**: Active environment and region context used by MISE for local development
- **Action Link**: Clickable URLs in pipeline summaries that trigger specific workflows with pre-filled parameters

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Teams can deploy any sub-project version to any environment within 5 minutes using tag assignment
- **SC-002**: 95% of pipeline completions display all required action links with correct parameters and working URLs
- **SC-003**: 90% of CI scripts contain comprehensive documentation and working examples for at least 3 technology stacks
- **SC-004**: Security scans detect 100% of hardcoded secrets with zero false negatives in committed code
- **SC-005**: Deployment conflicts are prevented 100% of the time with clear retry instructions provided
- **SC-006**: Developers can test any CI script locally in all 6 modes (PASS, FAIL, SKIP, TIMEOUT, DRY_RUN, EXECUTE) without running full pipeline
- **SC-007**: 95% of scripts maintain under 50 LOC excluding comments while maintaining functionality
- **SC-008**: Commit message enforcement blocks 100% of non-conventional commits with helpful error messages
- **SC-009**: Self-healing pipeline resolves 90% of formatting and linting issues automatically
- **SC-010**: Profile switching updates shell prompt correctly within 2 seconds for all environment/region combinations
- **SC-011**: Admin emergency overrides complete successfully within 10 minutes with proper audit trail generation
- **SC-012**: Webhook authentication rejects 100% of unauthorized requests while allowing valid ones
- **SC-013**: Security logs are automatically purged after 30 days and pipeline artifacts after 14 days with 99% cleanup success rate