# ADR-002: e-bash Library as Script Foundation

**Date**: 2025-12-10
**Status**: Accepted

## Context and Problem Statement

CI pipeline scripts produce large volumes of output that is difficult to parse visually. Without structured logging, debugging CI failures requires reading raw stdout line by line. We also need consistent error handling, argument parsing, dependency management, and trap handling across 70+ CI scripts. Building these utilities from scratch would duplicate effort and introduce inconsistencies.

## Decision Drivers

- Consistent, color-coded logging across all pipeline domains (build, test, release, etc.)
- Minimal boilerplate per script (3 lines to bootstrap)
- Ability to control verbosity via `DEBUG` environment variable
- Easy rollback path if the library proves problematic (string-replace `echo:Tag` back to `echo`)
- Reusable utilities: argument parsing, dependency checks, dry-run support, semver, trap management

## Considered Options

1. **e-bash library** (external, maintained separately) - full logging, hooks, utilities
2. **Custom logging functions** (inline per-project) - simpler, but duplicated across scripts
3. **No structured logging** (plain echo) - zero overhead, poor traceability

## Decision Outcome

**Chosen option**: "e-bash library", because it provides a battle-tested, modular set of Bash utilities (logger, hooks, traps, dependencies, semver, dry-run) maintained as an independent project. Integration via git subtree at `scripts/lib/` keeps the library updatable without vendoring snapshots.

Each CI script sources a single `_ci-common.sh` bootstrap that initializes domain-specific colored logger tags (`echo:Build`, `echo:Test`, `echo:Release`, etc.) and exposes CI helpers (`ci:param`, `ci:secret`, `ci:output`, `ci:require`).

## Consequences

### Positive
- Domain-colored output (`[build]` cyan, `[test]` green, `[release]` purple) makes pipeline logs scannable at a glance
- `DEBUG=build,test` filtering lets developers focus on specific domains
- 13 reusable modules eliminate boilerplate for argument parsing, dependency management, semver, and trap handling
- Independent maintenance cycle via git subtree (`scripts/lib/` tracks e-bash releases)

### Negative
- External dependency introduces a supply-chain coupling to the e-bash repository
- Contributors must learn e-bash conventions (logger tags, hook registration) on top of standard Bash
- Subtree updates (`e-bash upgrade`) require manual verification against CI scripts

## Related Decisions

- ADR-001: Stub-Based CI/CD Framework -- e-bash provides the consistency layer across all stubs
- ADR-006: Hooks-Based Extensibility -- e-bash's `_hooks.sh` module implements the hook discovery and execution mechanism
- ADR-011: ShellSpec Test Framework -- tests validate e-bash integration behavior
