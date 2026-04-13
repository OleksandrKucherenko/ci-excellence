# ADR-011: ShellSpec as Shell Script Test Framework

**Date**: 2026-01-15
**Status**: Accepted

## Context and Problem Statement

With 70+ CI scripts and 13 e-bash library modules, we need a testing framework that can validate Bash script behavior including exit codes, stdout/stderr output, environment variable handling, and function-level unit testing. The framework must support mocking of external commands (git, npm, docker) and integrate with CI pipelines for automated test execution.

## Decision Drivers

- BDD-style syntax for readable, maintainable test specifications
- Ability to mock external commands and environment variables
- Support for testing individual functions (not just whole scripts)
- CI integration (exit codes, JUnit/TAP output)
- Active maintenance and POSIX shell compatibility

## Considered Options

1. **ShellSpec** - BDD testing framework for shell scripts
2. **BATS** (Bash Automated Testing System) - TAP-compliant test runner
3. **shunit2** - xUnit-style shell testing
4. **Custom test scripts** - ad-hoc `assert` functions in Bash

## Decision Outcome

**Chosen option**: "ShellSpec", because its BDD syntax (`Describe`, `It`, `When call`, `The output should`) produces self-documenting tests that serve as behavior specifications. ShellSpec's built-in mocking (`Mock`/`Stub`) handles external command isolation, and its `--format junit` output integrates with CI reporting.

Test organization mirrors the script directory structure:
```
spec/
  build/          # Tests for scripts/ci/build/
  test/           # Tests for scripts/ci/test/
  release/        # Tests for scripts/ci/release/
  maintenance/    # Tests for scripts/ci/maintenance/
  notification/   # Tests for scripts/ci/notification/
  ops/            # Tests for scripts/ci/ops/
  reports/        # Tests for scripts/ci/reports/
  setup/          # Tests for scripts/ci/setup/
  e2e/            # End-to-end integration tests
  support/        # Shared test utilities (run_script.sh)
  spec_helper.sh  # Global test configuration
```

## Consequences

### Positive
- BDD syntax makes tests readable as behavior documentation
- `spec/support/run_script.sh` provides a reusable test harness for CI script execution
- Tests validate the e-bash integration (logger tags, hook execution, exit codes)
- `--format junit` output feeds CI test reporting and trend analysis

### Negative
- ShellSpec requires a platform-specific patch for Ubuntu reliability (timing-sensitive workaround)
- Learning curve for teams unfamiliar with BDD-style shell testing
- Mock complexity increases when scripts source multiple e-bash modules

## Related Decisions

- ADR-002: e-bash Library Foundation -- tests validate e-bash module behavior
- ADR-010: Mise Toolchain Management -- ShellSpec is installed and versioned via mise
