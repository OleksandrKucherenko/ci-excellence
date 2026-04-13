# Hooks System Reference

CI Excellence uses the e-bash hooks system to provide per-script extension points. Consuming projects customize behavior by dropping scripts into `ci-cd/{step-name}/` directories -- without modifying core CI scripts.

## e-bash Hooks Documentation

The hooks system is fully documented in the e-bash upstream repository:

- [Hooks overview](https://github.com/OleksandrKucherenko/e-bash?tab=readme-ov-file#hooks) -- README section
- [Hooks reference](https://github.com/OleksandrKucherenko/e-bash/blob/master/docs/public/hooks.md) -- full documentation
- [_hooks.sh API](https://github.com/OleksandrKucherenko/e-bash/blob/master/docs/public/lib/_hooks.md) -- module API reference
- [DeepWiki: Hooks System](https://deepwiki.com/OleksandrKucherenko/e-bash/3.7-hooks-system-(_hooks.sh)) -- community deep dive

### Demos

- [demo.hooks.sh](https://github.com/OleksandrKucherenko/e-bash/blob/master/demos/demo.hooks.sh) -- basic hook discovery and execution
- [demo.hooks-registration.sh](https://github.com/OleksandrKucherenko/e-bash/blob/master/demos/demo.hooks-registration.sh) -- function registration
- [demo.hooks-logging.sh](https://github.com/OleksandrKucherenko/e-bash/blob/master/demos/demo.hooks-logging.sh) -- hooks with logging
- [demo.ci-modes-middleware.sh](https://github.com/OleksandrKucherenko/e-bash/blob/master/demos/ci-mode/demo.ci-modes-middleware.sh) -- CI mode resolution middleware

## CI Excellence Integration

### How It Works

Every CI script sources [`_ci-common.sh`](../scripts/ci/_ci-common.sh) which:

1. Sets `HOOKS_DIR` to `ci-cd/{script-name}/` based on the calling script's filename (line 67)
2. Calls `hooks:bootstrap` to declare `begin` and `end` hooks and install an EXIT trap for end hooks
3. Registers the `_hooks:middleware:modes` middleware for contract-based communication

```bash
# From _ci-common.sh (lines 66-74):
_CI_SCRIPT_NAME="$(basename "${BASH_SOURCE[1]:-unknown}" .sh)"
export HOOKS_DIR="${HOOKS_DIR:-ci-cd/${_CI_SCRIPT_NAME}}"
hooks:bootstrap
hooks:middleware begin _hooks:middleware:modes
```

### Hook Directory Convention

Consuming projects create a `ci-cd/` directory at their project root. Each CI script has a corresponding sub-directory:

```
your-project/
  ci-cd/                              # Hook directories (you create this)
    ci-10-compile/                    # Hooks for ci-10-compile.sh
      begin_00_check-env.sh           # Runs before compilation
      begin_40_run-turbo.sh           # Custom build integration
      end_10_report.sh                # Runs after compilation
    ci-20-lint/                       # Hooks for ci-20-lint.sh
      begin_30_custom-rules.sh        # Custom lint configuration
    ci-10-unit-tests/                 # Hooks for ci-10-unit-tests.sh
      begin_00_setup-fixtures.sh      # Test fixture setup
      end_90_coverage-report.sh       # Coverage reporting
  scripts/ci/                         # CI scripts (from ci-excellence)
    build/ci-10-compile.sh
    build/ci-20-lint.sh
    test/ci-10-unit-tests.sh
```

### Hook Naming Pattern

`{hook_name}_{NN}_{purpose}.sh`

| Hook Type | Position | Purpose |
|-----------|----------|---------|
| `begin_00-09_*` | Early | Mode resolution, early setup |
| `begin_10-39_*` | Pre | Environment checks, tool setup |
| `begin_40-89_*` | Main | User integration (Turbo, custom builds) |
| `decide[0-9]_*` | Decision | Must echo a value to stdout (True/False/Skip) |
| `end_10-89_*` | Post | Cleanup, metrics, reports |

Hooks execute in **alphabetical order** within each type. Numbering controls execution sequence.

### Contract Protocol

Hook scripts communicate with the middleware by emitting directives on stdout:

```bash
# Set an environment variable for subsequent hooks and the main script
echo "contract:env:TURBO_CACHE_HIT=true"

# Signal an exit code
echo "contract:exit:0"
```

### Test Fixture Examples

Working hook examples exist in the test fixtures at [`spec/e2e/fixture/ci-cd/`](../spec/e2e/fixture/ci-cd/):

| Fixture | Purpose |
|---------|---------|
| `ci-10-compile/begin_00_check-env.sh` | Check environment before compilation |
| `ci-10-compile/end_10_report.sh` | Report after compilation |
| `ci-10-unit-tests/begin_00_setup-fixtures.sh` | Setup test fixtures |
| `ci-30-security-scan/end_10_failing-hook.sh` | Simulate a failing hook |

## Script to Hook Directory Mapping

Every `ci-NN-*.sh` script maps to a `ci-cd/ci-NN-*` directory. The table below lists all scripts grouped by domain.

### Setup

| Script | Hook Directory |
|--------|---------------|
| `setup/ci-10-install-tools.sh` | `ci-cd/ci-10-install-tools/` |
| `setup/ci-20-install-dependencies.sh` | `ci-cd/ci-20-install-dependencies/` |
| `setup/ci-30-github-actions-bot.sh` | `ci-cd/ci-30-github-actions-bot/` |

### Build

| Script | Hook Directory |
|--------|---------------|
| `build/ci-10-compile.sh` | `ci-cd/ci-10-compile/` |
| `build/ci-20-lint.sh` | `ci-cd/ci-20-lint/` |
| `build/ci-30-security-scan.sh` | `ci-cd/ci-30-security-scan/` |
| `build/ci-40-bundle.sh` | `ci-cd/ci-40-bundle/` |
| `build/ci-60-check-failures.sh` | `ci-cd/ci-60-check-failures/` |

### Test

| Script | Hook Directory |
|--------|---------------|
| `test/ci-10-unit-tests.sh` | `ci-cd/ci-10-unit-tests/` |
| `test/ci-20-integration-tests.sh` | `ci-cd/ci-20-integration-tests/` |
| `test/ci-30-e2e-tests.sh` | `ci-cd/ci-30-e2e-tests/` |
| `test/ci-40-smoke-tests.sh` | `ci-cd/ci-40-smoke-tests/` |

### Release

| Script | Hook Directory |
|--------|---------------|
| `release/ci-05-select-version.sh` | `ci-cd/ci-05-select-version/` |
| `release/ci-07-apply-stability-tag.sh` | `ci-cd/ci-07-apply-stability-tag/` |
| `release/ci-08-create-tag.sh` | `ci-cd/ci-08-create-tag/` |
| `release/ci-09-parse-tag.sh` | `ci-cd/ci-09-parse-tag/` |
| `release/ci-10-determine-version.sh` | `ci-cd/ci-10-determine-version/` |
| `release/ci-12-set-version-outputs.sh` | `ci-cd/ci-12-set-version-outputs/` |
| `release/ci-15-update-version.sh` | `ci-cd/ci-15-update-version/` |
| `release/ci-18-commit-version-changes.sh` | `ci-cd/ci-18-commit-version-changes/` |
| `release/ci-20-generate-changelog.sh` | `ci-cd/ci-20-generate-changelog/` |
| `release/ci-25-generate-release-notes.sh` | `ci-cd/ci-25-generate-release-notes/` |
| `release/ci-27-write-release-notes-output.sh` | `ci-cd/ci-27-write-release-notes-output/` |
| `release/ci-30-upload-assets.sh` | `ci-cd/ci-30-upload-assets/` |
| `release/ci-35-verify-github-release.sh` | `ci-cd/ci-35-verify-github-release/` |
| `release/ci-40-rollback-github.sh` | `ci-cd/ci-40-rollback-github/` |
| `release/ci-50-build-docs.sh` | `ci-cd/ci-50-build-docs/` |
| `release/ci-55-publish-docs.sh` | `ci-cd/ci-55-publish-docs/` |
| `release/ci-65-publish-npm.sh` | `ci-cd/ci-65-publish-npm/` |
| `release/ci-66-publish-npm-release.sh` | `ci-cd/ci-66-publish-npm-release/` |
| `release/ci-70-verify-npm-deployment.sh` | `ci-cd/ci-70-verify-npm-deployment/` |
| `release/ci-75-rollback-npm.sh` | `ci-cd/ci-75-rollback-npm/` |
| `release/ci-77-confirm-rollback.sh` | `ci-cd/ci-77-confirm-rollback/` |
| `release/ci-80-publish-docker.sh` | `ci-cd/ci-80-publish-docker/` |
| `release/ci-85-verify-docker-deployment.sh` | `ci-cd/ci-85-verify-docker-deployment/` |
| `release/ci-90-rollback-docker.sh` | `ci-cd/ci-90-rollback-docker/` |

### Maintenance

| Script | Hook Directory |
|--------|---------------|
| `maintenance/ci-10-sync-files.sh` | `ci-cd/ci-10-sync-files/` |
| `maintenance/ci-20-check-changes.sh` | `ci-cd/ci-20-check-changes/` |
| `maintenance/ci-30-cleanup-workflow-runs.sh` | `ci-cd/ci-30-cleanup-workflow-runs/` |
| `maintenance/ci-40-cleanup-artifacts.sh` | `ci-cd/ci-40-cleanup-artifacts/` |
| `maintenance/ci-50-cleanup-caches.sh` | `ci-cd/ci-50-cleanup-caches/` |
| `maintenance/ci-60-security-audit.sh` | `ci-cd/ci-60-security-audit/` |
| `maintenance/ci-70-identify-deprecated-versions.sh` | `ci-cd/ci-70-identify-deprecated-versions/` |
| `maintenance/ci-75-deprecate-npm-versions.sh` | `ci-cd/ci-75-deprecate-npm-versions/` |
| `maintenance/ci-80-deprecate-github-releases.sh` | `ci-cd/ci-80-deprecate-github-releases/` |
| `maintenance/ci-90-update-dependencies.sh` | `ci-cd/ci-90-update-dependencies/` |
| `maintenance/ci-91-test-after-update.sh` | `ci-cd/ci-91-test-after-update/` |

### Notification

| Script | Hook Directory |
|--------|---------------|
| `notification/ci-10-check-notifications-enabled.sh` | `ci-cd/ci-10-check-notifications-enabled/` |
| `notification/ci-20-determine-status.sh` | `ci-cd/ci-20-determine-status/` |
| `notification/ci-30-send-notification.sh` | `ci-cd/ci-30-send-notification/` |
| `notification/ci-40-maintenance-status.sh` | `ci-cd/ci-40-maintenance-status/` |
| `notification/ci-50-post-release-status.sh` | `ci-cd/ci-50-post-release-status/` |
| `notification/ci-60-release-status.sh` | `ci-cd/ci-60-release-status/` |

### Ops

| Script | Hook Directory |
|--------|---------------|
| `ops/ci-10-validate-inputs.sh` | `ci-cd/ci-10-validate-inputs/` |
| `ops/ci-20-promote-release.sh` | `ci-cd/ci-20-promote-release/` |
| `ops/ci-30-deploy.sh` | `ci-cd/ci-30-deploy/` |
| `ops/ci-40-mark-stability.sh` | `ci-cd/ci-40-mark-stability/` |

### Reports

| Script | Hook Directory |
|--------|---------------|
| `reports/ci-10-summary-pre-release.sh` | `ci-cd/ci-10-summary-pre-release/` |
| `reports/ci-20-summary-sync.sh` | `ci-cd/ci-20-summary-sync/` |
| `reports/ci-30-summary-cleanup.sh` | `ci-cd/ci-30-summary-cleanup/` |
| `reports/ci-40-summary-deprecations.sh` | `ci-cd/ci-40-summary-deprecations/` |
| `reports/ci-50-summary-security-audit.sh` | `ci-cd/ci-50-summary-security-audit/` |
| `reports/ci-60-summary-dependency-update.sh` | `ci-cd/ci-60-summary-dependency-update/` |
| `reports/ci-70-summary-maintenance.sh` | `ci-cd/ci-70-summary-maintenance/` |
| `reports/ci-80-summary-post-release-verify.sh` | `ci-cd/ci-80-summary-post-release-verify/` |
| `reports/ci-85-summary-rollback.sh` | `ci-cd/ci-85-summary-rollback/` |
| `reports/ci-90-summary-post-release.sh` | `ci-cd/ci-90-summary-post-release/` |
| `reports/ci-95-summary-release.sh` | `ci-cd/ci-95-summary-release/` |

## See Also

- [ADR-006: Hooks-Based Script Extensibility](adr/ADR-006_Hooks_Based_Extensibility.md)
- [Hooks Planning](HOOKS_PLANNING.md) -- detailed planning document
- [e-bash Library Reference](E-BASH.md) -- module documentation
