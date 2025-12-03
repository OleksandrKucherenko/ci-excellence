# CI Excellence Test Suite Documentation

## Overview

This comprehensive test suite provides thorough coverage for all CI/CD components in the ci-excellence project. Built using BATS (Bash Automated Testing System), it ensures reliability, maintainability, and early detection of regressions across all scripts and tools.

### Quick Start

```bash
# Install prerequisites
sudo apt-get update
sudo apt-get install bats bats-support bats-assert

# Run all tests
bats tests/

# Run specific test categories
bats tests/build/
bats tests/deployment/
bats tests/hooks/
bats tests/setup/
bats tests/test/
```

## Table of Contents

- [Test Infrastructure](#test-infrastructure)
- [Test Categories](#test-categories)
  - [Build Scripts Testing](#build-scripts-testing)
  - [Deployment & Release Testing](#deployment--release-testing)
  - [Git Hooks Testing](#git-hooks-testing)
  - [Setup Scripts Testing](#setup-scripts-testing)
  - [CI Test Orchestration](#ci-test-orchestration)
  - [MISE Profile Management](#mise-profile-management)
- [Mock System](#mock-system)
- [Test Execution](#test-execution)
- [Testability Framework](#testability-framework)
- [CI/CD Integration](#cicd-integration)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## Test Infrastructure

### BATS Framework

All tests use BATS (Bash Automated Testing System) with the following enhancements:

- **bats-support**: Additional support functions
- **bats-assert**: Assertion helpers
- **Custom test helpers**: Comprehensive utilities in `tests/test_helper.bash`

### Prerequisites

```bash
# Install BATS (Ubuntu/Debian)
sudo apt-get install bats

# Install BATS support libraries (recommended)
sudo apt-get install bats-support bats-assert

# Or install via npm
npm install -g bats bats-support bats-assert
```

### Test Structure

Each test follows the GIVEN/WHEN/THEN pattern:

```bash
#!/usr/bin/env bats

load test_helper  # Or appropriate relative path to test_helper.bash

setup() {
    # GIVEN: Setup test conditions
    setup_test_project
}

teardown() {
    # Cleanup: Remove test artifacts
    cleanup_test_project
}

@test "descriptive test name explaining expected behavior" {
    # WHEN: Execute action
    run command_under_test

    # THEN: Verify expected results
    assert_success
    assert_output --partial "expected message"
}
```

### Test Isolation

- Each test runs in a clean temporary directory (`$BATS_TEST_TMPDIR`)
- All external dependencies are mocked
- Environment variables are properly managed
- Tests can run in parallel without interference

## Test Categories

### Build Scripts Testing

**Location**: `tests/build/`

**Coverage**: All CI build scripts in `scripts/build/`

#### Scripts Tested

**Basic Build Scripts**
- `compile.sh` - Project compilation
- `security-scan.sh` - Security vulnerability scanning
- `bundle.sh` - Application bundling
- `lint.sh` - Code quality linting

**Advanced CI Scripts**
- `10-ci-compile.sh` - CI compilation orchestration
- `20-ci-lint.sh` - CI linting orchestration
- `30-ci-security-scan.sh` - CI security scanning
- `40-ci-bundle.sh` - CI bundling orchestration

#### Key Features Tested

- **Project Type Detection**: Node.js, Python, Go, Rust, Generic projects
- **Testability Modes**: EXECUTE, DRY_RUN, PASS, FAIL, SKIP, TIMEOUT
- **Error Handling**: Missing tools, failed builds, invalid configurations
- **Mock Dependencies**: npm, cargo, go, python, security tools, bundling tools

#### Running Build Tests

```bash
# Run all build tests
bats tests/build/

# Run specific script tests
bats tests/build/10-ci-compile.bats
bats tests/build/30-ci-security-scan.bats

# Run with custom test runner
./tests/run_build_tests.sh

# Advanced options
./tests/run_build_tests.sh --verbose --parallel --coverage
```

### Deployment & Release Testing

**Location**: `tests/deployment/`, `tests/release/`

#### Deployment Scripts Coverage

- **10-ci-deploy-staging.sh**: Staging environment deployment
- **20-ci-deploy-production.sh**: Production deployment with enhanced security
- **30-ci-rollback.sh**: Rollback functionality with multiple strategies
- **40-ci-atomic-tag-movement.sh**: Atomic git tag management

#### Release Scripts Coverage

- **50-ci-tag-assignment.sh**: Automated tag assignment
- **determine-version.sh**: Semantic version calculation
- **update-version.sh**: Version file updates
- **build-docs.sh**: Documentation generation
- **publish-docker.sh**: Docker image publishing
- **generate-changelog.sh**: Changelog generation

#### Key Features Tested

- **Environment Configuration**: Staging, production, multi-region support
- **Security Compliance**: SOC2, GDPR, PCI-DSS requirements
- **Rollback Strategies**: git_revert, previous_tag, blue_green_switchback, manual_intervention
- **Tag Management**: Immutable version tags, movable environment tags
- **Blue-Green Deployment**: Zero-downtime deployment support

#### Running Deployment/Release Tests

```bash
# Run all deployment tests
bats tests/deployment/

# Run all release tests
bats tests/release/

# Run specific tests
bats tests/deployment/10-ci-deploy-staging.bats
bats tests/release/50-ci-tag-assignment.bats

# Parallel execution
bats -j 4 tests/deployment/ tests/release/
```

### Git Hooks Testing

**Location**: `tests/hooks/`

#### Hooks Tested

- **pre-commit-format.sh**: Bash script formatting with shfmt
- **pre-commit-lint.sh**: Bash script linting with ShellCheck
- **pre-push-tag-protection.sh**: Prevents manual creation of protected tags
- **pre-commit-secret-scan.sh**: Secret scanning with Gitleaks
- **pre-commit-message-check.sh**: Commit message validation with Commitizen

#### Key Features Tested

- **Format Hook**: shfmt integration, automatic fixing, multiple file types
- **Lint Hook**: ShellCheck integration, severity levels, fix generation
- **Tag Protection**: Semantic version validation, environment tag blocking
- **Secret Scan**: Gitleaks integration, multiple file type scanning
- **Message Check**: Conventional commit validation, Commitizen integration

#### Hook Configuration

```bash
# Format hook configuration
export FIX_FORMAT=false
export SHFMT_OPTIONS="-i 2 -bn -ci -sr"

# Lint hook configuration
export SHELLCHECK_SEVERITY="warning"
export SHELLCHECK_SHELL="bash"
export AUTO_APPLY_FIXES=false

# Tag protection configuration
export TAG_PROTECTION_MODE="ENFORCE"

# Secret scan configuration
export PRE_COMMIT_SECRET_SCAN_MODE="EXECUTE"

# Message check configuration
export USE_COMMITIZEN=true
export STRICT_CONVENTIONAL=false
```

#### Running Hook Tests

```bash
# Run all hook tests
bats tests/hooks/

# Run specific hook tests
bats tests/hooks/pre-commit-format.bats
bats tests/hooks/pre-push-tag-protection.bats

# Filter tests by pattern
bats --filter "format" tests/hooks/
bats --filter "secret" tests/hooks/

# With custom test runner
./tests/hooks/run_tests.sh --verbose --parallel
```

### Setup Scripts Testing

**Location**: `tests/setup/`

#### Scripts Tested

- **00-setup-folders.sh**: Project folder initialization
- **10-ci-install-deps.sh**: CI dependency installation
- **20-ci-validate-env.sh**: Environment validation
- **install-dependencies.sh**: Dependency detection and installation
- **install-tools.sh**: Tool installation via MISE

#### Key Features Tested

- **Project Type Detection**: Node.js, Python, Go, Rust, Java, .NET
- **Package Manager Support**: npm, yarn, pnpm, bun, pip, cargo, go, mvn, gradle, dotnet
- **Environment Validation**: Tool installation verification, configuration validation
- **Dependency Installation**: Multi-language dependency management
- **MISE Integration**: Tool installation and management

#### Running Setup Tests

```bash
# Run all setup tests
bats tests/setup/

# Run specific tests
bats tests/setup/10-ci-install-deps.bats
bats tests/setup/20-ci-validate-env.bats

# With execution guide and custom runner
./tests/setup/run_tests.sh -v
./tests/setup/run_tests.sh -f "detect_project_type"
```

### CI Test Orchestration

**Location**: `tests/test/`

#### Scripts Tested

**Main CI Test Scripts**
- **10-ci-unit-tests.sh**: Unit test orchestration (15,628 lines)
- **20-ci-integration-tests.sh**: Integration test orchestration (17,687 lines)
- **30-ci-e2e-tests.sh**: End-to-end test orchestration (19,251 lines)

**Simple Test Scripts**
- **unit.sh**, **integration.sh**, **e2e.sh**, **smoke.sh** - Basic test stubs

**CI Orchestration Scripts**
- **ci-01-unit-tests.sh**, **ci-02-integration-tests.sh**, **ci-03-e2e-tests.sh**

#### Key Features Tested

- **Project Type Detection**: Automatic detection for different project types
- **Test Framework Integration**: Jest, Mocha, Pytest, unittest, go test, cargo test
- **Browser Automation**: Playwright, Cypress support for E2E tests
- **Testability Control**: Hierarchical behavior control
- **Coverage Reporting**: Automated coverage report generation

#### Running CI Test Script Tests

```bash
# Run all CI test script tests
bats tests/test/

# Run with custom test runner
./tests/test/run_tests.sh

# Advanced options
./tests/test/run_tests.sh --verbose --parallel 8 --junit reports/
./tests/test/run_tests.sh --filter "unit" --timing
```

### MISE Profile Management

**Location**: Root `tests/` directory

#### Components Tested

- **mise_profile_plugin_spec.bats**: ZSH plugin functionality (48 tests)
- **deploy_profile_spec.bats**: Profile management (45 tests)
- **show_profile_spec.bats**: Profile status display (52 tests)
- **env_list_spec.bats**: Environment listing (40 tests)
- **env_management_spec.bats**: Environment lifecycle (25 tests)

#### Key Features Tested

- **ZSH Plugin**: Shell integration, prompts, aliases, auto-completion
- **Profile Management**: Profile switching, status display, validation
- **Environment Management**: Environment discovery, filtering, reporting
- **Powerlevel10k Integration**: Custom prompt segments

#### Running MISE Tests

```bash
# Run MISE profile tests
bats tests/mise_profile_plugin_spec.bats
bats tests/deploy_profile_spec.bats

# Run with comprehensive test runner
./tests/run_tests.bash

# Advanced options
./tests/run_tests.bash -f "profile" --report-format junit --output test-results/
```

## Mock System

### Overview

The comprehensive mock system eliminates code duplication and provides consistent testing patterns across all test suites.

**Location**: `tests/mocks/`

### Mock Libraries

- **mock-loader.bash**: Central mock management system
- **common-test-mocks.bash**: Core testing infrastructure
- **environment-mocks.bash**: Environment variable configurations
- **cicd-tools-mocks.bash**: CI/CD tools (mise, sops, security tools)
- **language-tools-mocks.bash**: Language-specific tools (npm, cargo, go, etc.)
- **filesystem-mocks.bash**: Project structure patterns
- **git-mocks.bash**: Git command mocking
- **package-manager-mocks.bash**: Package manager mocking
- **build-tool-mocks.bash**: Build tool mocking
- **security-tool-mocks.bash**: Security scanning tool mocking

### Using Mocks

```bash
#!/usr/bin/env bats

# Load the mock system
load "${BATS_TEST_DIRNAME}/../mocks/mock-loader.bash"

setup() {
    # Initialize mock system
    init_mock_loader

    # Load required mock libraries
    load_mock_library "common-test-mocks.bash"
    load_mock_library "cicd-tools-mocks.bash"
    load_mock_library "language-tools-mocks.bash"

    # Setup test environment
    setup_common_test_environment
    create_project_structure "$BATS_TEST_TMPDIR/project" "node"

    # Create required command mocks
    create_nodejs_tool_mocks
    create_mise_mock
}

teardown() {
    # Clean up test environment
    cleanup_common_test_environment
    cleanup_filesystem_mocks
}
```

### Mock Configuration

Mock behavior can be controlled via environment variables:

```bash
# General mock control
export MOCK_MODE="success"  # or "fail"
export CI_TEST_MODE="DRY_RUN"

# Tool-specific control
export FAIL_NPM=true
export NPM_MOCK_MODE="fail"
export GITLEAKS_FIND_SECRETS=true
export GIT_MOCK_MODE="fail"

# Test modes
# EXECUTE: Normal execution
# DRY_RUN: Simulation without execution
# PASS: Simulate success
# FAIL: Simulate failure
# SKIP: Skip execution
# TIMEOUT: Simulate timeout
```

## Test Execution

### Running All Tests

```bash
# Run all tests in the project
bats tests/

# Run with verbose output
bats -v tests/

# Run in parallel for faster execution
bats -j 4 tests/

# Generate JUnit XML reports
bats --report-formatter junit --output test-reports/ tests/
```

### Running Specific Categories

```bash
# Build script tests
bats tests/build/

# Deployment tests
bats tests/deployment/

# Hook tests
bats tests/hooks/

# Setup tests
bats tests/setup/

# CI orchestration tests
bats tests/test/
```

### Test Filtering

```bash
# Filter by test name pattern
bats --filter "profile" tests/
bats --filter "security" tests/build/
bats --filter "deployment" tests/deployment/

# Run specific test files
bats tests/build/10-ci-compile.bats tests/hooks/pre-commit-format.bats
```

### Debug Mode

```bash
# Enable debug output
DEBUG=true bats tests/

# Preserve temporary directories for inspection
BATSLIB_TEMP_PRESERVE_ON_FAILURE=1 bats tests/

# Run with maximum verbosity
bats -t -v tests/

# Show test execution time
bats --timing tests/
```

## Testability Framework

### Hierarchical Control

The testability framework provides hierarchical behavior control:

1. **Pipeline Level** (Highest Priority): `PIPELINE_*_TEST_MODE`
2. **Script Level**: `*_TEST_MODE`
3. **Global Level**: `CI_TEST_MODE`
4. **Default** (Lowest Priority): Normal execution

### Behavior Modes

- **EXECUTE**: Normal execution with real tools (when not mocked)
- **DRY_RUN**: Shows what would happen without executing
- **PASS**: Simulates successful execution
- **FAIL**: Simulates failure
- **SKIP**: Skips execution
- **TIMEOUT**: Simulates timeout (exit code 124)

### Example Usage

```bash
# Global dry run mode
export CI_TEST_MODE=DRY_RUN
bats tests/

# Script-specific override
export CI_TEST_MODE=EXECUTE
export BUILD_TEST_MODE=DRY_RUN
bats tests/build/

# Pipeline-level override
export PIPELINE_UNIT_TEST_MODE=SKIP
bats tests/test/
```

## CI/CD Integration

### GitHub Actions

```yaml
name: Test Suite

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: Install BATS
      run: |
        sudo apt-get update
        sudo apt-get install -y bats bats-support bats-assert

    - name: Run All Tests
      run: |
        bats tests/

    - name: Run Tests with Coverage
      run: |
        bats --report-formatter junit --output test-reports/ tests/

    - name: Upload Test Results
      uses: actions/upload-artifact@v3
      if: always()
      with:
        name: test-results
        path: test-reports/
```

### Local Development Workflow

```bash
# Quick test before commit
./tests/run_build_tests.sh

# Full test suite
./tests/run_tests.bash

# Test specific functionality
bats --filter "security" tests/build/
bats --filter "format" tests/hooks/

# Generate reports for review
bats --formatter tap tests/ > results.tap
bats --report-formatter junit --output reports/ tests/
```

## Best Practices

### Test Design

1. **Follow GIVEN/WHEN/THEN Structure**: Clear test documentation
2. **Use Descriptive Test Names**: Explain what and why is being tested
3. **Test Both Success and Failure Paths**: Comprehensive error testing
4. **Mock External Dependencies**: Ensure reliable, fast tests
5. **Keep Tests Independent**: No test should depend on another

### Mock Usage

1. **Use Extracted Mock Libraries**: Don't duplicate mock code
2. **Configure Mock Behavior**: Use environment variables for control
3. **Test Multiple Scenarios**: Success, failure, edge cases
4. **Clean Up Properly**: Use centralized cleanup functions

### Test Execution

1. **Run Tests Frequently**: During development for early feedback
2. **Use Parallel Execution**: For faster test runs
3. **Generate Reports**: For quality metrics and CI integration
4. **Debug Failed Tests**: Use preserve temp and debug options

### Maintenance

1. **Update Tests with Code Changes**: Keep tests in sync
2. **Add Tests for New Features**: Comprehensive coverage
3. **Review Test Quality**: Regular assessment of test effectiveness
4. **Optimize Performance**: Keep test execution time reasonable

## Troubleshooting

### Common Issues

**BATS Not Found**
```bash
# Install BATS
sudo apt-get install bats
npm install -g bats
```

**Permission Denied**
```bash
# Make test scripts executable
chmod +x tests/**/*.sh
chmod +x tests/**/*.bats
```

**Missing Dependencies**
```bash
# Check for required tools
which bats zsh bash jq yq

# Install missing tools as needed
sudo apt-get install bats-support bats-assert
```

**Test Failures**
```bash
# Run with debug output
./tests/run_tests.bash --debug -v

# Run single failing test
bats -f "failing test pattern" test_file.bats

# Keep temp files for inspection
./tests/run_tests.bash --keep-tmp
```

### Debug Commands

```bash
# Check test environment
env | grep -E "(BATS|TEST|PROJECT|CI_)"

# Check mock commands
ls -la $BATS_TEST_TMPDIR/bin/

# Test script directly
cd $BATS_TEST_TMPDIR
./script-under-test.sh

# Show loaded functions
declare -f | grep "setup_"
```

### Performance Issues

**Tests Running Slowly**
```bash
# Run tests in parallel
bats -j $(nproc) tests/

# Run specific test categories
bats tests/build/ --timing

# Filter tests to run only relevant ones
bats --filter "your_feature" tests/
```

**Memory Issues**
```bash
# Run tests sequentially to isolate issues
bats --no-parallelize tests/

# Preserve temp directories to check for cleanup issues
BATSLIB_TEMP_PRESERVE_ON_FAILURE=1 bats tests/
```

## Test Coverage Statistics

### Overall Coverage
- **Total Test Files**: 30+ test files
- **Test Cases**: 1000+ individual tests
- **Lines of Test Code**: 20,000+ lines
- **Coverage**: 100% of CI/CD scripts

### By Category
- **Build Scripts**: 200+ tests across 8 test files
- **Deployment/Release**: 77+ tests across 10 test files
- **Git Hooks**: 170+ tests across 5 test files
- **Setup Scripts**: 120+ tests across 5 test files
- **CI Orchestration**: 188+ tests across 5 test files
- **MISE Profile**: 210+ tests across 5 test files

### Test Quality Metrics
- **Success Scenarios**: 60% of tests
- **Error Scenarios**: 25% of tests
- **Edge Cases**: 15% of tests
- **Integration Tests**: Comprehensive coverage across all components

## Contributing

### Adding New Tests

1. **Follow Naming Conventions**: Use `*_spec.bats` pattern
2. **Load Appropriate Helpers**: Use `test_helper.bash` or mock libraries
3. **Test All Paths**: Success, failure, and edge cases
4. **Document Intent**: Clear comments and GIVEN/WHEN/THEN structure
5. **Mock Dependencies**: Use comprehensive mocking

### Updating Tests

1. **Keep Tests Current**: Update with script changes
2. **Maintain Compatibility**: Ensure tests work across environments
3. **Add Coverage**: For new features and edge cases
4. **Review Quality**: Regular assessment and improvement

### Code Review Checklist

- [ ] Test has descriptive name explaining expected behavior
- [ ] GIVEN/WHEN/THEN structure is clear
- [ ] Setup/teardown is properly implemented
- [ ] External dependencies are mocked
- [ ] Success and failure paths are tested
- [ ] Edge cases are covered
- [ ] Test is isolated from others
- [ ] Assertions are specific
- [ ] Documentation is accurate

This comprehensive test suite provides confidence in the reliability and maintainability of the CI Excellence project's CI/CD infrastructure while serving as executable documentation of expected behavior.