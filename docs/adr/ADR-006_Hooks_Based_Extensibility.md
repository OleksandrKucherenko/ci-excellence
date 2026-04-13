# ADR-006: Hooks-Based Script Extensibility

**Date**: 2025-12-19
**Status**: Accepted

## Context and Problem Statement

Consuming projects need to customize CI script behavior (e.g., run Turborepo before compile, add coverage reports after tests, skip steps based on changed files). Directly editing CI scripts works but creates merge conflicts when pulling upstream framework updates. We need an extension mechanism that keeps core scripts untouched while giving consumers full customization power.

## Decision Drivers

- Customization without modifying core CI scripts
- Per-script isolation (hooks for compile do not affect hooks for lint)
- Support for decision points (should this step be skipped?)
- Discoverable and convention-based (no configuration files needed)
- Compatible with e-bash's hook infrastructure

## Considered Options

1. **Per-script hook directories** (`ci-cd/{script-name}/`) with auto-discovered shell scripts
2. **Central plugin registry** (single config file listing hook scripts per step)
3. **Environment variable callbacks** (`CI_HOOK_BEFORE_COMPILE=path/to/script.sh`)
4. **GitHub Actions composite actions** (wrap each step in a reusable action with pre/post)

## Decision Outcome

**Chosen option**: "Per-script hook directories", because they provide complete isolation per CI step while using simple file-system conventions for discovery. Each CI script sets `HOOKS_DIR="${PROJECT_ROOT}/ci-cd/${SCRIPT_NAME}"` and e-bash's `_hooks.sh` module auto-discovers and executes all scripts in that directory, sorted alphabetically.

Hook naming pattern: `{hook_name}_{NN}_{purpose}.sh`

| Hook Type | Position | Purpose |
|-----------|----------|---------|
| `begin_00-09` | Early | Mode resolution, setup |
| `begin_10-39` | Pre | Environment checks, tool setup |
| `begin_40-89` | Main | User integration (Turbo, custom builds) |
| `decide[0-9]_*` | Decision | Must echo a choice value to stdout (True/False/Skip) |
| `end_10-89` | Post | Cleanup, metrics, reports |

## Consequences

### Positive
- Core CI scripts remain untouched; all customization lives in `ci-cd/` directories
- Hook directories are self-documenting: `ls ci-cd/ci-10-compile/` shows all extensions
- Decision hooks (`decide0_*`) enable conditional execution without modifying script logic
- Upstream updates to CI scripts apply cleanly because hook injection points are stable

### Negative
- Hook discovery adds startup overhead (directory scan per script execution)
- Debug complexity increases when hooks interact in unexpected ways
- Decision hooks limited to 10 per script (0-9) to prevent complexity sprawl
- Hooks do not participate in caching unless they explicitly store files in `.cache/`

## Related Decisions

- ADR-001: Stub-Based CI/CD Framework -- hooks are the extension layer that avoids stub modification
- ADR-002: e-bash Library Foundation -- `_hooks.sh` module implements hook discovery and execution
- ADR-009: Hierarchical Configuration -- hooks operate at the per-script (Level 3) configuration tier
