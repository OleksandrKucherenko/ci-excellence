# ADR-001: Stub-Based CI/CD Framework Architecture

**Date**: 2025-12-13
**Status**: Accepted
**Supersedes**: None
**Superseded by**: None

## Context and Problem Statement

Setting up production-grade CI/CD pipelines is repetitive, error-prone, and time-consuming. Teams routinely face the same challenges: secret management, release orchestration, deployment verification, and maintenance automation. Each new project reinvents these solutions from scratch.

Existing CI/CD template approaches fall into two extremes: rigid "one-size-fits-all" generators that require significant modification, or loose collections of example scripts without a coherent architecture. Neither respects that different projects need different features at different times.

We need a framework that provides complete pipeline structure on day one while allowing teams to activate features incrementally and customize behavior without modifying core scripts.

**Technical Challenges**:
- **Feature Coupling**: Traditional CI templates break when features they assume are not configured
- **Customization Friction**: Modifying template scripts creates merge conflicts on updates
- **Onboarding Cost**: Complex CI setups require deep tribal knowledge to maintain

**Business Challenges**:
- **Time to Production**: New projects spend weeks building CI/CD from scratch
- **Consistency**: Teams across an organization use incompatible CI/CD patterns
- **Maintenance Burden**: Custom CI scripts accumulate tech debt without a shared standard

## Decision Drivers

- **Zero-Configuration Start**: A new project must have working pipelines without configuring anything beyond cloning the template
- **Progressive Enhancement**: Teams must be able to adopt features gradually over weeks/months, not all at once
- **Technology Agnosticism**: The framework must work with Node.js, Python, Go, Rust, or any stack
- **Upstream Updateability**: Consuming projects must be able to pull framework updates without merge conflicts in customized areas
- **Local Testability**: Every pipeline step must be runnable and testable locally, not only in CI

## Decision

We will build CI Excellence as a **stub-based overlay template** where all CI scripts exist as executable stubs with commented examples, activated through environment variable feature flags (`ENABLE_*`). The framework ships a complete pipeline structure (setup, build, test, release, maintenance, notification, ops, reports) organized as numbered Bash scripts that skip gracefully when their feature is not enabled.

### Architecture Overview

The framework separates concerns into three layers:

1. **Workflow Layer** (`.github/workflows/`): Six stable YAML workflows that define job structure and call scripts. These are defined once and never modified for customization.
2. **Script Layer** (`scripts/ci/`): Numbered Bash stubs organized by domain (build, test, release, etc.). Each script is a customization point that consumers edit for their stack.
3. **Extension Layer** (`ci-cd/`): Per-script hook directories where consuming projects inject behavior without modifying core scripts.

### Key Design Properties

**Stub Scripts**: Every CI script ships as an executable stub. Stubs contain commented examples for common tech stacks (Node.js, Python, Go, Rust) and return exit code 0 by default. This means every pipeline runs green on first clone.

**Feature Flags**: Each workflow job gates on a GitHub Actions variable (`vars.ENABLE_*`). When a variable is unset or `false`, the job skips with no failure. This eliminates red pipelines from unconfigured features.

**Stable Workflows**: Workflow YAML files are defined once and remain unchanged. All customization happens in scripts or hooks, preserving the ability to pull upstream updates.

## Considered Options

### Option 1: Stub-Based Overlay Template (Chosen)
- **Pros**: Zero-config start, progressive adoption, tech-agnostic, customizable without merge conflicts, locally testable
- **Cons**: Requires discipline to keep stubs consistent, consumers must understand the numbering and hook conventions

### Option 2: Monolithic CI Template Generator
- **Pros**: Generates exactly what you need, no unused code
- **Cons**: One-time generation means no upstream updates, generated code drifts from source, requires complex generator tooling

### Option 3: Reusable GitHub Actions (Composite Actions / Reusable Workflows)
- **Pros**: Native GitHub ecosystem, versioned via tags, shareable across repos
- **Cons**: Limited customization within actions, cannot test locally, tight coupling to GitHub-specific features, complex input/output passing between nested workflows

### Option 4: Makefile/Taskfile-Based CI
- **Pros**: Language-agnostic, simple dependency graph, well-understood
- **Cons**: Limited logging/traceability, no built-in hook system, poor secret management, harder to test individual steps in isolation

## Consequences

### Positive Consequences

- **Instant Adoption**: A new project clones the template and has green pipelines immediately, enabling progressive feature activation over weeks
- **Stack Independence**: The same framework serves Node.js, Python, Go, and Rust projects by editing only the stub scripts
- **Merge-Conflict-Free Updates**: Because customization lives in hooks and script bodies (not workflow YAML), upstream framework updates apply cleanly
- **Local Development Parity**: Every script runs locally with `bash scripts/ci/build/ci-10-compile.sh`, giving developers confidence before pushing

### Negative Consequences

- **Convention Learning Curve**: New contributors must understand the numbering scheme, directory structure, and hook system before contributing effectively
- **Stub Maintenance**: All stubs must be kept in sync with the framework's conventions; a stub that diverges from the pattern confuses consumers
- **Bash Dependency**: The framework assumes Bash availability and competency, which limits adoption in Windows-native environments

### Neutral Consequences

- **Documentation Load**: The stub-based approach requires thorough documentation (this ADR set, ARCHITECTURE.md, CUSTOMIZATION.md) to be effective, shifting effort from code to docs

## Related Decisions

- **ADR-002**: e-bash Library as Foundation -- provides the logging and utility layer that makes stubs consistent
- **ADR-003**: Variable-Driven Feature Activation -- the mechanism that makes stubs skip gracefully
- **ADR-004**: Three-Folder Script Organization -- the directory structure that organizes stubs
- **ADR-005**: Spaced Numbering Convention -- the numbering scheme for stub ordering
- **ADR-006**: Hooks-Based Extensibility -- the extension mechanism that avoids modifying stubs

## References

- [TRANSFORMATION_PLAN.md](../TRANSFORMATION_PLAN.md) -- the phased rollout plan for this architecture
- [ARCHITECTURE.md](../ARCHITECTURE.md) -- detailed system architecture documentation
- [CUSTOMIZATION.md](../CUSTOMIZATION.md) -- guide for adapting stubs to different tech stacks

---

*This is the foundational architectural decision for CI Excellence. All subsequent ADRs build on the stub-based, feature-toggled, hook-extensible framework defined here.*
