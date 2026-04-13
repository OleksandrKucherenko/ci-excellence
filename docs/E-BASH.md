# e-bash Library Reference

Reference guide for the e-bash modules available in `scripts/lib/` and how they integrate with CI Excellence scripts.

For full e-bash documentation, see the [upstream repository](https://github.com/OleksandrKucherenko/e-bash).

## Module Inventory

| Module | Key Functions | Purpose |
|--------|--------------|---------|
| [`_arguments.sh`](../scripts/lib/_arguments.sh) | `arguments:parse`, `arguments:usage` | Declarative CLI argument parser with auto-generated help |
| [`_colors.sh`](../scripts/lib/_colors.sh) | `cl_red`, `cl_green`, `st_bold`, `cl_reset` | ANSI color and style constants |
| [`_commons.sh`](../scripts/lib/_commons.sh) | `commons:timestamp`, `commons:elapsed`, `to:slug`, `env:resolve`, `coalesce` | Timing, env resolution, string utilities, variable fallbacks |
| [`_dependencies.sh`](../scripts/lib/_dependencies.sh) | `dependency:check`, `dependency:require`, `dependency:install` | Tool verification with caching and alias resolution |
| [`_dryrun.sh`](../scripts/lib/_dryrun.sh) | `dryrun:call`, `dryrun:is_active` | Three-mode execution: real, dry-run (print commands), trace |
| [`_gnu.sh`](../scripts/lib/_gnu.sh) | `gnu:require`, `gnu:is_available` | GNU/BSD compatibility shims (macOS vs Linux) |
| [`_hooks.sh`](../scripts/lib/_hooks.sh) | `hooks:bootstrap`, `hooks:do`, `hooks:flow:apply`, `hooks:register`, `hooks:middleware` | Hook discovery, registration, middleware, contract protocol |
| [`_logger.sh`](../scripts/lib/_logger.sh) | `logger:init`, `echo:Tag`, `printf:Tag` | Domain-specific colored logging with DEBUG filtering |
| [`_self-update.sh`](../scripts/lib/_self-update.sh) | `self_update:check`, `self_update:apply` | Library self-update mechanism |
| [`_semver.sh`](../scripts/lib/_semver.sh) | `semver:parse`, `semver:compare`, `semver:increment`, `semver:validate` | Full SemVer 2.0.0 parsing, comparison, constraint checking |
| [`_tmux.sh`](../scripts/lib/_tmux.sh) | `tmux:session`, `tmux:split` | Tmux session and pane utilities |
| [`_traps.sh`](../scripts/lib/_traps.sh) | `traps:add`, `traps:remove`, `traps:list` | Enhanced signal handling with EXIT trap stacking |

## CI Script Integration

All CI scripts bootstrap e-bash via a single `source` of [`_ci-common.sh`](../scripts/ci/_ci-common.sh):

```bash
#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

echo:Build "Starting compilation..."
```

This 3-line bootstrap initializes:

1. **Domain loggers** with colored prefixes (`echo:Build`, `echo:Test`, `echo:Release`, etc.)
2. **Hooks system** with per-script `HOOKS_DIR` pointing to `ci-cd/{script-name}/`
3. **Middleware** for contract-based hook communication

### Logger Tags

| Tag | Color | Usage |
|-----|-------|-------|
| `echo:Build` | Cyan, bold | Build pipeline scripts |
| `echo:Test` | Green, bold | Test pipeline scripts |
| `echo:Release` | Purple, bold | Release pipeline scripts |
| `echo:Setup` | Blue, bold | Environment setup scripts |
| `echo:Security` | Red, bold | Security scanning scripts |
| `echo:Ops` | Light purple, bold | Operations scripts |
| `echo:Notify` | Yellow | Notification scripts |
| `echo:Maint` | Grey, italic | Maintenance scripts |
| `echo:Report` | Grey | Report/summary scripts |
| `echo:Success` | Green, bold | Cross-cutting success markers |
| `echo:Error` | Red, bold | Cross-cutting error markers |

### CI Helpers

`_ci-common.sh` provides these helpers on top of e-bash modules:

| Helper | Signature | Purpose |
|--------|-----------|---------|
| `ci:param` | `ci:param <tag> <name> <value>` | Log a non-secret parameter |
| `ci:secret` | `ci:secret <tag> <name> <value>` | Log a masked secret (first 3 + last 3 chars) |
| `ci:output` | `ci:output <tag> <name> <value>` | Write to `GITHUB_OUTPUT` with logging |
| `ci:output:multiline` | `ci:output:multiline <tag> <name> <value>` | Write multiline value to `GITHUB_OUTPUT` |
| `ci:require` | `ci:require <tag> <var_name>` | Require env var or exit 1 |
| `ci:optional` | `ci:optional <tag> <var_name> [default]` | Log optional env var |

### Controlling Output

```bash
DEBUG=build,test ./script.sh      # Enable only build and test logs
DEBUG=*,-setup   ./script.sh      # Enable all except setup
DEBUG=*          ./script.sh      # Enable everything
```

In CI, all loggers are enabled by default (`DEBUG=ci,build,test,release,...`).

## Upstream bin/ Scripts (Not Yet Included)

The e-bash upstream repository provides additional scripts in [`bin/`](https://github.com/OleksandrKucherenko/e-bash/tree/master/bin) that are directly relevant but not yet embedded in CI Excellence:

| Script | Key Functions | Purpose |
|--------|--------------|---------|
| `git.conventional-commits.sh` | `conventional:parse`, `conventional:is_valid_commit`, `conventional:is_version_commit` | Conventional commit parsing and validation |
| `git.semantic-version.sh` | Version calculator | Compute next semantic version from commit history |
| `git.verify-all-commits.sh` | Compliance checker | Verify all commits follow conventional format (with `--patch` fix mode) |

These scripts use the same e-bash modules already present in `scripts/lib/`. See Gap #9 in the [gap analysis](answers/00-gap-analysis.md) for integration plans.

## Upgrading e-bash

The library is tracked as a git subtree at `scripts/lib/`. To upgrade:

```bash
curl -sSL https://git.new/e-bash | bash -s -- upgrade
```

Or manually via the e-bash installer with the `upgrade` flag.

## See Also

- [ADR-002: e-bash Library as Foundation](adr/ADR-002_E_Bash_Library_Foundation.md)
- [e-bash upstream documentation](https://github.com/OleksandrKucherenko/e-bash)
- [Architecture](ARCHITECTURE.md) -- system architecture overview
