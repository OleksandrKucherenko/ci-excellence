# ADR-008: Release State Machine with Stability Tags

**Date**: 2025-12-13
**Status**: Accepted

## Context and Problem Statement

Release management in CI/CD pipelines often conflates distinct concerns: artifact generation, public communication, deployment, and stability assessment. This conflation leads to ambiguous release states (is a "release" an artifact or a public announcement?) and makes rollback decisions unclear. We need a formal model that separates these concerns into distinct lifecycle phases.

## Decision Drivers

- Clear distinction between "artifact exists" and "artifact is publicly announced"
- Support for pre-release channels (alpha, beta, RC) alongside stable releases
- Rollback must be a first-class state transition, not an ad-hoc procedure
- Stability status must persist as metadata (tags), not ephemeral pipeline state
- The model must map cleanly to GitHub Releases, NPM tags, and Docker tags

## Considered Options

1. **Five-phase state machine** (Development -> Artifact -> Communication -> Deployment -> Stability)
2. **Three-phase model** (Build -> Release -> Deploy)
3. **Git-flow based** (develop -> release branch -> main -> hotfix)
4. **Continuous deployment** (every merge to main auto-deploys)

## Decision Outcome

**Chosen option**: "Five-phase state machine", because it explicitly separates artifact generation from communication, deployment from stability assessment, and provides formal state transitions with rollback paths.

**Phase 1 -- Development**: Commit -> Branch -> Push -> Pull Request
**Phase 2 -- Artifact Generation**: Release Candidate (canary) -> Deployable (in registry)
**Phase 3 -- Communication & Lifecycle**: GitHub Pre-Release -> GitHub Release -> Old -> Deprecated
**Phase 4 -- Deployment**: Staging -> Production
**Phase 5 -- Stability (Sticky Tags)**: Release `v{SemVer}` -> Stable `v{SemVer}-stable` | Unstable `v{SemVer}-unstable`

Stability tags are "sticky" -- they persist as git tags and can move between Stable and Unstable as the release's status changes over time.

## Consequences

### Positive
- "Deployable" and "Released" are distinct states; an artifact can exist in registries without being publicly announced
- Stability tags provide a persistent, queryable record of which versions are production-verified
- Rollback transitions are explicit: Deployment -> Unstable tag, with corresponding registry operations
- The model maps directly to the six GitHub Actions workflows (pre-release, release, post-release, maintenance, ops)

### Negative
- Five phases add conceptual complexity compared to simpler build-release-deploy models
- Stability tags accumulate in git history; periodic cleanup (via maintenance pipeline) is needed
- The model assumes GitHub Releases as the communication channel; other platforms require adaptation

## Related Decisions

- ADR-001: Stub-Based CI/CD Framework -- the state machine drives the workflow and script organization
- ADR-003: Variable-Driven Feature Activation -- each phase's features are independently activatable
- ADR-009: Hierarchical Configuration -- pipeline-level config (Level 1) maps to state machine phases
