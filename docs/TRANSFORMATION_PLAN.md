# Transformation Plan: CI Pipeline Excellence (v2.0)

This plan outlines the step-by-step transformation of the repository to adopt the "CI Pipeline Excellence" framework (v2.0), incorporating findings from the `002-ci-pipeline-update` Proof of Concept (PoC).

**Reference Spec**: `versions/002-ci-pipeline-update/specs/002-ci-pipeline-update/spec.md`
**Reference Implementation (PoC)**: `versions/002-ci-pipeline-update/`

> **Note**: The `versions` directory contains Proof of Concepts (PoCs) for evaluation and inspiration. This plan adapts those ideas into the `main` branch, which remains the single source of truth. We do not strictly copy the PoC; we strictly apply the defined principles.

## Guiding Principles

This transformation is governed by the project's core constitution. All changes must align with these principles:

1.  **Template-First Architecture**: Designed as an overlay template to instantly solve CI/CD complexity for existing projects.
2.  **Node.js Monorepo Focus**: Optimized for complex Node.js monorepos but gracefully supports simple projects.
3.  **Testability is Key**: Granular control and testability of every pipeline step (Locally & Remote).
4.  **e-bash Foundation**: `e-bash` library provides the standard for logging, error handling, and consistency.
5.  **Zero-Configuration Goal**: "Ready for Production" defaults; minimal setup required for the end user.
6.  **Customization & Flexibility**: Adjust pipelines via hooks and configuration without modifying core code.
7.  **Unified Control**: Centralized `ops.yaml` and static dashboard for release management.
8.  **Strict Script Organization**: `scripts/` contains ONLY `ci`, `lib`, and `setup`. No top-level pollution.
9.  **Minimalist Root Config**: `mise.toml` remains clean and portable; specialized tasks live in scripts.
10. **Hierarchical Configuration**: Support 4 levels of overrides (Global -> Pipeline -> Step -> Script).
11. **Traceability First**: Advanced logging via `e-bash`; placeholders for future metrics.
12. **Stable Workflows**: Worflows are defined one time and are not redefined in future. For customization should be used specially designed hooks, injection points, etc.
13. **Local Environment First**: Local environment should be the first priority. All configurations should be done locally first and then promoted to the CI/CD pipeline github actions.
14. **Zero down time**: Any modifications to CI/CD pipelines should not create a down time for pipelines. That mean that we should have ways of "feature toggle/flag" to enable/disable certain functionality in the pipeline.
15. **Dont Repeat Yourself**: Focus on re-usable scripts and functions. Keep one source of truth for each functionality. 

## Phase 1: Foundation & Tooling (Day 1)

**Objective**: Establish the strict directory structure, minimal toolchain, and configuration hierarchy.

1.  **Strict Directory Restructuring (`scripts/`)**
    *   **Principle**: "Only three sub-folders: ci, lib, setup".
    *   **Action**: Consolidate the 14+ folders from PoC into:
        *   `scripts/lib/`: Shared libraries (e-bash), helpers, common logic.
        *   `scripts/setup/`: Environment bootstrapping, tools checks, git hooks installation.
        *   `scripts/ci/`: The engine. Sub-organized by phase (`build`, `test`, `release`, `deploy`, `secrets`, `profile`).

2.  **Configuration Hierarchy Design**
    *   **Goal**: Support overrides at 4 levels using a strict naming convention.
    *   **Definition**:
        *   **Level 0 (Global)**: `CI_GLOBAL_*` (e.g., `CI_GLOBAL_DRY_RUN`) - Affects all pipelines.
        *   **Level 1 (Pipeline)**: `CI_PIPELINE_*` (e.g., release, testing) - Context for the entire flow.
        *   **Level 2 (Step)**: `CI_STEP_*` (e.g., build, lint) - Specific stage overrides.
        *   **Level 3 (Script)**: `CI_SCRIPT_*` (Individual script context) - Granular control.
    *   **Action**: Implement strict naming convention and enforce it usage in the project.
    *   **Configuration**: Level 3 overrides the values of lower levels. That will allow to have tests when we exclude all steps except the specific one.

3.  **Minimalist Toolchain (`mise.toml`)**
    *   **Principle**: "Keep root clean".
    *   **Action**: Define ONLY essential tools for local environment bootstrapping (`bun`, `sops`, `age`, `lefthook`).
    *   **Refinement**: Move complex task definitions into `scripts/setup/tasks/` or keep them as direct script calls.
    *   **Configuration Split**: Use `.config/mise/conf.d/*.toml` for organizing tasks and settings to keep root `mise.toml` clean.
    *   **Verification**: Ensure `mise` is primarily for local dev; CI agents can run scripts directly (`bash scripts/ci/build/ci-10-compile.sh`).

4.  **Traceability & Metrics Foundation**
    *   **Action**: Integrate `e-bash` logger in `scripts/lib/_logger.sh`.
    *   **Metrics**: Create a placeholder interface for future implementation (noop for now with `FIXME` keyword in comments).

5.  **Multi-Level Quality Gates**
    *   **Goal**: Prevent "human/AI mistakes" without disrupting flow.
    *   **Layer 1 (Local - Git Hooks)**: Deploy `.lefthook.yml` to enforce formatting, linting, and secret scanning and commit message checks before commit using `lefthook`.
    *   **Layer 2 (Local - Pre-Push)**: Prevent pushing tags or branches that violate policy.
    *   **Layer 3 (CI - Validation)**: Strict PR checks via CI pipeline steps.
    *   **Action**: Support validations execution on several levels. Keep validation logic in `scripts/setup/hooks/` and reuse it on each level


## Phase 2: Secrets & Environment Management (Day 1-2)

Objective: Implement the secure, multi-environment configuration system.

1.  **Secrets Infrastructure**
    *   **Action**: Support secured way of injecting secrets into the pipeline.
    *   **Task**: For local development all secretes should be configured via MISE (environments files) and be encrypted using SOPS.
    *   **Task**: For CI/CD pipeline secrets should be injected via Github environment variables.
    *   **Task**: Developer should have an easy way to publish secrets to Github via local cli tools/scripts.

2.  **Environment Configuration**
    *   **Action**: Populate `environments/` with template configurations.
    *   **Files**: `config.yml` and `secrets.json` for `staging`, `production`.
    *   **Source**: `versions/002-ci-pipeline-update/environments/`.

3.  **Profile Management**
    *   **Action**: Deploy `scripts/setup/profile/` scripts.
    *   **Verification**: Test `mise profile:switch staging` and `mise profile:list`.

## Phase 3: The "Dry" Script Architecture (Day 2-3)

Objective: Implement the testable, standalone CI scripts with strict execution mode support.

1.  **Script Migration**
    *   **Action**: Adapt/Copy scripts from `versions/002-ci-pipeline-update/scripts/` to their designated folders in `scripts/ci/`, `scripts/setup/`, and `scripts/lib/`.
    *   **Pattern**: Rename and standardize all CI engine scripts to follow the `ci-NN-name.sh` convention (e.g., `ci-10-compile.sh`).
    *   **Key Scripts**:
        *   `ci/build/`: Compile, lint, scan.
        *   `ci/test/`: Unit, integration, E2E.
        *   `ci/release/`: Versioning, publishing, tagging.
        *   `ci/deployment/`: Deploy scripts per environment.

2.  **Strict Execution Modes**
    *   **Requirement**: "All pipeline scripts must support these modes or gracefully reroute/fail with clear logs."
    *   **Modes**:
        *   `EXEC` (Default): Normal execution.
        *   `OK`: Do nothing, return success (noop).
        *   `DRY`: Do nothing, print intended commands for validation (via `e-bash _dryrun`), return success.
        *   `ERROR`: Do nothing, return defined error code.
        *   `SKIP`: Disable step (can also be handled via YAML conditions).
        *   `TIMEOUT`: Fail script after N seconds (for concurrency testing).
        *   `TEST`: Run user-provided mock script (for A/B testing/workarounds). It's a mode that activated when detected existing filepath that provided as `CI_SCRIPT_MODE_{script_name}={file_path}`
    *   **Configuration**: Modes are controlled via global env variables defined in Phase 1 (e.g., `CI_SCRIPT_MODE_{script_name}=DRY`).
    *   **Project Setup**: By default all pipeline in ci-excellence should run in `DRY` mode, that is an override of `EXEC` mode via github actions environment variables (Level 0).

3.  **Testability Verification**
    *   **Action**: Verify that `CI_SCRIPT_MODE_{script_name}` (and other hierarchy levels) correctly triggers these modes.
    *   **Test**: Run `CI_SCRIPT_MODE_ci_10_compile=DRY ./scripts/ci/build/ci-10-compile.sh`.
    *   **Test**: Run TEST mode as: `CI_SCRIPT_MODE_ci_10_compile=./mock.sh ./scripts/ci/build/ci-10-compile.sh`.

4.  **Injection & Customization Hooks**
    *   **Principle**: "Scripts support injection points for customization without modifying core logic."
    *   **Hook Moments**: `begin`, `end`, `decide[0-9]`, `rollback`.
    *   **Decision Hooks**: `decide[Y]` (where Y is 0-9) are special; they MUST echo a choice value to STDOUT (e.g., `True`, `False`, `Skip`). Limited to 9 points to prevent complexity.
    *   **Discovery**: Automatic execution of all alphabetic-sorted files in the customization directory.
    *   **Location Pattern**: `{CWD}/ci/{script_relative_path}/{hook}_{NN}_{purpose}.sh`.
        *   Example Standard: `ci/build/ci-10-compile.sh/begin_10_checking-changes.sh`.
        *   Example Decide: `ci/build/ci-10-compile.sh/decide0_10_should-skip.sh` (echoes "True/False").
    *   **Use Case**: Monorepo packages injecting specific behavior (e.g., skip compilation for specific package if unchanged, install additional tools, configure tools, etc).
    *   **Limitations**: hooks are not participate in caching, unless they store files in a pre-defined directory (e.g., `.cache/`). That means that tools installation is not the best place for hooks.
    *   **Documentation**: All available hooks for a script must be explicitly documented in the script's help/metadata.

## Phase 4: CI/CD Workflows (Day 3-4)

Objective: Replace/Upgrade GitHub Actions workflows to use the new architecture, categorized by function.

**Reference**: `docs/images/state-diagram-workflows.svg`

1.  **Major Pipelines (Core Lifecycle)**
    *   **Scope**: Standard delivery flow.
    *   **Workflows**:
        *   `pre-release.yml`: PR validation (Build, Test, Lint, Canary).
        *   `release.yml`: Release orchestration (Semantic Versioning, Publishing, Github Pre-Release or Release creation).
        *   `post-release.yml`: Synchronization (Repo sync, Changelog updates, Stability tag assignment).
        *   `deploy.yml`: Environment deployment (Staging/Production) with concurrency control (Deploy, Rollback, Observations Collector).
        *   `maintenance.yml`: Cron-based cleanup and health checks (Cache cleanup, Registry cleanup, Deprecate, Delete Old Versions, etc.).

2.  **Helper Pipelines (Support)**
    *   **Scope**: Operational support and self-correction.
    *   **Workflows**:
        *   `ops.yml`: Operations Dashboard backend (triggers manual jobs).
        *   `ci-web-ui.yml`: (Optional) Static site generator for the `gh-pages` dashboard.
        *   `self-healing.yml`: Automated fixers (lint/format) for PRs.
        *   `dependencies.yml`: (Optional) Dependency bot integration.
        *   `cache-warmup.yml`: (Optional) GitHub cache optimization.

3.  **Meta Pipelines (Self-Distribution)**
    *   **Scope**: For the `ci-excellence` template project itself (Not distributed to consumers).
    *   **Workflows**:
        *   `meta-{purpose}.yml`: Packages `ci-excellence` as a distributeable archive/template. purpose - `distribution`. We may define additional purposes in the future.

4.  **Workflow Validation**
    *   **Action**: Run `mise run validate-workflows` to check syntax.
    *   **Local Test**: Use `act` (via `mise run test-local-ci`) to simulate a workflow run.
    *   **Setup**: MISE shiould be used as an orchestrator for different scripts running.

## Phase 5: Documentation & Quality Gates (Day 5)

Objective: Finalize documentation, enforce coding standards, and ensure knowledge transfer.

1.  **Code Standardization (Headers & Comments)**
    *   **Requirement**: "Every script/file must have a Copyright and Purpose definition at the top."
    *   **Action**: Add standard headers to all `scripts/` and `.github/workflows/` files.
    *   **Enforcement**: Use `e-bash` git hooks (`pre-commit-copyright` & `pre-commit-copyright-last-revisit`) configured in `.config/mise/conf.d/hooks.toml`.
    *   **Script Meta**: Documentation within scripts must match the `ci-NN-name.sh -h` output, detailing:
        *   Expected Global Environment Variables.
        *   Side Effects (files created, services called).
        *   Generated Reports (format, location).

2.  **Documentation Structure (`docs/`)**
    *   **README.md**: Keeps strictly to Project Overview, Purpose, and High-Level Integration Steps.
    *   **Pipelines Documentation**:
        *   Create `docs/PIPELINES.md` linking to individual markdown files for each major pipeline if complex, or distinct sections.
        *   **Requirement**: Each pipeline must have its own architecture diagram (Mermaid/SVG) in `docs/architecture/`.
    *   **Credentials Guide**: Create `docs/CREDENTIALS.md` detailing required accounts, token scopes, and how developers obtain/rotate them (Security First).
    *   **General Docs**: All other guides (FAQ, Customization) remain in `docs/`.

3.  **Git Hooks & Quality Gates**
    *   **Action**: strict enforcement via `mise run install-hooks`.
    *   **Checks**:
        *   Commit Message: Conventional Commits.
        *   Linting: ShellCheck (scripts), Action-Validator (workflows).
        *   Security: Gitleaks/Trufflehog on every commit.

4.  **Final Cleanup**
    *   **Action**: Remove `versions/` directory once migration is complete and verified.
    *   **Action**: Remove legacy scripts/configs not used by the new system.

## Risks & Mitigation & Architecture Gaps

*   **Risk**: Disruption to current deployments.
    *   **Mitigation**: The new workflows use specific tag triggers. Existing workflows (if triggered by push to main) might conflict.
    *   **Plan**: Disable old workflows or ensure triggers don't overlap during transition.
*   **Risk**: Missing secrets in new environment.
    *   **Mitigation**: `scripts/secrets/inject-gh-secret.sh` can help migrate secrets to GitHub.
*   **Risk**: Local environment differences.
    *   **Mitigation**: Strict use of `mise` ensures tool version consistency.
*   **Gap: Observability**: How to handle detailed metrics (FAQ #245+)?
    *   **Solution**: "Easy via hooks." CI scripts output structured logs to STDOUT; external agents (DataDog, Honeycomb) or hooks scrape this output. We provide the extraction patterns.
*   **Gap: Blue/Green Deployment**: How to handle traffic shifting (FAQ #177)?
    *   **Solution**: "Provided by Hosting/Integrator." The `deploy.yml` pipeline uses `Observations Collector` hooks. The actual traffic swap logic is delegated to the specific cloud provider (AWS/Vercel) via these hooks. We provide a placeholder sample.
*   **Gap: Cross-Repo Workflows**: How to trigger external pipelines (FAQ #347)?
    *   **Solution**: "Use Hooks." Custom hooks (`end`, `post-release`) call external REST APIs or CLI tools to trigger remote workflows.
*   **Gap: Build Graph/Circular Deps**: How to solve complex monorepo graphs (FAQ #145)?
    *   **Solution**: "Use robust tools." We rely on `turborepo`, `nx`, or `lerna` to handle graph resolution. Our scripts delegate to these tools.
*   **Gap: Cost Allocation**: How to track costs per team (FAQ #325)?
    *   **Solution**: "Self-Hosted Services." Granular cost tracking is best resolved by using self-hosted GitHub Runners where infrastructure tagging can be applied.

## Next Steps

1.  Approve this plan.
2.  Begin Phase 1 execution.
