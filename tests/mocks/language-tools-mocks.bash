#!/usr/bin/env bash
# Language-Specific Tools Mocks Library for BATS Testing
# Provides comprehensive mock implementations for Node.js, Python, Go, Rust, Java, and .NET tools

# Create Node.js tool mocks (npm, yarn, pnpm, bun)
create_nodejs_tool_mocks() {
    local mock_bin="${1:-$BATS_TEST_TMPDIR/bin}"
    local mock_mode="${2:-success}"

    mkdir -p "$mock_bin"

    # NPM mock
    cat > "${mock_bin}/npm" << 'EOF'
#!/bin/bash
# Comprehensive npm mock for testing

MOCK_MODE="${NPM_MOCK_MODE:-success}"
MOCK_VERSION="${NPM_MOCK_VERSION:-9.8.7}"
MOCK_NODE_VERSION="${NPM_MOCK_NODE_VERSION:-v18.17.0}"
MOCK_HAS_LOCK="${NPM_HAS_LOCK:-false}"

case "$1" in
    "--version")
        echo "$MOCK_VERSION"
        return 0
        ;;
    "--help"|"help")
        echo "npm <command>"
        echo ""
        echo "Available commands:"
        echo "  install, i     Install packages"
        echo "  ci             Install dependencies for production"
        echo "  run, rum       Run scripts"
        echo "  test           Run tests"
        echo "  build          Build the package"
        echo "  publish        Publish the package"
        echo "  config         Manage configuration"
        echo "  audit          Run security audit"
        echo "  outdated       Check for outdated packages"
        ;;
    "install"|"i")
        if [[ "$MOCK_MODE" == "fail" || "${FAIL_NPM:-false}" == "true" ]]; then
            echo "npm install failed" >&2
            exit 1
        fi
        echo "npm install successful"
        if [[ "$MOCK_HAS_LOCK" == "true" ]]; then
            echo "Found package-lock.json, running npm ci instead"
        fi
        ;;
    "ci")
        if [[ "$MOCK_MODE" == "fail" || "${FAIL_NPM:-false}" == "true" ]]; then
            echo "npm ci failed" >&2
            exit 1
        fi
        echo "npm ci successful"
        ;;
    "run"|"rum")
        local script="$2"
        if [[ "$MOCK_MODE" == "fail" || "${FAIL_NPM:-false}" == "true" ]]; then
            echo "npm run $script failed" >&2
            exit 1
        fi
        echo "Running npm script: $script"
        case "$script" in
            "test")
                echo "Running tests..."
                echo "✓ All tests passed"
                ;;
            "build")
                echo "Building project..."
                echo "✓ Build completed successfully"
                ;;
            "lint")
                echo "Linting code..."
                echo "✓ No linting issues found"
                ;;
            *)
                echo "Running $script..."
                echo "✓ Script completed successfully"
                ;;
        esac
        ;;
    "test")
        if [[ "$MOCK_MODE" == "fail" || "${FAIL_NPM:-false}" == "true" ]]; then
            echo "Tests failed" >&2
            exit 1
        fi
        echo "Running tests..."
        echo "✓ All tests passed"
        ;;
    "build")
        if [[ "$MOCK_MODE" == "fail" || "${FAIL_NPM:-false}" == "true" ]]; then
            echo "Build failed" >&2
            exit 1
        fi
        echo "Building project..."
        echo "✓ Build completed successfully"
        ;;
    "audit")
        if [[ "${NPM_AUDIT_VULNERABILITIES:-false}" == "true" ]]; then
            echo "Found 3 vulnerabilities (2 moderate, 1 high)"
            echo "Run 'npm audit fix' to resolve them."
            exit 1
        else
            echo "No vulnerabilities found"
        fi
        ;;
    "outdated")
        if [[ "${NPM_OUTDATED_PACKAGES:-false}" == "true" ]]; then
            echo "Package     Current  Wanted   Latest  Location"
            echo "react       16.14.0  17.0.2   18.2.0  project"
            echo "express     4.17.1  4.18.2   4.18.2  project"
        else
            echo "Package     Current  Wanted   Latest  Location"
            echo "All packages are up to date"
        fi
        ;;
    "publish")
        if [[ "$MOCK_MODE" == "fail" || "${FAIL_NPM:-false}" == "true" ]]; then
            echo "Publish failed" >&2
            exit 1
        fi
        echo "Publishing package..."
        echo "✓ Package published successfully"
        ;;
    *)
        echo "npm $*"
        ;;
esac
EOF
    chmod +x "${mock_bin}/npm"

    # Yarn mock
    cat > "${mock_bin}/yarn" << 'EOF'
#!/bin/bash
# Yarn mock for testing

MOCK_MODE="${YARN_MOCK_MODE:-success}"
MOCK_VERSION="${YARN_MOCK_VERSION:-1.22.19}"

case "$1" in
    "--version")
        echo "$MOCK_VERSION"
        ;;
    "--help"|"help")
        echo "yarn <command>"
        ;;
    "install")
        if [[ "$MOCK_MODE" == "fail" || "${FAIL_YARN:-false}" == "true" ]]; then
            echo "yarn install failed" >&2
            exit 1
        fi
        echo "yarn install v1.22.19"
        echo "[1/4] Resolving packages..."
        echo "[2/4] Fetching packages..."
        echo "[3/4] Linking dependencies..."
        echo "[4/4] Building fresh packages..."
        echo "success Saved lockfile."
        echo "✓ Done in 0.10s."
        ;;
    "add")
        local package="$2"
        if [[ "$MOCK_MODE" == "fail" || "${FAIL_YARN:-false}" == "true" ]]; then
            echo "Failed to add $package" >&2
            exit 1
        fi
        echo "yarn add v1.22.19"
        echo "[1/4] Resolving packages..."
        echo "success Saved 1 new dependency."
        echo "✓ Done in 0.05s."
        ;;
    "run")
        local script="$2"
        if [[ "$MOCK_MODE" == "fail" || "${FAIL_YARN:-false}" == "true" ]]; then
            echo "Failed to run $script" >&2
            exit 1
        fi
        echo "yarn run v1.22.19"
        echo "$ $script"
        echo "✓ Script completed successfully"
        ;;
    "test")
        if [[ "$MOCK_MODE" == "fail" || "${FAIL_YARN:-false}" == "true" ]]; then
            echo "Tests failed" >&2
            exit 1
        fi
        echo "yarn test v1.22.19"
        echo "✓ All tests passed"
        ;;
    "build")
        if [[ "$MOCK_MODE" == "fail" || "${FAIL_YARN:-false}" == "true" ]]; then
            echo "Build failed" >&2
            exit 1
        fi
        echo "yarn build v1.22.19"
        echo "✓ Build completed successfully"
        ;;
    *)
        echo "yarn $*"
        ;;
esac
EOF
    chmod +x "${mock_bin}/yarn"

    # PNPM mock
    cat > "${mock_bin}/pnpm" << 'EOF'
#!/bin/bash
# pnpm mock for testing

MOCK_MODE="${PNPM_MOCK_MODE:-success}"
MOCK_VERSION="${PNPM_MOCK_VERSION:-8.15.0}"

case "$1" in
    "--version")
        echo "$MOCK_VERSION"
        ;;
    "install")
        if [[ "$MOCK_MODE" == "fail" || "${FAIL_PNPM:-false}" == "true" ]]; then
            echo "pnpm install failed" >&2
            exit 1
        fi
        echo "Lockfile is up to date, resolution step is skipped"
        echo "Progress: resolved 1, reused 1, downloaded 0, added 0"
        echo "Dependencies: 1 installed"
        echo "✓ Done in 0.1s"
        ;;
    "add")
        local package="$2"
        if [[ "$MOCK_MODE" == "fail" || "${FAIL_PNPM:-false}" == "true" ]]; then
            echo "Failed to add $package" >&2
            exit 1
        fi
        echo "Progress: resolved 1, reused 1, downloaded 0, added 0"
        echo "Dependencies: 1 installed"
        echo "✓ Done in 0.05s"
        ;;
    "test")
        if [[ "$MOCK_MODE" == "fail" || "${FAIL_PNPM:-false}" == "true" ]]; then
            echo "Tests failed" >&2
            exit 1
        fi
        echo "✓ All tests passed"
        ;;
    "build")
        if [[ "$MOCK_MODE" == "fail" || "${FAIL_PNPM:-false}" == "true" ]]; then
            echo "Build failed" >&2
            exit 1
        fi
        echo "✓ Build completed successfully"
        ;;
    *)
        echo "pnpm $*"
        ;;
esac
EOF
    chmod +x "${mock_bin}/pnpm"

    # Bun mock
    cat > "${mock_bin}/bun" << 'EOF'
#!/bin/bash
# Bun mock for testing

MOCK_MODE="${BUN_MOCK_MODE:-success}"
MOCK_VERSION="${BUN_MOCK_VERSION:-1.0.30}"

case "$1" in
    "--version")
        echo "$MOCK_VERSION"
        ;;
    "install")
        if [[ "$MOCK_MODE" == "fail" || "${FAIL_BUN:-false}" == "true" ]]; then
            echo "bun install failed" >&2
            exit 1
        fi
        echo "bun install"
        echo "✓ Installed 1 package"
        ;;
    "add")
        local package="$2"
        if [[ "$MOCK_MODE" == "fail" || "${FAIL_BUN:-false}" == "true" ]]; then
            echo "Failed to add $package" >&2
            exit 1
        fi
        echo "bun add $package"
        echo "✓ Added 1 package"
        ;;
    "test")
        if [[ "$MOCK_MODE" == "fail" || "${FAIL_BUN:-false}" == "true" ]]; then
            echo "Tests failed" >&2
            exit 1
        fi
        echo "bun test"
        echo "✓ All tests passed"
        ;;
    "build")
        if [[ "$MOCK_MODE" == "fail" || "${FAIL_BUN:-false}" == "true" ]]; then
            echo "Build failed" >&2
            exit 1
        fi
        echo "bun build"
        echo "✓ Build completed successfully"
        ;;
    "run")
        local script="$2"
        if [[ "$MOCK_MODE" == "fail" || "${FAIL_BUN:-false}" == "true" ]]; then
            echo "Failed to run $script" >&2
            exit 1
        fi
        echo "bun run $script"
        echo "✓ Script completed successfully"
        ;;
    *)
        echo "bun $*"
        ;;
esac
EOF
    chmod +x "${mock_bin}/bun"
}

# Create Python tool mocks (pip, pip3)
create_python_tool_mocks() {
    local mock_bin="${1:-$BATS_TEST_TMPDIR/bin}"

    mkdir -p "$mock_bin"

    # pip mock
    cat > "${mock_bin}/pip" << 'EOF'
#!/bin/bash
# pip mock for testing

MOCK_MODE="${PIP_MOCK_MODE:-success}"
MOCK_VERSION="${PIP_MOCK_VERSION:-23.0.0}"

case "$1" in
    "--version")
        echo "pip $MOCK_VERSION"
        ;;
    "install")
        if [[ "$MOCK_MODE" == "fail" || "${FAIL_PIP:-false}" == "true" ]]; then
            echo "pip install failed" >&2
            exit 1
        fi
        echo "Collecting packages"
        echo "Successfully installed packages"
        echo "pip install successful"
        ;;
    "freeze")
        echo "Flask==2.0.0"
        echo "requests==2.25.0"
        ;;
    "list")
        echo "Package    Version"
        echo "---------- -------"
        echo "Flask      2.0.0"
        echo "pip        23.0.0"
        echo "requests   2.25.0"
        ;;
    "check")
        echo "No broken requirements found."
        ;;
    *)
        echo "pip $*"
        ;;
esac
EOF
    chmod +x "${mock_bin}/pip"

    # pip3 mock (same as pip)
    cp "${mock_bin}/pip" "${mock_bin}/pip3"
}

# Create Go tool mocks
create_go_tool_mocks() {
    local mock_bin="${1:-$BATS_TEST_TMPDIR/bin}"

    mkdir -p "$mock_bin"

    cat > "${mock_bin}/go" << 'EOF'
#!/bin/bash
# Go mock for testing

MOCK_MODE="${GO_MOCK_MODE:-success}"
MOCK_VERSION="${GO_MOCK_VERSION:-go version go1.21.0}"

case "$1" in
    "version")
        echo "$MOCK_VERSION"
        ;;
    "mod")
        case "$2" in
            "download")
                if [[ "$MOCK_MODE" == "fail" || "${FAIL_GO:-false}" == "true" ]]; then
                    echo "go mod download failed" >&2
                    exit 1
                fi
                echo "go mod download successful"
                ;;
            "verify")
                if [[ "$MOCK_MODE" == "fail" || "${FAIL_GO_VERIFY:-false}" == "true" ]]; then
                    echo "go mod verify failed" >&2
                    exit 1
                fi
                echo "go mod verify successful"
                ;;
            "tidy")
                echo "go mod tidy"
                ;;
            *)
                echo "go mod $2"
                ;;
        esac
        ;;
    "build")
        if [[ "$MOCK_MODE" == "fail" || "${FAIL_GO:-false}" == "true" ]]; then
            echo "go build failed" >&2
            exit 1
        fi
        echo "Building Go application"
        echo "Build completed successfully"
        ;;
    "test")
        if [[ "$MOCK_MODE" == "fail" || "${FAIL_GO:-false}" == "true" ]]; then
            echo "go test failed" >&2
            exit 1
        fi
        echo "Running Go tests"
        echo "PASS"
        echo "ok      test-package    0.001s"
        ;;
    "run")
        shift
        if [[ "$MOCK_MODE" == "fail" || "${FAIL_GO:-false}" == "true" ]]; then
            echo "go run $* failed" >&2
            exit 1
        fi
        echo "Running Go application"
        echo "Application executed successfully"
        ;;
    *)
        echo "go $*"
        ;;
esac
EOF
    chmod +x "${mock_bin}/go"
}

# Create Rust tool mocks (cargo)
create_rust_tool_mocks() {
    local mock_bin="${1:-$BATS_TEST_TMPDIR/bin}"

    mkdir -p "$mock_bin"

    cat > "${mock_bin}/cargo" << 'EOF'
#!/bin/bash
# Cargo mock for testing

MOCK_MODE="${CARGO_MOCK_MODE:-success}"
MOCK_VERSION="${CARGO_MOCK_VERSION:-cargo 1.74.0}"

case "$1" in
    "--version")
        echo "$MOCK_VERSION"
        ;;
    "build")
        if [[ "$MOCK_MODE" == "fail" || "${FAIL_CARGO:-false}" == "true" ]]; then
            echo "cargo build failed" >&2
            exit 1
        fi
        echo "Compiling project v0.1.0"
        echo "Finished dev [unoptimized + debuginfo] target(s) in 0.10s"
        echo "cargo check successful"
        ;;
    "test")
        if [[ "$MOCK_MODE" == "fail" || "${FAIL_CARGO:-false}" == "true" ]]; then
            echo "cargo test failed" >&2
            exit 1
        fi
        echo "Running tests"
        echo "test test1 ... ok"
        echo "test test2 ... ok"
        echo "test result: ok. 2 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out"
        ;;
    "check")
        if [[ "$MOCK_MODE" == "fail" || "${FAIL_CARGO:-false}" == "true" ]]; then
            echo "cargo check failed" >&2
            exit 1
        fi
        echo "Checking project v0.1.0"
        echo "Finished dev [unoptimized + debuginfo] target(s) in 0.05s"
        echo "cargo check successful"
        ;;
    "run")
        if [[ "$MOCK_MODE" == "fail" || "${FAIL_CARGO:-false}" == "true" ]]; then
            echo "cargo run failed" >&2
            exit 1
        fi
        echo "Running project"
        echo "Hello, world!"
        ;;
    *)
        echo "cargo $*"
        ;;
esac
EOF
    chmod +x "${mock_bin}/cargo"
}

# Create Java tool mocks (mvn, gradle)
create_java_tool_mocks() {
    local mock_bin="${1:-$BATS_TEST_TMPDIR/bin}"

    mkdir -p "$mock_bin"

    # Maven mock
    cat > "${mock_bin}/mvn" << 'EOF'
#!/bin/bash
# Maven mock for testing

MOCK_MODE="${MVN_MOCK_MODE:-success}"
MOCK_VERSION="${MVN_MOCK_VERSION:-Apache Maven 3.9.4}"

case "$1" in
    "--version")
        echo "$MOCK_VERSION"
        ;;
    "compile")
        if [[ "$MOCK_MODE" == "fail" || "${FAIL_MAVEN:-false}" == "true" ]]; then
            echo "Maven compile failed" >&2
            exit 1
        fi
        echo "Maven install successful"
        ;;
    "test")
        if [[ "$MOCK_MODE" == "fail" || "${FAIL_MAVEN:-false}" == "true" ]]; then
            echo "Maven test failed" >&2
            exit 1
        fi
        echo "Running Maven tests"
        echo "Tests run: 1, Failures: 0, Errors: 0, Skipped: 0"
        ;;
    "package")
        if [[ "$MOCK_MODE" == "fail" || "${FAIL_MAVEN:-false}" == "true" ]]; then
            echo "Maven package failed" >&2
            exit 1
        fi
        echo "Building JAR package"
        echo "Maven install successful"
        ;;
    "install")
        if [[ "$MOCK_MODE" == "fail" || "${FAIL_MAVEN:-false}" == "true" ]]; then
            echo "Maven install failed" >&2
            exit 1
        fi
        echo "Installing to local repository"
        echo "Maven install successful"
        ;;
    "clean")
        echo "Cleaning build directory"
        ;;
    *)
        echo "mvn $*"
        ;;
esac
EOF
    chmod +x "${mock_bin}/mvn"

    # Gradle mock
    cat > "${mock_bin}/gradle" << 'EOF'
#!/bin/bash
# Gradle mock for testing

MOCK_MODE="${GRADLE_MOCK_MODE:-success}"
MOCK_VERSION="${GRADLE_MOCK_VERSION:-Gradle 8.4}"

case "$1" in
    "--version")
        echo "$MOCK_VERSION"
        ;;
    "build")
        if [[ "$MOCK_MODE" == "fail" || "${FAIL_GRADLE:-false}" == "true" ]]; then
            echo "Gradle build failed" >&2
            exit 1
        fi
        echo "Gradle build successful"
        ;;
    "test")
        if [[ "$MOCK_MODE" == "fail" || "${FAIL_GRADLE:-false}" == "true" ]]; then
            echo "Gradle test failed" >&2
            exit 1
        fi
        echo "Running Gradle tests"
        echo "BUILD SUCCESSFUL"
        ;;
    "clean")
        echo "Cleaning Gradle project"
        ;;
    "assemble")
        if [[ "$MOCK_MODE" == "fail" || "${FAIL_GRADLE:-false}" == "true" ]]; then
            echo "Gradle assemble failed" >&2
            exit 1
        fi
        echo "Assembling Gradle project"
        echo "BUILD SUCCESSFUL"
        ;;
    *)
        echo "gradle $*"
        ;;
esac
EOF
    chmod +x "${mock_bin}/gradle"
}

# Create .NET tool mocks
create_dotnet_tool_mocks() {
    local mock_bin="${1:-$BATS_TEST_TMPDIR/bin}"

    mkdir -p "$mock_bin"

    cat > "${mock_bin}/dotnet" << 'EOF'
#!/bin/bash
# .NET mock for testing

MOCK_MODE="${DOTNET_MOCK_MODE:-success}"
MOCK_VERSION="${DOTNET_MOCK_VERSION:-7.0.403}"

case "$1" in
    "--version")
        echo "$MOCK_VERSION"
        ;;
    "--info")
        echo ".NET SDKs installed:"
        echo "  7.0.403 [/usr/share/dotnet/sdk]"
        echo ""
        echo ".NET runtimes installed:"
        echo "  Microsoft.AspNetCore.App 7.0.12 [/usr/share/dotnet/shared/Microsoft.AspNetCore.App]"
        ;;
    "restore")
        if [[ "$MOCK_MODE" == "fail" || "${FAIL_DOTNET:-false}" == "true" ]]; then
            echo "dotnet restore failed" >&2
            exit 1
        fi
        echo "Restoring NuGet packages"
        echo "dotnet restore successful"
        ;;
    "build")
        if [[ "$MOCK_MODE" == "fail" || "${FAIL_DOTNET:-false}" == "true" ]]; then
            echo "dotnet build failed" >&2
            exit 1
        fi
        echo "Building .NET project"
        echo "Build succeeded."
        ;;
    "test")
        if [[ "$MOCK_MODE" == "fail" || "${FAIL_DOTNET:-false}" == "true" ]]; then
            echo "dotnet test failed" >&2
            exit 1
        fi
        echo "Running .NET tests"
        echo "Total tests: 1"
        echo "Passed: 1"
        echo "Failed: 0"
        ;;
    "run")
        if [[ "$MOCK_MODE" == "fail" || "${FAIL_DOTNET:-false}" == "true" ]]; then
            echo "dotnet run failed" >&2
            exit 1
        fi
        echo "Running .NET application"
        echo "Hello, World!"
        ;;
    "publish")
        if [[ "$MOCK_MODE" == "fail" || "${FAIL_DOTNET:-false}" == "true" ]]; then
            echo "dotnet publish failed" >&2
            exit 1
        fi
        echo "Publishing .NET project"
        echo "Publish succeeded."
        ;;
    *)
        echo "dotnet $*"
        ;;
esac
EOF
    chmod +x "${mock_bin}/dotnet"
}

# Create utility tool mocks (jq, yq, curl)
create_utility_tool_mocks() {
    local mock_bin="${1:-$BATS_TEST_TMPDIR/bin}"

    mkdir -p "$mock_bin"

    # jq mock
    cat > "${mock_bin}/jq" << 'EOF'
#!/bin/bash
# jq mock for JSON processing

MOCK_MODE="${JQ_MOCK_MODE:-success}"

case "$1" in
    "--version")
        echo "jq-1.6"
        ;;
    *)
        if [[ "$MOCK_MODE" == "fail" ]]; then
            echo "jq parse error" >&2
            exit 1
        fi
        # Basic JSON processing mock
        echo '"mock_value"'
        ;;
esac
EOF
    chmod +x "${mock_bin}/jq"

    # yq mock
    cat > "${mock_bin}/yq" << 'EOF'
#!/bin/bash
# yq mock for YAML processing

MOCK_MODE="${YQ_MOCK_MODE:-success}"

case "$1" in
    "eval")
        case "$3" in
            '.environment.type')
                echo "testing"
                ;;
            '.environment.description')
                echo "Test environment"
                ;;
            '.extends')
                echo "none"
                ;;
            '.environment.created')
                echo "2025-01-01"
                ;;
            *)
                echo "mock-value"
                ;;
        esac
        ;;
    '.')
        cat << YAML
environment:
  type: testing
  description: Test environment
  created: 2025-01-01
regions:
  us-east:
    description: US East region
  us-west:
    description: US West region
YAML
        ;;
    *)
        if [[ "$MOCK_MODE" == "fail" ]]; then
            echo "yq parse error" >&2
            exit 1
        fi
        echo "mock-value"
        ;;
esac
EOF
    chmod +x "${mock_bin}/yq"

    # curl mock
    cat > "${mock_bin}/curl" << 'EOF'
#!/bin/bash
# curl mock for HTTP requests

MOCK_MODE="${CURL_MOCK_MODE:-success}"
MOCK_STATUS_CODE="${CURL_STATUS_CODE:-200}"

case "$1" in
    "--version")
        echo "curl 7.81.0"
        ;;
    "-I"|"--head")
        echo "HTTP/2 $MOCK_STATUS_CODE"
        echo "content-type: application/json"
        echo "server: mock-server"
        ;;
    "-s"|"--silent"|"-f"|"--fail")
        shift
        if [[ "$MOCK_MODE" == "fail" ]]; then
            echo "curl: (22) The requested URL returned error: 404" >&2
            exit 22
        fi
        if [[ "$MOCK_STATUS_CODE" != "200" ]]; then
            exit $((MOCK_STATUS_CODE - 200))
        fi
        echo '{"status": "success", "message": "Mock response"}'
        ;;
    *)
        if [[ "$MOCK_MODE" == "fail" ]]; then
            echo "curl: Connection failed" >&2
            exit 1
        fi
        echo '{"status": "success", "message": "Mock response"}'
        ;;
esac
EOF
    chmod +x "${mock_bin}/curl"
}