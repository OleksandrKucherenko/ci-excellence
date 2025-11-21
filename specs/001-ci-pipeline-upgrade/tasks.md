# Tasks: CI Pipeline Comprehensive Upgrade

**Input**: Design documents from `/specs/001-ci-pipeline-upgrade/`
**Prerequisites**: plan.md, spec.md, data-model.md, contracts/, research.md, quickstart.md

**Testing Strategy**: Use shellspec for bash script testing (BDD-style), shfmt for formatting, shellcheck for linting, and act for local GitHub Actions testing.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

```text
.github/workflows/       - GitHub Actions workflows
scripts/                 - CI scripts organized by lifecycle phase
environments/            - Environment-specific configuration
```

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization, tool management, and basic repository structure

- [ ] T001 Create base directory structure for CI/CD framework
- [ ] T002 [P] Create mise.toml with tool definitions (SOPS, age, Lefthook, Gitleaks, Trufflehog, Commitizen, Bun, Apprise, shellspec, shfmt, shellcheck, act)
- [ ] T003 [P] Create .lefthook.yml with pre-commit and pre-push hooks configuration
- [ ] T004 [P] Create commitizen.json with conventional commits configuration
- [ ] T005 [P] Create .sops.yaml with age encryption rules and path patterns
- [ ] T006 [P] Create environments/ directory structure (global/, staging/, production/, canary/, sandbox/, performance/)
- [ ] T007 [P] Create region subdirectories in environments/staging/regions/ and environments/production/regions/
- [ ] T008 [P] Create README.md with CI/CD framework overview and tag architecture explanation
- [ ] T009 [P] Create SECURITY.md with secret rotation procedures documentation

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure scripts and utilities that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T010 Create scripts/ci/report-generator.sh for generating GitHub Actions job summaries with actionable links
- [ ] T011 [P] Create scripts/ci/workflow-validator.sh for validating GitHub Actions YAML syntax
- [ ] T012 [P] Create scripts/ci/cache-manager.sh for managing GitHub Actions cache optimization
- [ ] T013 [P] Create shared script utilities in scripts/lib/common.sh (testability functions, logging, error handling)
- [ ] T014 [P] Create shared script utilities in scripts/lib/tag-utils.sh (version parsing, tag manipulation, semver comparison)
- [ ] T015 [P] Create shared script utilities in scripts/lib/secret-utils.sh (SOPS decryption wrapper, environment variable loading)
- [ ] T016 [P] Create MISE tasks in mise.toml for decrypt-staging, decrypt-production, decrypt-global
- [ ] T017 [P] Add MISE task for setup (install hooks, generate keys, create environment folders)
- [ ] T018 [P] Add MISE task for edit-secrets (wrapper for SOPS edit command)
- [ ] T019 [P] Create .shellspec configuration file with project-specific settings
- [ ] T020 [P] Create spec/spec_helper.sh with shellspec test utilities and common test functions
- [ ] T021 [P] Create .shfmt.toml configuration (indent=2, binary-next-line, case-indent, space-redirects)
- [ ] T022 [P] Create .shellcheckrc configuration with SC2086, SC2155 rules and bash dialect settings
- [ ] T023 [P] Add MISE tasks for testing (test, test:watch, test:coverage, lint, format, format:check)
- [ ] T024 [P] Add MISE task for test:local-ci to run workflows with act in DRY_RUN mode

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Pipeline Success Reports with Action Links (Priority: P1) 🎯 MVP

**Goal**: Display comprehensive pipeline completion reports with actionable links for promoting releases, triggering rollbacks, assigning states, and running maintenance tasks.

**Independent Test**: Run any CI pipeline to completion and verify that logs and GitHub summary contain all required action links (promote to release, rollback, state assignment, maintenance triggers) with correct pre-filled parameters.

### Implementation for User Story 1

- [ ] T025 [P] [US1] Create scripts/setup/10-ci-install-deps.sh with testability support for installing project dependencies
- [ ] T026 [P] [US1] Create scripts/setup/20-ci-validate-env.sh with testability support for environment validation
- [ ] T027 [P] [US1] Create .github/workflows/pre-release.yml with setup, compile, lint, tests, security-scan, notify jobs
- [ ] T028 [US1] Implement report generation logic in scripts/ci/report-generator.sh to create markdown with workflow dispatch URLs
- [ ] T029 [US1] Add action link generation for "Promote to Release" in report-generator.sh (links to release.yml)
- [ ] T030 [US1] Add action link generation for "Rollback" in report-generator.sh (links to rollback.yml)
- [ ] T031 [US1] Add action link generation for "State Assignment" (stable/unstable) in report-generator.sh (links to tag-assignment.yml)
- [ ] T032 [US1] Add action link generation for "Maintenance Tasks" (all modes) in report-generator.sh (links to maintenance.yml)
- [ ] T033 [US1] Add action link generation for "Self-Healing" in report-generator.sh (links to self-healing.yml)
- [ ] T034 [US1] Integrate report-generator.sh call into notify-pre-release job in .github/workflows/pre-release.yml

### shellspec Tests for User Story 1

- [ ] T035 [P] [US1] Create spec/scripts/setup/install-deps_spec.sh with shellspec tests for dependency installation
- [ ] T036 [P] [US1] Create spec/scripts/setup/validate-env_spec.sh with shellspec tests for environment validation
- [ ] T037 [P] [US1] Create spec/scripts/ci/report-generator_spec.sh with shellspec tests for report generation and link formatting
- [ ] T038 [US1] Create spec/lib/common_spec.sh with shellspec tests for shared utilities (testability functions, logging)
- [ ] T039 [US1] Run mise run test to verify all User Story 1 tests pass

**Checkpoint**: At this point, User Story 1 should be fully functional and tested - pipelines display actionable links after completion

---

## Phase 4: User Story 2 - Advanced Git Tags for Deployment Control (Priority: P1)

**Goal**: Control deployments to different environments using a standardized git tagging system (version tags, environment tags, state tags) with enforcement preventing manual tag assignment.

**Independent Test**: Assign environment tags (production, staging) to commits via CI pipeline and verify that deployments trigger only for the tagged sub-project and environment combination, with git hooks blocking manual tag creation.

### Implementation for User Story 2

- [ ] T040 [P] [US2] Add pre-push hook script in scripts/hooks/pre-push-tag-protection.sh to block protected environment tags
- [ ] T041 [P] [US2] Configure Lefthook in .lefthook.yml to call pre-push-tag-protection.sh with tag pattern checks
- [ ] T042 [P] [US2] Create .github/workflows/tag-assignment.yml with workflow_dispatch inputs (tag_type, version, environment, state, sub_project, commit_sha, force_move)
- [ ] T043 [US2] Implement validate-tag job in tag-assignment.yml to verify tag format and immutability rules
- [ ] T044 [US2] Implement create-or-move-tag job in tag-assignment.yml to create version/state tags or move environment tags
- [ ] T045 [US2] Add logic to tag-assignment.yml to trigger deployment workflow after environment tag creation/move
- [ ] T046 [US2] Implement scripts/release/50-ci-tag-assignment.sh with testability support for git tag operations
- [ ] T047 [US2] Add logging for tag operations (old commit SHA → new commit SHA for environment tags)
- [ ] T048 [US2] Implement notify-tag-assignment job in tag-assignment.yml to report tag creation/move results

### shellspec Tests for User Story 2

- [ ] T049 [P] [US2] Create spec/scripts/hooks/pre-push-tag-protection_spec.sh with shellspec tests for tag protection rules
- [ ] T050 [P] [US2] Create spec/scripts/release/tag-assignment_spec.sh with shellspec tests for tag creation and validation
- [ ] T051 [P] [US2] Create spec/lib/tag-utils_spec.sh with shellspec tests for version parsing and semver comparison
- [ ] T052 [US2] Run mise run test to verify all User Story 2 tests pass

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently and be tested - tags can be assigned via pipeline, deployments trigger automatically

---

## Phase 5: User Story 7 - Enhanced Quality Gates and Security (Priority: P2)

**Goal**: Enforce quality gates including secret scanning, minimal dependencies, small focused scripts, stable versioning, and commit message enforcement to maintain security and code quality standards.

**Independent Test**: Run security scans on scripts to verify no hardcoded credentials, check script line counts (<50 LOC for 90%), confirm no "latest" tags in dependencies, and attempt non-standard commit messages (should be blocked).

### Implementation for User Story 7

- [ ] T053 [P] [US7] Create scripts/build/30-ci-security-scan.sh with Gitleaks and Trufflehog integration
- [ ] T054 [P] [US7] Configure security-scan job in .github/workflows/pre-release.yml to always run (not guardable by enable flags)
- [ ] T055 [P] [US7] Add pre-commit hook script in scripts/hooks/pre-commit-secret-scan.sh for local secret scanning with Gitleaks
- [ ] T056 [P] [US7] Add pre-commit hook script in scripts/hooks/pre-commit-format.sh using shfmt for bash formatting
- [ ] T057 [P] [US7] Add pre-commit hook script in scripts/hooks/pre-commit-lint.sh using shellcheck for bash linting
- [ ] T058 [P] [US7] Configure Lefthook in .lefthook.yml to call pre-commit hooks (secret-scan, format, lint, message-check)
- [ ] T059 [P] [US7] Add pre-commit hook for commitizen validation in scripts/hooks/pre-commit-message-check.sh
- [ ] T060 [P] [US7] Create .github/workflows/self-healing.yml with workflow_dispatch inputs (branch, scope)
- [ ] T061 [US7] Implement auto-format job in self-healing.yml to run shfmt on all bash scripts
- [ ] T062 [US7] Implement auto-lint-fix job in self-healing.yml to run shellcheck with suggestions
- [ ] T063 [US7] Implement commit-fixes job in self-healing.yml to create and push commit if changes detected
- [ ] T064 [US7] Document secret rotation procedures in SECURITY.md for each script using secrets

### shellspec Tests for User Story 7

- [ ] T065 [P] [US7] Create spec/scripts/build/security-scan_spec.sh with shellspec tests for Gitleaks and Trufflehog integration
- [ ] T066 [P] [US7] Create spec/scripts/hooks/pre-commit-format_spec.sh with shellspec tests for shfmt formatting validation
- [ ] T067 [P] [US7] Create spec/scripts/hooks/pre-commit-lint_spec.sh with shellspec tests for shellcheck linting rules
- [ ] T068 [US7] Run mise run test to verify all User Story 7 tests pass

**Checkpoint**: Security and quality gates are now enforced and tested across all pipelines

---

## Phase 6: User Story 4 - DRY CI Scripts with Testability (Priority: P2)

**Goal**: Extract all pipeline logic into standalone, testable script files with hierarchical testability control (CI_TEST_* environment variables) and clear naming conventions.

**Independent Test**: Execute any pipeline step script locally with test environment variables (CI_TEST_MODE=DRY_RUN, PASS, FAIL, SKIP, TIMEOUT), verify expected behavior, and confirm all workflow steps call external scripts rather than containing inline logic.

### Implementation for User Story 4

- [ ] T069 [P] [US4] Create scripts/build/10-ci-compile.sh with full testability hierarchy support (PIPELINE_SCRIPT, SCRIPT, MODE)
- [ ] T070 [P] [US4] Create scripts/build/20-ci-lint.sh with testability support
- [ ] T071 [P] [US4] Create scripts/build/40-ci-bundle.sh with testability support
- [ ] T072 [P] [US4] Create scripts/test/10-ci-unit-tests.sh with testability support
- [ ] T073 [P] [US4] Create scripts/test/20-ci-integration-tests.sh with testability support
- [ ] T074 [P] [US4] Create scripts/test/30-ci-e2e-tests.sh with testability support
- [ ] T075 [P] [US4] Create scripts/release/10-ci-determine-version.sh with testability support for parsing version from tags
- [ ] T076 [P] [US4] Create scripts/release/20-ci-generate-changelog.sh with testability support for conventional commits parsing
- [ ] T077 [P] [US4] Create scripts/release/30-ci-publish-npm.sh with testability support
- [ ] T078 [P] [US4] Create scripts/release/40-ci-publish-docker.sh with testability support
- [ ] T079 [US4] Update .github/workflows/pre-release.yml to call external scripts with workflow-level timeout-minutes configuration
- [ ] T080 [US4] Add CI_JOB_TIMEOUT_MINUTES environment variable override support in all workflow jobs
- [ ] T081 [US4] Document testability variable hierarchy in scripts/lib/common.sh header comments
- [ ] T082 [US4] Add logging for which testability variable source was used (pipeline+script, script, global, default)

### shellspec Tests for User Story 4

- [ ] T083 [P] [US4] Create spec/scripts/build/compile_spec.sh with shellspec tests for compile script and testability modes
- [ ] T084 [P] [US4] Create spec/scripts/build/lint_spec.sh with shellspec tests for lint script
- [ ] T085 [P] [US4] Create spec/scripts/test/unit-tests_spec.sh with shellspec tests for unit test execution
- [ ] T086 [P] [US4] Create spec/scripts/test/integration-tests_spec.sh with shellspec tests for integration test execution
- [ ] T087 [P] [US4] Create spec/scripts/release/determine-version_spec.sh with shellspec tests for version parsing from tags
- [ ] T088 [P] [US4] Create spec/scripts/release/generate-changelog_spec.sh with shellspec tests for changelog generation
- [ ] T089 [US4] Create spec/testability_spec.sh with comprehensive shellspec tests validating all CI_TEST_* modes work correctly
- [ ] T090 [US4] Run mise run test to verify all User Story 4 tests pass

**Checkpoint**: All CI scripts are now standalone, testable, tested with shellspec, and follow DRY principles

---

## Phase 7: User Story 3 - Multi-Environment Configuration Management (Priority: P2)

**Goal**: Manage environment-specific configuration (staging, production, sandbox, canary, performance) in organized sub-folders with support for regions, global scopes, and SOPS-encrypted secrets.

**Independent Test**: Create environment-specific folders with region sub-folders, verify deployments read correct configuration based on environment and region selection, and use profile switching to change active environment context.

### Implementation for User Story 3

- [ ] T091 [P] [US3] Create environments/staging/config.yml with staging-specific settings
- [ ] T092 [P] [US3] Create environments/production/config.yml with production-specific settings
- [ ] T093 [P] [US3] Create environments/global/config.yml with cross-environment shared settings
- [ ] T094 [P] [US3] Create environments/staging/secrets.enc placeholder (SOPS-encrypted)
- [ ] T095 [P] [US3] Create environments/production/secrets.enc placeholder (SOPS-encrypted)
- [ ] T096 [P] [US3] Create environments/global/secrets.enc placeholder (SOPS-encrypted)
- [ ] T097 [P] [US3] Create environments/staging/regions/us-east/config.yml with region-specific cloud mappings
- [ ] T098 [P] [US3] Create environments/staging/regions/eu-west/config.yml with region-specific cloud mappings
- [ ] T099 [P] [US3] Create environments/production/regions/us-east/config.yml with region-specific cloud mappings
- [ ] T100 [P] [US3] Create environments/production/regions/eu-west/config.yml with region-specific cloud mappings
- [ ] T101 [US3] Implement scripts/deployment/10-ci-deploy-staging.sh with environment config loading and SOPS decryption
- [ ] T102 [US3] Implement scripts/deployment/20-ci-deploy-production.sh with environment config loading and SOPS decryption
- [ ] T103 [US3] Add profile switching support in mise.toml tasks (mise run profile:staging:us-east)
- [ ] T104 [US3] Document cloud-agnostic region mapping in environments/global/config.yml

**Checkpoint**: Multi-environment configuration is now managed with regions and encrypted secrets

---

## Phase 8: User Story 2 - Deployment Pipeline and Queue (Priority: P1 - Continuation)

**Goal**: Complete deployment workflow with automatic version detection, queue management, and environment tag movement.

**Independent Test**: Trigger multiple deployments to same environment, verify FIFO queue behavior, and confirm environment tags move atomically after successful deployment.

### Implementation for User Story 2 (Deployment)

- [ ] T093 [US2] Create .github/workflows/deployment.yml with concurrency groups for queue management
- [ ] T094 [US2] Implement detect-version job in deployment.yml to find version tag on same commit as environment tag
- [ ] T095 [US2] Implement queue-check job in deployment.yml to display queue position and estimated wait time
- [ ] T096 [US2] Implement pre-deployment job in deployment.yml to validate environment and decrypt secrets via MISE
- [ ] T097 [US2] Implement deploy job in deployment.yml to execute deployment scripts for target environment/region
- [ ] T098 [US2] Implement post-deployment job in deployment.yml to run smoke tests and verify deployment
- [ ] T099 [US2] Add environment tag movement logic after successful deployment (git tag -f && git push -f)
- [ ] T100 [US2] Implement notify-deployment job in deployment.yml to report results with action links
- [ ] T101 [US2] Add concurrency configuration in deployment.yml: `group: deploy-${{ github.ref_name }}, cancel-in-progress: false`
- [ ] T102 [US2] Add deployment workflow trigger on push.tags matching environment tag patterns

**Checkpoint**: Deployments now work end-to-end with queue management and version detection

---

## Phase 9: User Story 2 - Rollback Mechanism (Priority: P1 - Continuation)

**Goal**: Implement rollback workflow with automatic previous version detection, stable version prioritization, and deprecated version exclusion.

**Independent Test**: Trigger rollback, verify system scans git tags, identifies previous version using semver comparison, prioritizes stable versions, excludes deprecated versions, and fails with clear error if no valid target exists.

### Implementation for User Story 2 (Rollback)

- [ ] T103 [US2] Create .github/workflows/rollback.yml with workflow_dispatch inputs (environment, sub_project, target_version, region)
- [ ] T104 [US2] Implement identify-current job in rollback.yml to find current version from environment tag commit
- [ ] T105 [US2] Implement identify-target job in rollback.yml with version scanning and semver comparison
- [ ] T106 [US2] Implement scripts/deployment/30-ci-rollback.sh with version selection algorithm (scan, filter, prioritize stable, exclude deprecated)
- [ ] T107 [US2] Add logic to prioritize versions with -stable state tags over versions without
- [ ] T108 [US2] Add logic to exclude versions with -deprecated state tags from rollback candidates
- [ ] T109 [US2] Implement validate-target job in rollback.yml to verify selected version is valid rollback candidate
- [ ] T110 [US2] Implement execute-rollback job in rollback.yml to move environment tag to target version commit
- [ ] T111 [US2] Implement verify-rollback job in rollback.yml to run smoke tests on rolled-back version
- [ ] T112 [US2] Implement notify-rollback job in rollback.yml to report results with version selection reasoning
- [ ] T113 [US2] Add clear error message and failure if no valid rollback target exists

**Checkpoint**: Rollback functionality is complete with intelligent version selection

---

## Phase 10: User Story 1 - Release Pipeline (Priority: P1 - Continuation)

**Goal**: Complete release pipeline with version tag creation, changelog generation, and publishing to npm/Docker/GitHub Releases.

**Independent Test**: Push version tag or manually trigger release workflow, verify changelog generation from conventional commits, artifacts published to registries, and GitHub Release created with release notes.

### Implementation for User Story 1 (Release)

- [ ] T128 [US1] Create .github/workflows/release.yml with trigger on push.tags matching version tag patterns
- [ ] T129 [US1] Add workflow_dispatch inputs to release.yml (version, skip_npm, skip_docker, skip_docs)
- [ ] T130 [US1] Implement determine-version job in release.yml calling scripts/release/10-ci-determine-version.sh
- [ ] T131 [US1] Implement changelog job in release.yml calling scripts/release/20-ci-generate-changelog.sh
- [ ] T132 [US1] Implement publish-npm job in release.yml calling scripts/release/30-ci-publish-npm.sh (if ENABLE_NPM_PUBLISH)
- [ ] T133 [US1] Implement publish-github job in release.yml to create GitHub Release with artifacts
- [ ] T134 [US1] Implement publish-docker job in release.yml calling scripts/release/40-ci-publish-docker.sh (if ENABLE_DOCKER_PUBLISH)
- [ ] T135 [US1] Implement deploy-docs job in release.yml (if ENABLE_DOCS_DEPLOY)
- [ ] T136 [US1] Implement notify-release job in release.yml with action links (deploy to staging, deploy to production, tag as stable, rollback)

**Checkpoint**: Release pipeline is complete end-to-end

---

## Phase 11: User Story 1 - Post-Release and Maintenance Pipelines (Priority: P1 - Continuation)

**Goal**: Complete post-release verification and maintenance pipelines with smoke tests, health checks, and automated maintenance tasks.

**Independent Test**: Trigger post-release workflow after deployment, verify smoke tests and health checks run, and manually trigger maintenance tasks to confirm cleanup, audits, and dependency updates work.

### Implementation for User Story 1 (Post-Release & Maintenance)

- [ ] T137 [P] [US1] Create .github/workflows/post-release.yml with workflow_run trigger and workflow_dispatch inputs
- [ ] T138 [P] [US1] Implement smoke-tests job in post-release.yml to verify deployed version
- [ ] T139 [P] [US1] Implement health-checks job in post-release.yml with retry and exponential backoff
- [ ] T140 [P] [US1] Implement performance-check job in post-release.yml (if ENABLE_PERFORMANCE_CHECK)
- [ ] T141 [US1] Implement notify-post-release job in post-release.yml with action links (mark as stable, rollback, open incident)
- [ ] T142 [P] [US1] Create .github/workflows/maintenance.yml with schedule trigger and workflow_dispatch inputs (task_mode, dry_run)
- [ ] T143 [P] [US1] Create scripts/maintenance/10-ci-cleanup.sh with testability support for removing old artifacts and deprecated tags
- [ ] T144 [P] [US1] Create scripts/maintenance/20-ci-security-audit.sh with testability support for comprehensive security checks
- [ ] T145 [P] [US1] Create scripts/maintenance/30-ci-dependency-update.sh with testability support for checking and proposing updates
- [ ] T146 [P] [US1] Create scripts/maintenance/40-ci-deprecate-versions.sh with testability support for auto-marking old versions
- [ ] T147 [US1] Implement maintenance workflow jobs (cleanup, sync-files, deprecate-old-versions, security-audit, dependency-update)
- [ ] T148 [US1] Implement notify-maintenance job in maintenance.yml with action links (review PRs, security dashboard)

**Checkpoint**: All pipelines (pre-release, release, post-release, maintenance) are complete

---

## Phase 12: User Story 5 - Script Placeholders with Implementation Guidance (Priority: P3)

**Goal**: Ensure all CI scripts are well-documented placeholders with inline examples and testability documentation so developers can understand and customize them.

**Independent Test**: Open any CI script file and verify it contains clear header comments explaining purpose, usage examples for common scenarios (Node.js/TypeScript), and testability environment variables.

### Implementation for User Story 5

- [ ] T118 [P] [US5] Add comprehensive header comments to scripts/build/10-ci-compile.sh with purpose, customization examples, testability modes
- [ ] T119 [P] [US5] Add comprehensive header comments to scripts/build/20-ci-lint.sh with examples for ESLint, Prettier, etc.
- [ ] T120 [P] [US5] Add comprehensive header comments to scripts/test/10-ci-unit-tests.sh with examples for Jest, Vitest, etc.
- [ ] T121 [P] [US5] Add comprehensive header comments to scripts/release/30-ci-publish-npm.sh with npm registry configuration examples
- [ ] T122 [P] [US5] Add comprehensive header comments to scripts/release/40-ci-publish-docker.sh with Docker registry examples
- [ ] T123 [P] [US5] Add comprehensive header comments to scripts/deployment/10-ci-deploy-staging.sh with deployment examples
- [ ] T124 [P] [US5] Add comprehensive header comments to scripts/deployment/20-ci-deploy-production.sh with deployment examples
- [ ] T125 [US5] Add commented TypeScript/Bun examples for complex logic scenarios in all relevant scripts
- [ ] T126 [US5] Document all supported CI_TEST_* environment variables in script headers (EXECUTE, DRY_RUN, PASS, FAIL, SKIP, TIMEOUT)

**Checkpoint**: All scripts have comprehensive inline documentation

---

## Phase 13: User Story 6 - Minimalistic Auto-Activation Configuration (Priority: P3)

**Goal**: Enable features to auto-activate when sufficient configuration is detected without requiring explicit enable flags, with ability to explicitly disable via DISABLE_* flags.

**Independent Test**: Add APPRISE_URL to GitHub Secrets, verify next pipeline run automatically sends notifications without setting ENABLE_NOTIFICATIONS=true, and confirm DISABLE_NOTIFICATIONS=true overrides auto-activation.

### Implementation for User Story 6

- [ ] T127 [P] [US6] Add auto-activation logic to notify-pre-release job in .github/workflows/pre-release.yml (check for APPRISE_URL secret)
- [ ] T128 [P] [US6] Add auto-activation logic for npm publishing in release.yml (check for NPM_TOKEN secret)
- [ ] T129 [P] [US6] Add auto-activation logic for Docker publishing in release.yml (check for DOCKER_USERNAME and DOCKER_PASSWORD secrets)
- [ ] T130 [US6] Implement graceful skip with log message when auto-activation credentials are missing
- [ ] T131 [US6] Add DISABLE_* flag override support in all auto-activation checks (DISABLE_NOTIFICATIONS, DISABLE_NPM_PUBLISH, DISABLE_DOCKER_PUBLISH)
- [ ] T132 [US6] Document auto-activation behavior in README.md with examples

**Checkpoint**: Features now auto-enable intelligently based on configuration

---

## Phase 14: Polish & Cross-Cutting Concerns

**Purpose**: Final improvements, documentation, and validation

- [ ] T133 [P] Create quickstart documentation in docs/quickstart.md (if not already exists)
- [ ] T134 [P] Create architecture diagram in docs/architecture.md showing four-stage pipeline and tag structure
- [ ] T135 [P] Add example GitHub Actions workflow runs to docs/examples/ directory
- [ ] T136 [P] Create troubleshooting guide in docs/troubleshooting.md with common issues and solutions
- [ ] T137 [P] Update CLAUDE.md with complete technology stack and command reference
- [ ] T138 [P] Add workflow validation checks using scripts/ci/workflow-validator.sh to mise.toml as task
- [ ] T139 [P] Add comprehensive logging across all scripts with [INFO], [DEBUG], [ERROR], [SUCCESS] prefixes
- [ ] T140 [P] Validate all SOPS-encrypted files are properly encrypted and not committed in plaintext
- [ ] T141 [P] Add GitHub Actions caching configuration for dependencies in all workflows
- [ ] T142 [P] Configure artifact retention periods (7 days pre-release, 30 days deployment, 90 days release)
- [ ] T143 Run full pipeline test using CI_TEST_MODE=DRY_RUN to verify all scripts execute without errors
- [ ] T144 Verify quickstart.md instructions by following setup steps in clean environment
- [ ] T145 Test tag protection by attempting manual environment tag creation (should be blocked by hooks)
- [ ] T146 Test rollback version selection algorithm with sample git tags (stable, unstable, deprecated)
- [ ] T147 Final review: Confirm 90% of scripts are under 50 LOC (excluding comments and testability boilerplate)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational (Phase 2) - Core pipeline reports
- **User Story 2 (Phase 4-5, 8-9)**: Depends on Foundational (Phase 2) - Tag control and deployment (spans multiple phases)
- **User Story 7 (Phase 5)**: Depends on Foundational (Phase 2) - Security gates
- **User Story 4 (Phase 6)**: Depends on Foundational (Phase 2) - Script testability
- **User Story 3 (Phase 7)**: Depends on Foundational (Phase 2) - Environment config
- **User Story 1 Continuation (Phase 10-11)**: Depends on Phase 3 - Release and maintenance pipelines
- **User Story 5 (Phase 12)**: Depends on Phase 6 (scripts must exist before documenting)
- **User Story 6 (Phase 13)**: Depends on Phase 10-11 (pipelines must exist)
- **Polish (Phase 14)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories (though integrates with US1)
- **User Story 7 (P2)**: Can start after Foundational (Phase 2) - Enhances US1/US2 but independently testable
- **User Story 4 (P2)**: Can start after Foundational (Phase 2) - Refactors scripts from US1/US2 but independently testable
- **User Story 3 (P2)**: Can start after Foundational (Phase 2) - Integrates with US2 (deployment) but independently testable
- **User Story 5 (P3)**: Depends on US4 (scripts must exist first)
- **User Story 6 (P3)**: Depends on US1 (pipelines must exist first)

### Within Each Phase

- Tasks marked [P] can run in parallel (different files, no dependencies)
- Sequential tasks must complete in order
- Checkpoint indicates when phase is independently testable

### Parallel Opportunities

**Setup Phase (Phase 1)**: All tasks marked [P] can run in parallel (T002-T009)

**Foundational Phase (Phase 2)**: All tasks marked [P] can run in parallel (T011-T018)

**User Story Phases**: Tasks marked [P] within each phase can run in parallel

**Example - Phase 3 (US1)**: T019-T020 can run in parallel

**Example - Phase 12 (US5)**: T118-T124 can run in parallel

---

## Parallel Example: Setup Phase

```bash
# Launch all parallel setup tasks together:
Task: "Create mise.toml with tool definitions"
Task: "Create .lefthook.yml with git hooks"
Task: "Create commitizen.json with commit config"
Task: "Create .sops.yaml with encryption rules"
Task: "Create environments/ directory structure"
Task: "Create region subdirectories"
Task: "Create README.md with framework overview"
Task: "Create SECURITY.md with rotation procedures"
```

---

## Parallel Example: User Story 1

```bash
# Launch parallel tasks for User Story 1:
Task: "Create scripts/setup/10-ci-install-deps.sh"
Task: "Create scripts/setup/20-ci-validate-env.sh"

# Then launch second wave:
Task: "Create .github/workflows/pre-release.yml"
# (depends on setup scripts existing for reference)
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (Pipeline Reports)
4. Complete Phase 4-5, 8-9: User Story 2 (Tag Control & Deployment)
5. **STOP and VALIDATE**: Test US1 and US2 independently
6. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (Basic pipeline reports!)
3. Add User Story 2 → Test independently → Deploy/Demo (Tag-based deployment!)
4. Add User Story 7 → Test independently → Deploy/Demo (Security gates!)
5. Add User Story 4 → Test independently → Deploy/Demo (Testable scripts!)
6. Add User Story 3 → Test independently → Deploy/Demo (Multi-environment!)
7. Add User Story 5 → Test independently → Deploy/Demo (Documentation!)
8. Add User Story 6 → Test independently → Deploy/Demo (Auto-activation!)
9. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (Phases 3, 10, 11)
   - Developer B: User Story 2 (Phases 4-5, 8-9)
   - Developer C: User Story 7 (Phase 5)
3. After core stories complete:
   - Developer A: User Story 4 (Phase 6)
   - Developer B: User Story 3 (Phase 7)
   - Developer C: User Story 5 (Phase 12)
4. Stories complete and integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Tests are NOT included (not requested in specification)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
