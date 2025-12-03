#!/usr/bin/env bash
# Package Manager Mocks Library for BATS Testing
# Provides comprehensive mock implementations for package managers (npm, yarn, pnpm, bun)

# Create npm mock with comprehensive functionality
create_npm_mock() {
    local mock_bin="${1:-$BATS_TEST_TMPDIR/bin}"
    local mock_mode="${2:-success}"

    mkdir -p "$mock_bin"

    cat > "$mock_bin/npm" << 'EOF'
#!/bin/bash
# Comprehensive npm mock for testing

# Default behavior
MOCK_MODE="${NPM_MOCK_MODE:-success}"
MOCK_VERSION="${NPM_MOCK_VERSION:-9.8.7}"
MOCK_NODE_VERSION="${NPM_MOCK_NODE_VERSION:-v18.17.0}"

# Handle npm commands
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
        echo "  update         Update packages"
        echo "  audit          Run security audit"
        echo "  cache          Manage cache"
        echo "  link, ln       Link packages"
        echo "  ls, list       List packages"
        echo "  search         Search packages"
        echo "  info           Package information"
        echo "  init           Initialize a package"
        echo "  pack           Create a tarball"
        echo "  outdated       Check for outdated packages"
        ;;
    "install"|"i")
        if [[ "$MOCK_MODE" == "fail" ]]; then
            echo "npm ERR! code ERESOLVE"
            echo "npm ERR! ERESOLVE unable to resolve dependency tree"
            echo "npm ERR! Please see full log at: /tmp/npm-debug.log"
            return 1
        fi

        echo "npm WARN deprecated package@1.0.0: This package is deprecated"
        if [[ "$2" == "--save-dev" || "$3" == "--save-dev" ]]; then
            echo "added 15 packages, and audited 156 packages in 2s"
            echo "45 packages are looking for funding"
            echo "run \`npm fund\` for details"
        else
            echo "added 20 packages, and audited 180 packages in 3s"
            echo "52 packages are looking for funding"
            echo "run \`npm fund\` for details"
        fi
        echo "found 0 vulnerabilities"
        return 0
        ;;
    "ci")
        if [[ "$MOCK_MODE" == "fail" ]]; then
            echo "npm ERR! code ENOENT"
            echo "npm ERR! errno -2"
            echo "npm ERR! syscall open"
            echo "npm ERR! path package-lock.json"
            return 1
        fi
        echo "npm WARN prepare removing existing node_modules/ before installation"
        echo "added 156 packages in 5s"
        echo "45 packages are looking for funding"
        echo "run \`npm fund\` for details"
        return 0
        ;;
    "run"|"rum")
        local script_name="$2"
        shift 2

        case "$script_name" in
            "test")
                if [[ "$MOCK_MODE" == "fail" ]]; then
                    echo "Test failed"
                    return 1
                fi
                echo "Test suite executed successfully"
                echo "15 tests passed"
                ;;
            "test:unit")
                echo "Unit tests executed"
                echo "10 unit tests passed"
                ;;
            "test:integration")
                echo "Integration tests executed"
                echo "5 integration tests passed"
                ;;
            "test:e2e")
                echo "E2E tests executed"
                echo "3 e2e tests passed"
                ;;
            "test:coverage")
                echo "Coverage report generated"
                echo "File coverage: 95%"
                echo "Line coverage: 92%"
                echo "Branch coverage: 88%"
                ;;
            "build")
                if [[ "$MOCK_MODE" == "fail" ]]; then
                    echo "Build failed"
                    return 1
                fi
                echo "Build completed successfully"
                echo "Output directory: dist/"
                ;;
            "dev")
                echo "Development server starting on http://localhost:3000"
                echo "Hot reload enabled"
                ;;
            "start")
                echo "Production server starting on http://localhost:8080"
                ;;
            "lint")
                echo "Linting completed"
                echo "No linting errors found"
                ;;
            "lint:fix")
                echo "Linting issues fixed automatically"
                ;;
            "format")
                echo "Code formatting completed"
                ;;
            "type-check")
                echo "Type checking completed"
                echo "No type errors found"
                ;;
            "clean")
                echo "Build artifacts cleaned"
                rm -rf dist/ node_modules/.cache/
                ;;
            "deploy")
                echo "Deployment started"
                echo "Application deployed successfully"
                ;;
            *)
                echo "Running script: $script_name $*"
                echo "Script executed successfully"
                ;;
        esac
        return 0
        ;;
    "test")
        if [[ "$MOCK_MODE" == "fail" ]]; then
            echo "Test failed"
            return 1
        fi
        echo "Test suite executed successfully"
        echo "15 tests passed"
        return 0
        ;;
    "build")
        if [[ "$MOCK_MODE" == "fail" ]]; then
            echo "Build failed"
            return 1
        fi
        echo "Build completed successfully"
        echo "Output directory: dist/"
        return 0
        ;;
    "publish")
        if [[ "$MOCK_MODE" == "fail" ]]; then
            echo "Publish failed: Package already exists"
            return 1
        fi
        echo "Package published successfully"
        echo "Version: 1.0.0"
        echo "Package name: test-package"
        return 0
        ;;
    "config")
        if [[ "$2" == "get" ]]; then
            case "$3" in
                "prefix")
                    echo "/usr/local"
                    ;;
                "cache")
                    echo "~/.npm"
                    ;;
                "registry")
                    echo "https://registry.npmjs.org/"
                    ;;
                *)
                    echo "Value for $3 not set"
                    ;;
            esac
        elif [[ "$2" == "set" ]]; then
            echo "Config set: $3=$4"
        else
            echo "npm configuration"
        fi
        return 0
        ;;
    "audit")
        if [[ "$MOCK_MODE" == "fail" ]]; then
            echo "found 3 vulnerabilities (2 moderate, 1 high)"
            return 1
        fi
        echo "found 0 vulnerabilities"
        return 0
        ;;
    "update")
        echo "updated 10 packages in 5s"
        echo "15 packages are looking for funding"
        echo "run \`npm fund\` for details"
        return 0
        ;;
    "cache"|"c")
        case "$2" in
            "clean"|"verify")
                echo "Cache verified and cleaned"
                ;;
            "add")
                echo "Added $3 to cache"
                ;;
            *)
                echo "Cache operation: $*"
                ;;
        esac
        return 0
        ;;
    "link"|"ln")
        if [[ -n "$2" ]]; then
            echo "Linked $2"
        else
            echo "Package linked globally"
        fi
        return 0
        ;;
    "ls"|"list")
        case "$2" in
            "--depth=0")
                echo "test-package@1.0.0"
                echo "lodash@4.17.21"
                echo "express@4.18.2"
                ;;
            "--production")
                echo "express@4.18.2"
                echo "body-parser@1.20.2"
                ;;
            "--dev")
                echo "jest@29.5.0"
                echo "eslint@8.45.0"
                echo "@types/node@20.4.5"
                ;;
            *)
                echo "test-package@1.0.0"
                echo "├── lodash@4.17.21"
                echo "├── express@4.18.2"
                echo "│   └── body-parser@1.20.2"
                echo "└── jest@29.5.0 (dev)"
                ;;
        esac
        return 0
        ;;
    "search")
        echo "Search results for '$2':"
        echo "package-name@1.0.0 - Description of package"
        echo "another-package@2.0.0 - Another package description"
        return 0
        ;;
    "info")
        echo "Package: $2"
        echo "Version: 1.0.0"
        echo "Description: A test package"
        echo "Author: Test Author <test@example.com>"
        echo "License: MIT"
        return 0
        ;;
    "init")
        echo "Initialized package.json"
        echo "Created package.json with default values"
        return 0
        ;;
    "pack")
        echo "Package created: test-package-1.0.0.tgz"
        return 0
        ;;
    "outdated")
        if [[ "$MOCK_MODE" == "fail" ]]; then
            echo "Package Current Wanted Latest Location"
            echo "lodash 4.15.0 4.17.21 4.17.21 test-package"
            echo "express 4.16.0 4.18.2 4.18.2 test-package"
        else
            echo "All packages are up to date"
        fi
        return 0
        ;;
    "fund")
        echo "Funding packages:"
        echo "test-package - https://example.com/sponsor"
        echo "lodash - https://opencollective.com/lodash"
        return 0
        ;;
    "team")
        case "$2" in
            "add")
                echo "Added $3 to $4 team"
                ;;
            "remove")
                echo "Removed $3 from $4 team"
                ;;
            *)
                echo "Team operation: $*"
                ;;
        esac
        return 0
        ;;
    "access")
        case "$2" in
            "public")
                echo "Package is now public"
                ;;
            "restricted")
                echo "Package is now restricted"
                ;;
            *)
                echo "Access operation: $*"
                ;;
        esac
        return 0
        ;;
    "owner")
        case "$2" in
            "add")
                echo "Added $3 as owner of test-package"
                ;;
            "rm")
                echo "Removed $3 as owner of test-package"
                ;;
            "ls")
                echo "test-package owners:"
                echo "test-user"
                ;;
            *)
                echo "Owner operation: $*"
                ;;
        esac
        return 0
        ;;
    "deprecate")
        echo "Deprecated $2: $3"
        return 0
        ;;
    "unpublish")
        echo "Unpublished $2"
        return 0
        ;;
    "star")
        echo "Starred $2"
        return 0
        ;;
    "stars")
        echo "⭐ 123 stars for test-package"
        return 0
        ;;
    "view")
        echo "Package details for $2"
        return 0
        ;;
    "dist-tag")
        case "$2" in
            "add")
                echo "Added tag $3 to version $4"
                ;;
            "rm")
                echo "Removed tag $3"
                ;;
            "ls")
                echo "latest: 1.0.0"
                echo "beta: 1.1.0-beta.1"
                ;;
            *)
                echo "Dist-tag operation: $*"
                ;;
        esac
        return 0
        ;;
    "login")
        echo "Logged in as test-user"
        return 0
        ;;
    "logout")
        echo "Logged out successfully"
        return 0
        ;;
    "whoami")
        echo "test-user"
        return 0
        ;;
    "token")
        case "$2" in
            "list")
                echo "token1234567890abcdef - Created: 2023-01-01"
                ;;
            "revoke")
                echo "Token revoked: $3"
                ;;
            "create")
                echo "New token created: abcdef1234567890"
                ;;
            *)
                echo "Token operation: $*"
                ;;
        esac
        return 0
        ;;
    "profile")
        echo "Profile information for test-user"
        echo "Name: Test User"
        echo "Email: test@example.com"
        echo "Public email: public@example.com"
        return 0
        ;;
    "ping")
        echo "Ping successful"
        return 0
        ;;
    "doctor")
        echo "npm doctor check"
        echo "✓ npm ping successful"
        echo "✓ npm registry reachable"
        echo "✓ npm cache clean"
        echo "✓ npm permissions correct"
        return 0
        ;;
    "help")
        echo "npm help"
        echo ""
        echo "Most commonly used commands:"
        echo "  install, i     Install packages"
        echo "  run, rum       Run scripts"
        echo "  test           Run tests"
        echo "  build          Build the package"
        echo "  publish        Publish the package"
        return 0
        ;;
    *)
        echo "npm: unknown command $1"
        echo "Run 'npm help' for available commands"
        return 1
        ;;
esac
EOF

    chmod +x "$mock_bin/npm"
}

# Create yarn mock with comprehensive functionality
create_yarn_mock() {
    local mock_bin="${1:-$BATS_TEST_TMPDIR/bin}"
    local mock_mode="${2:-success}"

    mkdir -p "$mock_bin"

    cat > "$mock_bin/yarn" << 'EOF'
#!/bin/bash
# Comprehensive yarn mock for testing

# Default behavior
MOCK_MODE="${YARN_MOCK_MODE:-success}"
MOCK_VERSION="${YARN_MOCK_VERSION:-1.22.19}"

# Handle yarn commands
case "$1" in
    "--version")
        echo "$MOCK_VERSION"
        return 0
        ;;
    "install")
        if [[ "$MOCK_MODE" == "fail" ]]; then
            echo "error An unexpected error occurred"
            return 1
        fi
        echo "yarn install v$MOCK_VERSION"
        echo "[1/4] Resolving packages..."
        echo "[2/4] Fetching packages..."
        echo "[3/4] Linking dependencies..."
        echo "[4/4] Building fresh packages..."
        echo "success Saved lockfile."
        echo "Done in 2.45s."
        return 0
        ;;
    "add")
        echo "yarn add v$MOCK_VERSION"
        echo "[1/4] Resolving packages..."
        echo "[2/4] Fetching packages..."
        echo "[3/4] Linking dependencies..."
        echo "[4/4] Building fresh packages..."
        echo "success Saved $2."
        echo "Done in 1.23s."
        return 0
        ;;
    "remove"|"rm")
        echo "yarn remove v$MOCK_VERSION"
        echo "info This package exists at the workspace root"
        echo "Done in 0.89s."
        return 0
        ;;
    "run")
        local script_name="$2"
        shift 2

        case "$script_name" in
            "test")
                echo "yarn run v$MOCK_VERSION"
                echo "$ jest"
                echo "Test Suites: 15 passed, 15 total"
                echo "Tests:       45 passed, 45 total"
                echo "Done in 5.67s."
                ;;
            "build")
                echo "yarn run v$MOCK_VERSION"
                echo "$ webpack"
                echo "Build completed successfully"
                echo "Done in 3.45s."
                ;;
            "dev")
                echo "yarn run v$MOCK_VERSION"
                echo "$ next dev"
                echo "Development server started on http://localhost:3000"
                ;;
            "lint")
                echo "yarn run v$MOCK_VERSION"
                echo "$ eslint src/"
                echo "Done in 1.23s."
                ;;
            *)
                echo "yarn run v$MOCK_VERSION"
                echo "$ $script_name $*"
                echo "Done in 1.00s."
                ;;
        esac
        return 0
        ;;
    "test")
        echo "yarn test v$MOCK_VERSION"
        echo "Test Suites: 15 passed, 15 total"
        echo "Tests:       45 passed, 45 total"
        return 0
        ;;
    "build")
        echo "yarn build v$MOCK_VERSION"
        echo "Build completed successfully"
        return 0
        ;;
    "start")
        echo "yarn start v$MOCK_VERSION"
        echo "Production server started on http://localhost:8080"
        return 0
        ;;
    "dev")
        echo "yarn dev v$MOCK_VERSION"
        echo "Development server started on http://localhost:3000"
        return 0
        ;;
    "upgrade")
        echo "yarn upgrade v$MOCK_VERSION"
        echo "Upgraded packages"
        echo "Done in 2.34s."
        return 0
        ;;
    "outdated")
        echo "yarn outdated v$MOCK_VERSION"
        echo "Package Current Wanted Latest Package Type URL"
        echo "lodash  4.15.0 4.17.21 4.17.21 dependencies
        echo "express 4.16.0 4.18.2  4.18.2  dependencies"
        return 0
        ;;
    "why")
        echo "Why is $2 installed?"
        echo "info Found $2"
        echo "info Reasons for dependency"
        echo "info Halting for now"
        return 0
        ;;
    "info")
        echo "Information for $2"
        echo "Current version: 1.0.0"
        echo "Latest version: 1.1.0"
        echo "Resolvable: yes"
        return 0
        ;;
    "list"|"ls")
        echo "yarn list v$MOCK_VERSION"
        echo "├─ test-package@1.0.0"
        echo "│  ├─ lodash@4.17.21"
        echo "│  └─ express@4.18.2"
        echo "└─ jest@29.5.0"
        return 0
        ;;
    "global")
        case "$2" in
            "add")
                echo "Added $3 globally"
                ;;
            "remove")
                echo "Removed $3 globally"
                ;;
            "list")
                echo "Global packages:"
                echo "│  ├─ typescript@4.9.5"
                echo "│  └─ nodemon@2.0.22"
                ;;
            *)
                echo "Global operation: $*"
                ;;
        esac
        return 0
        ;;
    "cache")
        case "$2" in
            "clean")
                echo "Cache cleared"
                ;;
            "dir")
                echo "Cache directory: ~/.cache/yarn"
                ;;
            *)
                echo "Cache operation: $*"
                ;;
        esac
        return 0
        ;;
    "check")
        echo "yarn check v$MOCK_VERSION"
        echo "success Folder in sync."
        return 0
        ;;
    "config")
        if [[ "$2" == "get" ]]; then
            echo "registry: https://registry.yarnpkg.com"
        elif [[ "$2" == "set" ]]; then
            echo "Set $3 to $4"
        else
            echo "Configuration"
        fi
        return 0
        ;;
    "login")
        echo "Logged in successfully"
        return 0
        ;;
    "logout")
        echo "Logged out successfully"
        return 0
        ;;
    "publish")
        echo "Published package"
        return 0
        ;;
    "unlink")
        echo "Unlinked package"
        return 0
        ;;
    "link")
        echo "Linked package"
        return 0
        ;;
    "team")
        echo "Team operation: $*"
        return 0
        ;;
    "upgrade-interactive")
        echo "Interactive upgrade mode"
        return 0
        ;;
    "create")
        echo "Created new project: $2"
        return 0
        ;;
    "dlx")
        echo "Executed $2 without installing"
        return 0
        ;;
    "node")
        echo "Node version information"
        return 0
        ;;
    "self-update")
        echo "Updated yarn to latest version"
        return 0
        ;;
    "version")
        echo "Current version: $MOCK_VERSION"
        return 0
        ;;
    "help")
        echo "Yarn help"
        echo ""
        echo "Available commands:"
        echo "  add, adddep    Add dependencies"
        echo "  bin            Display bin folder"
        echo "  cache          Manage Yarn cache"
        echo "  check          Verify dependencies"
        echo "  clean          Clean unused dependencies"
        echo "  config         Manage configuration"
        echo "  create         Create new packages"
        echo "  generate-lock  Generate lockfile"
        echo "  global         Global package management"
        echo "  help           Display help"
        echo "  import         Import dependencies"
        echo "  info           Package information"
        echo "  init           Create package.json"
        echo "  install        Install dependencies"
        echo "  licenses       Display licenses"
        echo "  link, ln       Link packages"
        echo "  list, ls       List packages"
        echo "  lockfile       Manage lockfile"
        echo "  login          Login to registry"
        echo "  logout         Logout from registry"
        echo "  node           Manage Node.js versions"
        echo "  outdated       Check for outdated packages"
        echo "  owner          Manage package owners"
        echo "  pack           Create package archive"
        echo "  publish        Publish packages"
        echo "  remove, rm     Remove dependencies"
        echo "  run            Execute scripts"
        echo "  search         Search packages"
        echo "  self-update    Update Yarn"
        echo "  tag            Manage package tags"
        echo "  team           Manage team members"
        echo "  test           Run tests"
        echo "  unlink         Unlink packages"
        echo "  unplug         Unplug packages"
        echo "  upgrade        Upgrade dependencies"
        echo "  upgrade-interactive  Interactive upgrade"
        echo "  version        Show version"
        echo "  versions       Show versions"
        echo "  why            Show dependency reasons"
        echo "  workspace      Workspaces management"
        return 0
        ;;
    *)
        echo "yarn: unknown command '$1'"
        echo "Run 'yarn help' for available commands"
        return 1
        ;;
esac
EOF

    chmod +x "$mock_bin/yarn"
}

# Create pnpm mock with comprehensive functionality
create_pnpm_mock() {
    local mock_bin="${1:-$BATS_TEST_TMPDIR/bin}"
    local mock_mode="${2:-success}"

    mkdir -p "$mock_bin"

    cat > "$mock_bin/pnpm" << 'EOF'
#!/bin/bash
# Comprehensive pnpm mock for testing

# Default behavior
MOCK_MODE="${PNPM_MOCK_MODE:-success}"
MOCK_VERSION="${PNPM_MOCK_VERSION:-8.6.12}"

# Handle pnpm commands
case "$1" in
    "--version")
        echo "$MOCK_VERSION"
        return 0
        ;;
    "install")
        echo "Lockfile is up to date, resolution step is skipped"
        echo "Progress: resolved 156, reused 156, downloaded 0, added 0, done"
        echo "dependencies:"
        echo "+ lodash 4.17.21"
        echo "+ express 4.18.2"
        echo "devDependencies:"
        echo "+ jest 29.5.0"
        echo "+ eslint 8.45.0"
        echo "Done in 1.2s"
        return 0
        ;;
    "add")
        echo "Packages: +1"
        echo "+"
        echo "+ $2 1.0.0"
        echo "Progress: resolved 157, reused 156, downloaded 1, added 1, done"
        echo "Done in 890ms"
        return 0
        ;;
    "remove"|"rm")
        echo "Packages: -1"
        echo "-"
        echo "- $2 1.0.0"
        echo "Done in 456ms"
        return 0
        ;;
    "update")
        echo "Progress: resolved 156, reused 144, downloaded 12, added 12, done"
        echo "Done in 3.4s"
        return 0
        ;;
    "run")
        local script_name="$2"
        shift 2

        case "$script_name" in
            "test")
                echo "PASS  src/app.test.js"
                echo "Test Suites: 1 passed, 1 total"
                echo "Tests:       10 passed, 10 total"
                echo "Snapshots:   0 total"
                echo "Time:        2.345 s"
                echo "Ran all test suites."
                ;;
            "test:watch")
                echo "Watch mode enabled"
                ;;
            "build")
                echo "build succeeded"
                echo "Created build directory"
                ;;
            "dev")
                echo "  VITE v4.4.5  ready in 123 ms"
                echo ""
                echo "  ➜  Local:   http://localhost:5173/"
                echo "  ➜  Network: use --host to expose"
                ;;
            *)
                echo "Running script: $script_name $*"
                ;;
        esac
        return 0
        ;;
    "test")
        echo "PASS  src/app.test.js"
        echo "Test Suites: 1 passed, 1 total"
        echo "Tests:       10 passed, 10 total"
        return 0
        ;;
    "build")
        echo "build succeeded"
        echo "Created build directory"
        return 0
        ;;
    "start")
        echo "Production server started"
        return 0
        ;;
    "dev")
        echo "  VITE v4.4.5  ready in 123 ms"
        echo ""
        echo "  ➜  Local:   http://localhost:5173/"
        return 0
        ;;
    "outdated")
        echo "Deprecated: 'pnpm outdated' is deprecated"
        echo "Use 'pnpm list --outdated' instead"
        return 0
        ;;
    "list"|"ls")
        case "$2" in
            "--depth=0")
                echo "test-package@1.0.0"
                echo "lodash@4.17.21"
                echo "express@4.18.2"
                echo "jest@29.5.0"
                echo "eslint@8.45.0"
                ;;
            "--prod")
                echo "test-package@1.0.0"
                echo "lodash@4.17.21"
                echo "express@4.18.2"
                ;;
            "--dev")
                echo "jest@29.5.0"
                echo "eslint@8.45.0"
                ;;
            *)
                echo "test-package@1.0.0"
                echo "├── lodash@4.17.21"
                echo "├── express@4.18.2"
                echo "└── jest@29.5.0 dev"
                ;;
        esac
        return 0
        ;;
    "why")
        echo "$2 is required by test-package"
        return 0
        ;;
    "info")
        echo ""
        echo "test-package@1.0.0"
        echo ""
        echo "MIT"
        echo ""
        echo "Dependencies:"
        echo "- lodash 4.17.21"
        echo "- express 4.18.2"
        return 0
        ;;
    "store")
        case "$2" in
            "path")
                echo "~/.local/share/pnpm/store/v3"
                ;;
            "prune")
                echo "Packages pruned successfully"
                ;;
            "status")
                echo "Store path: ~/.local/share/pnpm/store/v3"
                echo "Packages in store: 1234"
                echo "Store size: 2.3 GB"
                ;;
            *)
                echo "Store operation: $*"
                ;;
        esac
        return 0
        ;;
    "server")
        echo "Server started"
        return 0
        ;;
    "dlx")
        echo "Executing $2 without installation"
        return 0
        ;;
    "create")
        echo "Created new project: $2"
        return 0
        ;;
    "exec")
        echo "Executing: $*"
        return 0
        ;;
    "doctor")
        echo "Doctor check completed"
        echo "All systems operational"
        return 0
        ;;
    "audit")
        echo "No known vulnerabilities found"
        return 0
        ;;
    "licenses"|"license")
        echo "MIT"
        return 0
        ;;
    "root")
        echo "/path/to/project/root"
        return 0
        ;;
    "bin")
        echo "/path/to/project/node_modules/.bin"
        return 0
        ;;
    "add-dev")
        echo "Packages: +1"
        echo "+ $2 1.0.0"
        echo "Done in 456ms"
        return 0
        ;;
    "remove-dev")
        echo "Packages: -1"
        echo "- $2 1.0.0"
        echo "Done in 234ms"
        return 0
        ;;
    "link")
        echo "Linked package: $2"
        return 0
        ;;
    "unlink")
        echo "Unlinked package: $2"
        return 0
        ;;
    "import")
        echo "Imported dependencies"
        return 0
        ;;
    "rebuild")
        echo "Rebuilding dependencies"
        echo "Done in 2.3s"
        return 0
        ;;
    "purge")
        echo "Purged node_modules"
        return 0
        ;;
    "fetch")
        echo "Fetched packages"
        return 0
        ;;
    "install-test")
        echo "Installed dependencies and ran tests"
        return 0
        ;;
    "link-global")
        echo "Linked package globally"
        return 0
        ;;
    "unlink-global")
        echo "Unlinked package globally"
        return 0
        ;;
    "outdated")
        echo "Checking for outdated packages..."
        echo "All packages are up to date"
        return 0
        ;;
    "patch")
        echo "Created patch for $2"
        return 0
        ;;
    "publish")
        echo "Published package to registry"
        return 0
        ;;
    "search")
        echo "Search results for '$2':"
        echo "test-package - Description of package"
        return 0
        ;;
    "self-update")
        echo "Updated pnpm to latest version"
        return 0
        ;;
    "setup")
        echo "Setup completed"
        return 0
        ;;
    "shamefully-hoist")
        echo "Dependencies hoisted"
        return 0
        ;;
    "stage")
        echo "Staging packages"
        return 0
        ;;
    "state")
        echo "Current state: clean"
        return 0
        ;;
    "terminal")
        echo "Terminal information"
        return 0
        ;;
    "upgrade")
        echo "Upgraded packages"
        return 0
        ;;
    "verify")
        echo "Dependencies verified"
        return 0
        ;;
    "version")
        echo "Current version: $MOCK_VERSION"
        return 0
        ;;
    "workspace")
        echo "Workspace information"
        return 0
        ;;
    "help")
        echo "pnpm <command>"
        echo ""
        echo "Commands:"
        echo "  add, adddep      Add dependencies"
        echo "  bin              Display bin folder"
        echo "  create           Create new projects"
        echo "  dlx              Execute command without installation"
        echo "  exec             Execute command"
        echo "  help             Display help"
        echo "  import           Import dependencies"
        echo "  install, i       Install dependencies"
        echo "  install-test     Install dependencies and run tests"
        echo "  link, ln         Link packages"
        echo "  list, ls         List packages"
        echo "  outdated         Check for outdated packages"
        echo "  prune            Remove unused packages"
        echo "  rebuild          Rebuild packages"
        echo "  remove, rm       Remove dependencies"
        echo "  run              Execute scripts"
        echo "  server           Start package server"
        echo "  store            Manage store"
        echo "  test             Run tests"
        echo "  unlink           Unlink packages"
        echo "  update           Update dependencies"
        echo "  version          Show version"
        echo "  why              Show why package is installed"
        return 0
        ;;
    *)
        echo "pnpm: unknown command '$1'"
        echo "Run 'pnpm help' for available commands"
        return 1
        ;;
esac
EOF

    chmod +x "$mock_bin/pnpm"
}

# Create bun mock with comprehensive functionality
create_bun_mock() {
    local mock_bin="${1:-$BATS_TEST_TMPDIR/bin}"
    local mock_mode="${2:-success}"

    mkdir -p "$mock_bin"

    cat > "$mock_bin/bun" << 'EOF'
#!/bin/bash
# Comprehensive bun mock for testing

# Default behavior
MOCK_MODE="${BUN_MOCK_MODE:-success}"
MOCK_VERSION="${BUN_MOCK_VERSION:-1.0.0}"

# Handle bun commands
case "$1" in
    "--version")
        echo "$MOCK_VERSION"
        return 0
        ;;
    "install")
        echo "bun install v$MOCK_VERSION"
        echo "✨ 45 dependencies installed"
        return 0
        ;;
    "add")
        echo "bun add v$MOCK_VERSION"
        echo "✨ $2 added"
        echo "✨ 46 dependencies installed"
        return 0
        ;;
    "remove"|"rm")
        echo "bun remove v$MOCK_VERSION"
        echo "✨ $2 removed"
        echo "✨ 44 dependencies installed"
        return 0
        ;;
    "update")
        echo "bun update v$MOCK_VERSION"
        echo "✨ dependencies updated"
        return 0
        ;;
    "run")
        local script_name="$2"
        shift 2

        case "$script_name" in
            "test")
                echo "bun test v$MOCK_VERSION"
                echo "15 pass"
                echo "0 fail"
                echo "15 todo"
                echo "15 skip"
                ;;
            "test:watch")
                echo "bun test v$MOCK_VERSION --watch"
                echo "Watching for changes..."
                ;;
            "build")
                echo "bun build v$MOCK_VERSION"
                echo "Build successful"
                echo "Output: dist/index.js"
                ;;
            "dev")
                echo "bun run v$MOCK_VERSION dev"
                echo "Listening on http://localhost:3000/"
                ;;
            "start")
                echo "bun run v$MOCK_VERSION start"
                echo "Production server started"
                ;;
            *)
                echo "bun run v$MOCK_VERSION $script_name $*"
                ;;
        esac
        return 0
        ;;
    "test")
        echo "bun test v$MOCK_VERSION"
        echo "15 pass"
        echo "0 fail"
        return 0
        ;;
    "build")
        echo "bun build v$MOCK_VERSION"
        echo "Build successful"
        return 0
        ;;
    "start")
        echo "bun start v$MOCK_VERSION"
        echo "Server started on http://localhost:3000"
        return 0
        ;;
    "dev")
        echo "bun dev v$MOCK_VERSION"
        echo "Hot reload enabled on http://localhost:3000"
        return 0
        ;;
    "create")
        echo "✨ Created test-project"
        echo "✨ 5 packages installed"
        return 0
        ;;
    "init")
        echo "✨ Initialized project"
        echo "✨ package.json created"
        return 0
        ;;
    "pm")
        case "$2" in
            "start")
                echo "bun pm start v$MOCK_VERSION"
                echo "Process started"
                ;;
            "stop")
                echo "bun pm stop v$MOCK_VERSION"
                echo "Process stopped"
                ;;
            "restart")
                echo "bun pm restart v$MOCK_VERSION"
                echo "Process restarted"
                ;;
            "logs")
                echo "Process logs..."
                ;;
            "status")
                echo "Process status: running"
                ;;
            *)
                echo "bun pm $2"
                ;;
        esac
        return 0
        ;;
    "x")
        echo "bun x v$MOCK_VERSION $*"
        echo "Command executed successfully"
        return 0
        ;;
    "dx")
        echo "bun dx v$MOCK_VERSION $*"
        echo "Development command executed"
        return 0
        ;;
    "upgrade")
        echo "bun upgrade v$MOCK_VERSION"
        echo "Bun upgraded successfully"
        return 0
        ;;
    "rebuild")
        echo "bun rebuild v$MOCK_VERSION"
        echo "Dependencies rebuilt"
        return 0
        ;;
    "link")
        echo "bun link v$MOCK_VERSION"
        echo "Package linked"
        return 0
        ;;
    "unlink")
        echo "bun unlink v$MOCK_VERSION"
        echo "Package unlinked"
        return 0
        ;;
    "lockfile")
        echo "bun lockfile v$MOCK_VERSION"
        echo "Lockfile generated"
        return 0
        ;;
    "purge")
        echo "bun purge v$MOCK_VERSION"
        echo "Cache purged"
        return 0
        ;;
    "cache")
        case "$2" in
            "clear")
                echo "bun cache clear v$MOCK_VERSION"
                echo "Cache cleared"
                ;;
            "dir")
                echo "~/.bun/cache"
                ;;
            *)
                echo "bun cache $2"
                ;;
        esac
        return 0
        ;;
    "pm"|"proc")
        echo "bun pm v$MOCK_VERSION"
        return 0
        ;;
    "discord")
        echo "bun discord v$MOCK_VERSION"
        echo "Discord integration enabled"
        return 0
        ;;
    "fig")
        echo "bun fig v$MOCK_VERSION"
        echo "Fig integration enabled"
        return 0
        ;;
    "shell")
        echo "bun shell v$MOCK_VERSION"
        echo "Interactive shell started"
        return 0
        ;;
    "repl")
        echo "bun repl v$MOCK_VERSION"
        echo "REPL started"
        return 0
        ;;
    "completions")
        echo "bun completions v$MOCK_VERSION"
        echo "Completions generated"
        return 0
        ;;
    "help")
        echo "bun <command>"
        echo ""
        echo "Commands:"
        echo "  add, a           Add dependencies"
        echo "  create, c        Create projects"
        echo "  dev, d           Start development server"
        echo "  discord          Enable Discord integration"
        echo "  dx               Run development commands"
        echo "  fig              Enable Fig integration"
        echo "  help, h          Display help"
        echo "  init, i          Initialize projects"
        echo "  install          Install dependencies"
        echo "  link             Link packages"
        echo "  lockfile         Generate lockfile"
        echo "  pm               Process management"
        echo "  remove, rm       Remove dependencies"
        echo "  repl             Start REPL"
        echo "  run              Execute scripts"
        echo "  shell            Start shell"
        echo "  test, t          Run tests"
        echo "  unlink           Unlink packages"
        echo "  update, u        Update dependencies"
        echo "  upgrade          Upgrade Bun"
        echo "  x                Execute package binaries"
        return 0
        ;;
    *)
        echo "bun: unknown command '$1'"
        echo "Run 'bun help' for available commands"
        return 1
        ;;
esac
EOF

    chmod +x "$mock_bin/bun"
}

# Configure package manager mocks behavior
configure_package_manager_mocks() {
    local mode="${1:-success}"
    local npm_version="${2:-9.8.7}"
    local yarn_version="${3:-1.22.19}"
    local pnpm_version="${4:-8.6.12}"
    local bun_version="${5:-1.0.0}"

    export NPM_MOCK_MODE="$mode"
    export YARN_MOCK_MODE="$mode"
    export PNPM_MOCK_MODE="$mode"
    export BUN_MOCK_MODE="$mode"

    export NPM_MOCK_VERSION="$npm_version"
    export YARN_MOCK_VERSION="$yarn_version"
    export PNPM_MOCK_VERSION="$pnpm_version"
    export BUN_MOCK_VERSION="$bun_version"
}

# Set package manager mocks to failure mode
set_package_manager_mocks_failure() {
    configure_package_manager_mocks "fail"
}

# Clean up package manager mocks
cleanup_package_manager_mocks() {
    unset NPM_MOCK_MODE YARN_MOCK_MODE PNPM_MOCK_MODE BUN_MOCK_MODE
    unset NPM_MOCK_VERSION YARN_MOCK_VERSION PNPM_MOCK_VERSION BUN_MOCK_VERSION
}

# Create all package manager mocks
create_all_package_manager_mocks() {
    local mock_bin="${1:-$BATS_TEST_TMPDIR/bin}"
    local mock_mode="${2:-success}"

    create_npm_mock "$mock_bin" "$mock_mode"
    create_yarn_mock "$mock_bin" "$mock_mode"
    create_pnpm_mock "$mock_bin" "$mock_mode"
    create_bun_mock "$mock_bin" "$mock_mode"
}

# Helper functions for common scenarios
setup_package_manager_for_nodejs_project() {
    configure_package_manager_mocks "success" "9.8.7" "1.22.19" "8.6.12" "1.0.0"
}

setup_package_manager_for_failing_tests() {
    configure_package_manager_mocks "fail" "9.8.7" "1.22.19" "8.6.12" "1.0.0"
}

setup_package_manager_for_build_failure() {
    export NPM_MOCK_MODE="fail"
    export YARN_MOCK_MODE="fail"
    export PNPM_MOCK_MODE="fail"
    export BUN_MOCK_MODE="fail"
}

# Mock package detection functions
detect_package_manager() {
    if [[ -f "package-lock.json" ]]; then
        echo "npm"
    elif [[ -f "yarn.lock" ]]; then
        echo "yarn"
    elif [[ -f "pnpm-lock.yaml" ]]; then
        echo "pnpm"
    elif [[ -f "bun.lockb" ]]; then
        echo "bun"
    else
        echo "npm"  # Default
    fi
}

# Install dependencies using detected package manager
install_dependencies() {
    local pkg_manager=$(detect_package_manager)

    case "$pkg_manager" in
        "npm")
            if [[ -f "package-lock.json" ]]; then
                npm ci
            else
                npm install
            fi
            ;;
        "yarn")
            yarn install
            ;;
        "pnpm")
            pnpm install
            ;;
        "bun")
            bun install
            ;;
    esac
}