---

description: "Task list for CI Pipeline Comprehensive Update feature implementation"
---

# Tasks: CI Pipeline Comprehensive Update

**Input**: Design documents from `/specs/002-ci-pipeline-update/`
**Prerequisites**: plan.md, spec.md, data-model.md, contracts/github-actions.yaml, research.md

**Tests**: Include test tasks based on ShellSpec testing requirements from specification

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Workflows**: `.github/workflows/`
- **Scripts**: `scripts/` (organized by lifecycle phase)
- **Config**: `environments/` (environment-specific configuration)
- **Tests**: `spec/` (ShellSpec tests for bash scripts)

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
- [ ] T008 [P] Create config/ directory with .env.template and .env.local examples
- [ ] T009 [P] Create .secrets/ directory for age key storage
- [ ] T010 [P] Create .shellspec.toml configuration with project-specific settings
- [ ] T011 [P] Create .shfmt.toml configuration (indent=2, binary-next-line, case-indent, space-redirects)
- [ ] T012 [P] Create .shellcheckrc configuration with SC2086, SC2155 rules and bash dialect settings
- [ ] T013 Create README.md with CI/CD framework overview and tag architecture explanation
- [ ] T014 Create SECURITY.md with secret rotation procedures documentation

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure scripts and utilities that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T015 Create scripts/ci/report-generator.sh for generating GitHub Actions job summaries with actionable links
- [ ] T016 [P] Create scripts/ci/workflow-validator.sh for validating GitHub Actions YAML syntax
- [ ] T017 [P] Create scripts/ci/cache-manager.sh for managing GitHub Actions cache optimization
- [ ] T018 [P] Create shared script utilities in scripts/lib/common.sh (testability functions, logging, error handling)
- [ ] T019 [P] Create shared script utilities in scripts/lib/tag-utils.sh (version parsing, tag manipulation, semver comparison)
- [ ] T020 [P] Create shared script utilities in scripts/lib/secret-utils.sh (SOPS decryption wrapper, environment variable loading)
- [ ] T021 [P] Create scripts/profile/switch-profile.sh for MISE profile switching
- [ ] T022 [P] Create scripts/profile/show-profile.sh for displaying current profile status
- [ ] T023 [P] Create scripts/secrets/init-secrets.sh for initializing encrypted secrets
- [ ] T024 [P] Create scripts/secrets/rotate-keys.sh for key rotation procedures
- [ ] T025 [P] Create scripts/tools/verify-tools.sh for validating tool installation
- [ ] T026 [P] Create scripts/tools/setup-platform.sh for cross-platform setup
- [ ] T027 Add MISE tasks in mise.toml for profile switching, secret management, and tool verification
- [ ] T028 [P] Add MISE task for setup (install hooks, generate keys, create environment folders)
- [ ] T029 [P] Add MISE task for edit-secrets (wrapper for SOPS edit command)
- [ ] T030 [P] Add MISE tasks for testing (test, test:watch, test:coverage, lint, format, format:check)
- [ ] T031 [P] Add MISE task for test:local-ci to run workflows with act in DRY_RUN mode

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Pipeline Success Reports with Action Links (Priority: P1) 🎯 MVP

**Goal**: Display comprehensive pipeline completion reports with actionable links for promoting releases, triggering rollbacks, assigning states, and running maintenance tasks.

**Independent Test**: Run any CI pipeline to completion and verify that logs and GitHub summary contain all required action links (promote to release, rollback, state assignment, maintenance triggers) with correct parameters.

### shellspec Tests for User Story 1

- [ ] T032 [P] [US1] Create spec/scripts/ci/report-generator_spec.sh with shellspec tests for report generation and link formatting
- [ ] T033 [P] [US1] Create spec/lib/common_spec.sh with shellspec tests for shared utilities (testability functions, logging)

### Implementation for User Story 1

- [ ] T034 [P] [US1] Create scripts/setup/10-ci-install-deps.sh with testability support for installing project dependencies
- [ ] T035 [P] [US1] Create scripts/setup/20-ci-validate-env.sh with testability support for environment validation
- [ ] T036 [US1] Create .github/workflows/pre-release.yml with setup, compile, lint, tests, security-scan, notify jobs
- [ ] T037 [US1] Implement report generation logic in scripts/ci/report-generator.sh to create markdown with workflow dispatch URLs
- [ ] T038 [US1] Add action link generation for "Promote to Release" in report-generator.sh (links to release.yml)
- [ ] T039 [US1] Add action link generation for "Rollback" in report-generator.sh (links to rollback.yml)
- [ ] T040 [US1] Add action link generation for "State Assignment" (stable/unstable) in report-generator.sh (links to tag-assignment.yml)
- [ ] T041 [US1] Add action link generation for "Maintenance Tasks" (all modes) in report-generator.sh (links to maintenance.yml)
- [ ] T042 [US1] Add action link generation for "Self-Healing" in report-generator.sh (links to self-healing.yml)
- [ ] T043 [US1] Add action link generation for webhook execution with authentication in report-generator.sh
- [ ] T044 [US1] Integrate report-generator.sh call into notify-pre-release job in .github/workflows/pre-release.yml

**Checkpoint**: At this point, User Story 1 should be fully functional and tested - pipelines display actionable links after completion

---

## Phase 4: User Story 2 - Advanced Git Tags for Deployment Control (Priority: P1)

**Goal**: Control deployments to different environments using a standardized git tagging system with enforcement preventing manual tag assignment.

**Independent Test**: Assign environment tags (production, staging) to commits via CI pipeline and verify that deployments trigger only for the tagged sub-project and environment combination, with git hooks blocking manual tag creation.

### shellspec Tests for User Story 2

- [ ] T045 [P] [US2] Create spec/scripts/hooks/pre-push-tag-protection_spec.sh with shellspec tests for tag protection rules
- [ ] T046 [P] [US2] Create spec/scripts/release/tag-assignment_spec.sh with shellspec tests for tag creation and validation
- [ ] T047 [P] [US2] Create spec/lib/tag-utils_spec.sh with shellspec tests for version parsing and semver comparison

### Implementation for User Story 2

- [ ] T048 [P] [US2] Add pre-push hook script in scripts/hooks/pre-push-tag-protection.sh to block protected environment tags
- [ ] T049 [US2] Configure Lefthook in .lefthook.yml to call pre-push-tag-protection.sh with tag pattern checks
- [ ] T050 [US2] Create .github/workflows/tag-assignment.yml with workflow_dispatch inputs (tag_type, version, environment, state, sub_project, commit_sha, force_move)
- [ ] T051 [US2] Implement validate-tag job in tag-assignment.yml to verify tag format and immutability rules
- [ ] T052 [US2] Implement create-or-move-tag job in tag-assignment.yml to create version/state tags or move environment tags
- [ ] T053 [US2] Add logic to tag-assignment.yml to trigger deployment workflow after environment tag creation/move
- [ ] T054 [US2] Implement scripts/release/50-ci-tag-assignment.sh with testability support for git tag operations
- [ ] T055 [US2] Add logging for tag operations (old commit SHA → new commit SHA for environment tags)
- [ ] T056 [US2] Implement notify-tag-assignment job in tag-assignment.yml to report tag creation/move results
- [ ] T057 [US2] Create .github/workflows/deployment.yml with concurrency groups for deployment conflict management
- [ ] T058 [US2] Add concurrency configuration in deployment.yml: `group: deploy-${{ inputs.subproject }}-${{ inputs.environment }}`

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently and be tested - tags can be assigned via pipeline, deployments trigger automatically

---

## Phase 5: User Story 6 - Enhanced Quality Gates and Security (Priority: P2)

**Goal**: Enforce quality gates including secret scanning, minimal dependencies, small focused scripts, stable versioning, and commit message enforcement.

**Independent Test**: Run security scans on scripts, verify no credentials are hardcoded, check script line counts, confirm no "latest" tags in dependencies, and attempt commits with non-standard messages (should be blocked by commitizen).

### shellspec Tests for User Story 6

- [ ] T059 [P] [US6] Create spec/scripts/build/security-scan_spec.sh with shellspec tests for Gitleaks and Trufflehog integration
- [ ] T060 [P] [US6] Create spec/scripts/hooks/pre-commit-format_spec.sh with shellspec tests for shfmt formatting validation
- [ ] T061 [P] [US6] Create spec/scripts/hooks/pre-commit-lint_spec.sh with shellspec tests for shellcheck linting rules

### Implementation for User Story 6

- [ ] T062 [P] [US6] Create scripts/build/30-ci-security-scan.sh with Gitleaks and Trufflehog integration
- [ ] T063 [US6] Configure security-scan job in .github/workflows/pre-release.yml to always run (not guardable by enable flags)
- [ ] T064 [P] [US6] Add pre-commit hook script in scripts/hooks/pre-commit-secret-scan.sh for local secret scanning with Gitleaks
- [ ] T065 [P] [US6] Add pre-commit hook script in scripts/hooks/pre-commit-format.sh using shfmt for bash formatting
- [ ] T066 [P] [US6] Add pre-commit hook script in scripts/hooks/pre-commit-lint.sh using shellcheck for bash linting
- [ ] T067 [US6] Configure Lefthook in .lefthook.yml to call pre-commit hooks (secret-scan, format, lint, message-check)
- [ ] T068 [US6] Add pre-commit hook for commitizen validation in scripts/hooks/pre-commit-message-check.sh
- [ ] T069 [US6] Create .github/workflows/self-healing.yml with workflow_dispatch inputs (branch, scope)
- [ ] T070 [US6] Implement auto-format job in self-healing.yml to run shfmt on all bash scripts
- [ ] T071 [US6] Implement auto-lint-fix job in self-healing.yml to run shellcheck with suggestions
- [ ] T072 [US6] Implement commit-fixes job in self-healing.yml to create and push commit if changes detected
- [ ] T073 [US6] Document secret rotation procedures in SECURITY.md for each script using secrets

**Checkpoint**: Security and quality gates are now enforced and tested across all pipelines

---

## Phase 6: User Story 4 - DRY CI Scripts with Testability (Priority: P2)

**Goal**: Extract all pipeline logic into standalone, testable script files with hierarchical testability control and clear naming conventions.

**Independent Test**: Execute any pipeline step script locally with test environment variables, verify expected behavior, and confirm all workflow steps call external scripts rather than containing inline logic.

### shellspec Tests for User Story 4

- [ ] T074 [P] [US4] Create spec/scripts/build/compile_spec.sh with shellspec tests for compile script and testability modes
- [ ] T075 [P] [US4] Create spec/scripts/test/test_spec.sh with shellspec tests for test execution modes
- [ ] T076 [P] [US4] Create spec/testability_spec.sh with comprehensive shellspec tests validating all CI_TEST_* modes work correctly

### Implementation for User Story 4

- [ ] T077 [P] [US4] Create scripts/build/10-ci-compile.sh with full testability hierarchy support (PIPELINE_SCRIPT, SCRIPT, MODE)
- [ ] T078 [P] [US4] Create scripts/build/20-ci-lint.sh with testability support
- [ ] T079 [P] [US4] Create scripts/build/40-ci-bundle.sh with testability support
- [ ] T080 [P] [US4] Create scripts/test/10-ci-unit-tests.sh with testability support
- [ ] T081 [P] [US4] Create scripts/test/20-ci-integration-tests.sh with testability support
- [ ] T082 [P] [US4] Create scripts/test/30-ci-e2e-tests.sh with testability support
- [ ] T083 [US4] Create scripts/release/10-ci-determine-version.sh with testability support for parsing version from tags
- [ ] T084 [P] [US4] Create scripts/release/20-ci-generate-changelog.sh with testability support for conventional commits parsing
- [ ] T085 [P] [US4] Create scripts/release/30-ci-publish-npm.sh with testability support
- [ ] T086 [P] [US4] Create scripts/release/40-ci-publish-docker.sh with testability support
- [ ] T087 [US4] Update .github/workflows/pre-release.yml to call external scripts with workflow-level timeout-minutes configuration
- [ ] T088 [US4] Add CI_JOB_TIMEOUT_MINUTES environment variable override support in all workflow jobs
- [ ] T089 [US4] Document testability variable hierarchy in scripts/lib/common.sh header comments
- [ ] T090 [US4] Add logging for which testability variable source was used (pipeline+script, script, global, default)

**Checkpoint**: All CI scripts are now standalone, testable, and follow DRY principles

---

## Phase 7: User Story 3 - Multi-Environment Configuration Management (Priority: P2)

**Goal**: Manage environment-specific configuration in organized sub-folders with support for regions and global scopes.

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
- [ ] T103 [US3] Add MISE tasks for decrypt-staging, decrypt-production, decrypt-global
- [ ] T104 [US3] Implement scripts/deployment/40-ci-atomic-tag-movement.sh for atomic environment tag operations
- [ ] T105 [US3] Document cloud-agnostic region mapping in environments/global/config.yml

**Checkpoint**: Multi-environment configuration is now managed with regions and encrypted secrets

---

## Phase 8: User Story 5 - Script Placeholders with Implementation Guidance (Priority: P3)

**Goal**: Ensure all scripts are well-documented placeholders with inline examples and clear extension points.

**Independent Test**: Read any CI script file and verify it contains clear comments explaining purpose, usage examples for common scenarios, testability environment variables, and extension points.

### Implementation for User Story 5

- [ ] T106 [P] [US5] Add comprehensive header comments to all existing scripts with purpose, usage, and testability variables
- [ ] T107 [US5] Add commented implementation examples for Node.js/TypeScript in all compile scripts
- [ ] T108 [US5] Add commented implementation examples for Python in all compile scripts
- [ ] T109 [US5] Add commented implementation examples for Go in all compile scripts
- [ ] T110 [US5] Add clear extension points documentation in all scripts
- [ ] T111 [US5] Add guidance on script size limits and when to extract helpers in all scripts
- [ ] T112 [US5] Create script template in templates/ci-script-template.sh with full documentation structure
- [ ] T113 [US5] Add script development guide in docs/script-development.md

**Checkpoint**: All scripts are now well-documented placeholders with implementation guidance

---

## Phase 9: Additional Workflows and Completion

**Purpose**: Complete remaining workflow implementations and cross-cutting concerns

- [ ] T114 [P] Create .github/workflows/release.yml for version tag triggered releases
- [ ] T115 [P] Create .github/workflows/post-release.yml for post-deployment verification
- [ ] T116 [P] Create .github/workflows/maintenance.yml for cron-based background tasks
- [ ] T117 [P] Create .github/workflows/rollback.yml for rollback operations
- [ ] T118 [P] Implement scripts/maintenance/10-ci-cleanup.sh for artifact and log cleanup
- [ ] T119 [P] Implement scripts/maintenance/20-ci-security-audit.sh for periodic security reviews
- [ ] T120 [P] Implement scripts/maintenance/30-ci-dependency-update.sh for automated dependency updates
- [ ] T121 [P] Implement scripts/maintenance/40-ci-deprecate-versions.sh for version lifecycle management
- [ ] T122 [P] Implement scripts/deployment/30-ci-rollback.sh for rollback execution
- [ ] T123 [P] Create ZSH plugin in scripts/shell/mise-profile.plugin.zsh for profile visualization
- [ ] T124 [P] Create script for shell integration setup in scripts/shell/setup-shell-integration.sh

---

## Phase 10: Polish & Cross-Cutting Concerns

**Purpose**: Final improvements, documentation, and validation

- [ ] T125 [P] Update quickstart.md with complete setup and usage instructions
- [ ] T126 [P] Create comprehensive developer guide in docs/developer-guide.md
- [ ] T127 [P] Create troubleshooting guide in docs/troubleshooting.md
- [ ] T128 [P] Add performance monitoring and metrics to all scripts
- [ ] T129 [P] Run comprehensive security audit on all scripts and configurations
- [ ] T130 [P] Validate all scripts are under 50 LOC (excluding comments)
- [ ] T131 [P] Run full test suite with mise run test to ensure all shellspec tests pass
- [ ] T132 [P] Validate quickstart.md instructions by following them end-to-end
- [ ] T133 [P] Create migration guide from existing CI/CD setups
- [ ] T134 [P] Add integration examples for different project types (Node.js, Python, Go)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-8)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (US1/US2 → US6 → US4 → US3 → US5)
- **Additional Workflows (Phase 9)**: Depends on User Stories 1, 2, 6 completion
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P1)**: Can start after Foundational (Phase 2) - Integrates with US1 for action links but independently testable
- **User Story 6 (P2)**: Can start after Foundational (Phase 2) - Enhances all stories but independently testable
- **User Story 4 (P2)**: Can start after Foundational (Phase 2) - Refactors scripts used by all stories
- **User Story 3 (P2)**: Can start after Foundational (Phase 2) - Used by deployment workflows from US2
- **User Story 5 (P3)**: Can start after all scripts are created (Phase 4/6) - Documentation enhancement

### Within Each User Story

- Tests MUST be written and FAIL before implementation (where applicable)
- Core implementation before integration
- Story complete before moving to next priority
- All tasks in story should be marked complete before story checkpoint

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes, User Story 1 and 2 can start in parallel (both P1)
- User Stories 6, 4, 3 can start in parallel after P1 stories (different team members)
- All tests for a user story marked [P] can run in parallel
- Environment configuration tasks marked [P] can run in parallel
- Different user stories can be worked on in parallel by different team members

---

## Parallel Example: User Story 1 (P1)

```bash
# Launch User Story 1 tests together:
Task: "Create spec/scripts/ci/report-generator_spec.sh with shellspec tests for report generation and link formatting"
Task: "Create spec/lib/common_spec.sh with shellspec tests for shared utilities (testability functions, logging)"

# Launch User Story 1 script creation together:
Task: "Create scripts/setup/10-ci-install-deps.sh with testability support for installing project dependencies"
Task: "Create scripts/setup/20-ci-validate-env.sh with testability support for environment validation"

# Launch User Story 1 action link generation together:
Task: "Add action link generation for "Promote to Release" in report-generator.sh (links to release.yml)"
Task: "Add action link generation for "Rollback" in report-generator.sh (links to rollback.yml)"
Task: "Add action link generation for "State Assignment" (stable/unstable) in report-generator.sh (links to tag-assignment.yml)"
```

---

## Implementation Strategy

### MVP First (User Stories 1 & 2)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (Pipeline Reports)
4. Complete Phase 4: User Story 2 (Git Tags)
5. **STOP and VALIDATE**: Test both stories independently - core CI/CD functionality working
6. Deploy/demo core functionality

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (Actionable reports!)
3. Add User Story 2 → Test independently → Deploy/Demo (Deployment control!)
4. Add User Story 6 → Test independently → Deploy/Demo (Security & quality!)
5. Add User Story 4 → Test independently → Deploy/Demo (Maintainable scripts!)
6. Add User Story 3 → Test independently → Deploy/Demo (Multi-environment!)
7. Add User Story 5 → Test independently → Deploy/Demo (Developer experience!)

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (Pipeline Reports)
   - Developer B: User Story 2 (Git Tags)
3. After P1 stories complete:
   - Developer A: User Story 6 (Quality Gates) + User Story 4 (Script Testability)
   - Developer B: User Story 3 (Multi-Environment) + User Story 5 (Documentation)
4. Stories complete and integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing (TDD approach for bash scripts)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- All scripts must follow constitutional principles (stateless, variable-driven, stub-based)
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence