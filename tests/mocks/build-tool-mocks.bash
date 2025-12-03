#!/usr/bin/env bash
# Build Tool Mocks Library for BATS Testing
# Provides comprehensive mock implementations for build tools (cargo, go, mvn, gradle, dotnet, etc.)

# Create cargo mock with comprehensive functionality
create_cargo_mock() {
    local mock_bin="${1:-$BATS_TEST_TMPDIR/bin}"
    local mock_mode="${2:-success}"

    mkdir -p "$mock_bin"

    cat > "$mock_bin/cargo" << 'EOF'
#!/bin/bash
# Comprehensive cargo mock for testing

# Default behavior
MOCK_MODE="${CARGO_MOCK_MODE:-success}"
MOCK_VERSION="${CARGO_MOCK_VERSION:-cargo 1.75.0 (1d8b05cdd 2023-11-20)}"

# Handle cargo commands
case "$1" in
    "--version")
        echo "$MOCK_VERSION"
        return 0
        ;;
    "build")
        echo "   Compiling test-project v0.1.0 (/tmp/test-project)"
        echo "    Finished dev [unoptimized + debuginfo] target(s) in 2.45s"
        if [[ "$MOCK_MODE" == "fail" ]]; then
            echo "error: failed to compile test-project v0.1.0"
            echo "error: could not compile test-project"
            return 1
        fi
        return 0
        ;;
    "build"|"b" "--release")
        echo "   Compiling test-project v0.1.0 (/tmp/test-project)"
        echo "    Finished release [optimized] target(s) in 15.23s"
        return 0
        ;;
    "run")
        shift
        echo "   Running \`target/debug/test-project\`"
        echo "Hello, world!"
        if [[ -n "$*" ]]; then
            echo "Arguments received: $*"
        fi
        return 0
        ;;
    "run"|"r" "--release")
        shift
        echo "   Running \`target/release/test-project\`"
        echo "Hello, world! (optimized)"
        return 0
        ;;
    "test")
        echo "   Compiling test-project v0.1.0 (/tmp/test-project)"
        echo "    Finished test [unoptimized + debuginfo] target(s) in 1.23s"
        echo ""
        echo "running unittests"
        echo ""
        echo "test test::tests::it_works ... ok"
        echo "test test::tests::another_test ... ok"
        echo ""
        echo "test result: ok. 2 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out"
        return 0
        ;;
    "check")
        echo "    Checking test-project v0.1.0 (/tmp/test-project)"
        echo "    Finished dev [unoptimized + debuginfo] target(s) in 0.67s"
        if [[ "$MOCK_MODE" == "fail" ]]; then
            echo "error: could not compile test-project"
            echo "error: aborting due to previous error"
            return 1
        fi
        return 0
        ;;
    "clippy")
        echo "    Checking test-project v0.1.0 (/tmp/test-project)"
        echo "    Finished dev [unoptimized + debuginfo] target(s) in 1.45s"
        if [[ "$MOCK_MODE" == "fail" ]]; then
            echo "warning: function is never used: \`unused_function\`"
            echo "  --> src/main.rs:5:4"
            echo "   |"
            echo "5 | fn unused_function() {"
            echo "   |    ^^^^^^^^^^^^^^^"
            echo "   |"
            echo "   = note: #[warn(dead_code)] on by default"
            return 0  # Clippy warnings are not failures by default
        fi
        return 0
        ;;
    "fmt")
        case "$2" in
            "--check")
                echo "Diff in src/main.rs at line 1:"
                echo "-fn main() {"
                echo "+fn main() {"
                if [[ "$MOCK_MODE" == "fail" ]]; then
                    return 1
                fi
                ;;
            "")
                echo "1 file formatted"
                ;;
            *)
                echo "Formatting files..."
                ;;
        esac
        return 0
        ;;
    "doc")
        echo " Documenting test-project v0.1.0 (/tmp/test-project)"
        echo "    Finished dev [unoptimized + debuginfo] target(s) in 1.23s"
        echo "Generated documentation in target/doc/"
        return 0
        ;;
    "clean")
        echo "    Removed 15 files, 2 directories"
        return 0
        ;;
    "install")
        echo "    Updating crates.io index"
        echo "   Installing test-project v0.1.0"
        echo "    Updating crates.io index"
        echo "    Installed package \`test-project v0.1.0\` (executable \`test-project\`)"
        return 0
        ;;
    "publish")
        if [[ "$MOCK_MODE" == "fail" ]]; then
            echo "error: failed to publish to registry"
            echo "Caused by:"
            echo "  the remote server responded with an error: 403 Forbidden"
            return 1
        fi
        echo "    Updating crates.io index"
        echo "   Packaging test-project v0.1.0"
        echo "   Packaged 15 files, 1.2MiB (2.1MiB compressed)"
        echo "   Uploading test-project v0.1.0"
        echo "    Uploaded test-project v0.1.0 to registry"
        echo "note: waiting for a job to become available..."
        echo "    Published test-project v0.1.0 at registry"
        return 0
        ;;
    "update")
        echo "    Updating crates.io index"
        return 0
        ;;
    "search")
        echo "Searching crates.io for \"$2\""
        echo "test-package = \"0.1.0\""
        echo "Another package = \"1.2.3\""
        return 0
        ;;
    "init")
        echo "     Created binary (application) package"
        echo "See \`cargo help init\` for more information."
        return 0
        ;;
    "new")
        echo "     Created binary (application) \`${2}\` package"
        return 0
        ;;
    "add")
        echo "      Adding serde to dependencies."
        echo "      Adding features [\"derive\"] to serde."
        return 0
        ;;
    "remove"|"rm")
        echo "    Removing serde from dependencies"
        return 0
        ;;
    "tree")
        echo "test-project v0.1.0 (/tmp/test-project)"
        echo "└── serde v1.0.163"
        echo "    ├── serde_derive v1.0.163 (proc-macro)"
        echo "    └── serde_json v1.0.96"
        return 0
        ;;
    "metadata")
        echo "{"
        echo "  \"name\": \"test-project\","
        echo "  \"version\": \"0.1.0\","
        echo "  \"dependencies\": {"
        echo "    \"serde\": \"1.0.163\""
        echo "  }"
        echo "}"
        return 0
        ;;
    "login")
        echo "    Login successful"
        return 0
        ;;
    "logout")
        echo "    Logged out successfully"
        return 0
        ;;
    "owner")
        case "$2" in
            "list")
                echo "Owner list for test-project:"
                echo "testuser"
                ;;
            "add")
                echo "    Added testuser2 as an owner"
                ;;
            "remove")
                echo "    Removed testuser2 as an owner"
                ;;
            *)
                echo "owner $2"
                ;;
        esac
        return 0
        ;;
    "yank")
        echo "    Yanked test-project v0.1.0 from crates.io"
        return 0
        ;;
    "unyank")
        echo "    Unyanked test-project v0.1.0 from crates.io"
        return 0
        ;;
    "bench")
        echo "   Compiling test-project v0.1.0 (/tmp/test-project)"
        echo "    Finished release [optimized] target(s) in 2.34s"
        echo "     Running unittests"
        echo "test test::bench_test ... bench: 1,234 ns/iter (+/- 123)"
        return 0
        ;;
    "audit")
        if [[ "$MOCK_MODE" == "fail" ]]; then
            echo "warning: 1 vulnerability found"
            echo "  ID: RUSTSEC-2023-1234"
            echo "  Crate: old-crate"
            echo "  Version: 0.1.0"
            echo "  Advisory: https://rustsec.org/advisories/RUSTSEC-2023-1234"
            return 0  # Audit warnings are not failures
        fi
        echo "Success! No vulnerable packages found"
        return 0
        ;;
    "deny")
        if [[ "$MOCK_MODE" == "fail" ]]; then
            echo "error: found 1 duplicate dependencies"
            echo "└─ log v0.4.17"
            echo "  └─ log v0.4.14"
            return 1
        fi
        echo "success: no duplicate dependencies found"
        return 0
        ;;
    "outdated")
        echo "Package     Current  Latest"
        echo "serde       1.0.163  1.0.164"
        echo "serde_json  1.0.96   1.0.97"
        return 0
        ;;
    "profile")
        echo "Profiler started"
        return 0
        ;;
    "expand")
        echo "#![feature(prelude_import)]"
        echo "#[prelude_import]"
        echo "use std::prelude::rust_2021::*;"
        return 0
        ;;
    "udeps")
        if [[ "$MOCK_MODE" == "fail" ]]; then
            echo "unused dependencies:"
            echo "└── feature_check v0.1.0 (unused)"
            return 0
        fi
        echo "All dependencies seem to be used."
        return 0
        ;;
    "config")
        if [[ "$2" == "get" ]]; then
            echo "build.target-dir = \"target\""
        elif [[ "$2" == "set" ]]; then
            echo "Set $3 to $4"
        else
            echo "Configuration"
        fi
        return 0
        ;;
    "help")
        echo "cargo <command>"
        echo ""
        echo "Common cargo commands:"
        echo "    build, b        Compile the current package"
        echo "    check, c        Analyze the current package and report errors, but don't build object files"
        echo "    clean           Remove the target directory"
        echo "    doc, d          Build this package's documentation"
        echo "    new             Create a new cargo package"
        echo "    init            Create a new cargo package in an existing directory"
        echo "    run, r          Run a binary or example of the local package"
        echo "    test, t         Run the tests"
        echo "    benchmark       Run the benchmarks"
        echo "    update          Update dependencies listed in Cargo.lock"
        return 0
        ;;
    *)
        echo "error: no such subcommand: \`$1\`"
        echo "Did you mean \`build\`?"
        return 1
        ;;
esac
EOF

    chmod +x "$mock_bin/cargo"
}

# Create go mock with comprehensive functionality
create_go_mock() {
    local mock_bin="${1:-$BATS_TEST_TMPDIR/bin}"
    local mock_mode="${2:-success}"

    mkdir -p "$mock_bin"

    cat > "$mock_bin/go" << 'EOF'
#!/bin/bash
# Comprehensive go mock for testing

# Default behavior
MOCK_MODE="${GO_MOCK_MODE:-success}"
MOCK_VERSION="${GO_MOCK_VERSION:-go version go1.21.5 linux/amd64}"

# Handle go commands
case "$1" in
    "version")
        echo "$MOCK_VERSION"
        return 0
        ;;
    "mod")
        case "$2" in
            "init")
                echo "go: creating new go.mod: module github.com/example/test-project"
                echo "go: to add module requirements and sums:"
                echo "        go mod tidy"
                return 0
                ;;
            "tidy")
                echo "go: finding module for path github.com/gin-gonic/gin"
                echo "go: found github.com/gin-gonic/gin in github.com/gin-gonic/gin v1.9.1"
                echo "go: downloading github.com/gin-gonic/gin v1.9.1"
                echo "go: added github.com/gin-gonic/gin v1.9.1"
                return 0
                ;;
            "download")
                if [[ "$MOCK_MODE" == "fail" ]]; then
                    echo "go: module github.com/example/nonexistent@latest: no such module"
                    return 1
                fi
                echo "go: downloading github.com/gin-gonic/gin v1.9.1"
                echo "go: added github.com/gin-gonic/gin v1.9.1"
                return 0
                ;;
            "verify")
                if [[ "$MOCK_MODE" == "fail" ]]; then
                    echo "go: github.com/gin-gonic/gin@v1.9.1: verification failed"
                    echo "go: checksum mismatch"
                    return 1
                fi
                echo "go: verifying module github.com/gin-gonic/gin@v1.9.1"
                echo "go: checksum verified"
                return 0
                ;;
            "why")
                echo "# github.com/example/test-project"
                echo "github.com/example/test-project"
                echo "github.com/gin-gonic/gin"
                return 0
                ;;
            "graph")
                echo "github.com/example/test-project"
                echo "github.com/gin-gonic/gin@v1.9.1"
                echo "github.com/gin-contrib/sse@v0.1.0"
                return 0
                ;;
            "edit")
                echo "go: editing requirements"
                return 0
                ;;
            "vendor")
                echo "go: creating vendor directory"
                return 0
                ;;
            *)
                echo "go mod $2"
                return 0
                ;;
        esac
        ;;
    "build")
        echo "github.com/example/test-project"
        if [[ "$MOCK_MODE" == "fail" ]]; then
            echo "# github.com/example/test-project"
            echo "main.go:5:2: syntax error: unexpected newline, expecting comma or }"
            return 1
        fi
        return 0
        ;;
    "run")
        shift
        echo "Hello, world!"
        if [[ -n "$*" ]]; then
            echo "Arguments: $*"
        fi
        return 0
        ;;
    "test")
        case "$2" in
            "-v"|"--verbose")
                echo "=== RUN   TestExample"
                echo "--- PASS: TestExample (0.00s)"
                echo "PASS"
                echo "ok      github.com/example/test-project    0.002s"
                ;;
            "-cover"|"--cover")
                echo "ok      github.com/example/test-project    0.002s  coverage: 80.0% of statements"
                ;;
            "-race")
                echo "=== RUN   TestExample"
                echo "--- PASS: TestExample (0.00s)"
                echo "PASS"
                echo "ok      github.com/example/test-project    0.012s  race enabled"
                ;;
            "-bench=.")
                echo "goos: linux"
                echo "goarch: amd64"
                echo "pkg: github.com/example/test-project"
                echo "cpu: Intel(R) Core(TM) i7-9750H CPU @ 2.60GHz"
                echo "BenchmarkExample-8   	  123456	      9456 ns/op"
                echo "PASS"
                ;;
            *)
                echo "ok      github.com/example/test-project    0.002s"
                ;;
        esac
        return 0
        ;;
    "install")
        if [[ "$MOCK_MODE" == "fail" ]]; then
            echo "go: build errors: no go files in /tmp"
            return 1
        fi
        echo "go: downloading github.com/example/test-project"
        echo "go: install github.com/example/test-project"
        return 0
        ;;
    "get")
        echo "go: downloading github.com/gin-gonic/gin v1.9.1"
        echo "go: added github.com/gin-gonic/gin v1.9.1"
        return 0
        ;;
    "clean")
        echo "cleaned cache"
        return 0
        ;;
    "fmt")
        case "$2" in
            "-l"|"--list")
                # In list mode, return files that need formatting
                if [[ "$MOCK_MODE" == "fail" ]]; then
                    echo "main.go"
                    return 1
                fi
                return 0
                ;;
            "-d"|"--diff")
                if [[ "$MOCK_MODE" == "fail" ]]; then
                    echo "diff -u main.go.orig main.go"
                    echo "--- main.go.orig"
                    echo "+++ main.go"
                    echo "@@ -1,3 +1,3 @@"
                    echo "-fmt.Println(\"hello\")"
                    echo "+fmt.Println(\"hello\")"
                    return 1
                fi
                return 0
                ;;
            "-w"|"--write")
                if [[ -f "main.go" ]]; then
                    echo "main.go"
                fi
                return 0
                ;;
            "")
                echo "main.go"
                ;;
            *)
                echo "go fmt $*"
                ;;
        esac
        return 0
        ;;
    "vet")
        if [[ "$MOCK_MODE" == "fail" ]]; then
            echo "# github.com/example/test-project"
            echo "main.go:10:2: Printf call needs arguments"
            return 1
        fi
        return 0
        ;;
    "tool")
        case "$2" in
            "cover")
                case "$3" in
                    "-html="*)
                        echo "coverage: 80.0% of statements"
                        ;;
                    "-func="*)
                        echo "main.go:10:    Example    100.0%"
                        ;;
                    "-mode=count"|"count")
                        echo "mode: count"
                        echo "github.com/example/test-project/main.go:10.32,15.2 1 1"
                        ;;
                    *)
                        echo "go tool cover $*"
                        ;;
                esac
                ;;
            "pprof")
                echo "Profile generated"
                ;;
            "trace")
                echo "Trace generated"
                ;;
            "compile")
                echo "Compilation complete"
                ;;
            "link")
                echo "Linking complete"
                ;;
            "fix")
                echo "Fixed imports"
                ;;
            *)
                echo "go tool $*"
                ;;
        esac
        return 0
        ;;
    "doc")
        echo "package main // import \"github.com/example/test-project\""
        echo ""
        echo "func main()"
        echo "    main is the entry point of the application."
        return 0
        ;;
    "list")
        echo "github.com/example/test-project"
        return 0
        ;;
    "generate")
        echo "main.go"
        return 0
        ;;
    "work")
        case "$2" in
            "init")
                echo "go: creating go work in /tmp/test-project"
                ;;
            "use")
                echo "go: using ./module1"
                ;;
            "sync")
                echo "go: downloading modules"
                ;;
            *)
                echo "go work $*"
                ;;
        esac
        return 0
        ;;
    "env")
        case "$2" in
            "GOPATH")
                echo "/home/user/go"
                ;;
            "GOROOT")
                echo "/usr/local/go"
                ;;
            "GOMODCACHE")
                echo "/home/user/go/pkg/mod"
                ;;
            "")
                echo "GO111MODULE=\"on\""
                echo "GOARCH=\"amd64\""
                echo "GOBIN=\"/home/user/go/bin\""
                echo "GOCACHE=\"/home/user/.cache/go-build\""
                echo "GOENV=\"/home/user/.config/go/env\""
                echo "GOEXE=\"\""
                echo "GOEXPERIMENT=\"\""
                echo "GOFLAGS=\"\""
                echo "GOHOSTARCH=\"amd64\""
                echo "GOHOSTOS=\"linux\""
                echo "GOINSECURE=\"\""
                echo "GOMOD=\"/tmp/test-project/go.mod\""
                echo "GOMODCACHE=\"/home/user/go/pkg/mod\""
                echo "GONOPROXY=\"\""
                echo "GONOSUMDB=\"\""
                echo "GOOS=\"linux\""
                echo "GOPATH=\"/home/user/go\""
                echo "GOPRIVATE=\"\""
                echo "GOPROXY=\"https://proxy.golang.org,direct\""
                echo "GOROOT=\"/usr/local/go\""
                echo "GOSUMDB=\"sum.golang.org\""
                echo "GOTMPDIR=\"\""
                echo "GOTOOLDIR=\"/usr/local/go/pkg/tool/linux_amd64\""
                echo "GOVCS=\"\""
                echo "GOWORK=\"\""
                ;;
            *)
                echo "GO$2=VALUE"
                ;;
        esac
        return 0
        ;;
    "version")
        echo "$MOCK_VERSION"
        return 0
        ;;
    "help")
        echo "Go is a tool for managing Go source code."
        echo ""
        echo "Usage:"
        echo ""
        echo "        go <command> [arguments]"
        echo ""
        echo "The commands are:"
        echo ""
        echo "        bug         start a bug report"
        echo "        build       compile packages and dependencies"
        echo "        clean       remove object files and cached files"
        echo "        doc         show documentation for package or symbol"
        echo "        env         print Go environment information"
        echo "        fix         update packages to use new APIs"
        echo "        fmt         gofmt (reformat) package sources"
        echo "        generate    generate Go files by processing source"
        echo "        get         add dependencies to current module and install them"
        echo "        install     compile and install packages and dependencies"
        echo "        list        list packages or modules"
        echo "        mod         module maintenance"
        echo "        work        workspace maintenance"
        echo "        run         compile and run Go program"
        echo "        test        test packages"
        echo "        tool        run specified go tool"
        echo "        version     print Go version"
        echo "        vet         report likely mistakes in packages"
        return 0
        ;;
    *)
        echo "go: unknown command \"$1\""
        echo "Run 'go help' for usage."
        return 1
        ;;
esac
EOF

    chmod +x "$mock_bin/go"
}

# Create maven mock with comprehensive functionality
create_maven_mock() {
    local mock_bin="${1:-$BATS_TEST_TMPDIR/bin}"
    local mock_mode="${2:-success}"

    mkdir -p "$mock_bin"

    cat > "$mock_bin/mvn" << 'EOF'
#!/bin/bash
# Comprehensive maven mock for testing

# Default behavior
MOCK_MODE="${MVN_MOCK_MODE:-success}"
MOCK_VERSION="${MVN_MOCK_VERSION:-Apache Maven 3.9.5}"

# Handle maven commands
case "$1" in
    "--version")
        echo "$MOCK_VERSION"
        echo "Maven home: /usr/share/maven"
        echo "Java version: 11.0.16, vendor: Ubuntu, runtime: /usr/lib/jvm/java-11-openjdk-amd64"
        echo "Default locale: en_US, platform encoding: UTF-8"
        echo "OS name: \"linux\", version: \"5.15.0-91-generic\", arch: \"amd64\", family: \"unix\""
        return 0
        ;;
    "compile")
        echo "[INFO] Scanning for projects..."
        echo "[INFO] ------------------------------------------------------------------------"
        echo "[INFO] Reactor Build Order:"
        echo "[INFO]"
        echo "[INFO] test-project                                   [jar]"
        echo "[INFO] ------------------------------------------------------------------------"
        echo "[INFO]"
        echo "[INFO] --- test-project:1.0-SNAPSHOT ---"
        echo "[INFO] Compiling 5 source files to /tmp/test-project/target/classes"
        echo "[INFO] ------------------------------------------------------------------------"
        echo "[INFO] BUILD SUCCESS"
        echo "[INFO] ------------------------------------------------------------------------"
        echo "[INFO] Total time:  2.456 s"
        echo "[INFO] Finished at: 2023-11-22T10:30:00Z"
        echo "[INFO] ------------------------------------------------------------------------"
        if [[ "$MOCK_MODE" == "fail" ]]; then
            echo "[ERROR] COMPILATION ERROR : "
            echo "[INFO] -------------------------------------------------------------"
            echo "[ERROR] /tmp/test-project/src/main/java/com/example/App.java:[8,39] error: cannot find symbol"
            echo "[ERROR]   symbol:   method println(String)"
            echo "[ERROR]   location: variable out of type PrintStream"
            return 1
        fi
        return 0
        ;;
    "test")
        echo "[INFO] Scanning for projects..."
        echo "[INFO] ------------------------------------------------------------------------"
        echo "[INFO]"
        echo "[INFO] --- test-project:1.0-SNAPSHOT ---"
        echo "[INFO]"
        echo "[INFO] -------------------------------------------------------"
        echo "[INFO]  T E S T S"
        echo "[INFO] -------------------------------------------------------"
        echo "[INFO] Running com.example.AppTest"
        echo "[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.567 s - in com.example.AppTest"
        echo "[INFO]"
        echo "[INFO] Results:"
        echo "[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0"
        echo "[INFO] ------------------------------------------------------------------------"
        echo "[INFO] BUILD SUCCESS"
        echo "[INFO] ------------------------------------------------------------------------"
        if [[ "$MOCK_MODE" == "fail" ]]; then
            echo "[ERROR] Tests run: 1, Failures: 1, Errors: 0, Skipped: 0"
            echo "[ERROR] Failure in testShouldAnswerWithTrue(com.example.AppTest)"
            echo "[ERROR] Expected:<true> but was:<false>"
            return 1
        fi
        return 0
        ;;
    "package")
        echo "[INFO] Scanning for projects..."
        echo "[INFO]"
        echo "[INFO] --- test-project:1.0-SNAPSHOT ---"
        echo "[INFO] Building jar: /tmp/test-project/target/test-project-1.0-SNAPSHOT.jar"
        echo "[INFO] Building jar: /tmp/test-project/target/test-project-1.0-SNAPSHOT-sources.jar"
        echo "[INFO] ------------------------------------------------------------------------"
        echo "[INFO] BUILD SUCCESS"
        echo "[INFO] ------------------------------------------------------------------------"
        return 0
        ;;
    "install")
        echo "[INFO] Scanning for projects..."
        echo "[INFO]"
        echo "[INFO] --- test-project:1.0-SNAPSHOT ---"
        echo "[INFO] Installing /tmp/test-project/target/test-project-1.0-SNAPSHOT.jar to ~/.m2/repository/com/example/test-project/1.0-SNAPSHOT/test-project-1.0-SNAPSHOT.jar"
        echo "[INFO] Installing /tmp/test-project/pom.xml to ~/.m2/repository/com/example/test-project/1.0-SNAPSHOT/test-project-1.0-SNAPSHOT.pom"
        echo "[INFO] ------------------------------------------------------------------------"
        echo "[INFO] BUILD SUCCESS"
        echo "[INFO] ------------------------------------------------------------------------"
        return 0
        ;;
    "deploy")
        echo "[INFO] Scanning for projects..."
        echo "[INFO]"
        echo "[INFO] --- test-project:1.0-SNAPSHOT ---"
        echo "[INFO] Uploading to repository: https://repo.maven.apache.org/maven2"
        echo "[INFO] Uploading: https://repo.maven.apache.org/maven2/com/example/test-project/1.0-SNAPSHOT/test-project-1.0-SNAPSHOT.jar"
        echo "[INFO] ------------------------------------------------------------------------"
        echo "[INFO] BUILD SUCCESS"
        echo "[INFO] ------------------------------------------------------------------------"
        if [[ "$MOCK_MODE" == "fail" ]]; then
            echo "[ERROR] Failed to execute goal org.apache.maven.plugins:maven-deploy-plugin:3.0.0:deploy (default-deploy) on project test-project: Failed to deploy artifacts: Could not transfer artifact com.example:test-project:jar:1.0-SNAPSHOT from/to central (https://repo.maven.apache.org/maven2): Failed to transfer file: https://repo.maven.apache.org/maven2/com/example/test-project/1.0-SNAPSHOT/test-project-1.0-SNAPSHOT.jar. Return code is: 401"
            return 1
        fi
        return 0
        ;;
    "clean")
        echo "[INFO] Scanning for projects..."
        echo "[INFO]"
        echo "[INFO] --- test-project:1.0-SNAPSHOT ---"
        echo "[INFO] Deleting /tmp/test-project/target"
        echo "[INFO] ------------------------------------------------------------------------"
        echo "[INFO] BUILD SUCCESS"
        echo "[INFO] ------------------------------------------------------------------------"
        return 0
        ;;
    "validate")
        echo "[INFO] Scanning for projects..."
        echo "[INFO]"
        echo "[INFO] --- test-project:1.0-SNAPSHOT ---"
        echo "[INFO] ------------------------------------------------------------------------"
        echo "[INFO] BUILD SUCCESS"
        echo "[INFO] ------------------------------------------------------------------------"
        return 0
        ;;
    "verify")
        echo "[INFO] Scanning for projects..."
        echo "[INFO]"
        echo "[INFO] --- test-project:1.0-SNAPSHOT ---"
        echo "[INFO] ------------------------------------------------------------------------"
        echo "[INFO] BUILD SUCCESS"
        echo "[INFO] ------------------------------------------------------------------------"
        return 0
        ;;
    "site")
        echo "[INFO] Scanning for projects..."
        echo "[INFO]"
        echo "[INFO] --- test-project:1.0-SNAPSHOT ---"
        echo "[INFO] Generating project in English..."
        echo "[INFO] ------------------------------------------------------------------------"
        echo "[INFO] BUILD SUCCESS"
        echo "[INFO] ------------------------------------------------------------------------"
        return 0
        ;;
    "dependency:"*)
        case "$1" in
            "dependency:resolve")
                echo "[INFO] Scanning for projects..."
                echo "[INFO]"
                echo "[INFO] --- test-project:1.0-SNAPSHOT ---"
                echo "[INFO]"
                echo "[INFO] Dependencies resolved:"
                echo "[INFO] junit:junit:jar:4.13.2:test"
                echo "[INFO] ------------------------------------------------------------------------"
                echo "[INFO] BUILD SUCCESS"
                echo "[INFO] ------------------------------------------------------------------------"
                ;;
            "dependency:tree")
                echo "[INFO] Scanning for projects..."
                echo "[INFO]"
                echo "[INFO] --- test-project:1.0-SNAPSHOT ---"
                echo "[INFO] com.example:test-project:jar:1.0-SNAPSHOT"
                echo "[INFO] +- junit:junit:jar:4.13.2:test"
                echo "[INFO] \\- org.hamcrest:hamcrest-core:jar:1.3:test"
                echo "[INFO] ------------------------------------------------------------------------"
                echo "[INFO] BUILD SUCCESS"
                echo "[INFO] ------------------------------------------------------------------------"
                ;;
            "dependency:list")
                echo "[INFO] Scanning for projects..."
                echo "[INFO]"
                echo "[INFO] --- test-project:1.0-SNAPSHOT ---"
                echo "[INFO]"
                echo "[INFO] The following files have been resolved:"
                echo "[INFO]    junit:junit:jar:4.13.2:compile"
                echo "[INFO]    org.hamcrest:hamcrest-core:jar:1.3:test"
                echo "[INFO] ------------------------------------------------------------------------"
                echo "[INFO] BUILD SUCCESS"
                echo "[INFO] ------------------------------------------------------------------------"
                ;;
            "dependency:analyze")
                echo "[INFO] Scanning for projects..."
                echo "[INFO]"
                echo "[INFO] --- test-project:1.0-SNAPSHOT ---"
                echo "[INFO] Dependency Analysis:"
                echo "[INFO] Used undeclared dependencies found:"
                echo "[INFO]    junit:junit:jar:4.13.2:test"
                echo "[INFO] Unused declared dependencies found:"
                echo "[INFO]    org.hamcrest:hamcrest-core:jar:1.3:test"
                echo "[INFO] ------------------------------------------------------------------------"
                echo "[INFO] BUILD SUCCESS"
                echo "[INFO] ------------------------------------------------------------------------"
                ;;
            *)
                echo "dependency command: $*"
                ;;
        esac
        return 0
        ;;
    "help")
        if [[ -n "$2" ]]; then
            echo "Help for goal: $2"
            echo "Description: $2 description"
            echo "Parameters:"
            echo "  -Darg=arg1    Parameter description"
        else
            echo "$MOCK_VERSION"
            echo "Maven home: /usr/share/maven"
            echo "Java version: 11.0.16, vendor: Ubuntu, runtime: /usr/lib/jvm/java-11-openjdk-amd64"
            echo ""
            echo "Usage: mvn <options> <goal> [<phase> [<phase> ...]]"
            echo ""
            echo "Options:"
            echo "  -am,--also-make                        If project list is specified, also build projects required by the list"
            echo "  -amd,--also-make-dependents            If project list is specified, also build projects that depend on projects on the list"
            echo "  -B,--batch-mode                        Run in non-interactive (batch) mode"
            echo "  -b,--builder <arg>                     The id of the build strategy to use"
            echo "  -C,--strict-checksums                  Fail the build if checksums don't match"
            echo "  -c,--lax-checksums                     Warn if checksums don't match"
            echo "  -cpu,--check-plugin-updates           Ineffective, only kept for backward compatibility"
            echo "  -D,--define <arg>                      Define a system property"
            echo "  -e,--errors                             Produce execution error messages"
            echo "  -emp,--encrypt-master-password <arg>    Encrypt master security password"
            echo "  -ep,--encrypt-password <arg>            Encrypt server password"
            echo "  -f,--file <arg>                        Force the use of an alternate POM file (or directory with pom.xml)"
            echo "  -fae,--fail-at-end                      Only fail the build afterwards; allow all non-impacted builds to continue"
            echo "  -ff,--fail-fast                         Stop at first failure in reactorized builds"
            echo "  -fn,--fail-never                        NEVER fail the build, regardless of project result"
            echo "  -gs,--global-settings <arg>             Alternate path for the global settings file"
            echo "  -gt,--global-toolchains <arg>           Alternate path for the global toolchains file"
            echo "  -h,--help                               Display help information"
            echo "  -l,--log-file <arg>                     Log to a file"
            echo "  -ll,--legacy-local-repository           Use Maven 2 legacy local repository behaviour, i.e. use a repository-based layout"
            echo "  -N,--non-recursive                      Do not recurse into sub-projects"
            echo "  -npr,--no-plugin-registry               Ineffective, only kept for backward compatibility"
            echo "  -npu,--no-plugin-updates                Ineffective, only kept for backward compatibility"
            echo "  -nsu,--no-snapshot-updates              Suppress SNAPSHOT updates"
            echo "  -o,--offline                             Work offline"
            echo "  -P,--activate-profiles <arg>            Comma-delimited list of profiles to activate"
            echo "  -pl,--projects <arg>                    Build specified reactor projects instead of all projects"
            echo "  -q,--quiet                              Quiet output - only show errors"
            echo "  -r,--reactor                            Build down the reactor"
            echo "  -rf,--resume-from <arg>                 Resume reactor from specified project"
            echo "  -s,--settings <arg>                     Alternate path for the user settings file"
            echo "  -t,--toolchains <arg>                   Alternate path for the user toolchains file"
            echo "  -T,--threads <arg>                      Thread count, for instance 2.0C where C is core count"
            echo "  -U,--update-snapshots                  Forces the use of updated releases for snapshot dependencies"
            echo "  -up,--update-plugins                    Ineffective, only kept for backward compatibility"
            echo "  -v,--version                            Display version information"
            echo "  -V,--show-version                       Display version information WITHOUT stopping build"
            echo "  -X,--debug                              Produce execution debug output"
            echo ""
            echo "Standard Lifecycle Phases:"
            echo "  validate                                - validate the project is correct and all necessary information is available"
            echo "  compile                                 - compile the source code of the project"
            echo "  test                                    - test the compiled source code using a suitable unit testing framework"
            echo "  package                                 - take the compiled code and package it in its distributable format"
            echo "  verify                                  - run any checks to verify the package is valid and meets quality criteria"
            echo "  install                                 - install the package into the local repository"
            echo "  deploy                                  - copy the final package to the remote repository"
            echo ""
            echo "See also:"
            echo "  Maven User Guide: https://maven.apache.org/guides/index.html"
            echo "  Maven Reference: https://maven.apache.org/ref/3.9.5/"
            echo "  Maven Plugin Developer Center: https://maven.apache.org/plugins/"
            echo "  Maven Versions: https://maven.apache.org/versions.html"
            echo "  Maven邮件列表 (Chinese): https://maven.apache.org/mail-lists.html"
            echo "  Maven Slack: https://maven.apache.org/slack.html"
        fi
        return 0
        ;;
    *)
        echo "Unknown Maven command: $1"
        echo "Run 'mvn help' for usage information"
        return 1
        ;;
esac
EOF

    chmod +x "$mock_bin/mvn"
}

# Create gradle mock with comprehensive functionality
create_gradle_mock() {
    local mock_bin="${1:-$BATS_TEST_TMPDIR/bin}"
    local mock_mode="${2:-success}"

    mkdir -p "$mock_bin"

    cat > "$mock_bin/gradle" << 'EOF'
#!/bin/bash
# Comprehensive gradle mock for testing

# Default behavior
MOCK_MODE="${GRADLE_MOCK_MODE:-success}"
MOCK_VERSION="${GRADLE_MOCK_VERSION:-Gradle 8.5}"

# Handle gradle commands
case "$1" in
    "--version")
        echo "$MOCK_VERSION"
        echo ""
        echo "Build time:   2023-11-22 00:00:00 UTC"
        echo "Revision:     unknown"
        echo ""
        echo "Kotlin:       1.9.10"
        echo "Groovy:       3.0.17"
        echo "Ant:          Apache Ant(TM) version 1.10.12 compiled on October 13 2022"
        echo "JVM:          11.0.16 (Ubuntu 11.0.16+8-post-Ubuntu-0ubuntu122.04)"
        echo "OS:           Linux 5.15.0-91-generic amd64"
        return 0
        ;;
    "build")
        echo "Configuration on demand is an incubating feature."
        echo "Gradle Daemon started"
        echo "Starting a Gradle Daemon"
        echo ""
        echo "> Task :compileJava"
        echo "Note: /tmp/test-project/src/main/java/com/example/App.java uses or overrides a deprecated API."
        echo "Note: Recompile with -Xlint:deprecation for details."
        echo ""
        echo "> Task :processResources"
        echo "NO-SOURCE"
        echo ""
        echo "> Task :classes"
        echo ""
        echo "> Task :jar"
        echo ""
        echo "> Task :assemble"
        echo ""
        echo "> Task :compileTestJava"
        echo "Note: /tmp/test-project/src/test/java/com/example/AppTest.java uses or overrides a deprecated API."
        echo "Note: Recompile with -Xlint:deprecation for details."
        echo ""
        echo "> Task :processTestResources"
        echo "NO-SOURCE"
        echo ""
        echo "> Task :testClasses"
        echo ""
        echo "> Task :test"
        echo ""
        echo "BUILD SUCCESSFUL in 5s"
        echo "5 actionable tasks: 5 executed"
        if [[ "$MOCK_MODE" == "fail" ]]; then
            echo ""
            echo "FAILURE: Build failed with an exception."
            echo ""
            echo "* What went wrong:"
            echo "Execution failed for task ':compileJava'."
            echo "> Could not resolve all files for configuration ':compileClasspath'."
            echo "   > Could not find junit:junit:4.13.2."
            echo ""
            echo "* Try:"
            echo "> Run with --stacktrace option to get the stack trace."
            echo "> Run with --info or --debug option to get more log output."
            echo "> Run with --scan to get full insights."
            echo ""
            echo "* Get more help at https://help.gradle.org"
            echo ""
            echo "BUILD FAILED in 2s"
            return 1
        fi
        return 0
        ;;
    "test")
        echo "Configuration on demand is an incubating feature."
        echo ""
        echo "> Task :test"
        echo ""
        echo "BUILD SUCCESSFUL in 2s"
        echo "1 actionable task: 1 executed"
        if [[ "$MOCK_MODE" == "fail" ]]; then
            echo ""
            echo "test.AppTest > testShouldAnswerWithTrue FAILED"
            echo "    org.opentest4j.AssertionFailedError at AppTest.java:15"
            echo ""
            echo "1 test completed, 1 failed"
            echo ""
            echo "FAILURE: Build failed with an exception."
            return 1
        fi
        return 0
        ;;
    "compileJava")
        echo "> Task :compileJava"
        echo "Note: Some input files use or override a deprecated API."
        echo "Note: Recompile with -Xlint:deprecation for details."
        echo ""
        echo "BUILD SUCCESSFUL in 1s"
        echo "1 actionable task: 1 executed"
        if [[ "$MOCK_MODE" == "fail" ]]; then
            echo ""
            echo "FAILURE: Build failed with an exception."
            echo "> Could not resolve all files for configuration ':compileClasspath'."
            return 1
        fi
        return 0
        ;;
    "jar")
        echo "> Task :jar"
        echo ""
        echo "BUILD SUCCESSFUL in 500ms"
        echo "1 actionable task: 1 executed"
        return 0
        ;;
    "clean")
        echo "> Task :clean"
        echo ""
        echo "BUILD SUCCESSFUL in 100ms"
        echo "1 actionable task: 1 executed"
        return 0
        ;;
    "assemble")
        echo "> Task :assemble"
        echo ""
        echo "BUILD SUCCESSFUL in 1s"
        echo "1 actionable task: 1 executed"
        return 0
        ;;
    "dependencies")
        echo ""
        echo "runtimeClasspath - Runtime classpath of source set 'main'."
        echo "+--- org.springframework.boot:spring-boot-starter:3.1.5"
        echo "|    +--- org.springframework.boot:spring-boot:3.1.5 (*)"
        echo "|    +--- org.springframework.boot:spring-boot-autoconfigure:3.1.5 (*)"
        echo "|    +--- org.springframework.boot:spring-boot-starter-logging:3.1.5 (*)"
        echo "\\--- junit:junit:4.13.2"
        echo "     \\--- org.hamcrest:hamcrest-core:1.3"
        echo ""
        echo "testCompileClasspath - Compile classpath for source set 'test'."
        echo "+--- org.springframework.boot:spring-boot-starter-test:3.1.5"
        echo "|    +--- org.springframework.boot:spring-boot-starter:3.1.5 (*)"
        echo "\\--- junit:junit:4.13.2 (*)"
        echo ""
        echo "(*) - dependencies omitted (listed previously)"
        return 0
        ;;
    "projects")
        echo ""
        echo "Root project"
        echo "subproject1"
        echo "subproject2"
        return 0
        ;;
    "tasks")
        echo ""
        echo "Tasks runnable from root project"
        echo ""
        echo "Application tasks"
        echo "------------------"
        echo "run - Runs this project as a JVM application"
        echo ""
        echo "Build tasks"
        echo "-----------"
        echo "assemble - Assembles the outputs of this project."
        echo "build - Assembles and tests this project."
        echo "clean - Deletes the build directory."
        echo "jar - Assembles a jar archive containing the main classes."
        echo ""
        echo "Build Setup tasks"
        echo "-----------------"
        echo "init - Initializes a new Gradle build."
        echo "wrapper - Generates Gradle wrapper files."
        echo ""
        echo "Documentation tasks"
        echo "--------------------"
        echo "javadoc - Generates Javadoc API documentation for the main source code."
        echo ""
        echo "Help tasks"
        echo "----------"
        echo "buildEnvironment - Displays all buildscript dependencies declared in root project."
        echo "dependencies - Displays all dependencies declared in root project."
        echo "dependencyInsight - Displays the insight into a specific dependency in root project."
        echo "help - Displays a help message."
        echo "javaToolchains - Displays the detected java toolchains."
        echo "projects - Displays the sub-projects of root project."
        echo "properties - Displays the properties of root project."
        echo "tasks - Displays the tasks runnable from root project."
        echo ""
        echo "Verification tasks"
        echo "-------------------"
        echo "check - Runs all checks."
        echo "test - Runs the unit tests."
        return 0
        ;;
    "run")
        echo "> Task :compileJava"
        echo "> Task :processResources"
        echo "> Task :classes"
        echo "> Task :run"
        echo "Hello, world!"
        return 0
        ;;
    "bootRun")
        echo "> Task :compileJava"
        echo "> Task :processResources"
        echo "> Task :classes"
        echo "> Task :bootRun"
        echo "  .   ____          _            __ _ _"
        echo " /\\\\ / ___'_ __ _ _(_)_ __  __ _ \\ \\ \\ \\"
        echo "( ( )\\___ | '_ \\ '_| | '_ \\/ _` | \\ \\ \\ \\"
        echo " \\\\/  ___)| |_)| | | | | || (_| |  ) ) ) )"
        echo "  '  |____| .__|_| |_|_| |_\\__, | / / / /"
        echo " =========|_|==============|___/=/_/_/_/"
        echo " :: Spring Boot ::                (v3.1.5)"
        echo ""
        echo "2023-11-22T10:30:00.000Z  INFO 12345 --- [           main] com.example.App         : Starting App"
        echo "2023-11-22T10:30:00.123Z  INFO 12345 --- [           main] com.example.App         : Started App"
        return 0
        ;;
    "wrapper")
        case "$2" in
            "--gradle-version")
                echo "8.5"
                ;;
            *)
                echo "> Task :wrapper"
                echo "BUILD SUCCESSFUL in 1s"
                echo "1 actionable task: 1 executed"
                ;;
        esac
        return 0
        ;;
    "init")
        echo "Starting a Gradle Daemon (subsequent builds will be faster)"
        echo ""
        echo "Select type of project to generate:"
        echo "  1: basic"
        echo "  2: application"
        echo "  3: library"
        echo "  4: Gradle plugin"
        echo "Enter selection (default: basic) [1..4] 2"
        echo ""
        echo "Select implementation language:"
        echo "  1: Java"
        echo "  2: Kotlin"
        echo "  3: Groovy"
        echo "  4: Scala"
        echo "Enter selection (default: Java) [1..4] 1"
        echo ""
        echo "Split functionality across multiple subprojects? (default: no) [yes, no] no"
        echo ""
        echo "Select build script DSL:"
        echo "  1: Groovy"
        echo "  2: Kotlin"
        echo "Enter selection (default: Groovy) [1..2] 1"
        echo ""
        echo "Select test framework:"
        echo "  1: JUnit 4"
        echo "  2: TestNG"
        echo "  3: Spock"
        echo "  4: JUnit Jupiter"
        echo "Enter selection (default: JUnit 4) [1..4] 1"
        echo ""
        echo "Project name (default: test-project): "
        echo "Source package (default: test.project): com.example"
        echo ""
        echo "BUILD SUCCESSFUL in 3s"
        echo "2 actionable tasks: 2 executed"
        return 0
        ;;
    "help")
        if [[ -n "$2" ]]; then
            echo "Detailed help for task: $2"
            echo ""
            echo "Description:"
            echo "Task description for $2"
            echo ""
            echo "Group:"
            echo "Build tasks"
            echo ""
            echo "Type:"
            echo "Task type: DefaultTask"
            echo ""
            echo "Options:"
            echo "  --option1    Option description"
        else
            echo "$MOCK_VERSION"
            echo ""
            echo "USAGE: gradle [option...] [task...]"
            echo ""
            echo "To run a build using the Gradle wrapper, use the command"
            echo "    ./gradlew <task>"
            echo ""
            echo "To see more detail about a task, run gradle help --task <task>"
            echo ""
            echo "For more detail on using Gradle, see https://docs.gradle.org/8.5/userguide/command_line_interface.html"
            echo ""
            echo "COMMAND OPTIONS"
            echo ""
            echo "  --build-cache                           Enables the Gradle build cache. Gradle will try to reuse outputs from previous builds."
            echo "  --configuration-cache                  Enables the configuration cache. Gradle will try to reuse the build configuration from previous builds."
            echo "  -D, --system-property <key=value>      Sets a system property of the JVM (e.g. -Dmyprop=myvalue)."
            echo "  --no-configuration-cache               Disables the configuration cache."
            echo "  --no-daemon                            Do not use the Gradle daemon to run the build. Useful occasionally when debugging or dealing with subtle build problems."
            echo "  --no-opt                               Ignore any task optimization. Tasks will only be executed if not up-to-date."
            echo "  --no-scan                              Do not create a build scan. For more information about build scans see https://gradle.com/build-scans."
            echo "  --no-watch-fs                          Disables watching the file system."
            echo "  --offline                               Execute the build without accessing network resources. This can be useful in environments with limited network connectivity."
            echo "  -P, --project-prop <key=value>         Sets a project property of the root project (e.g. -Pmyprop=myvalue)."
            echo "  -p, --project-dir <dir>                Specifies the start directory for Gradle. Defaults to the current directory."
            echo "  --parallel                             Build projects in parallel. Gradle will attempt to determine the optimal number of concurrent worker processes to use."
            echo "  --priority                             Defines the priority for the worker process. The options are normal or low"
            echo "  --profile                              Profile the execution of the build and write a report to the build directory."
            echo "  --refresh-dependencies                 Refresh the state of dependencies."
            echo "  --refresh-keys                          Refresh the state of cached keys. Useful for troubleshooting problems with cached keys."
            echo "  --rerun-tasks                          Ignore previously cached task results."
            echo "  --scan                                 Create a build scan. For more information about build scans see https://gradle.com/build-scans."
            echo "  -S, --full-stacktrace                 Print out the full (very verbose) stacktrace for any exceptions."
            echo "  -s, --stacktrace                       Print out the stacktrace for any exceptions."
            echo "  --status                               Shows status of running and recently stopped Gradle Daemon(s)."
            echo "  --stop                                 Stops all running Gradle Daemon(s)."
            echo "  -v, --version                          Print version info."
            echo "  -w, --warn                             Enables logme level warn. "
            echo "  --warning-mode <mode>                  Specifies which mode of warnings to generate. The options are: all, fail, summary, none"
            echo "  --write-locks                          Persists dependency resolution for locked configurations, if any."
            echo ""
            echo "For complete documentation, visit https://docs.gradle.org"
        fi
        return 0
        ;;
    *)
        echo "Unknown Gradle command: $1"
        echo "Run 'gradle help' for usage information"
        return 1
        ;;
esac
EOF

    chmod +x "$mock_bin/gradle"
}

# Create dotnet mock with comprehensive functionality
create_dotnet_mock() {
    local mock_bin="${1:-$BATS_TEST_TMPDIR/bin}"
    local mock_mode="${2:-success}"

    mkdir -p "$mock_bin"

    cat > "$mock_bin/dotnet" << 'EOF'
#!/bin/bash
# Comprehensive dotnet mock for testing

# Default behavior
MOCK_MODE="${DOTNET_MOCK_MODE:-success}"
MOCK_VERSION="${DOTNET_MOCK_VERSION:-7.0.403}"

# Handle dotnet commands
case "$1" in
    "--version")
        echo "$MOCK_VERSION"
        return 0
        ;;
    "--info")
        echo ".NET SDKs installed:"
        echo "  7.0.403 [/usr/share/dotnet/sdk]"
        echo "  6.0.417 [/usr/share/dotnet/sdk]"
        echo ""
        echo ".NET runtimes installed:"
        echo "  Microsoft.AspNetCore.App 7.0.13 [/usr/share/dotnet/shared/Microsoft.AspNetCore.App]"
        echo "  Microsoft.AspNetCore.App 6.0.25 [/usr/share/dotnet/shared/Microsoft.AspNetCore.App]"
        echo "  Microsoft.NETCore.App 7.0.13 [/usr/share/dotnet/shared/Microsoft.NETCore.App]"
        echo "  Microsoft.NETCore.App 6.0.25 [/usr/share/dotnet/shared/Microsoft.NETCore.App]"
        echo ""
        echo "Other architectures found:"
        echo "  None"
        echo ""
        echo "Environment variables:"
        echo "  Not set"
        echo ""
        echo "host:"
        echo "  Version:      7.0.13"
        echo "  Architecture: x64"
        echo "  Commit:      e7187bf0ca"
        echo ""
        echo ".NET SDKs installed:"
        echo "  7.0.403 [/usr/share/dotnet/sdk]"
        echo ""
        echo ".NET runtimes installed:"
        echo "  Microsoft.NETCore.App 7.0.13 [/usr/share/dotnet/shared/Microsoft.NETCore.App]"
        echo ""
        echo "Download .NET:"
        echo "  https://aka.ms/dotnet-download"
        return 0
        ;;
    "new")
        local template_type="$2"
        local project_name="${3:-TestProject}"

        echo "The template \"$template_type\" was created successfully."
        echo ""
        echo "Processing post-creation actions..."
        echo "Running 'dotnet restore' on $project_name/$project_name.csproj..."
        echo "  Determining projects to restore..."
        echo "  All projects are up-to-date for restore."
        echo ""
        echo "Restore succeeded."
        echo ""
        echo "Generated $project_name/$project_name.csproj, $project_name/Program.cs, $project_name/TestProject.csproj, $project_name/UnitTest1.cs"
        return 0
        ;;
    "restore")
        echo "  Determining projects to restore..."
        echo "  All projects are up-to-date for restore."
        echo ""
        echo "  NuGet Config files used:"
        echo "      /tmp/test-project/NuGet.Config"
        echo ""
        echo "  Feeds used:"
        echo "      https://api.nuget.org/v3/index.json/"
        echo ""
        echo "  Installed Versions:"
        echo "      Microsoft.NETCore.App 7.0.13 from /usr/share/dotnet/shared/Microsoft.NETCore.App"
        echo "      Microsoft.AspNetCore.App 7.0.13 from /usr/share/dotnet/shared/Microsoft.AspNetCore.App"
        echo ""
        echo "  Restore succeeded."
        if [[ "$MOCK_MODE" == "fail" ]]; then
            echo ""
            echo "NuGet Package Manager: 6.6.1"
            echo "Failed to download package 'Microsoft.AspNetCore.App.Ref' from 'https://api.nuget.org/v3-flatcontainer/microsoft.aspnetcore.app.ref/7.0.13/microsoft.aspnetcore.app.ref.7.0.13.nupkg'."
            echo "  RETRYING: Downloading 'Microsoft.AspNetCore.App.Ref' from 'https://api.nuget.org/v3-flatcontainer/microsoft.aspnetcore.app.ref/7.0.13/microsoft.aspnetcore.app.ref.7.0.13.nupkg'."
            return 1
        fi
        return 0
        ;;
    "build")
        echo "MSBuild version 17.7.2+a34f2df33 for .NET"
        echo "  Determining projects to restore..."
        echo "  All projects are up-to-date for restore."
        echo "  TestProject -> /tmp/test-project/bin/Debug/net7.0/TestProject.dll"
        echo ""
        echo "Build succeeded."
        echo "    0 Warning(s)"
        echo "    0 Error(s)"
        echo ""
        echo "Time Elapsed 00:00:05.67"
        if [[ "$MOCK_MODE" == "fail" ]]; then
            echo ""
            echo "/tmp/test-project/Program.cs(9,17): error CS1002: ; expected"
            echo ""
            echo "Build failed."
            echo "    0 Warning(s)"
            echo "    1 Error(s)"
            echo ""
            echo "Time Elapsed 00:00:01.23"
            return 1
        fi
        return 0
        ;;
    "run")
        echo "Project TestProject (.NETCoreApp,Version=v7.0) will be compiled because expected outputs are missing"
        echo "Compiling TestProject for .NET 7.0..."
        echo "MSBuild version 17.7.2+a34f2df33 for .NET"
        echo "  Determining projects to restore..."
        echo "  All projects are up-to-date for restore."
        echo "  TestProject -> /tmp/test-project/bin/Debug/net7.0/TestProject.dll"
        echo ""
        echo "Hello, World!"
        return 0
        ;;
    "test")
        echo "Test run for /tmp/test-project/TestProject.csproj (.NETCoreApp,Version=v7.0)"
        echo "Starting test execution, please wait..."
        echo "A total of 1 test files matched the specified pattern."
        echo ""
        echo "Passed!  - Failed:     0, Passed:     1, Skipped:     0, Total:      1, Duration: < 1 ms - TestProject.dll (net7.0)"
        if [[ "$MOCK_MODE" == "fail" ]]; then
            echo ""
            echo "Failed!  - Failed:     1, Passed:     0, Skipped:     0, Total:      1, Duration: < 1 ms - TestProject.dll (net7.0)"
            return 1
        fi
        return 0
        ;;
    "publish")
        echo "MSBuild version 17.7.2+a34f2df33 for .NET"
        echo "  Determining projects to restore..."
        echo "  All projects are up-to-date for restore."
        echo "  TestProject -> /tmp/test-project/bin/Debug/net7.0/linux-x64/TestProject.dll"
        echo "  TestProject -> /tmp/test-project/bin/Debug/net7.0/publish/"
        echo ""
        echo "TestProject -> /tmp/test-project/bin/Debug/net7.0/publish/"
        echo ""
        echo "Publish succeeded."
        return 0
        ;;
    "clean")
        echo "  TestProject -> /tmp/test-project/bin/Debug/net7.0/"
        echo ""
        echo "Build succeeded."
        echo "    0 Warning(s)"
        echo "    0 Error(s)"
        echo ""
        echo "Time Elapsed 00:00:01.12"
        return 0
        ;;
    "pack")
        echo "MSBuild version 17.7.2+a34f2df33 for .NET"
        echo "  Determining projects to restore..."
        echo "  All projects are up-to-date for restore."
        echo "  TestProject -> /tmp/test-project/bin/Debug/net7.0/TestProject.dll"
        echo "  Successfully created package '/tmp/test-project/bin/Debug/TestProject.1.0.0.nupkg'."
        echo ""
        echo "Pack succeeded."
        return 0
        ;;
    "add")
        case "$2" in
            "package")
                local package_name="$3"
                echo "PackageReference for package '$package_name' version '1.0.0' added to file '/tmp/test-project/TestProject.csproj'."
                ;;
            "reference")
                local project_path="$3"
                echo "Reference for '$project_path' added to file '/tmp/test-project/TestProject.csproj'."
                ;;
            *)
                echo "dotnet add $*"
                ;;
        esac
        return 0
        ;;
    "remove")
        case "$2" in
            "package")
                local package_name="$3"
                echo "PackageReference for package '$package_name' removed from file '/tmp/test-project/TestProject.csproj'."
                ;;
            "reference")
                local project_path="$3"
                echo "Reference for '$project_path' removed from file '/tmp/test-project/TestProject.csproj'."
                ;;
            *)
                echo "dotnet remove $*"
                ;;
        esac
        return 0
        ;;
    "list")
        case "$2" in
            "package")
                echo "Project 'TestProject' has the following package references"
                echo "   [net7.0]:"
                echo "   Top-level Package References:"
                echo "   > Microsoft.NET.Test.Sdk 17.6.0"
                echo "   > coverlet.collector 6.0.0"
                echo "   Transitive Package References:"
                echo "   > Microsoft.CodeCoverage 17.6.0"
                ;;
            "reference")
                echo "Project 'TestProject' has no references"
                ;;
            "project-to-project")
                echo "Project has no project-to-project references."
                ;;
            *)
                echo "dotnet list $*"
                ;;
        esac
        return 0
        ;;
    "sln")
        case "$2" in
            "add")
                local project_path="$3"
                echo "Project `TestProject` added to the solution."
                ;;
            "remove")
                local project_name="$3"
                echo "Project `TestProject` removed from the solution."
                ;;
            "list")
                echo "Project reference(s)"
                echo "--------------------"
                echo "TestProject.csproj"
                ;;
            "new")
                echo "The solution \"TestProject.sln\" was created."
                ;;
            *)
                echo "dotnet sln $*"
                ;;
        esac
        return 0
        ;;
    "ef")
        case "$2" in
            "database")
                case "$3" in
                    "update")
                        echo "Build started..."
                        echo "Build succeeded."
                        echo "Done. To undo this action, use 'ef migrations remove'"
                        ;;
                    "drop")
                        echo "Dropping database..."
                        echo "Done."
                        ;;
                    *)
                        echo "dotnet ef database $*"
                        ;;
                esac
                ;;
            "migrations")
                case "$3" in
                    "add")
                        local migration_name="$4"
                        echo "Build started..."
                        echo "Build succeeded."
                        echo "Done. To undo this action, use 'ef migrations remove'"
                        ;;
                    "remove")
                        echo "Removing migration..."
                        echo "Done."
                        ;;
                    *)
                        echo "dotnet ef migrations $*"
                        ;;
                esac
                ;;
            *)
                echo "dotnet ef $*"
                ;;
        esac
        return 0
        ;;
    "tool")
        case "$2" in
            "install")
                local tool_name="$3"
                echo "You can invoke the tool using the following command: $tool_name"
                echo "Tool '$tool_name' (version '1.0.0') was successfully installed."
                ;;
            "uninstall")
                local tool_name="$3"
                echo "Tool '$tool_name' was successfully uninstalled."
                ;;
            "list")
                echo "Package Id                           Version      Commands"
                echo "-----------------------------------------------------------"
                echo "dotnet-ef                           7.0.13       dotnet-ef"
                echo "dotnet-dev-certs                    7.0.13       dotnet-dev-certs"
                ;;
            "restore")
                echo "Tool 'dotnet-ef' (version '7.0.13') was restored."
                echo "Available commands: dotnet-ef"
                ;;
            *)
                echo "dotnet tool $*"
                ;;
        esac
        return 0
        ;;
    "dev-certs")
        case "$2" in
            "https")
                echo "Creating a new certificate valid for 1 year."
                echo "The HTTPS developer certificate was generated successfully."
                echo "Trusting the HTTPS development certificate was successful."
                ;;
            "clean")
                echo "Cleaning HTTPS development certificates from the machine."
                echo "A certificate was successfully removed."
                ;;
            *)
                echo "dotnet dev-certs $*"
                ;;
        esac
        return 0
        ;;
    "user-secrets")
        case "$2" in
            "set")
                echo "Successfully saved TestSecret = 123"
                ;;
            "list")
                echo "TestSecret = 123"
                ;;
            "remove")
                echo "Successfully deleted TestSecret"
                ;;
            "clear")
                echo "User secrets cleared successfully"
                ;;
            *)
                echo "dotnet user-secrets $*"
                ;;
        esac
        return 0
        ;;
    "watch")
        echo "watch : Started"
        echo "Using launch settings from /tmp/test-project/Properties/launchSettings.json..."
        echo "watch : Hot reload enabled. For a list of supported edits, see https://aka.ms/dotnet-hots-reload"
        echo "  Starting up..."
        echo "  Now listening on: http://localhost:5000"
        echo "  Application started. Press Ctrl+C to shut down."
        echo ""
        echo "watch : File changed: /tmp/test-project/Program.cs"
        echo "watch : Hot reload of change succeeded"
        return 0
        ;;
    "format")
        echo "1 file formatted in 10ms."
        return 0
        ;;
    "help")
        if [[ -n "$2" ]]; then
            echo "Usage: dotnet $2 [options] [arguments]"
            echo ""
            echo "Description:"
            echo "Description for $2 command"
        else
            echo "$MOCK_VERSION"
            echo ""
            echo "Usage: dotnet [options] [command]"
            echo ""
            echo "Description:"
            echo "  .NET Command Line Tools"
            echo ""
            echo "Options:"
            echo "  -h|--help         Show help information"
            echo "  --version         Display .NET version information"
            echo "  --info            Display .NET environment information"
            echo ""
            echo "Common Commands:"
            echo "  new               Create a new project"
            echo "  restore           Restore project dependencies"
            echo "  build             Build a project"
            echo "  publish           Publish a project"
            echo "  run               Run project source code"
            echo "  test              Run unit tests using the test runner"
            echo ""
            echo "Advanced Commands:"
            echo "  clean             Clean build outputs"
            echo "  sln               Modify solution (SLN) files"
            echo "  add               Add package or reference to a project"
            echo "  remove            Remove package or reference from a project"
            echo "  list              List project references"
            echo "  reference         Add a project-to-project reference"
            echo ""
            echo "NuGet Commands:"
            echo "  nuget             Manage NuGet packages"
            echo ""
            echo "Project Modification Commands:"
            echo "  add               Add a file or folder"
            echo "  remove            Remove a file or folder"
            echo ""
            echo "Workload Commands:"
            echo "  workload          Manage .NET workloads"
            echo ""
            echo "Tool Commands:"
            echo "  tool              Install or manage tools"
            echo ""
            echo "Run Commands:"
            echo "  watch             Run file watcher"
            echo ""
            echo "Other Commands:"
            echo "  dev-certs         Manage development certificates"
            echo "  user-secrets      Manage user secrets"
            echo "  format            Format code"
            echo "  ef                Entity Framework Core tools"
            echo ""
            echo "For more information on a specific command, run 'dotnet help <command>'"
            echo ""
            echo "For more information on .NET, visit https://learn.microsoft.com/dotnet/"
        fi
        return 0
        ;;
    *)
        echo "Unknown .NET command: $1"
        echo "Run 'dotnet help' for usage information"
        return 1
        ;;
esac
EOF

    chmod +x "$mock_bin/dotnet"
}

# Configure build tool mocks behavior
configure_build_tool_mocks() {
    local mode="${1:-success}"
    local cargo_version="${2:-cargo 1.75.0 (1d8b05cdd 2023-11-20)}"
    local go_version="${3:-go version go1.21.5 linux/amd64}"
    local maven_version="${4:-Apache Maven 3.9.5}"
    local gradle_version="${5:-Gradle 8.5}"
    local dotnet_version="${6:-7.0.403}"

    export CARGO_MOCK_MODE="$mode"
    export GO_MOCK_MODE="$mode"
    export MVN_MOCK_MODE="$mode"
    export GRADLE_MOCK_MODE="$mode"
    export DOTNET_MOCK_MODE="$mode"

    export CARGO_MOCK_VERSION="$cargo_version"
    export GO_MOCK_VERSION="$go_version"
    export MVN_MOCK_VERSION="$maven_version"
    export GRADLE_MOCK_VERSION="$gradle_version"
    export DOTNET_MOCK_VERSION="$dotnet_version"
}

# Set build tool mocks to failure mode
set_build_tool_mocks_failure() {
    configure_build_tool_mocks "fail"
}

# Clean up build tool mocks
cleanup_build_tool_mocks() {
    unset CARGO_MOCK_MODE GO_MOCK_MODE MVN_MOCK_MODE GRADLE_MOCK_MODE DOTNET_MOCK_MODE
    unset CARGO_MOCK_VERSION GO_MOCK_VERSION MVN_MOCK_VERSION GRADLE_MOCK_VERSION DOTNET_MOCK_VERSION
}

# Create all build tool mocks
create_all_build_tool_mocks() {
    local mock_bin="${1:-$BATS_TEST_TMPDIR/bin}"
    local mock_mode="${2:-success}"

    create_cargo_mock "$mock_bin" "$mock_mode"
    create_go_mock "$mock_bin" "$mock_mode"
    create_maven_mock "$mock_bin" "$mock_mode"
    create_gradle_mock "$mock_bin" "$mock_mode"
    create_dotnet_mock "$mock_bin" "$mock_mode"
}

# Helper functions for common scenarios
setup_build_tools_for_rust_project() {
    configure_build_tool_mocks "success" "cargo 1.75.0" "" "" "" ""
}

setup_build_tools_for_go_project() {
    configure_build_tool_mocks "success" "" "go version go1.21.5" "" "" ""
}

setup_build_tools_for_java_project() {
    configure_build_tool_mocks "success" "" "" "Apache Maven 3.9.5" "" ""
}

setup_build_tools_for_dotnet_project() {
    configure_build_tool_mocks "success" "" "" "" "" "7.0.403"
}

setup_build_tools_for_failing_build() {
    configure_build_tool_mocks "fail"
}

# Mock build detection functions
detect_build_tool() {
    if [[ -f "Cargo.toml" ]]; then
        echo "cargo"
    elif [[ -f "go.mod" ]]; then
        echo "go"
    elif [[ -f "pom.xml" ]]; then
        echo "mvn"
    elif [[ -f "build.gradle" || -f "build.gradle.kts" ]]; then
        echo "gradle"
    elif [[ -f "*.csproj" || -f "*.sln" ]]; then
        echo "dotnet"
    else
        echo "unknown"
    fi
}

# Build project using detected build tool
build_project() {
    local build_tool=$(detect_build_tool)

    case "$build_tool" in
        "cargo")
            cargo build
            ;;
        "go")
            go build
            ;;
        "mvn")
            mvn compile
            ;;
        "gradle")
            gradle build
            ;;
        "dotnet")
            dotnet build
            ;;
        *)
            echo "No supported build tool found"
            return 1
            ;;
    esac
}