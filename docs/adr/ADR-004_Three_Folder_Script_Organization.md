# ADR-004: Strict Three-Folder Script Organization

**Date**: 2025-12-13
**Status**: Accepted

## Context and Problem Statement

The v1 proof-of-concept (`002-ci-pipeline-update`) accumulated 14+ top-level script directories, making it unclear where new scripts belong and increasing the cognitive load for contributors. The `scripts/` directory needs a clear, enforceable organizational rule that prevents folder sprawl while accommodating all CI/CD concerns.

## Decision Drivers

- Predictable structure that new contributors can learn in minutes
- Prevention of directory sprawl as features grow
- Clear separation between CI engine scripts, shared libraries, and setup utilities
- Convention-over-configuration approach to reduce decisions

## Considered Options

1. **Three folders only**: `scripts/ci/`, `scripts/lib/`, `scripts/setup/`
2. **Flat structure**: all scripts at `scripts/` root with naming prefixes
3. **Domain-per-folder**: `scripts/build/`, `scripts/test/`, `scripts/release/`, etc. at top level
4. **Functional split**: `scripts/core/`, `scripts/plugins/`, `scripts/utils/`

## Decision Outcome

**Chosen option**: "Three folders only", because it provides a simple rule ("only `ci`, `lib`, and `setup` exist under `scripts/`") that is easy to enforce and understand. Each folder has a clear purpose:

- **`scripts/ci/`**: The CI engine. Sub-organized by domain: `build/`, `test/`, `release/`, `maintenance/`, `notification/`, `reports/`, `ops/`, `setup/`
- **`scripts/lib/`**: Shared libraries (e-bash modules). Never executed directly.
- **`scripts/setup/`**: Local development environment bootstrapping.

## Consequences

### Positive
- One rule to learn: "scripts has three folders"
- Domain sub-directories within `scripts/ci/` group related scripts without polluting the top level
- Clear ownership: CI scripts in `ci/`, libraries in `lib/`, dev setup in `setup/`

### Negative
- The `scripts/ci/` directory grows deep (two levels), which some developers find less discoverable than flat structures
- Adding a genuinely new category (e.g., `scripts/migrations/`) requires an ADR to justify breaking the three-folder rule

## Related Decisions

- ADR-001: Stub-Based CI/CD Framework -- the three-folder rule is Principle #8 of the transformation plan
- ADR-005: Spaced Numbering Convention -- governs ordering within `scripts/ci/` sub-directories
