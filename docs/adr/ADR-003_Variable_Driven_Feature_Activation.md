# ADR-003: Variable-Driven Feature Activation

**Date**: 2025-12-13
**Status**: Accepted

## Context and Problem Statement

CI/CD frameworks that include features a project does not use create two failure modes: either unconfigured jobs fail with red pipelines (causing notification fatigue and confusion), or teams must manually delete unused workflow jobs (preventing upstream updates). We need a mechanism where unused features are invisible -- no failures, no noise -- while remaining instantly activatable when the team is ready.

## Decision Drivers

- Zero failures from disabled features
- Progressive adoption over weeks/months
- No workflow YAML modification required to enable/disable features
- Clear visibility into which features are active

## Considered Options

1. **GitHub Actions `vars.ENABLE_*` flags** - workflow `if:` conditions gate on repository variables
2. **Conditional file existence** - jobs check for script presence before running
3. **Branch-based feature gates** - different branches carry different workflow definitions
4. **Environment-based profiles** - different .env files activate different feature sets

## Decision Outcome

**Chosen option**: "GitHub Actions `vars.ENABLE_*` flags", because they provide a single, centralized control plane visible in repository settings. Each workflow job includes an `if: vars.ENABLE_FEATURE == 'true'` condition that causes the job to skip (not fail) when the variable is unset or false.

Recommended progressive adoption schedule:
- **Week 1**: `ENABLE_COMPILE`, `ENABLE_LINT`, `ENABLE_UNIT_TESTS`
- **Week 2**: `ENABLE_INTEGRATION_TESTS`, `ENABLE_SECURITY_SCAN`
- **Week 3**: `ENABLE_GITHUB_RELEASE`, `ENABLE_NOTIFICATIONS`
- **Month 2**: `ENABLE_NPM_PUBLISH`, `ENABLE_DOCKER_PUBLISH`, `ENABLE_DOCUMENTATION`
- **Month 3**: `ENABLE_CLEANUP`, `ENABLE_FILE_SYNC`, `ENABLE_SECURITY_AUDIT`, `ENABLE_DEPENDENCY_UPDATE`

## Consequences

### Positive
- Green pipelines from day one -- no job failures from unconfigured features
- Teams adopt features at their own pace without touching workflow YAML
- Feature state is auditable in repository settings (no hidden config files)
- Aligns with the "zero downtime" principle -- toggling a feature off never breaks the pipeline

### Negative
- GitHub Variables UI is not version-controlled; changes are not tracked in git history
- Large number of `ENABLE_*` variables can be overwhelming without documentation
- Job-level `if:` conditions add visual noise to workflow YAML

## Related Decisions

- ADR-001: Stub-Based CI/CD Framework -- feature flags are the activation mechanism for stubs
- ADR-009: Hierarchical Configuration -- `ENABLE_*` flags operate at the global (Level 0) configuration tier
