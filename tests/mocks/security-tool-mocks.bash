#!/usr/bin/env bash
# Security Tool Mocks Library for BATS Testing
# Provides comprehensive mock implementations for security tools (gitleaks, trufflehog, shellcheck, etc.)

# Create gitleaks mock with comprehensive functionality
create_gitleaks_mock() {
    local mock_bin="${1:-$BATS_TEST_TMPDIR/bin}"
    local mock_mode="${2:-success}"

    mkdir -p "$mock_bin"

    cat > "$mock_bin/gitleaks" << 'EOF'
#!/bin/bash
# Comprehensive gitleaks mock for testing

# Default behavior
MOCK_MODE="${GITLEAKS_MOCK_MODE:-success}"
MOCK_VERSION="${GITLEAKS_MOCK_VERSION:-v8.18.2}"
MOCK_HAS_SECRETS="${GITLEAKS_HAS_SECRETS:-false}"

# Handle gitleaks commands
case "$1" in
    "--version")
        echo "$MOCK_VERSION"
        return 0
        ;;
    "detect")
        shift
        local files=()
        local repo_path="."
        local config_file=""

        # Parse arguments
        while [[ $# -gt 0 ]]; do
            case "$1" in
                "--repo")
                    repo_path="$2"
                    shift 2
                    ;;
                "--config")
                    config_file="$2"
                    shift 2
                    ;;
                "--report-format")
                    shift 2
                    ;;
                "--report-path")
                    shift 2
                    ;;
                "--verbose")
                    shift
                    ;;
                "--redact")
                    shift
                    ;;
                *)
                    files+=("$1")
                    shift
                    ;;
            esac
        done

        echo "    ○"
        echo "    │╲"
        echo "    │ ○"
        echo "    ○ ░"
        echo "      ░"
        echo "Gitleaks Scan Summary"
        echo ""
        echo "--------------------"
        echo "Scanned files: ${#files[@]}"
        echo "Secrets found: 0"

        if [[ "$MOCK_MODE" == "fail" || "$MOCK_HAS_SECRETS" == "true" ]]; then
            echo ""
            echo "Findings:"
            echo ""
            echo "🔑 AWS Access Key ID:"
            echo "  File: config/production.yml"
            echo "  Line: 15"
            echo "  Secret: AKIAIOSFODNN7EXAMPLE"
            echo "  Rule: AWS Access Key ID"
            echo "  Severity: HIGH"
            echo ""
            echo "🔑 AWS Secret Access Key:"
            echo "  File: config/production.yml"
            echo "  Line: 16"
            echo "  Secret: sk-abcdefghijklmnopqrstuvwxyz123456"
            echo "  Rule: AWS Secret Access Key"
            echo "  Severity: HIGH"
            echo ""
            echo "🔑 GitHub Token:"
            echo "  File: scripts/deploy.sh"
            echo "  Line: 42"
            echo "  Secret: ghp_1234567890abcdef1234567890abcdef123456"
            echo "  Rule: GitHub Personal Access Token"
            echo "  Severity: HIGH"
            echo ""
            echo "Scanned files: ${#files[@]}"
            echo "Secrets found: 3"
            echo "Scan duration: 2.34s"
            return 1
        fi

        echo ""
        echo "🎉 No secrets found!"
        echo ""
        echo "Scan completed successfully"
        echo "Scanned files: ${#files[@]}"
        echo "Secrets found: 0"
        echo "Scan duration: 1.23s"
        return 0
        ;;
    "protect")
        shift
        echo "Gitleaks Protect"
        echo ""
        echo "Pre-commit secret scanning enabled"
        echo "No secrets found in staged changes"
        return 0
        ;;
    "config")
        case "$2" in
            "init")
                echo "Created .gitleaks.toml configuration file"
                ;;
            "validate")
                if [[ "$MOCK_MODE" == "fail" ]]; then
                    echo "Configuration validation failed"
                    echo "Error: Invalid rule format"
                    return 1
                fi
                echo "Configuration is valid"
                ;;
            "path")
                echo "/path/to/.gitleaks.toml"
                ;;
            *)
                echo "gitleaks config $*"
                ;;
        esac
        return 0
        ;;
    "report")
        case "$2" in
            "summarize")
                echo "Gitleaks Report Summary"
                echo "Total scans: 25"
                echo "Secrets found: 3"
                echo "Last scan: 2023-11-22T10:30:00Z"
                ;;
            "generate")
                local format="$3"
                echo "Generated $format report"
                ;;
            *)
                echo "gitleaks report $*"
                ;;
        esac
        return 0
        ;;
    "baseline")
        local file="$2"
        echo "Created baseline file: $file"
        return 0
        ;;
    "verify")
        local baseline_file="$2"
        echo "Verifying baseline: $baseline_file"
        echo "Baseline is valid"
        return 0
        ;;
    "--help")
        echo "Gitleaks $MOCK_VERSION"
        echo ""
        echo "Usage:"
        echo "  gitleaks [command]"
        echo ""
        echo "Available Commands:"
        echo "  detect        Detect secrets in repository"
        echo "  protect       Protect repository from secrets"
        echo "  config        Configuration management"
        echo "  report        Generate reports"
        echo "  baseline      Create/verify baseline"
        echo "  verify        Verify configuration"
        echo ""
        echo "Options:"
        echo "  --version     Show version information"
        echo "  --help        Show this help message"
        return 0
        ;;
    *)
        echo "Unknown gitleaks command: $1"
        echo "Run 'gitleaks --help' for usage information"
        return 1
        ;;
esac
EOF

    chmod +x "$mock_bin/gitleaks"
}

# Create trufflehog mock with comprehensive functionality
create_trufflehog_mock() {
    local mock_bin="${1:-$BATS_TEST_TMPDIR/bin}"
    local mock_mode="${2:-success}"

    mkdir -p "$mock_bin"

    cat > "$mock_bin/trufflehog" << 'EOF'
#!/bin/bash
# Comprehensive trufflehog mock for testing

# Default behavior
MOCK_MODE="${TRUFFLEHOG_MOCK_MODE:-success}"
MOCK_VERSION="${TRUFFLEHOG_MOCK_VERSION:-3.81.0}"
MOCK_HAS_SECRETS="${TRUFFLEHOG_HAS_SECRETS:-false}"

# Handle trufflehog commands
case "$1" in
    "--version")
        echo "$MOCK_VERSION"
        return 0
        ;;
    "filesystem")
        shift
        local paths=()
        local json_output=false
        local rules=""

        # Parse arguments
        while [[ $# -gt 0 ]]; do
            case "$1" in
                "--json")
                    json_output=true
                    shift
                    ;;
                "--rules")
                    rules="$2"
                    shift 2
                    ;;
                "--entropy")
                    shift
                    ;;
                "--regex")
                    shift
                    ;;
                *)
                    paths+=("$1")
                    shift
                    ;;
            esac
        done

        if [[ "$json_output" == true ]]; then
            echo '{"SourceMetadata":{"Data":{"Filesystem":{"File":"'${paths[0]:-unknown_file}'"}}},"DetectorName":"AWS","DetectorType":null,"Raw":"AKIAIOSFODNN7EXAMPLE","Redacted":"AKIA...EXAMPLE","ExtraData":null,"Start":1,"End":20}'

            if [[ "$MOCK_MODE" == "fail" || "$MOCK_HAS_SECRETS" == "true" ]]; then
                echo '{"SourceMetadata":{"Data":{"Filesystem":{"File":"config/database.yml"}}},"DetectorName":"Generic API Key","DetectorType":null,"Raw":"sk-abcdefghijklmnopqrstuvwxyz123456","Redacted":"sk-...456","ExtraData":null,"Start":42,"End":80}'
                echo '{"SourceMetadata":{"Data":{"Filesystem":{"File":"scripts/deploy.sh"}}},"DetectorName":"GitHub","DetectorType":null,"Raw":"ghp_1234567890abcdef1234567890abcdef123456","Redacted":"ghp_...456","ExtraData":null,"Start":15,"End":65}'
            fi
        else
            echo "🐷🔑🤖 Snout 🐷🔑🤖 TruffleHog 🐷🔑🤖 Snout 🐷🔑🤖"
            echo ""
            echo "Scanning filesystem..."

            if [[ "$MOCK_MODE" == "fail" || "$MOCK_HAS_SECRETS" == "true" ]]; then
                echo ""
                echo "🔴 Found credentials!"
                echo ""
                echo "File: config/production.yml"
                echo "Line: 15"
                echo "Detector: AWS"
                echo "Secret: AKIA...EXAMPLE"
                echo ""
                echo "File: config/database.yml"
                echo "Line: 42"
                echo "Detector: Generic API Key"
                echo "Secret: sk-...456"
                echo ""
                echo "File: scripts/deploy.sh"
                echo "Line: 8"
                echo "Detector: GitHub"
                echo "Secret: ghp_...456"
                echo ""
                echo "Found 3 secrets"
                return 1
            else
                echo ""
                echo "🟢 No secrets found!"
                echo "Scanned ${#paths[@]} files"
            fi
        fi
        return 0
        ;;
    "git")
        shift
        local repo_url="."
        local json_output=false
        local since_commit=""
        local branch=""

        # Parse arguments
        while [[ $# -gt 0 ]]; do
            case "$1" in
                "--json")
                    json_output=true
                    shift
                    ;;
                "--since-commit")
                    since_commit="$2"
                    shift 2
                    ;;
                "--branch")
                    branch="$2"
                    shift 2
                    ;;
                *)
                    repo_url="$1"
                    shift
                    ;;
            esac
        done

        if [[ "$json_output" == true ]]; then
            echo '{"SourceMetadata":{"Data":{"Git":{"Commit":"abc123def4567890abcdef1234567890abcdef12","File":"config/secrets.yml","Email":"test@example.com","Repository":"test-repo"}}},"DetectorName":"AWS","DetectorType":null,"Raw":"AKIAIOSFODNN7EXAMPLE","Redacted":"AKIA...EXAMPLE","ExtraData":null,"Start":5,"End":30}'

            if [[ "$MOCK_MODE" == "fail" || "$MOCK_HAS_SECRETS" == "true" ]]; then
                echo '{"SourceMetadata":{"Data":{"Git":{"Commit":"def4567890abcdef1234567890abcdef12def456","File":"api/keys.json","Email":"dev@example.com","Repository":"test-repo"}}},"DetectorName":"Slack","DetectorType":null,"Raw":"xoxb-1234567890-abcdefghijABCDEFGHIJ1234567890","Redacted":"xoxb-...4567890","ExtraData":null,"Start":12,"End":55}'
            fi
        else
            echo "🐷🔑🤖 Snout 🐷🔑🤖 TruffleHog 🐷🔑🤖 Snout 🐷🔑🤖"
            echo ""
            echo "Scanning git repository: $repo_url"
            if [[ -n "$since_commit" ]]; then
                echo "Since commit: $since_commit"
            fi
            if [[ -n "$branch" ]]; then
                echo "Branch: $branch"
            fi

            if [[ "$MOCK_MODE" == "fail" || "$MOCK_HAS_SECRETS" == "true" ]]; then
                echo ""
                echo "🔴 Found credentials in git history!"
                echo ""
                echo "Commit: abc123def4567890abcdef1234567890abcdef12"
                echo "File: config/secrets.yml"
                echo "Email: test@example.com"
                echo "Detector: AWS"
                echo "Secret: AKIA...EXAMPLE"
                echo ""
                echo "Commit: def4567890abcdef1234567890abcdef12def456"
                echo "File: api/keys.json"
                echo "Email: dev@example.com"
                echo "Detector: Slack"
                echo "Secret: xoxb-...4567890"
                echo ""
                echo "Found 2 secrets"
                return 1
            else
                echo ""
                echo "🟢 No secrets found in git history!"
                echo "Scanned 150 commits"
            fi
        fi
        return 0
        ;;
    "github")
        shift
        local repo_name="$1"
        local token="$2"

        echo "🐷🔑🤖 Snout 🐷🔑🤖 TruffleHog 🐷🔑🤖 Snout 🐷🔑🤖"
        echo ""
        echo "Scanning GitHub repository: $repo_name"

        if [[ "$MOCK_MODE" == "fail" || "$MOCK_HAS_SECRETS" == "true" ]]; then
            echo ""
            echo "🔴 Found credentials in GitHub repository!"
            echo ""
            echo "Repository: $repo_name"
            echo "File: .env.production"
            echo "Commit: main@abc123def"
            echo "Detector: Google API Key"
            echo "Secret: AIza...def"
            echo ""
            echo "Found 1 secret"
            return 1
        else
            echo ""
            echo "🟢 No secrets found in GitHub repository!"
            echo "Scanned all branches and pull requests"
        fi
        return 0
        ;;
    "github")
        shift
        local repo_name="$1"
        local token="$2"

        echo "🐷🔑🤖 Snout 🐷🔑🤖 TruffleHog 🐷🔑🤖 Snout 🐷🔑🤖"
        echo ""
        echo "Scanning GitHub repository: $repo_name"

        if [[ "$MOCK_MODE" == "fail" || "$MOCK_HAS_SECRETS" == "true" ]]; then
            echo ""
            echo "🔴 Found credentials in GitHub repository!"
            echo ""
            echo "Repository: $repo_name"
            echo "File: .env.production"
            echo "Commit: main@abc123def"
            echo "Detector: Google API Key"
            echo "Secret: AIza...def"
            echo ""
            echo "Found 1 secret"
            return 1
        else
            echo ""
            echo "🟢 No secrets found in GitHub repository!"
            echo "Scanned all branches and pull requests"
        fi
        return 0
        ;;
    "ui")
        echo "🐷🔑🤖 Snout 🐷🔑🤖 TruffleHog 🐷🔑🤖 Snout 🐷🔑🤖"
        echo ""
        echo "Starting TruffleHog UI server on http://localhost:8080"
        echo "Web interface available at http://localhost:8080"
        return 0
        ;;
    "--help")
        echo "TruffleHog $MOCK_VERSION"
        echo ""
        echo "Find credentials all over the place."
        echo ""
        echo "Usage:"
        echo "  trufflehog [command] [options]"
        echo ""
        echo "Available Commands:"
        echo "  filesystem    Scan filesystem for secrets"
        echo "  git           Scan git repository for secrets"
        echo "  github        Scan GitHub repository for secrets"
        echo "  gitlab        Scan GitLab repository for secrets"
        echo "  s3            Scan S3 bucket for secrets"
        echo "  gcs           Scan Google Cloud Storage for secrets"
        echo "  azure         Scan Azure Blob Storage for secrets"
        echo "  docker        Scan Docker image for secrets"
        echo "  ui            Start web UI"
        echo ""
        echo "Options:"
        echo "  --version     Show version information"
        echo "  --help        Show this help message"
        return 0
        ;;
    *)
        echo "Unknown trufflehog command: $1"
        echo "Run 'trufflehog --help' for usage information"
        return 1
        ;;
esac
EOF

    chmod +x "$mock_bin/trufflehog"
}

# Create shellcheck mock with comprehensive functionality
create_shellcheck_mock() {
    local mock_bin="${1:-$BATS_TEST_TMPDIR/bin}"
    local mock_mode="${2:-success}"

    mkdir -p "$mock_bin"

    cat > "$mock_bin/shellcheck" << 'EOF'
#!/bin/bash
# Comprehensive shellcheck mock for testing

# Default behavior
MOCK_MODE="${SHELLCHECK_MOCK_MODE:-success}"
MOCK_VERSION="${SHELLCHECK_MOCK_VERSION:-ShellCheck - v0.9.0}"
MOCK_SEVERITY="${SHELLCHECK_MOCK_SEVERITY:-warning}"

# Handle shellcheck commands
case "$1" in
    "--version")
        echo "$MOCK_VERSION"
        return 0
        ;;
    "-f")
        local format="$2"
        shift 2
        local file="$1"

        if [[ "$format" == "diff" && -n "$file" ]]; then
            if [[ "$MOCK_MODE" == "fail" ]]; then
                echo "--- a/$file"
                echo "+++ b/$file"
                echo "@@ -1,3 +1,3 @@"
                echo "- echo \$unquoted_variable"
                echo "+ echo \"\$unquoted_variable\""
                echo ""
                echo "@@ -5,2 +5,2 @@"
                echo "- if [[ \$var == test ]]; then"
                echo "+ if [[ \$var == \"test\" ]]; then"
                echo ""
                echo "SC2086: Double quote to prevent globbing and word splitting"
                echo "SC2086: info: Double quote to prevent globbing and word splitting [SC2086]"
                return 1
            else
                echo "No shellcheck issues found in $file"
                return 0
            fi
        fi
        ;;
    "-o"|"--output-format")
        local format="$2"
        shift 2
        echo "Output format: $format"
        return 0
        ;;
    "-s"|"--shell")
        local shell_type="$2"
        shift 2
        echo "Shell type: $shell_type"
        return 0
        ;;
    "-S"|"--severity")
        local severity="$2"
        shift 2
        echo "Severity level: $severity"
        return 0
        ;;
    "-W"|"--wiki-link-count")
        local count="$2"
        shift 2
        echo "Wiki link count: $count"
        return 0
        ;;
    "-a"|"--check-sourced")
        echo "Checking sourced files"
        return 0
        ;;
    "-x"|"--external-sources")
        echo "Checking external sources"
        return 0
        ;;
    "-e"|"--exclude")
        local code="$2"
        shift 2
        echo "Excluding code: $code"
        return 0
        ;;
    "-i"|"--include")
        local code="$2"
        shift 2
        echo "Including code: $code"
        return 0
        ;;
    "-V"|"--version")
        echo "$MOCK_VERSION"
        return 0
        ;;
    "-C"|"--color")
        local color_mode="$2"
        shift 2
        echo "Color mode: $color_mode"
        return 0
        ;;
    "")
        # No arguments provided, show help
        echo "ShellCheck - v0.9.0"
        echo ""
        echo "Usage: shellcheck [OPTIONS] FILES..."
        echo ""
        echo "For more information:"
        echo "  Run 'shellcheck --help'"
        echo "  Check out https://www.shellcheck.net"
        return 0
        ;;
    "--help")
        echo "ShellCheck - v0.9.0"
        echo ""
        echo "Usage: shellcheck [OPTIONS] FILES..."
        echo "       shellcheck --help"
        echo ""
        echo "For more information:"
        echo "  Check out https://www.shellcheck.net or 'man shellcheck'"
        echo ""
        echo "Example usage:"
        echo "  shellcheck myscript.sh"
        echo "  shellcheck -s bash myscript.sh"
        echo "  shellcheck -x myscript.sh"
        echo ""
        echo "Options:"
        echo "  -V, --version              Show version information"
        echo "  -a, --check-sourced        Include sourced files in checks"
        echo "  -C, --color[=WHEN]         Use color in output (auto, always, never)"
        echo "  -e CODE1,CODE2..           Exclude types of warnings"
        echo "  -f FORMAT                  Output format (checkstyle, diff, gcc, json, quiet)"
        echo "  -i CODE1,CODE2..           Include types of warnings"
        echo "  -o, --output-format FORMAT Same as -f"
        echo "  -s SHELLNAME               Specify shell dialect (bash, sh, ksh, zsh)"
        echo "  -S SEVERITY                Minimum severity of errors (error, warning, info)"
        echo "  -W WIKI COUNT              Show top COUNT most common wiki links"
        echo "  -x                         Follow 'source' directives"
        echo "      --help                 Show this help summary"
        echo "      --wiki-link-count COUNT Same as -W"
        echo "      --color=WHEN           Same as -C"
        echo "      --output-format FORMAT Same as -f"
        echo "      --shell SHELLNAME      Same as -s"
        echo "      --severity SEVERITY    Same as -S"
        echo "      --check-sourced        Same as -a"
        echo "      --external-sources     Same as -x"
        return 0
        ;;
    *)
        # Default behavior - check files for shell script issues
        local files=("$@")

        if [[ "$MOCK_MODE" == "fail" ]]; then
            local found_issues=false

            for file in "${files[@]}"; do
                if [[ -f "$file" ]]; then
                    # Mock common shellcheck issues
                    echo "In $file line 3:"
                    echo "  unquoted_var=\"test\""
                    echo "      ^----^ SC2086: Double quote to prevent globbing and word splitting"
                    echo ""
                    echo "In $file line 5:"
                    echo "  if [[ \$var == test ]]; then"
                    echo "          ^---^ SC3009: These are not the same. Use '!=' in non-posix shells."
                    found_issues=true
                fi
            done

            if [[ "$found_issues" == "true" ]]; then
                echo "For more information:"
                echo "  https://www.shellcheck.net/wiki/SC2086"
                echo "  https://www.shellcheck.net/wiki/SC3009"
                return 1
            fi
        fi

        echo "All files passed shellcheck analysis"
        return 0
        ;;
esac
EOF

    chmod +x "$mock_bin/shellcheck"
}

# Create detect-secrets mock with comprehensive functionality
create_detect_secrets_mock() {
    local mock_bin="${1:-$BATS_TEST_TMPDIR/bin}"
    local mock_mode="${2:-success}"

    mkdir -p "$mock_bin"

    cat > "$mock_bin/detect-secrets" << 'EOF'
#!/bin/bash
# Comprehensive detect-secrets mock for testing

# Default behavior
MOCK_MODE="${DETECT_SECRETS_MOCK_MODE:-success}"
MOCK_VERSION="${DETECT_SECRETS_MOCK_VERSION:-detect-secrets 1.0.0}"
MOCK_HAS_SECRETS="${DETECT_SECRETS_HAS_SECRETS:-false}"

# Handle detect-secrets commands
case "$1" in
    "--version")
        echo "$MOCK_VERSION"
        return 0
        ;;
    "scan")
        shift
        local files=()
        local all_files=false
        local baseline_file=""

        # Parse arguments
        while [[ $# -gt 0 ]]; do
            case "$1" in
                "--all-files")
                    all_files=true
                    shift
                    ;;
                "--baseline")
                    baseline_file="$2"
                    shift 2
                    ;;
                *)
                    files+=("$1")
                    shift
                    ;;
            esac
        done

        if [[ "$MOCK_MODE" == "fail" || "$MOCK_HAS_SECRETS" == "true" ]]; then
            echo "Scanning repository..."
            echo ""
            echo "Potential secrets detected:"
            echo ""
            echo "File: config/database.yml"
            echo "Secret Type: Generic High Entropy String"
            echo "Location: Line 12"
            echo "Secret: abc123def4567890ghij1234567890"
            echo ""
            echo "File: .env"
            echo "Secret Type: AWS Access Key ID"
            echo "Location: Line 3"
            echo "Secret: AKIAIOSFODNN7EXAMPLE"
            echo ""
            echo "File: scripts/setup.sh"
            echo "Secret Type: GitHub Token"
            echo "Location: Line 25"
            echo "Secret: ghp_1234567890abcdef1234567890abcdef123456"
            echo ""
            echo "3 potential secrets found"
            echo ""
            echo "Recommendations:"
            echo "- Remove secrets from repository"
            echo "- Use environment variables"
            echo "- Consider using secret management tools"
            return 1
        else
            echo "Scanning repository..."
            echo ""
            echo "✅ No secrets detected"
            echo ""
            if [[ "$all_files" == "true" ]]; then
                echo "Scanned all files in repository"
            else
                echo "Scanned modified files only"
            fi
        fi
        return 0
        ;;
    "install")
        local hook_name="$2"
        echo "Installing detect-secrets pre-commit hook: $hook_name"
        echo "Hook installed successfully"
        return 0
        ;;
    "baseline")
        local baseline_file="$1"
        echo "Creating baseline file: $baseline_file"
        cat > "$baseline_file" << 'BASELINE_EOF'
{
    "version": "1.0.0",
    "plugins_used": [
        {
            "name": "AWSKeyDetector"
        },
        {
            "name": "GitHubTokenDetector"
        },
        {
            "name": "PrivateKeyDetector"
        },
        {
            "name": "BasicAuthDetector"
        }
    ],
    "results": []
}
BASELINE_EOF
        echo "Baseline created with 0 known secrets"
        return 0
        ;;
    "audit")
        local baseline_file="$1"
        echo "Auditing baseline: $baseline_file"
        echo ""
        echo "Baseline audit summary:"
        echo "- Total secrets in baseline: 0"
        echo "- Secrets still present: 0"
        echo "- Secrets removed: 0"
        echo "- New secrets: 0"
        return 0
        ;;
    "removeall")
        local baseline_file="$1"
        echo "Removing all secrets from baseline: $baseline_file"
        echo "All secrets removed from baseline"
        return 0
        ;;
    "update")
        local baseline_file="$1"
        echo "Updating baseline: $baseline_file"
        echo "Baseline updated with latest scan results"
        return 0
        ;;
    "list")
        echo "Available detect-secrets plugins:"
        echo "- AWSKeyDetector: Detects AWS access keys"
        echo "- GitHubTokenDetector: Detects GitHub tokens"
        echo "- PrivateKeyDetector: Detects private keys"
        echo "- BasicAuthDetector: Detects basic authentication"
        echo "- HexHighEntropyString: Detects hex high entropy strings"
        echo "- Base64HighEntropyString: Detects base64 high entropy strings"
        return 0
        ;;
    "report")
        local format="$2"
        case "$format" in
            "json")
                echo '{"scan_summary": {"total_secrets": 0, "files_scanned": 25}}'
                ;;
            "markdown")
                echo "# Detect-Secrets Scan Report"
                echo ""
                echo "## Summary"
                echo "- Total files scanned: 25"
                echo "- Secrets found: 0"
                ;;
            *)
                echo "Scan Summary:"
                echo "- Total files scanned: 25"
                echo "- Secrets found: 0"
                ;;
        esac
        return 0
        ;;
    "--help")
        echo "detect-secrets: An enterprise friendly way of detecting and preventing secrets in code."
        echo ""
        echo "Usage: detect-secrets [command] [options]"
        echo ""
        echo "Commands:"
        echo "  scan              Scan for secrets"
        echo "  install           Install pre-commit hooks"
        echo "  baseline          Create baseline file"
        echo "  audit             Audit baseline file"
        echo "  removeall         Remove all secrets from baseline"
        echo "  update            Update baseline file"
        echo "  list              List available plugins"
        echo "  report            Generate scan report"
        echo ""
        echo "Options:"
        echo "  --version         Show version information"
        echo "  --help            Show this help message"
        return 0
        ;;
    *)
        echo "Unknown detect-secrets command: $1"
        echo "Run 'detect-secrets --help' for usage information"
        return 1
        ;;
esac
EOF

    chmod +x "$mock_bin/detect-secrets"
}

# Configure security tool mocks behavior
configure_security_tool_mocks() {
    local mode="${1:-success}"
    local gitleaks_version="${2:-v8.18.2}"
    local trufflehog_version="${3:-3.81.0}"
    local shellcheck_version="${4:-ShellCheck - v0.9.0}"
    local detect_secrets_version="${5:-detect-secrets 1.0.0}"

    export GITLEAKS_MOCK_MODE="$mode"
    export TRUFFLEHOG_MOCK_MODE="$mode"
    export SHELLCHECK_MOCK_MODE="$mode"
    export DETECT_SECRETS_MOCK_MODE="$mode"

    export GITLEAKS_MOCK_VERSION="$gitleaks_version"
    export TRUFFLEHOG_MOCK_VERSION="$trufflehog_version"
    export SHELLCHECK_MOCK_VERSION="$shellcheck_version"
    export DETECT_SECRETS_MOCK_VERSION="$detect_secrets_version"
}

# Set security tool mocks to failure mode
set_security_tool_mocks_failure() {
    configure_security_tool_mocks "fail"
}

# Set security tool mocks to have secrets
set_security_tool_mocks_has_secrets() {
    configure_security_tool_mocks "success"
    export GITLEAKS_HAS_SECRETS="true"
    export TRUFFLEHOG_HAS_SECRETS="true"
    export DETECT_SECRETS_HAS_SECRETS="true"
}

# Clean up security tool mocks
cleanup_security_tool_mocks() {
    unset GITLEAKS_MOCK_MODE TRUFFLEHOG_MOCK_MODE SHELLCHECK_MOCK_MODE DETECT_SECRETS_MOCK_MODE
    unset GITLEAKS_HAS_SECRETS TRUFFLEHOG_HAS_SECRETS DETECT_SECRETS_HAS_SECRETS
    unset GITLEAKS_MOCK_VERSION TRUFFLEHOG_MOCK_VERSION SHELLCHECK_MOCK_VERSION DETECT_SECRETS_MOCK_VERSION
    unset SHELLCHECK_MOCK_SEVERITY
}

# Create all security tool mocks
create_all_security_tool_mocks() {
    local mock_bin="${1:-$BATS_TEST_TMPDIR/bin}"
    local mock_mode="${2:-success}"

    create_gitleaks_mock "$mock_bin" "$mock_mode"
    create_trufflehog_mock "$mock_bin" "$mock_mode"
    create_shellcheck_mock "$mock_bin" "$mock_mode"
    create_detect_secrets_mock "$mock_bin" "$mock_mode"
}

# Helper functions for common scenarios
setup_security_tools_for_clean_scan() {
    configure_security_tool_mocks "success"
}

setup_security_tools_for_secrets_found() {
    set_security_tool_mocks_has_secrets
}

setup_security_tools_for_scan_failure() {
    configure_security_tool_mocks "fail"
}

setup_shellcheck_for_strict_linting() {
    configure_security_tool_mocks "success" "" "" "ShellCheck - v0.9.0" ""
    export SHELLCHECK_MOCK_SEVERITY="error"
}

# Mock security scan functions
run_secrets_scan() {
    local tool="${1:-gitleaks}"
    local target="${2:-.}"

    case "$tool" in
        "gitleaks")
            gitleaks detect --repo "$target"
            ;;
        "trufflehog")
            trufflehog filesystem "$target"
            ;;
        "detect-secrets")
            detect-secrets scan --all-files
            ;;
        "all")
            echo "Running comprehensive secrets scan..."
            gitleaks detect --repo "$target" || true
            trufflehog filesystem "$target" || true
            detect-secrets scan --all-files || true
            ;;
        *)
            echo "Unknown security tool: $tool"
            return 1
            ;;
    esac
}

run_linting_check() {
    local tool="${1:-shellcheck}"
    local files=("${@:2}")

    case "$tool" in
        "shellcheck")
            if [[ ${#files[@]} -gt 0 ]]; then
                shellcheck "${files[@]}"
            else
                shellcheck ./**/*.sh
            fi
            ;;
        *)
            echo "Unknown linting tool: $tool"
            return 1
            ;;
    esac
}