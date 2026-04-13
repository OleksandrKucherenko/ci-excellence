# Feature Flags Reference

All CI Excellence workflows are **variable-driven** -- features skip gracefully when not enabled. This document is the single reference for all `ENABLE_*` flags and configuration variables.

Set flags in: **Repository Settings > Secrets and variables > Actions > Variables**

## Feature Flags

### Pre-Release Pipeline (`pre-release.yml`)

| Flag | Job(s) Controlled | Default | Purpose |
|------|-------------------|---------|---------|
| `ENABLE_COMPILE` | compile | `false` | Build/compile the project |
| `ENABLE_LINT` | lint | `false` | Run code linters |
| `ENABLE_UNIT_TESTS` | unit-tests | `false` | Run unit tests with coverage |
| `ENABLE_INTEGRATION_TESTS` | integration-tests | `false` | Run integration tests |
| `ENABLE_E2E_TESTS` | e2e-tests | `false` | Run end-to-end tests |
| `ENABLE_SECURITY_SCAN` | security-scan | `false` | Run vulnerability scans |
| `ENABLE_BUNDLE` | bundle | `false` | Create distribution packages |

Note: `ENABLE_COMPILE` is also checked by integration-tests, e2e-tests, and bundle jobs to determine whether to restore build artifacts.

### Release Pipeline (`release.yml`)

| Flag | Job(s) Controlled | Default | Purpose |
|------|-------------------|---------|---------|
| `ENABLE_COMPILE` | build | `false` | Build release artifacts |
| `ENABLE_TESTS` | test | `false` | Run tests on release build |
| `ENABLE_NPM_PUBLISH` | publish-npm | `false` | Publish to NPM registry |
| `ENABLE_GITHUB_RELEASE` | publish-github | `false` | Create GitHub Release |
| `ENABLE_DOCKER_PUBLISH` | publish-docker | `false` | Build and push Docker images |
| `ENABLE_DOCUMENTATION` | publish-documentation | `false` | Build and deploy docs |

### Post-Release Pipeline (`post-release.yml`)

| Flag | Job(s) Controlled | Default | Purpose |
|------|-------------------|---------|---------|
| `ENABLE_DEPLOYMENT_VERIFICATION` | verify-deployment | `false` | Check all deployment targets |
| `ENABLE_STABILITY_TAGGING` | tag-stable, tag-unstable | `false` | Mark versions as stable/unstable |
| `ENABLE_ROLLBACK` | rollback | `false` | Enable rollback capability |

The verify-deployment and rollback jobs also check `ENABLE_NPM_PUBLISH`, `ENABLE_GITHUB_RELEASE`, and `ENABLE_DOCKER_PUBLISH` to determine which targets to verify/rollback.

### Maintenance Pipeline (`maintenance.yml`)

| Flag | Job(s) Controlled | Default | Purpose |
|------|-------------------|---------|---------|
| `ENABLE_CLEANUP` | cleanup steps | `false` | Remove old workflows, artifacts, caches |
| `ENABLE_FILE_SYNC` | sync-and-update steps | `false` | Keep package.json and CHANGELOG in sync |
| `ENABLE_DEPRECATION` | deprecate-old-versions steps | `false` | Mark old versions as deprecated |
| `ENABLE_SECURITY_AUDIT` | security-audit steps | `false` | Run periodic security audits |
| `ENABLE_DEPENDENCY_UPDATE` | dependency-update steps | `false` | Update dependencies automatically |

Deprecation also checks `ENABLE_NPM_PUBLISH` and `ENABLE_GITHUB_RELEASE` to determine which registries to deprecate in.

### Cross-Cutting

| Flag | Workflows | Default | Purpose |
|------|-----------|---------|---------|
| `ENABLE_NOTIFICATIONS` | pre-release, release, post-release, maintenance | `false` | Send pipeline notifications via Apprise |

## Configuration Variables

These are non-boolean settings that control workflow behavior:

### Pre-Release Pipeline

| Variable | Default | Purpose |
|----------|---------|---------|
| `ARTIFACT_RETENTION_DAYS` | `5` | Days to retain build artifacts |
| `DELIVERABLE_RETENTION_DAYS` | `30` | Days to retain deliverables |
| `REPORT_RETENTION_DAYS` | `7` | Days to retain reports |

### Auto-Fix Quality Pipeline (`auto-fix-quality.yml`)

| Variable | Default | Purpose |
|----------|---------|---------|
| `AUTO_COMMIT` | `true` | Auto-commit security fixes |
| `AUTO_APPLY_FIXES` | `true` | Auto-apply fixes when found |
| `PUSH_CHANGES` | `false` | Auto-push fixed changes (use with caution) |

## Progressive Adoption Schedule

Enable features gradually as your team is ready:

**Week 1 -- Basic CI:**
```
ENABLE_COMPILE=true
ENABLE_LINT=true
ENABLE_UNIT_TESTS=true
```

**Week 2 -- Extended Testing:**
```
ENABLE_INTEGRATION_TESTS=true
ENABLE_SECURITY_SCAN=true
```

**Week 3 -- Releases:**
```
ENABLE_GITHUB_RELEASE=true
ENABLE_NOTIFICATIONS=true
```

**Month 2 -- Publishing:**
```
ENABLE_NPM_PUBLISH=true
ENABLE_DOCKER_PUBLISH=true
ENABLE_DOCUMENTATION=true
```

**Month 3 -- Maintenance:**
```
ENABLE_CLEANUP=true
ENABLE_FILE_SYNC=true
ENABLE_SECURITY_AUDIT=true
ENABLE_DEPENDENCY_UPDATE=true
```

## Local Development

Feature flags are also defined in the [`.env`](../.env) template for local testing. Source this file to simulate CI behavior locally:

```bash
source .env
./scripts/ci/build/ci-10-compile.sh
```

## See Also

- [ADR-003: Variable-Driven Feature Activation](adr/ADR-003_Variable_Driven_Feature_Activation.md)
- [Workflows Documentation](WORKFLOWS.md) -- detailed workflow reference
- [Architecture](ARCHITECTURE.md) -- system architecture overview
