# Gap Analysis: Documentation, Structure, and Implementation

> This document identifies areas where CI Excellence documentation is unclear, incomplete, or where the current solution makes certain goals hard to achieve. Each gap includes a severity assessment and recommendation.

## Legend

- **Severity:** Critical (blocks users) | High (causes confusion) | Medium (missing convenience) | Low (nice to have)
- **Type:** Documentation (docs missing/unclear) | Structure (code organization) | Implementation (feature gap)

---

## 0. E-Bash Library Capabilities Under-Leveraged in Documentation

**Severity:** High | **Type:** Documentation | **Status:** Partially addressed

The e-bash library (`scripts/lib/`) provides a rich set of modules that are used internally by CI scripts but were not prominently referenced in the FAQ answer documents. Modules include: `_semver.sh` (full SemVer 2.0.0), `_dryrun.sh` (three-mode execution), `_dependencies.sh` (tool verification with caching), `_traps.sh` (enhanced signal handling), `_commons.sh` (timing, env resolution, coalescing), `_arguments.sh` (declarative CLI parser), `_logger.sh` (domain-specific logging), and `_hooks.sh` (extension system). Several FAQ answers previously recommended external tools (e.g., `conventional-changelog` for version arithmetic, manual semver comparison scripts) when e-bash already provides the functionality.

**Progress:** Answer documents have been updated to reference e-bash modules where they replace or complement external tool recommendations. Key updates include: `_semver.sh` for version comparison and downgrade prevention, `_dryrun.sh` for rollback and dry-run operations, `_dependencies.sh` for tool verification, `_logger.sh` and `DEBUG` variable for debugging, `_commons.sh` timing functions for profiling, `_arguments.sh` for custom script argument parsing, and a comprehensive module inventory in the platform configuration answers.

**Additionally:** The e-bash upstream repository provides `bin/` scripts that are directly relevant but not included in the CI Excellence `scripts/lib/` subtree:
- `git.conventional-commits.sh` -- Conventional commit parsing (`conventional:parse`, `conventional:is_valid_commit`, `conventional:is_version_commit`)
- `git.semantic-version.sh` -- Semantic version calculator from commit history
- `git.verify-all-commits.sh` -- Commit compliance verification with `--patch` fix mode

These scripts use the same e-bash library modules already in `scripts/lib/` and should be pulled into CI Excellence to close the changelog generation gap (see Gap #9).

**Remaining work:** A dedicated `docs/E-BASH.md` reference guide documenting all available modules (including `bin/` scripts), their functions, and usage examples would help users discover and adopt these capabilities.

---

## 1. Hooks System Is Under-Documented

**Severity:** Critical | **Type:** Documentation | **Status:** Partially addressed

The e-bash hooks system (`scripts/lib/_hooks.sh`) is a core extensibility mechanism but has minimal documentation. Users were previously told to "customize stubs" but the hooks system (drop scripts in `ci-cd/{step_name}/` directories) was barely mentioned outside of `_ci-common.sh` comments.

**Progress:** All answer documents (`01-release-management.md`, `02-post-release-verification.md`, `03-maintenance-operations.md`, `05-developer-loop.md`, `07-environments-deployments.md`, `08-platform-configuration.md`) now include an **Extension Model** callout near the top explaining the hooks system, and individual answers have been updated to recommend creating hook scripts in `ci-cd/{step_name}/` directories rather than editing stubs directly. The pattern of `begin-*.sh` / `end-*.sh` hooks, alphabetical execution order, and `contract:env:NAME=VALUE` communication protocol are referenced throughout.

**Remaining work:** A dedicated `docs/HOOKS.md` guide is still needed with: comprehensive hook discovery mechanics, the full `contract:env:NAME=VALUE` communication protocol, middleware execution details, a worked end-to-end example, and a reference table mapping each CI step to its hooks directory.

**Affected FAQ areas:** All customization questions, Platform and Configuration, Monorepo

**Recommendation:** Create a dedicated `docs/HOOKS.md` with the full hooks reference. The answer documents now bridge the gap by pointing users toward the correct extension model, but the authoritative technical reference is still missing.

---

## 2. Stubs vs. Real Implementations Not Clearly Identified

**Severity:** High | **Type:** Documentation

Of 62 CI scripts, only 30 are real implementations. The remaining 26 are stubs with commented examples and 6 are validation-only. There is no documentation that tells users which scripts need customization and which work out of the box. Users discover this only by reading each script.

**Affected FAQ areas:** Every section assumes users know what's implemented

**Recommendation:** Add a "Customization Required" table to `docs/CUSTOMIZATION.md` or `docs/ARCHITECTURE.md` showing each script's implementation status (Real / Stub / Validation). Mark stubs clearly in their file headers.

---

## 3. ENABLE_\* Flags Have No Single Reference

**Severity:** High | **Type:** Documentation + Structure

Flags are scattered across 6 workflow files and `config/.env.template`. There's no single authoritative list showing: flag name, which workflow uses it, what job it controls, and default value. Users must grep across files.

**Affected FAQ areas:** Release Management (Feature Flags), Developer Loop, Platform Configuration

**Recommendation:** Create a `docs/FEATURE-FLAGS.md` reference or add a comprehensive table to `docs/WORKFLOWS.md`. The `config/.env.template` partially serves this purpose but lacks workflow mapping.

---

## 4. Monorepo Is Not a First-Class Concern

**Severity:** High | **Type:** Implementation

CI Excellence operates at repository root level. All scripts assume a single build artifact, single version, and single publish target. The `[{path}/]v{semver}` tag convention is the intended monorepo tagging pattern, and there is partial support:

- The release workflow trigger (`push: tags: '**/v*'`) correctly matches path-prefixed tags like `packages/core/v1.2.0`.
- `ci-09-parse-tag.sh` extracts the semver via `VERSION="${TAG##*v}"`, which strips any path prefix correctly. **However**, it does not output the path component, so downstream jobs cannot identify which package was released.
- `ci-10-determine-version.sh` uses `git describe --tags --match "v*"` which only finds root-level tags. It would need `--match "${path}v*"` or `--match "**/v*"` to discover path-prefixed tags like `packages/core/v1.2.0`.

**Why it's hard:** Beyond the tag parsing gaps, the spaced numbering system and hooks could theoretically support per-package logic, but there's no change detection, dependency graph, or per-package versioning infrastructure. Every downstream script would need a `CI_PACKAGE` parameter.

**Affected FAQ areas:** Monorepo (all 22 questions), parts of Release Management

**Recommendation:** Either document that CI Excellence is single-package and recommend pairing with Turborepo/Nx/Changesets, or create a `monorepo/` extension module. As a minimal step, update `ci-09-parse-tag.sh` to output a `CI_PACKAGE_PATH` variable and update `ci-10-determine-version.sh` to accept a path-aware tag match pattern.

---

## 5. Deployment Scripts Are Empty Stubs

**Severity:** High | **Type:** Implementation

The Ops workflow (`ops.yml`) supports deploy-staging and deploy-production actions, but `ci-30-deploy.sh` and `ci-20-promote-release.sh` are stubs with no example implementations. Unlike build/test stubs which have commented examples for multiple languages, deployment stubs lack practical patterns.

**Why it's hard:** Deployment is inherently infrastructure-specific. However, the lack of even basic patterns (e.g., kubectl apply, AWS ECS update, Helm upgrade) means users start from zero.

**Affected FAQ areas:** Environments and Deployments (all 19 questions)

**Recommendation:** Add deployment examples similar to how `docs/CUSTOMIZATION.md` provides build examples for Node/Python/Go/Rust. Cover: Docker Compose, Kubernetes, AWS ECS, serverless.

---

## 6. No Concurrency Controls in Any Workflow

**Severity:** Medium | **Type:** Implementation

None of the 6 workflows define `concurrency` groups. Multiple pushes to the same branch can trigger parallel runs that waste resources or cause conflicts (especially in release and maintenance workflows).

**Affected FAQ areas:** Advanced Patterns (Cost Optimization), Developer Loop (Performance)

**Recommendation:** Add `concurrency` settings to each workflow. For example: `concurrency: { group: "${{ github.workflow }}-${{ github.ref }}", cancel-in-progress: true }` for pre-release.

---

## 7. No Path Filters on Workflow Triggers

**Severity:** Medium | **Type:** Implementation

The pre-release and auto-fix workflows trigger on all pushes to matching branches regardless of which files changed. This wastes CI minutes when only docs or config files change.

**Affected FAQ areas:** Developer Loop (skip CI, changed files), Cost Optimization

**Recommendation:** Add `paths` / `paths-ignore` filters to workflow triggers. At minimum, ignore `docs/**`, `*.md`, `LICENSE`.

---

## 8. No GitHub Environments Integration

**Severity:** Medium | **Type:** Implementation

The `environments/` directory exists with staging/production layouts, and the ops workflow supports deploy actions, but no workflow references GitHub Environments. This means no deployment protection rules, required reviewers, or environment-specific secrets.

**Affected FAQ areas:** Environments and Deployments, Security (approvals), Team Collaboration

**Recommendation:** Add `environment:` references to ops.yml deploy jobs and document the GitHub Environments setup.

---

## 9. Changelog and Release Notes Generation Are Not Wired In

**Severity:** Medium | **Type:** Integration (not implementation)

`ci-20-generate-changelog.sh` is a stub with no default behavior. `ci-25-generate-release-notes.sh` generates only a template with placeholder content. Despite enforcing conventional commits (which enable automated changelogs), the existing tools are not wired into the CI pipeline.

**What already exists in e-bash:** The upstream e-bash library provides all the building blocks:
- [`git.conventional-commits.sh`](https://github.com/OleksandrKucherenko/e-bash/blob/master/bin/git.conventional-commits.sh) -- Parses conventional commits (`conventional:parse`), validates them (`conventional:is_valid_commit`), detects version-bump commits (`conventional:is_version_commit`), and can recompose messages
- [`git.semantic-version.sh`](https://github.com/OleksandrKucherenko/e-bash/blob/master/bin/git.semantic-version.sh) -- Full semantic version calculator that walks commit history, classifies each commit, and computes the next version
- [`git.verify-all-commits.sh`](https://github.com/OleksandrKucherenko/e-bash/blob/master/bin/git.verify-all-commits.sh) -- Verifies all commits for conventional commit compliance (with `--patch` mode to fix them interactively)
- `_semver.sh` -- Version arithmetic (parsing, comparison, constraint checking, incrementing)

**The gap is integration, not implementation.** These `bin/` scripts live in the upstream e-bash repository but are not included in the CI Excellence `scripts/lib/` subtree (only the `.scripts/` modules are pulled in). They need to be:
1. Added to CI Excellence (e.g., in a `scripts/bin/` directory or via the e-bash subtree)
2. Wired into `ci-20-generate-changelog.sh` and `ci-25-generate-release-notes.sh` via hooks

**Affected FAQ areas:** Release Management, Post-Release (changelog between releases)

**Recommendation:** Pull the e-bash `bin/` scripts (`git.conventional-commits.sh`, `git.semantic-version.sh`, `git.verify-all-commits.sh`) into the CI Excellence repo and wire them into the changelog/release-notes stubs via hook scripts. This eliminates the need for external tools like `git-cliff` or `conventional-changelog`.

---

## 10. No Observability or Metrics Infrastructure

**Severity:** Medium | **Type:** Implementation

The framework provides colored logging and GITHUB_STEP_SUMMARY reports but no integration with APM, distributed tracing, or metrics platforms. This is an entire FAQ section (60+ questions) with no built-in answers.

**Affected FAQ areas:** Observability and Performance Analysis (all questions)

**Recommendation:** This is largely out of scope for a CI framework. Document clearly that observability integration is a customization point and provide one worked example (e.g., Datadog CI Visibility or GitHub Actions OpenTelemetry).

---

## 11. Draft PR / WIP Detection Not Implemented

**Severity:** Low | **Type:** Implementation

Pre-release workflow triggers on all PRs including drafts. There's no condition to skip draft PRs, which wastes CI resources during early development.

**Affected FAQ areas:** Developer Loop (skip CI for WIP/draft PRs)

**Recommendation:** Add `if: github.event.pull_request.draft == false` condition or document the `[skip ci]` workaround.

---

## 12. No Caching Strategy in Workflows

**Severity:** Medium | **Type:** Implementation

No workflow uses `actions/cache` for dependencies, build outputs, or tool installations. Every run installs all mise tools and project dependencies from scratch.

**Affected FAQ areas:** Developer Loop (Performance), Advanced Patterns (Cost Optimization)

**Recommendation:** Add caching for mise tool installations and document cache patterns for common stacks in `docs/CUSTOMIZATION.md`.

---

## 13. Secret Rotation Lacks Automation

**Severity:** Low | **Type:** Implementation + Documentation

Secret management (SOPS + age) is well-documented for initial setup but there's no automation for rotation, revocation, or key migration. The only guidance is manual re-encryption.

**Affected FAQ areas:** Security and Compliance, Platform Configuration (credentials)

**Recommendation:** Document a rotation runbook and consider adding a `mise run rotate-secrets` task.

---

## 14. Pre-Release Type Choices Are Limited to alpha/beta/rc

**Severity:** Medium | **Type:** Implementation

The `pre-release-type` input in `.github/workflows/release.yml` only offers `alpha`, `beta`, and `rc` as choices. However, the underlying version calculation in `ci-10-determine-version.sh` correctly handles arbitrary pre-release type strings. Common stages like `hotfix`, `canary`, and `nightly` cannot be selected from the workflow UI without first editing the choices list.

This is a notable gap because the `[{path}/]v{semver}` tag strategy relies on pre-release stages for hotfix releases (`v1.0.0-hotfix.1`) rather than branch-based tagging. Without `hotfix` in the choices list, users must either manually create tags or edit `release.yml` before they can use the workflow-driven hotfix flow.

**Affected FAQ areas:** Release Management (hotfix releases, canary/pre-release builds), Environments and Deployments (pre-release channels)

**Recommendation:** Add `hotfix`, `canary`, and `nightly` to the `pre-release-type` choices in `release.yml`. The version calculation logic already supports them -- only the workflow input constraint needs updating.

---

## Summary Matrix

| # | Gap | Severity | Type | Effort |
|---|-----|----------|------|--------|
| 0 | E-bash library under-leveraged in docs | High (partially addressed) | Documentation | Low |
| 1 | Hooks system under-documented | Critical (partially addressed) | Documentation | Low |
| 2 | Stub/real status not identified | High | Documentation | Low |
| 3 | No single ENABLE_* reference | High | Documentation | Low |
| 4 | Monorepo not first-class (partial tag support) | High | Implementation | High |
| 5 | Deployment stubs empty | High | Implementation | Medium |
| 6 | No concurrency controls | Medium | Implementation | Low |
| 7 | No path filters | Medium | Implementation | Low |
| 8 | No GitHub Environments | Medium | Implementation | Medium |
| 9 | Changelog generation weak | Medium | Implementation | Medium |
| 10 | No observability infra | Medium | Implementation | High |
| 11 | No draft PR detection | Low | Implementation | Low |
| 12 | No caching strategy | Medium | Implementation | Medium |
| 13 | Secret rotation manual | Low | Docs + Impl | Medium |
| 14 | Pre-release type limited to alpha/beta/rc | Medium | Implementation | Low |

**Priority recommendation:** Address items 0-3 first (all low-effort documentation fixes), then 6-7 and 14 (low-effort workflow improvements), then 5 and 9 (medium-effort feature completions). Item 0 has been partially addressed by updating answer documents to reference e-bash modules.
