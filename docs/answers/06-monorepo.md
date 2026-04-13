# Monorepo-Specific Questions

> **Honest disclaimer:** CI Excellence is designed as a **single-project framework**. It does not have built-in monorepo support. The guidance below describes workarounds using the stub system, GitHub Actions features, and external tools. Adopting CI Excellence in a monorepo requires significant customization effort.

The framework has a few small touches that hint at monorepo awareness -- the release workflow triggers on tags matching `**/v*` (e.g. `packages/app/v1.0.0`), and the spaced numbering system (10, 20, 30...) leaves room for inserting per-package steps -- but no scripts implement per-package logic today. All scripts operate at repository root level.

---

## What should I do if my monorepo sub-project needs custom build steps?

CI Excellence scripts are stubs. You can edit any stub to add package-aware logic. The most practical approach:

1. **Wrapper script pattern.** Edit `scripts/ci/build/ci-10-compile.sh` to detect which packages changed, then loop over them and call package-specific build commands.

2. **Insert per-package scripts.** Use the spaced numbering to add scripts like `ci-11-compile-pkg-core.sh`, `ci-12-compile-pkg-api.sh`, etc. Then reference them from the workflow YAML.

3. **Delegate to a monorepo tool.** Replace the compile stub body with a call to an external build orchestrator:

```bash
#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# Let Turborepo handle per-package builds
npx turbo run build
```

**External tools to consider:** [Turborepo](https://turbo.build/repo), [Nx](https://nx.dev/), [Lerna](https://lerna.js.org/), [moon](https://moonrepo.dev/).

The key limitation is that the workflow YAML defines a single linear job graph (setup -> compile -> lint -> test -> bundle). If different packages need fundamentally different job structures, you will need to duplicate or rewrite workflow files.

---

## How do I run CI only for changed packages in a monorepo?

CI Excellence does not detect changed packages. You have two main options:

**Option A: GitHub Actions `paths` filters.** Add path filters to the workflow trigger so it only fires when relevant files change:

```yaml
on:
  pull_request:
    paths:
      - 'packages/api/**'
      - 'shared/**'
```

This is coarse-grained -- the entire workflow runs or does not run. You cannot skip individual jobs within a workflow this way.

**Option B: Change detection inside scripts.** Add a change detection step early in the workflow and use its output to skip later steps:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Detect changed packages compared to the base branch
CHANGED=$(git diff --name-only origin/main...HEAD | cut -d/ -f1-2 | sort -u)

echo "Changed paths:"
echo "$CHANGED"

# Export as output for downstream steps
echo "changed-packages=$CHANGED" >> "$GITHUB_OUTPUT"
```

**Option C: Use an external change detection tool.** Tools like [Nx affected](https://nx.dev/concepts/affected), [Turborepo filtering](https://turbo.build/repo/docs/crafting-your-repository/running-tasks#using-filters), or [changesets](https://github.com/changesets/changesets) provide sophisticated change detection with dependency-graph awareness.

You would insert a detection script (e.g. `ci-05-detect-changes.sh`) before the build step and pass its output to subsequent scripts via `GITHUB_OUTPUT`.

---

## How do I handle dependencies between packages in the same monorepo?

CI Excellence has no concept of an internal dependency graph. It runs scripts sequentially at root level.

**Workaround:** Delegate dependency resolution to your package manager or build tool:

- **npm/pnpm/yarn workspaces** handle install-time dependency linking automatically when you run `npm install` at the root.
- **Turborepo / Nx** understand the dependency graph and build packages in topological order.
- **Lerna** can run commands respecting the dependency graph with `lerna run build --sort`.

Edit `scripts/ci/setup/ci-20-install-dependencies.sh` to install workspace dependencies, and `scripts/ci/build/ci-10-compile.sh` to use a graph-aware build command:

```bash
#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

echo:Build "Building packages in dependency order..."
npx turbo run build
```

If you need CI Excellence to orchestrate dependencies itself, you would need to write custom shell logic to parse package.json workspace references and build in order. This is not recommended -- use an existing tool.

---

## How do I version packages independently vs. unified versioning?

CI Excellence supports a single version determined at repository root level. The release pipeline calls `scripts/ci/release/ci-10-determine-version.sh` and `ci-12-set-version-outputs.sh` to compute one version number that flows through the entire pipeline.

**For unified versioning (all packages share one version):** This works with CI Excellence as-is. Edit the version determination script to bump one version and apply it everywhere.

**For independent versioning:** This requires significant rework. Two practical approaches:

1. **Use Changesets.** [Changesets](https://github.com/changesets/changesets) is designed for independent versioning in monorepos. Replace the release scripts with changesets commands:

```bash
#!/usr/bin/env bash
set -euo pipefail

# In ci-10-determine-version.sh
npx changeset version
```

2. **Per-package release workflows.** Duplicate `release.yml` for each package (e.g. `release-core.yml`, `release-api.yml`) with different path filters and version sources. This multiplies maintenance burden proportionally to package count.

The `**/v*` tag pattern in `release.yml` suggests awareness of per-package tags like `packages/core/v1.2.0`, but the downstream scripts (`ci-09-parse-tag.sh`, etc.) do not extract a package name from the tag -- they only extract the version number. You would need to modify the parse script and propagate a `CI_PACKAGE` variable through the pipeline.

---

## How do I publish only changed packages to NPM?

The release pipeline publishes a single artifact via `scripts/ci/release/ci-66-publish-npm-release.sh`. It does not know about multiple packages.

**Workaround with Changesets:**

```bash
#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# Changesets only publishes packages with version bumps
npx changeset publish
```

**Workaround with Lerna:**

```bash
#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# Lerna publishes only changed packages
npx lerna publish from-package --yes
```

**Workaround with pnpm:**

```bash
#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# Publish all packages that have versions not yet on the registry
pnpm -r publish --no-git-checks
```

In all cases you replace the body of the NPM publish stub with the monorepo-aware command. The `ENABLE_NPM_PUBLISH` feature flag and the surrounding workflow logic still work fine -- you are only changing what the script does internally.

---

## How do I run tests for affected packages based on file changes?

CI Excellence runs all tests unconditionally at the root level. To scope tests to affected packages:

**Option A: Use a build tool's affected command:**

```bash
#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# In ci-10-unit-tests.sh
echo:Test "Running tests for affected packages..."
npx nx affected --target=test --base=origin/main
# or
npx turbo run test --filter='...[origin/main]'
```

**Option B: Manual change detection with test scoping:**

```bash
#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

CHANGED_PACKAGES=$(git diff --name-only origin/main...HEAD \
  | grep '^packages/' \
  | cut -d/ -f2 \
  | sort -u)

for pkg in $CHANGED_PACKAGES; do
  echo:Test "Testing packages/$pkg..."
  cd "packages/$pkg" && npm test && cd -
done
```

Both approaches replace the stub body. The workflow structure (the test job, artifact uploads, reporting) remains unchanged.

---

## How do I handle shared configuration across monorepo packages?

This is outside CI Excellence's scope -- it is a project structure concern, not a CI concern. However, CI Excellence stubs can be customized to support common patterns:

- **Shared tsconfig / eslint / prettier configs:** Place shared configs at the repo root or in a `packages/config-*` package. Reference them via `extends` in each package. The lint stub (`ci-20-lint.sh`) works fine running a root-level lint command that inherits shared config.

- **Shared CI environment variables:** GitHub Actions variables and secrets are already repository-wide. Use them directly in scripts.

- **Shared build configuration:** Put shared build logic in `scripts/lib/` (CI Excellence already has this directory). Source it from package-specific build scripts.

- **Per-package overrides:** Use the spaced numbering to insert package-specific steps that override or extend the shared behavior. For example, `ci-21-lint-override-api.sh` could apply stricter rules to the API package.

---

## How do I build packages in the correct dependency order?

CI Excellence does not model dependency graphs. The `ci-10-compile.sh` stub runs one command.

**Solution: Delegate to a graph-aware tool.** Replace the compile stub:

```bash
#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

echo:Build "Building in topological order..."

# Turborepo resolves the dependency graph automatically
npx turbo run build

# Or with Nx
npx nx run-many --target=build --all

# Or with Lerna
npx lerna run build --sort
```

If you cannot use an external tool, you can write a custom script that reads `package.json` workspace references and builds in order, but this is error-prone and hard to maintain. The build tools listed above exist precisely to solve this problem.

---

## How do I parallelize builds for independent packages?

The CI Excellence workflow YAML defines jobs that can run in parallel (e.g. `compile` and `lint` run concurrently). But within a single job, steps run sequentially.

**Option A: Let the build tool parallelize.** Turborepo and Nx both parallelize independent packages within a single command:

```bash
# Turborepo uses all available cores by default
npx turbo run build

# Nx parallelizes with --parallel
npx nx run-many --target=build --all --parallel=4
```

**Option B: GitHub Actions matrix strategy.** If you need true parallel runners, use a matrix to fan out across packages. This requires modifying the workflow YAML:

```yaml
jobs:
  detect-packages:
    runs-on: ubuntu-latest
    outputs:
      packages: ${{ steps.detect.outputs.packages }}
    steps:
      - uses: actions/checkout@v4
      - id: detect
        run: |
          PACKAGES=$(ls packages/ | jq -R -s -c 'split("\n")[:-1]')
          echo "packages=$PACKAGES" >> "$GITHUB_OUTPUT"

  build:
    needs: detect-packages
    strategy:
      matrix:
        package: ${{ fromJson(needs.detect-packages.outputs.packages) }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: cd packages/${{ matrix.package }} && npm run build
```

This is a significant departure from the standard CI Excellence workflow structure. You are effectively writing a new workflow at this point.

---

## How do I cache build outputs per package?

The pre-release workflow caches `node_modules`, `~/.cache`, and `.cache` with a key based on lockfile hashes. This is a repository-wide cache, not per-package.

**Option A: Use Turborepo remote caching.** Turborepo has built-in remote caching that stores per-package build outputs:

```bash
npx turbo run build --remote-only
```

Configure with a `TURBO_TOKEN` and `TURBO_TEAM` in GitHub secrets.

**Option B: Use Nx remote caching (Nx Cloud):**

```bash
npx nx run-many --target=build --all
```

Nx Cloud handles per-task caching automatically.

**Option C: Per-package GitHub Actions cache.** Add multiple cache steps keyed by package:

```yaml
- uses: actions/cache@v4
  with:
    path: packages/core/dist
    key: build-core-${{ hashFiles('packages/core/src/**') }}

- uses: actions/cache@v4
  with:
    path: packages/api/dist
    key: build-api-${{ hashFiles('packages/api/src/**') }}
```

This requires modifying workflow YAML and does not scale well beyond a handful of packages.

---

## How do I handle circular dependencies in the build graph?

Circular dependencies are a project architecture problem, not a CI problem. CI Excellence cannot help resolve them.

**General guidance:**

- Circular dependencies between packages indicate a design issue. Extract the shared code into a separate package that both depend on.
- Turborepo and Nx will error on circular dependencies, which is the correct behavior -- they force you to fix the architecture.
- If you genuinely need mutual references (rare), consider combining the packages into one or using runtime dynamic imports instead of build-time dependencies.

No CI configuration can work around a circular build dependency. Fix the dependency graph first.

---

## How do I build only what's needed for a specific deployment?

CI Excellence deploys a single artifact. The ops workflow (`ops.yml`) targets environments (staging, production) but does not filter by package.

**Workaround:** Modify the deploy script to accept a package parameter:

```bash
#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

PACKAGE="${CI_DEPLOY_PACKAGE:-all}"

if [ "$PACKAGE" = "all" ]; then
  npx turbo run build
else
  npx turbo run build --filter="$PACKAGE"
fi
```

Add a `package` input to the `ops.yml` `workflow_dispatch` configuration:

```yaml
inputs:
  package:
    description: 'Package to deploy (or "all")'
    required: false
    default: 'all'
```

Then set `CI_DEPLOY_PACKAGE: ${{ github.event.inputs.package }}` in the job's `env`.

---

## How do I run different test suites for different packages?

The test scripts (`ci-10-unit-tests.sh`, `ci-20-integration-tests.sh`, `ci-30-e2e-tests.sh`) each run a single command at the root level.

**Option A: Delegate to a monorepo tool.**

```bash
#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

echo:Test "Running unit tests across all packages..."
npx turbo run test:unit
# Each package defines its own "test:unit" script in its package.json
```

Each package can use a different test framework (Jest, Vitest, pytest, etc.) as long as it exposes a consistent script name.

**Option B: Use matrix jobs.** If different packages need different runner environments or dependencies, use a matrix strategy in the workflow YAML (see the parallelization answer above). Each matrix entry can run a different test command.

---

## How do I aggregate test coverage across all packages?

CI Excellence uploads coverage artifacts from individual test jobs but does not merge them.

**Workaround:**

1. Have each package output coverage in a common format (e.g. lcov).
2. Add a script to merge them:

```bash
#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

echo:Test "Merging coverage reports..."

# Collect all lcov files
find packages -name 'lcov.info' -exec cat {} + > coverage/merged-lcov.info

# Or use nyc/istanbul to merge
npx nyc merge coverage/ coverage/merged.json
npx nyc report --reporter=lcov --temp-dir=coverage
```

3. Insert this as `ci-15-merge-coverage.sh` (between unit tests at 10 and integration tests at 20), or add it after all test steps.

**External tools:** [Codecov](https://codecov.io/) and [Coveralls](https://coveralls.io/) can automatically merge coverage uploads from multiple jobs or packages.

---

## How do I enforce code quality standards per package vs. globally?

The lint script (`ci-20-lint.sh`) runs one command. There is no per-package configuration in CI Excellence.

**Global standards:** Run a single linter at the root. ESLint, Prettier, and similar tools support monorepo configurations with per-directory overrides (`.eslintrc` in each package directory).

**Per-package standards:** Replace the lint stub with a tool that respects per-package config:

```bash
#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

echo:Build "Running linters across all packages..."
npx turbo run lint
# Each package's "lint" script can use different rules
```

**Mixed approach:** Run global checks (formatting, secret scanning) at root level, and delegate package-specific quality checks to per-package scripts via Turborepo or Nx.

---

## How do I run integration tests that span multiple packages?

Integration tests that span packages (e.g. testing that `@myorg/api` correctly uses `@myorg/core`) are best run after all packages are built.

In CI Excellence, `ci-20-integration-tests.sh` already depends on the compile job. Edit the stub to:

```bash
#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

echo:Test "Running cross-package integration tests..."

# Build all packages first (if not already done in compile step)
npx turbo run build

# Run integration tests from a dedicated test package or root
npx turbo run test:integration

# Or run from a specific test directory
cd tests/integration && npm test
```

The key point: cross-package integration tests need all packages built and linked. Your package manager's workspace feature handles linking. The build tool handles build order.

---

## How do I handle different test frameworks in different packages?

This is transparent to CI Excellence as long as each package exposes a consistent npm script name (e.g. `test`).

```bash
#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

echo:Test "Running tests across all packages..."
npx turbo run test
```

Package A can use Jest, Package B can use Vitest, Package C can use pytest (if it is a Python package in the monorepo). Each `package.json` (or equivalent) defines its own `test` script. Turborepo or Nx calls them all.

If you do not use a build orchestrator, the test stub can loop over packages:

```bash
for pkg_dir in packages/*/; do
  if [ -f "$pkg_dir/package.json" ]; then
    echo:Test "Testing $pkg_dir..."
    (cd "$pkg_dir" && npm test)
  fi
done
```

---

## How do I coordinate releases across multiple packages?

This is the hardest monorepo problem and CI Excellence is not equipped to handle it out of the box. The release pipeline produces one version, one tag, one GitHub release, one NPM publish, and one Docker image.

**Recommended approach: Use Changesets.**

[Changesets](https://github.com/changesets/changesets) is the standard tool for coordinating multi-package releases. It tracks which packages changed, determines version bumps, generates per-package changelogs, and publishes only what changed.

Replace the release scripts:

```bash
# ci-10-determine-version.sh
npx changeset version

# ci-66-publish-npm-release.sh
npx changeset publish

# ci-20-generate-changelog.sh
# Changesets handles this during `changeset version`
```

**Alternative: Use Lerna.**

```bash
npx lerna version --conventional-commits --yes
npx lerna publish from-package --yes
```

**Alternative: Use Nx Release.**

```bash
npx nx release version
npx nx release changelog
npx nx release publish
```

In all cases, you are replacing the internals of CI Excellence scripts with monorepo-aware commands while keeping the workflow structure (jobs, conditions, feature flags) intact.

---

## How do I create a release with some packages bumped and others unchanged?

CI Excellence has no concept of partial releases. Its workflow bumps one version and publishes one set of artifacts.

**Use Changesets.** This is exactly what Changesets does:

1. Developers add changeset files during development: `npx changeset add`
2. Each changeset records which packages are affected and the bump type.
3. `npx changeset version` only bumps packages with pending changesets.
4. `npx changeset publish` only publishes packages with new versions.

Packages without changesets remain at their current version.

**Use Lerna with `--no-private`:**

```bash
npx lerna version --conventional-commits --yes
# Only packages with commits since last tag get bumped
```

---

## How do I handle breaking changes in one package affecting others?

This is a dependency management and communication problem. CI Excellence does not track inter-package compatibility.

**With Changesets:** When you add a changeset for a major (breaking) bump on package A, you can also add changesets for packages that depend on A, indicating they need a corresponding bump.

**With Nx Release:** Nx can be configured to automatically bump dependents when a dependency has a major version change.

**General guidance:**

1. Use a consistent versioning policy. If `@myorg/core` makes a breaking change, all packages that depend on it should be tested and potentially bumped.
2. Run cross-package integration tests (see above) to catch breakage.
3. Document breaking changes in package-level changelogs.
4. Consider using peer dependencies to make version requirements explicit.

---

## How do I generate changelogs per package vs. monorepo-wide?

CI Excellence generates one changelog via `scripts/ci/release/ci-20-generate-changelog.sh`.

**Per-package changelogs:**

- **Changesets** generates a `CHANGELOG.md` in each package directory automatically during `npx changeset version`.
- **Lerna** with `--conventional-commits` generates per-package changelogs.
- **Nx Release** supports per-project changelogs.

**Monorepo-wide changelog:** Keep the existing CI Excellence changelog script for a root-level summary, and add per-package changelogs via one of the tools above.

**Hybrid approach:** Generate per-package changelogs with Changesets, then aggregate them into a root changelog:

```bash
#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

echo:Release "Generating changelogs..."

# Per-package changelogs via changesets
npx changeset version

# Aggregate into root CHANGELOG
echo "# Changelog" > CHANGELOG.md
echo "" >> CHANGELOG.md
for pkg in packages/*/CHANGELOG.md; do
  pkg_name=$(basename "$(dirname "$pkg")")
  echo "## $pkg_name" >> CHANGELOG.md
  cat "$pkg" >> CHANGELOG.md
  echo "" >> CHANGELOG.md
done
```

---

## How do I tag releases in a monorepo (single tag vs. per-package tags)?

The CI Excellence version tag pattern is `[{path}/]v{semver}`, where the optional `{path}/` prefix maps to a monorepo sub-folder. This IS the intended monorepo tagging convention. Examples:

- **Root-level (single project):** `v1.0.0`, `v2.1.0-beta`
- **Per-package:** `packages/core/v1.2.0`, `libs/utils/v0.5.0`, `packages/app/v2.1.0-hotfix.1`

The release workflow trigger (`push: tags: '**/v*'`) already matches both plain and path-prefixed tags. The tag parsing script (`ci-09-parse-tag.sh`) extracts the semver portion via `VERSION="${TAG##*v}"`, which correctly strips any path prefix (e.g., `packages/core/v1.2.0` yields `1.2.0`).

**Current implementation gaps:**

1. **`ci-09-parse-tag.sh` does not output the path component.** It extracts the version but discards the package path. Downstream jobs have no way to know which package was released. To fix this, the script would need to extract and output a `CI_PACKAGE_PATH` variable (e.g., `packages/core`) alongside `CI_VERSION`.

2. **`ci-10-determine-version.sh` cannot find path-prefixed tags.** It uses `git describe --tags --match "v*"` to find the latest tag, which only matches root-level tags like `v1.2.3`. For path-prefixed tags, this would need to be changed to `--match "${path}v*"` or `--match "**/v*"` to discover tags like `packages/core/v1.2.0`.

3. **No `CI_PACKAGE` variable is propagated.** Even if the path were extracted, no downstream scripts (build, test, publish) accept a package parameter to scope their work.

These gaps mean that while the tag trigger and parse logic partially work, full monorepo release automation requires modifications to the parse and version-determination scripts plus all downstream scripts.

**To use per-package tags today (manual workaround):**

```bash
# Create a path-prefixed tag manually
git tag -a packages/core/v1.2.0 -m "Release packages/core v1.2.0"
git push origin packages/core/v1.2.0

# The release workflow triggers, ci-09-parse-tag.sh extracts version 1.2.0
# But downstream jobs won't know this is for packages/core specifically
```

**Alternative: Use Changesets or Lerna for tagging.** These tools create per-package tags in the format `@scope/package@version` and handle the coordination automatically. Trigger your release workflow on those tags instead:

```yaml
on:
  push:
    tags:
      - '@myorg/*@*'
```

---

## Hard to Implement

Monorepo support is the single largest gap in CI Excellence. Here is an honest assessment of why it is hard and what would need to change.

### Why monorepo is hard with the current design

1. **Single-artifact pipeline assumption.** Every workflow assumes one build, one test suite, one version, one publish target. Monorepos need N of each, where N is the number of packages.

2. **No dependency graph.** CI Excellence has no model of which packages depend on which. Without this, it cannot determine build order, affected packages, or cascading version bumps.

3. **Root-level scripts.** All scripts in `scripts/ci/` operate at the repository root. They do not accept a "package" parameter and do not iterate over packages. Every script would need modification.

4. **Single version flow.** The release pipeline computes one version (`CI_VERSION`) and threads it through every job. Independent versioning requires per-package version tracking, which the current `GITHUB_OUTPUT`-based plumbing does not support.

5. **Workflow YAML structure.** GitHub Actions workflows are static -- you cannot dynamically create jobs based on the number of packages (though matrix strategies help). A true monorepo CI needs dynamic job generation or a separate workflow per package.

6. **Tag parsing is partially implemented but incomplete.** The `[{path}/]v{semver}` tag pattern is the intended monorepo convention, and the release workflow trigger (`**/v*`) correctly matches path-prefixed tags. The parse script (`ci-09-parse-tag.sh`) correctly extracts the semver portion via `VERSION="${TAG##*v}"`. However, two gaps remain: (a) `ci-09-parse-tag.sh` does not output the path component, so downstream jobs cannot identify which package was released; (b) `ci-10-determine-version.sh` uses `git describe --tags --match "v*"` which only finds root-level tags, not path-prefixed tags like `packages/core/v1.2.0`.

### What would need to change for first-class support

- **New concept: package registry.** A configuration file listing packages, their paths, dependencies, and publish targets.
- **New scripts: change detection.** A script to determine which packages changed relative to a base ref.
- **Modified scripts: all of them.** Every build, test, and release script would need a `CI_PACKAGE` (or `CI_PACKAGES`) parameter.
- **Modified workflows: matrix jobs.** Workflows would need dynamic matrix strategies that fan out across changed packages.
- **New scripts: dependency graph.** Logic to determine build order and affected packages.
- **New release model.** Per-package versioning, tagging, changelog generation, and publishing.

### Recommended path forward

Rather than trying to bolt monorepo support onto CI Excellence, **use CI Excellence alongside a dedicated monorepo tool**:

| Concern | Tool | CI Excellence role |
|---|---|---|
| Build orchestration | Turborepo, Nx, moon | Scripts call the tool |
| Change detection | Nx affected, Turbo filter | Script wraps the tool |
| Version management | Changesets, Lerna, Nx Release | Scripts call the tool |
| Publishing | Changesets publish, Lerna publish | Script wraps the tool |
| Dependency graph | Turborepo, Nx | Handled externally |

CI Excellence still provides value in a monorepo for:
- Workflow structure and job orchestration
- Feature flags (`ENABLE_*` variables)
- Notification infrastructure
- Maintenance automation (cleanup, security audits)
- Environment management (staging/production)
- The stub-based progressive enhancement philosophy

But the per-package logic belongs to a monorepo-native tool, not to CI Excellence scripts.

---

## Documentation Gaps

The following areas lack documentation and would benefit from dedicated guides if monorepo support is prioritized:

- **Monorepo setup guide.** Step-by-step instructions for integrating CI Excellence with Turborepo, Nx, or Changesets. Currently users must figure this out on their own.
- **Per-package workflow examples.** Complete workflow YAML examples showing matrix strategies, per-package caching, and fan-out/fan-in job patterns for monorepos.
- **Change detection cookbook.** Recipes for detecting changed packages using git diff, Nx affected, or Turborepo filters, and wiring the output into CI Excellence scripts.
- **Independent versioning guide.** How to replace the single-version release pipeline with Changesets or Lerna, including which scripts to modify and what to put in them.
- **Per-package tag parsing.** Documentation for modifying `ci-09-parse-tag.sh` to extract package names from tags like `packages/core/v1.2.0` or `@scope/package@1.2.0`.
- **Cross-package testing patterns.** How to structure integration tests that span packages, including build order, linking, and test isolation.
- **Coverage aggregation.** How to merge coverage reports from multiple packages into a single report for tools like Codecov or Coveralls.
- **Cost allocation.** How to track CI minutes and costs per package in a monorepo (relevant for large teams with many packages).
- **Migration guide.** How to move from a multi-repo setup to a monorepo while preserving CI Excellence workflows, or how to adopt CI Excellence in an existing monorepo that already uses Nx/Turborepo.
