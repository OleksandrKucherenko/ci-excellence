# ADR-013: Deployment Pipeline as Continuous Delivery Extension

**Date**: 2026-04-13
**Status**: Proposed

## Context and Problem Statement

The CI Excellence framework currently implements the **Continuous Integration** side of the CI/CD lifecycle: code validation (pre-release), artifact creation and publishing (release), deployment verification and stability tagging (post-release), and automated housekeeping (maintenance). These are served by six workflows: `pre-release.yml`, `release.yml`, `post-release.yml`, `maintenance.yml`, `auto-fix-quality.yml`, and `ops.yml`.

The **Continuous Delivery/Deployment** side -- promoting artifacts through environments (staging, production), managing concurrency, observing deployment health, and triggering rollbacks based on live metrics -- is not yet implemented. The `ops.yml` workflow contains deploy stubs (`deploy-staging`, `deploy-production`) that acknowledge this gap. The state diagram (`docs/images/state-diagram-workflows.png`) shows `deploy.yml` as a planned workflow with environment promotion, observation collection, and rollback flows.

## Decision Drivers

- Clear CI/CD boundary: CI produces verified, tagged artifacts; CD consumes them for environment deployment
- Environment promotion model: artifacts flow staging -> production with gates
- Concurrency control: only one deployment per environment at a time
- Observation period: health checks between deploy and stability tagging
- Hosting-agnostic: the deploy pipeline delegates actual infrastructure operations to hooks (AWS, Vercel, GCP, etc.)

## Considered Options

1. **Dedicated `deploy.yml` workflow** with environment jobs, concurrency controls, and observation hooks
2. **Extend `ops.yml`** with full deployment logic alongside existing manual operations
3. **External CD tool** (ArgoCD, Spinnaker, Flux) with CI Excellence providing only artifacts

## Decision Outcome

**Chosen option**: "Dedicated `deploy.yml` workflow", because it maintains the one-workflow-per-concern principle established by the existing architecture. The deploy workflow will:

- Accept a version/artifact reference as input (from release pipeline or manual trigger)
- Deploy to staging with concurrency locks (`concurrency: deploy-staging`)
- Run an observation/health-check period via hooks
- Gate production promotion on staging stability
- Deploy to production with concurrency locks
- Delegate actual infrastructure operations to per-project hooks in `ci-cd/` directories

This maintains the stub-based, hooks-extensible pattern: the framework provides the orchestration skeleton, consuming projects implement the actual deploy commands via hooks.

### Relationship to Existing Workflows

```
CI (implemented)                    CD (planned)
─────────────────                   ──────────────
pre-release.yml  ──build/test──►
release.yml      ──publish────►    deploy.yml ──► staging ──► production
post-release.yml ◄──verify/tag──   
maintenance.yml  ──cleanup──►
ops.yml          ──manual ops──►   (deploy stubs move to deploy.yml)
```

## Consequences

### Positive
- Completes the CI/CD lifecycle shown in the state diagram
- Deploy stubs in `ops.yml` can be removed, simplifying that workflow to pure operations
- Hosting-agnostic design (hooks) means the same framework serves AWS, Vercel, GCP, bare-metal

### Negative
- Adds a seventh workflow, increasing the total surface area
- Observation/health-check hooks are inherently project-specific; the framework can only provide the timing skeleton
- Environment concurrency locks require careful testing to avoid deadlocks

## Implementation Requirements

- [ ] Create `deploy.yml` with staging and production jobs
- [ ] Implement concurrency controls per environment
- [ ] Add observation collector hook points (health checks, metrics sampling)
- [ ] Create deploy scripts in `scripts/ci/deploy/` (or extend `scripts/ci/ops/`)
- [ ] Migrate deploy stubs from `ops.yml` to `deploy.yml`
- [ ] Add `ENABLE_DEPLOY_STAGING` and `ENABLE_DEPLOY_PRODUCTION` feature flags
- [ ] Update state diagram and WORKFLOWS.md documentation

## Related Decisions

- ADR-001: Stub-Based CI/CD Framework -- deploy.yml follows the same stub + hooks pattern
- ADR-003: Variable-Driven Feature Activation -- deployment features gated by ENABLE_* flags
- ADR-006: Hooks-Based Extensibility -- actual deploy commands implemented as per-project hooks
- ADR-008: Release State Machine -- deployment is Phase 4, consuming artifacts from Phase 2
- ADR-009: Hierarchical Configuration -- deploy scripts use CI_PIPELINE_* and CI_STEP_* variables
