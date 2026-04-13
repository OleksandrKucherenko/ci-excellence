# ADR-009: Hierarchical Configuration Override System

**Date**: 2025-12-13
**Status**: Accepted

## Context and Problem Statement

CI scripts need configuration at different granularities: some settings apply globally (dry-run mode), some per-pipeline (release channel), some per-step (lint strictness), and some per-script (individual tool flags). A flat configuration model forces either excessive duplication or awkward naming conventions. We need a layered system where specific overrides narrow-scope settings without repeating broad defaults.

## Decision Drivers

- Support testing individual steps in isolation (override everything except the target)
- Clear precedence: specific overrides win over general defaults
- Environment-variable-based (works in both local shell and GitHub Actions)
- Strict naming convention to prevent ambiguity

## Considered Options

1. **Four-level hierarchy** (Global -> Pipeline -> Step -> Script) with strict naming prefixes
2. **Two-level** (Global -> Per-script) with simple naming
3. **Configuration files** (YAML/JSON per environment)
4. **Cascading .env files** (`.env`, `.env.release`, `.env.release.npm`)

## Decision Outcome

**Chosen option**: "Four-level hierarchy", because it maps cleanly to CI/CD concepts (the whole system, a pipeline run, a pipeline stage, an individual script) and uses strict naming prefixes for unambiguous resolution.

| Level | Prefix | Scope | Example |
|-------|--------|-------|---------|
| 0 (Global) | `CI_GLOBAL_*` | All pipelines | `CI_GLOBAL_DRY_RUN=true` |
| 1 (Pipeline) | `CI_PIPELINE_*` | One pipeline run | `CI_PIPELINE_RELEASE_CHANNEL=beta` |
| 2 (Step) | `CI_STEP_*` | One pipeline stage | `CI_STEP_LINT_STRICT=true` |
| 3 (Script) | `CI_SCRIPT_*` | One script | `CI_SCRIPT_MODE_ci_10_compile=DRY` |

Level 3 overrides Level 2, which overrides Level 1, which overrides Level 0. This enables testing: set `CI_GLOBAL_DRY_RUN=true` to skip everything, then `CI_SCRIPT_MODE_ci_10_compile=EXEC` to test only compilation.

## Consequences

### Positive
- Enables fine-grained testing: disable all steps globally, enable one script for isolated testing
- Strict prefixes prevent name collisions between levels
- Works identically in local shell (`export CI_GLOBAL_DRY_RUN=true`) and GitHub Actions (`env:`)
- Supports execution modes per script: EXEC, OK, DRY, ERROR, SKIP, TIMEOUT, TEST

### Negative
- Four levels of precedence can be confusing when debugging unexpected behavior
- Long variable names (`CI_SCRIPT_MODE_ci_10_compile`) are verbose
- No built-in validation that variable names follow the naming convention

## Related Decisions

- ADR-003: Variable-Driven Feature Activation -- `ENABLE_*` flags are a parallel system operating at the workflow job level (GitHub Variables), while this hierarchy operates at the script execution level (environment variables)
- ADR-006: Hooks-Based Extensibility -- hooks operate at Level 3 (per-script) in this hierarchy
