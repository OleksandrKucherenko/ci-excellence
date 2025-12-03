#!/usr/bin/env bash
# CI/CD Tool Mocks Library for BATS Testing
# Provides comprehensive mock implementations for CI/CD tools (mise, sops, age, jq, yq)

# Create mise mock with comprehensive functionality
create_mise_mock() {
    local mock_bin="${1:-$BATS_TEST_TMPDIR/bin}"
    local mock_mode="${2:-success}"

    mkdir -p "$mock_bin"

    cat > "$mock_bin/mise" << 'EOF'
#!/bin/bash
# Comprehensive mise mock for testing

# Default behavior
MOCK_MODE="${MISE_MOCK_MODE:-success}"
MOCK_VERSION="${MISE_MOCK_VERSION:-2024.1.1}"
MOCK_PROFILE="${MISE_MOCK_PROFILE:-local}"

# Handle mise commands
case "$1" in
    "--version")
        echo "$MOCK_VERSION"
        return 0
        ;;
    "profile")
        case "$2" in
            "current")
                echo "${MOCK_PROFILE:-local}"
                ;;
            "list")
                echo "PROFILE     TYPE     SOURCE"
                echo "local       local    mise.toml"
                echo "development local    mise.development.toml"
                echo "staging     remote   s3://mise-profiles/staging.toml"
                echo "production  remote   s3://mise-profiles/production.toml"
                ;;
            "activate")
                local profile_name="$3"
                export MISE_ACTIVE_PROFILE="$profile_name"
                echo "Activated profile: $profile_name"
                ;;
            "deactivate")
                unset MISE_ACTIVE_PROFILE
                echo "Deactivated profile"
                ;;
            "show")
                local profile_name="$3"
                echo "Profile: $profile_name"
                echo "Environment:"
                echo "  NODE_ENV=production"
                echo "  DATABASE_URL=postgres://localhost:5432/mydb"
                echo "  REDIS_URL=redis://localhost:6379"
                echo "  API_BASE_URL=https://api.example.com"
                ;;
            "remove"|"rm"|"delete")
                local profile_name="$3"
                echo "Removed profile: $profile_name"
                ;;
            "create")
                local profile_name="$3"
                echo "Created profile: $profile_name"
                ;;
            "edit")
                local profile_name="$3"
                echo "Opening editor for profile: $profile_name"
                ;;
            "validate")
                local profile_name="$3"
                if [[ "$MOCK_MODE" == "fail" ]]; then
                    echo "Validation failed for profile: $profile_name"
                    echo "Error: Missing required environment variable: DATABASE_URL"
                    return 1
                fi
                echo "Profile validation successful: $profile_name"
                ;;
            "export")
                echo "export NODE_ENV=production"
                echo "export DATABASE_URL=postgres://localhost:5432/mydb"
                echo "export REDIS_URL=redis://localhost:6379"
                echo "export API_BASE_URL=https://api.example.com"
                ;;
            "diff")
                local profile1="$3"
                local profile2="$4"
                echo "Diff between profiles:"
                echo "--- $profile1"
                echo "+++ $profile2"
                echo "- NODE_ENV=development"
                echo "+ NODE_ENV=production"
                ;;
            "merge")
                local target_profile="$3"
                shift 3
                local source_profiles=("$@")
                echo "Merged profiles into $target_profile:"
                for profile in "${source_profiles[@]}"; do
                    echo "  + $profile"
                done
                ;;
            "backup")
                local profile_name="$3"
                echo "Created backup of profile: $profile_name"
                ;;
            "restore")
                local profile_name="$3"
                echo "Restored profile from backup: $profile_name"
                ;;
            *)
                echo "Unknown mise profile command: $2"
                return 1
                ;;
        esac
        return 0
        ;;
    "tasks")
        case "$2" in
            "--list"|"-l")
                echo "TASK                                    DESCRIPTION"
                echo "build                                   Build the application"
                echo "test                                    Run tests"
                echo "lint                                    Run linting"
                echo "format                                  Format code"
                echo "clean                                   Clean build artifacts"
                echo "deploy                                  Deploy application"
                echo "validate                                Validate configuration"
                echo "security:scan                           Run security scan"
                echo "database:migrate                        Run database migrations"
                echo "database:seed                           Seed database with test data"
                ;;
            "run")
                local task_name="$3"
                case "$task_name" in
                    "build")
                        echo "Building application..."
                        echo "Build completed successfully"
                        ;;
                    "test")
                        echo "Running tests..."
                        echo "15 tests passed, 0 failed"
                        ;;
                    "lint")
                        echo "Running linting..."
                        echo "Linting completed - no issues found"
                        ;;
                    "format")
                        echo "Formatting code..."
                        echo "Code formatting completed"
                        ;;
                    "clean")
                        echo "Cleaning build artifacts..."
                        echo "Build artifacts cleaned"
                        ;;
                    "deploy")
                        echo "Deploying application..."
                        echo "Application deployed successfully"
                        ;;
                    "validate")
                        echo "Validating configuration..."
                        echo "Configuration is valid"
                        ;;
                    "security:scan")
                        echo "Running security scan..."
                        echo "Security scan completed - no issues found"
                        ;;
                    "database:migrate")
                        echo "Running database migrations..."
                        echo "Migrations completed successfully"
                        ;;
                    "database:seed")
                        echo "Seeding database..."
                        echo "Database seeded successfully"
                        ;;
                    *)
                        echo "Running task: $task_name"
                        echo "Task completed successfully"
                        ;;
                esac
                ;;
            *)
                echo "Unknown mise tasks command: $2"
                return 1
                ;;
        esac
        return 0
        ;;
    "run"|"exec")
        shift
        echo "Running command: $*"
        echo "Command executed successfully"
        return 0
        ;;
    "install")
        local tool_name="$2"
        case "$tool_name" in
            "node@18")
                echo "Installing node@18..."
                echo "node@18.17.0 installed"
                ;;
            "python@3.11")
                echo "Installing python@3.11..."
                echo "python@3.11.5 installed"
                ;;
            "rust@1.75")
                echo "Installing rust@1.75..."
                echo "rust@1.75.0 installed"
                ;;
            *)
                echo "Installing $tool_name..."
                echo "$tool_name installed successfully"
                ;;
        esac
        return 0
        ;;
    "uninstall")
        local tool_name="$2"
        echo "Uninstalling $tool_name..."
        echo "$tool_name uninstalled successfully"
        return 0
        ;;
    "list")
        echo "Tool            Version         Source"
        echo "node            18.17.0         mise"
        echo "python          3.11.5          mise"
        echo "rust            1.75.0          mise"
        echo "go              1.21.5          mise"
        echo "java            17.0.8          mise"
        return 0
        ;;
    "latest")
        local tool_name="$2"
        case "$tool_name" in
            "node")
                echo "18.17.0"
                ;;
            "python")
                echo "3.11.5"
                ;;
            "rust")
                echo "1.75.0"
                ;;
            *)
                echo "latest-version"
                ;;
        esac
        return 0
        ;;
    "where")
        local tool_name="$2"
        echo "~/.local/share/mise/installs/$tool_name/latest/bin/$tool_name"
        return 0
        ;;
    "which")
        local tool_name="$2"
        echo "~/.local/share/mise/installs/$tool_name/latest/bin/$tool_name"
        return 0
        ;;
    "local")
        case "$2" in
            "node@18")
                echo "mise node@18.17.0"
                ;;
            "python@3.11")
                echo "mise python@3.11.5"
                ;;
            "")
                echo "node@18.17.0"
                echo "python@3.11.5"
                ;;
            *)
                echo "mise $2"
                ;;
        esac
        return 0
        ;;
    "global")
        case "$2" in
            "node@18")
                echo "mise node@18.17.0"
                ;;
            "python@3.11")
                echo "mise python@3.11.5"
                ;;
            "")
                echo "node@18.17.0"
                echo "python@3.11.5"
                ;;
            *)
                echo "mise $2"
                ;;
        esac
        return 0
        ;;
    "registry")
        case "$2" in
            "list")
                echo "short        short descriptions"
                echo "long         long descriptions"
                echo "csv          comma separated"
                echo "json         JSON format"
                ;;
            *)
                echo "mise registry $*"
                ;;
        esac
        return 0
        ;;
    "settings")
        case "$2" in
            "get")
                case "$3" in
                    "experimental")
                        echo "true"
                        ;;
                    "verbose")
                        echo "false"
                        ;;
                    "profile_auto_activated")
                        echo "true"
                        ;;
                    *)
                        echo "mise $3"
                        ;;
                esac
                ;;
            "set")
                local setting="$3"
                local value="$4"
                echo "Set $setting to $value"
                ;;
            "unset")
                local setting="$3"
                echo "Unset $setting"
                ;;
            *)
                echo "mise settings $*"
                ;;
        esac
        return 0
        ;;
    "sync")
        echo "Syncing mise configuration..."
        echo "Configuration synced successfully"
        return 0
        ;;
    "doctor")
        echo "Mise Diagnostics:"
        echo "✓ mise is up to date"
        echo "✓ Configuration is valid"
        echo "✓ Tools are properly installed"
        echo "✓ Profile is activated"
        return 0
        ;;
    "completion")
        case "$2" in
            "bash")
                echo "# mise bash completion script"
                echo "_mise_completion() {"
                echo "  # completion logic"
                echo "}"
                ;;
            "zsh")
                echo "#compdef mise"
                echo "_mise() {"
                echo "  # zsh completion logic"
                echo "}"
                ;;
            "fish")
                echo "complete -c mise -f"
                ;;
            *)
                echo "Completion script for $2"
                ;;
        esac
        return 0
        ;;
    "cache")
        case "$2" in
            "clean")
                echo "Cleaning mise cache..."
                echo "Cache cleaned successfully"
                ;;
            "prune")
                echo "Pruning mise cache..."
                echo "Cache pruned successfully"
                ;;
            "status")
                echo "Cache status:"
                echo "  Tools: 234.5 MB"
                echo "  Registry: 45.6 MB"
                echo "  Total: 280.1 MB"
                ;;
            *)
                echo "mise cache $*"
                ;;
        esac
        return 0
        ;;
    "plugins")
        case "$2" in
            "list")
                echo "PLUGIN        URL"
                echo "node          https://github.com/asdf-vm/asdf-nodejs.git"
                echo "python        https://github.com/danhper/asdf-python.git"
                echo "rust          https://github.com/code-lever/asdf-rust.git"
                ;;
            "add")
                local plugin_name="$3"
                echo "Added plugin: $plugin_name"
                ;;
            "remove"|"rm")
                local plugin_name="$3"
                echo "Removed plugin: $plugin_name"
                ;;
            "update")
                local plugin_name="$3"
                echo "Updated plugin: $plugin_name"
                ;;
            *)
                echo "mise plugins $*"
                ;;
        esac
        return 0
        ;;
    "reshim")
        echo "Reshimming mise..."
        echo "Reshim completed successfully"
        return 0
        ;;
    "asdf")
        case "$2" in
            "global")
                echo "mise asdf compatibility mode"
                ;;
            *)
                echo "mise asdf $*"
                ;;
        esac
        return 0
        ;;
    "exec")
        local command="$2"
        shift 2
        echo "Executing '$command' with mise environment"
        echo "Command output"
        return 0
        ;;
    "hook-env")
        echo "export MISE_SHELL=bash"
        echo "export PATH=\"~/.local/share/mise/shims:\$PATH\""
        return 0
        ;;
    "hook-not-found")
        return 0
        ;;
    "activate")
        echo "mise activated"
        return 0
        ;;
    "deactivate")
        echo "mise deactivated"
        return 0
        ;;
    "self-update")
        echo "Checking for updates..."
        echo "mise is up to date"
        return 0
        ;;
    "render")
        echo "Rendering template..."
        echo "Rendered content"
        return 0
        ;;
    "implode")
        echo "Imploding mise installation..."
        echo "mise uninstalled"
        return 0
        ;;
    "help")
        if [[ -n "$2" ]]; then
            echo "Help for mise $2"
            echo ""
            echo "Usage: mise $2 [options]"
            echo "Description of $2 command"
        else
            echo "mise $MOCK_VERSION"
            echo ""
            echo "Runtime Environment Manager (asdf replacement)"
            echo ""
            echo "Usage: mise <COMMAND> [ARGS]..."
            echo ""
            echo "Core Commands:"
            echo "  install       Install a tool version"
            echo "  uninstall     Uninstall a tool version"
            echo "  list          List installed tool versions"
            echo "  latest        Show latest version of a tool"
            echo "  where         Display where a tool version is installed"
            echo "  which         Display which executable will be run"
            echo ""
            echo "Project Commands:"
            echo "  local         Set tool version for local project"
            echo "  global        Set tool version globally"
            echo "  tasks         Run tasks"
            echo "  profile       Manage environment profiles"
            echo ""
            echo "Utility Commands:"
            echo "  doctor        Check mise installation"
            echo "  exec          Execute a command with mise environment"
            echo "  render        Render template files"
            echo "  sync          Sync configuration"
            echo ""
            echo "Other Commands:"
            echo "  activate      Activate mise in shell"
            echo "  alias         Manage tool aliases"
            echo "  cache         Manage mise cache"
            echo "  completion    Generate shell completions"
            echo "  current       Show current tool version"
            echo "  env           mise environment variables"
            echo "  hook-not-found Run if mise command not found"
            echo "  implode       Remove mise installation"
            echo "  install-info  Display build information"
            echo "  link          Create symbolic link"
            echo "  ls-remote     List tool versions available"
            echo "  outdated      Show outdated tool versions"
            echo "  plugins       Manage plugins"
            echo "  prune         Clean unused mise installations"
            echo "  registry      Manage registries"
            echo "  reshim        Rebuild mise shims"
            echo "  self-update   Update mise"
            echo "  settings      Manage settings"
            echo "  shell         Set a tool version for current shell session"
            echo "  trust         Manage trust files"
            echo "  uninstall     Uninstall a tool version"
            echo "  upgrade       Upgrade mise"
            echo "  usage         Print usage information"
            echo "  watch         Watch for file changes and run tasks"
            echo ""
            echo "For more detailed help, see https://mise.jdx.dev"
        fi
        return 0
        ;;
    *)
        echo "Unknown mise command: $1"
        echo "Run 'mise help' for usage information"
        return 1
        ;;
esac
EOF

    chmod +x "$mock_bin/mise"
}

# Create sops mock with comprehensive functionality
create_sops_mock() {
    local mock_bin="${1:-$BATS_TEST_TMPDIR/bin}"
    local mock_mode="${2:-success}"

    mkdir -p "$mock_bin"

    cat > "$mock_bin/sops" << 'EOF'
#!/bin/bash
# Comprehensive sops mock for testing

# Default behavior
MOCK_MODE="${SOPS_MOCK_MODE:-success}"
MOCK_VERSION="${SOPS_MOCK_VERSION:-3.8.1}"

# Handle sops commands
case "$1" in
    "--version")
        echo "$MOCK_VERSION"
        return 0
        ;;
    "-e"|"--encrypt")
        local file="$2"
        echo "Encrypted $file"
        echo "Creating new encrypted file: $file.enc"
        return 0
        ;;
    "-d"|"--decrypt")
        local file="$2"
        if [[ "$MOCK_MODE" == "fail" ]]; then
            echo "Failed to decrypt $file: could not find matching key"
            return 1
        fi
        echo "Decrypted content of $file"
        echo "DATABASE_URL=postgres://localhost:5432/mydb"
        echo "API_SECRET=super-secret-key"
        echo "REDIS_PASSWORD=redis-password"
        return 0
        ;;
    "-r"|"--rotate")
        local file="$2"
        echo "Rotating encryption key for $file"
        echo "Key rotation completed successfully"
        return 0
        ;;
    "--set")
        local file="$2"
        shift 2
        echo "Setting value in $file: $*"
        echo "Value set successfully"
        return 0
        ;;
    "--extract")
        local file="$2"
        local path="$3"
        echo "Extracted value from $file at $path"
        echo "secret-value"
        return 0
        ;;
    "--output-type")
        local format="$2"
        shift 2
        echo "Converted output format to: $format"
        return 0
        ;;
    "-i"|"--in-place")
        local file="$2"
        shift 2
        echo "Modified $file in place"
        return 0
        ;;
    "--kms")
        local kms_key="$2"
        shift 2
        echo "Using KMS key: $kms_key"
        return 0
        ;;
    "--aws-profile")
        local profile="$2"
        shift 2
        echo "Using AWS profile: $profile"
        return 0
        ;;
    "--gcp-kms")
        local kms_key="$2"
        shift 2
        echo "Using GCP KMS key: $kms_key"
        return 0
        ;;
    "--azure-keyvault")
        local keyvault="$2"
        shift 2
        echo "Using Azure Key Vault: $keyvault"
        return 0
        ;;
    "--hc-vault-transit")
        local vault_config="$2"
        shift 2
        echo "Using HashiCorp Vault transit: $vault_config"
        return 0
        ;;
    "--pgp")
        local pgp_key="$2"
        shift 2
        echo "Using PGP key: $pgp_key"
        return 0
        ;;
    "--age")
        local age_key="$2"
        shift 2
        echo "Using age key: $age_key"
        return 0
        ;;
    "--shamir-secret-sharing")
        local threshold="$2"
        shift 2
        echo "Using Shamir Secret Sharing with threshold: $threshold"
        return 0
        ;;
    "--ignore-mac")
        echo "Ignoring MAC verification"
        return 0
        ;;
    "--decrypt-file")
        local input_file="$2"
        local output_file="$3"
        echo "Decrypting $input_file to $output_file"
        return 0
        ;;
    "--encrypt-file")
        local input_file="$2"
        local output_file="$3"
        echo "Encrypting $input_file to $output_file"
        return 0
        ;;
    "--config")
        local config_file="$2"
        echo "Using config file: $config_file"
        return 0
        ;;
    "--verbose")
        echo "Verbose mode enabled"
        return 0
        ;;
    "--disable-version-check")
        echo "Version check disabled"
        return 0
        ;;
    "updatekeys")
        local file="$2"
        echo "Updating keys for $file"
        echo "Key update completed successfully"
        return 0
        ;;
    "publish")
        local file="$2"
        echo "Publishing $file"
        echo "File published successfully"
        return 0
        ;;
    "pubkeys")
        echo "age1ql3z7hjy54pw3hyww5p5t067pytp72mfw5lcsdfhr6z7qjk6s3ysqn0yf99"
        echo "age1qy63h8rca5a3tewx799c5fekurwh3nmcg4qpvr3h7xln9ryl4zqqufqx02v"
        return 0
        ;;
    "groups")
        echo "Available groups:"
        echo "developers"
        echo "admin"
        echo "readonly"
        return 0
        ;;
    "--help")
        if [[ -n "$2" ]]; then
            echo "Help for sops $2"
        else
            echo "Sops $MOCK_VERSION - Secrets OPerationS"
            echo ""
            echo "Usage:"
            echo "  sops [options] FILE"
            echo ""
            echo "Options:"
            echo "  -e, --encrypt                       Encrypt a file"
            echo "  -d, --decrypt                       Decrypt a file"
            echo "  -r, --rotate                        Rotate encryption keys"
            echo "      --set STRING                    Set a specific key in the input file"
            echo "      --extract STRING                Extract a specific key from the input file"
            echo "      --output-type yaml|json|binary  Output format for the encrypted file"
            echo "  -i, --in-place                      Write output back to the same file"
            echo "      --kms KMS_ARN                   KMS key ARN"
            echo "      --gcp-kms KMS_RESOURCE_ID       GCP KMS resource ID"
            echo "      --azure-keyvault KEYVAULT_URL   Azure Key Vault URL"
            echo "      --hc-vault-transit VAULT_CONFIG HashiCorp Vault transit configuration"
            echo "      --pgp PGP_FINGERPRINT           PGP key fingerprint"
            echo "      --age AGE_RECIPIENT             age recipient"
            echo "      --shamir-secret-sharing THRESHOLD"
            echo "      --ignore-mac                    Ignore MAC verification"
            echo "      --decrypt-file                  Decrypt a file to a new file"
            echo "      --encrypt-file                  Encrypt a file to a new file"
            echo "      --config                        Path to sops config file"
            echo "      --verbose                       Print data a little more verbosely"
            echo "      --disable-version-check         Disable sops version check"
            echo ""
            echo "Commands:"
            echo "  updatekeys FILE                     Update encryption keys"
            echo "  publish FILE                        Publish file to S3"
            echo "  pubkeys                             Print public keys"
            echo "  groups                              List groups"
            echo "  help                                Show help"
        fi
        return 0
        ;;
    *)
        echo "Unknown sops command: $1"
        echo "Run 'sops --help' for usage information"
        return 1
        ;;
esac
EOF

    chmod +x "$mock_bin/sops"
}

# Create age mock with comprehensive functionality
create_age_mock() {
    local mock_bin="${1:-$BATS_TEST_TMPDIR/bin}"
    local mock_mode="${2:-success}"

    mkdir -p "$mock_bin"

    cat > "$mock_bin/age" << 'EOF'
#!/bin/bash
# Comprehensive age mock for testing

# Default behavior
MOCK_MODE="${AGE_MOCK_MODE:-success}"
MOCK_VERSION="${AGE_MOCK_VERSION:-v1.1.1}"

# Handle age commands
case "$1" in
    "--version")
        echo "$MOCK_VERSION"
        return 0
        ;;
    "-d"|"--decrypt")
        local file="$2"
        if [[ "$MOCK_MODE" == "fail" ]]; then
            echo "Failed to decrypt $file: no identity matches any recipient"
            return 1
        fi
        echo "Decrypted content from $file"
        echo "This is secret data"
        return 0
        ;;
    "-e"|"--encrypt")
        shift
        local recipients=()
        local file=""

        # Parse arguments
        while [[ $# -gt 0 ]]; do
            case "$1" in
                "-r"|"--recipient")
                    recipients+=("$2")
                    shift 2
                    ;;
                "-R"|"--recipients-file")
                    echo "Using recipients file: $2"
                    shift 2
                    ;;
                "-a"|"--armor")
                    echo "Armor format enabled"
                    shift
                    ;;
                "-i"|"--identity")
                    echo "Using identity: $2"
                    shift 2
                    ;;
                "-j"|"--encrypt-with-passphrase")
                    echo "Encrypting with passphrase"
                    shift
                    ;;
                -*)
                    shift
                    ;;
                *)
                    file="$1"
                    shift
                    ;;
            esac
        done

        if [[ -n "$file" ]]; then
            echo "Encrypted $file for ${#recipients[@]} recipients"
        else
            echo "-----BEGIN AGE ENCRYPTED FILE-----"
            echo "YWdlLWVudHJ5IGJhc2U2NCBlbmNvZGluZw=="
            echo "..."
            echo "-----END AGE ENCRYPTED FILE-----"
        fi
        return 0
        ;;
    "-r"|"--recipient")
        shift
        local recipient="$1"
        echo "Using recipient: $recipient"
        return 0
        ;;
    "-R"|"--recipients-file")
        shift
        local file="$1"
        echo "Using recipients file: $file"
        return 0
        ;;
    "-i"|"--identity")
        shift
        local identity="$1"
        echo "Using identity: $identity"
        return 0
        ;;
    "-p"|"--passphrase")
        echo "Passphrase mode enabled"
        return 0
        ;;
    "-a"|"--armor")
        echo "Armor format enabled"
        return 0
        ;;
    "-j"|"--encrypt-with-passphrase")
        echo "Encrypting with passphrase"
        return 0
        ;;
    "-d"|"--decrypt")
        local file="$2"
        echo "Decrypting $file"
        return 0
        ;;
    "generate")
        echo "age1ql3z7hjy54pw3hyww5p5t067pytp72mfw5lcsdfhr6z7qjk6s3ysqn0yf99"
        return 0
        ;;
    "--encrypt")
        shift
        echo "Encrypting data..."
        echo "Encryption completed"
        return 0
        ;;
    "--decrypt")
        shift
        echo "Decrypting data..."
        echo "Decryption completed"
        return 0
        ;;
    "-o"|"--output")
        local output_file="$2"
        echo "Output will be written to: $output_file"
        return 0
        ;;
    "--help")
        echo "age $MOCK_VERSION"
        echo ""
        echo "Usage:"
        echo "  age [-r RECIPIENT] [-i IDENTITY] [-a] [-o OUTPUT] [INPUT]"
        echo "  age --decrypt [-i IDENTITY] [-o OUTPUT] INPUT"
        echo "  age --encrypt [OPTIONS]"
        echo "  age --decrypt [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  -e, --encrypt                    Encrypt the input to the output"
        echo "  -d, --decrypt                    Decrypt the input to the output"
        echo "  -o, --output OUTPUT              Write the result to the file at path OUTPUT"
        echo "  -a, --armor                       Generate an armored encrypted file"
        echo "  -r, --recipient RECIPIENT         Encrypt to the specified RECIPIENT"
        echo "  -R, --recipients-file FILE       Encrypt to recipients listed at FILE"
        echo "  -i, --identity IDENTITY           Use the identity file at IDENTITY"
        echo "  -j, --encrypt-with-passphrase    Encrypt with a passphrase"
        echo "  -p, --passphrase                  Same as -j"
        echo ""
        echo "Examples:"
        echo "  $ age -r age1ql3z7hjy54pw3hyww5p5t067pytp72mfw5lcsdfhr6z7qjk6s3ysqn0yf99 secrets.txt > secrets.txt.age"
        echo "  $ age -d -i key.txt secrets.txt.age > secrets.txt"
        echo "  $ age --encrypt -r -p -o secrets.txt.age secrets.txt"
        echo ""
        echo "Recipient format:"
        echo "  age1ql3z7hjy54pw3hyww5p5t067pytp72mfw5lcsdfhr6z7qjk6s3ysqn0yf99"
        echo ""
        echo "Identity format:"
        echo "  AGE-SECRET-KEY-1QL3Z7HJY54PW3HYWW5P5T067PYTP72MFW5LC"
        echo "  age1ql3z7hjy54pw3hyww5p5t067pytp72mfw5lcsdfhr6z7qjk6s3ysqn0yf99"
        return 0
        ;;
    *)
        echo "Unknown age command: $1"
        echo "Run 'age --help' for usage information"
        return 1
        ;;
esac
EOF

    chmod +x "$mock_bin/age"
}

# Create jq mock with comprehensive functionality
create_jq_mock() {
    local mock_bin="${1:-$BATS_TEST_TMPDIR/bin}"
    local mock_mode="${2:-success}"

    mkdir -p "$mock_bin"

    cat > "$mock_bin/jq" << 'EOF'
#!/bin/bash
# Comprehensive jq mock for testing

# Default behavior
MOCK_MODE="${JQ_MOCK_MODE:-success}"
MOCK_VERSION="${JQ_MOCK_VERSION:-jq-1.6}"

# Handle jq commands
case "$1" in
    "--version")
        echo "$MOCK_VERSION"
        return 0
        ;;
    "--help")
        echo "jq - commandline JSON processor [version 1.6]"
        echo ""
        echo "Usage: jq [options] <jq filter> [file...]"
        echo ""
        echo "jq is a tool for processing JSON inputs, applying the given filter to"
        echo "its JSON text inputs and producing the filter's results as JSON."
        echo ""
        echo "The simplest filter is ., which copies jq's input to its output"
        echo "unmodified (that's the identity operator)."
        echo ""
        echo "For more advanced filters see the jq(1) manpage (\"man jq\")"
        echo "and/or https://stedolan.github.io/jq"
        echo ""
        echo "Example:"
        echo ""
        echo "    $ echo '{\"foo\": 0}' | jq ."
        echo "    {"
        echo "      \"foo\": 0"
        echo "    }"
        echo ""
        echo "Some of the options include:"
        echo "  -c             compact instead of pretty-printed output;"
        echo "  -n             use \`null\` as the single input value;"
        echo "  -e             set exit status code based on the output;"
        echo "  -s             read (slurp) all inputs into an array; apply filter to it;"
        echo "  -r             output raw strings, not JSON texts;"
        echo "  -R             read raw strings, not JSON texts;"
        echo "  -C             colorize JSON;"
        echo "  -M             monochrome (don't colorize JSON);"
        echo "  -S             sort keys of objects on output;"
        echo "  --tab          use tabs for indentation;"
        echo "  --arg a v      set variable \\$a to value <v>;"
        echo "  --argjson a v  set variable \\$a to JSON value <v>;"
        echo "  --slurpfile a f set variable \\$a to an array of JSON texts read from <f>;"
        echo "  --rawfile a f  set variable \\$a to string containing contents of <f>;"
        echo "  --args         remaining arguments are positional string arguments;"
        echo "  --jsonargs     remaining arguments are positional JSON arguments."
        return 0
        ;;
    *)
        # Default jq behavior for JSON processing
        local filter="$1"
        shift

        if [[ "$MOCK_MODE" == "fail" ]]; then
            echo "jq: error: parse error: Invalid numeric literal at line 1, column 5" >&2
            return 1
        fi

        # Mock common jq filters
        case "$filter" in
            ".")
                if [[ -t 0 ]]; then
                    # Reading from file argument
                    local file="$1"
                    if [[ -f "$file" ]]; then
                        cat "$file"
                    else
                        echo '{"test": "data"}'
                    fi
                else
                    # Reading from stdin
                    cat
                fi
                ;;
            ".key")
                echo '"value"'
                ;;
            ".name")
                echo '"test-project"'
                ;;
            ".version")
                echo '"1.0.0"'
                ;;
            ".environment")
                echo '"production"'
                ;;
            ".dependencies")
                echo '["node", "npm", "typescript"]'
                ;;
            ".dependencies[]")
                echo "node"
                echo "npm"
                echo "typescript"
                ;;
            ".scripts.start")
                echo '"node server.js"'
                ;;
            ".scripts.*")
                echo '"node server.js"'
                echo '"jest"'
                echo '"eslint ."'
                ;;
            "keys")
                echo '["name", "version", "dependencies", "scripts"]'
                ;;
            "has")
                echo "true"
                ;;
            "length")
                echo "3"
                ;;
            ".[]")
                echo "item1"
                echo "item2"
                echo "item3"
                ;;
            ".foo // .bar")
                echo '"fallback value"'
                ;;
            ".foo + .bar")
                echo '"concatenated value"'
                ;;
            ".foo == \"test\"")
                echo "true"
                ;;
            ".foo | .bar")
                echo '"nested value"'
                ;;
            "map(.name)")
                echo '"item1"'
                echo '"item2"'
                ;;
            "select(.enabled == true)")
                echo '{"name": "enabled-item", "enabled": true}'
                ;;
            "{name: .name, version: .version}")
                echo '{"name": "test-project", "version": "1.0.0"}'
                ;;
            ". + {\"new_field\": \"value\"}")
                echo '{"name": "test-project", "version": "1.0.0", "new_field": "value"}'
                ;;
            *)
                # Generic mock response for unknown filters
                if [[ -t 0 ]]; then
                    echo '{"result": "mock jq output for '"$filter"'"}'
                else
                    echo '{"result": "mock jq output"}'
                fi
                ;;
        esac
        return 0
        ;;
esac
EOF

    chmod +x "$mock_bin/jq"
}

# Create yq mock with comprehensive functionality
create_yq_mock() {
    local mock_bin="${1:-$BATS_TEST_TMPDIR/bin}"
    local mock_mode="${2:-success}"

    mkdir -p "$mock_bin"

    cat > "$mock_bin/yq" << 'EOF'
#!/bin/bash
# Comprehensive yq mock for testing

# Default behavior
MOCK_MODE="${YQ_MOCK_MODE:-success}"
MOCK_VERSION="${YQ_MOCK_VERSION:-yq version 4.35.2}"

# Handle yq commands
case "$1" in
    "--version")
        echo "$MOCK_VERSION"
        return 0
        ;;
    "--help")
        echo "yq is a portable command-line YAML, JSON, XML, CSV and properties processor"
        echo ""
        echo "Usage:"
        echo "  yq [flags] <expression> [FILE(s)...]"
        echo ""
        echo "Examples:"
        echo "  # read from stdin"
        echo "  cat data.yml | yq '.a.b[0].c'"
        echo ""
        echo "  # read from file"
        echo "  yq '.a.b[0].c' data.yml"
        echo ""
        echo "  # read multiple files"
        echo "  yq '.a' file1.yml file2.yml"
        echo ""
        echo "  # merge files"
        echo "  yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' file1.yml file2.yml"
        echo ""
        echo "Flags:"
        echo "      --eval-color string       Force colored output"
        echo "      --eval-flags string       Pass extra flags to the eval command"
        echo "      --input-format string     Input format (yaml, json, xml, csv, properties)"
        echo "      --output-format string    Output format (yaml, json, xml, csv, props)"
        echo "      --unwrapScalar            Unwrap scalars (arrays of scalars)"
        echo "  -C, --colors                  Force colored output"
        echo "  -I, --indent int              indent level (default 2)"
        echo "  -M, --unwrap-scalars          Unwrap scalars (arrays of scalars)"
        echo "  -N, --no-colors               Disable color output"
        echo "  -P, --prettyPrint             Pretty print (indent level 2, yaml output format)"
        echo "  -v, --verbose                 Verbose logging"
        echo "  -i, --inplace                 Update the file in place"
        echo "      --exists-exit-code         Exit with non-zero code when expression returns null"
        echo "  -n, --null-input              Don't read input"
        echo "      --arg string               Set variable (multiple --arg can be provided)"
        echo "      --argjson string           Set variable (multiple --argjson can be provided)"
        echo "      --from-file string         Load variable from file (multiple --from-file can be provided)"
        echo "      --input-decoder string     Set input decoder"
        echo "      --output-encoder string    Set output encoder"
        echo "      --properties-separator string"
        echo "                                Set properties separator"
        echo "      --csv-separator string     Set csv separator"
        echo "  -j, --tojson                   Output as json"
        echo "  -o, --output-format string     Output format (yaml, json, xml, csv, props)"
        echo "  -I, --indent int               Indent level (default 2)"
        echo "      --unwrapScalar             Unwrap scalars (arrays of scalars)"
        echo "  -p, --prettyPrint              Pretty print (indent level 2, yaml output format)"
        echo "  -C, --colors                  Force colored output"
        echo "  -N, --no-colors               Disable color output"
        echo "  -M, --unwrap-scalars          Unwrap scalars (arrays of scalars)"
        echo "  -v, --verbose                 Verbose logging"
        echo "  -i, --inplace                 Update the file in place"
        echo "      --exists-exit-code         Exit with non-zero code when expression returns null"
        echo "  -n, --null-input              Don't read input"
        echo "      --arg string               Set variable (multiple --arg can be provided)"
        echo "      --argjson string           Set variable (multiple --argjson can be provided)"
        echo "      --from-file string         Load variable from file (multiple --from-file can be provided)"
        echo "      --input-decoder string     Set input decoder"
        echo "      --output-encoder string    Set output encoder"
        echo "      --properties-separator string"
        echo "                                Set properties separator"
        echo "      --csv-separator string     Set csv separator"
        echo "      --help                     Show help message"
        echo "      --version                  Show version"
        return 0
        ;;
    "eval")
        shift
        local expression="$1"
        shift

        if [[ "$MOCK_MODE" == "fail" ]]; then
            echo "yq: Error: bad expression: $expression" >&2
            return 1
        fi

        # Mock common yq expressions
        case "$expression" in
            ".environment.type")
                echo "production"
                ;;
            ".environment.description")
                echo "Production environment"
                ;;
            ".environment.region")
                echo "us-east-1"
                ;;
            ".services[]")
                echo "web"
                echo "api"
                echo "database"
                ;;
            ".services[] | select(.name == \"web\")")
                echo "name: web"
                echo "version: \"1.0.0\""
                echo "replicas: 3"
                ;;
            ".services | length")
                echo "3"
                ;;
            ".services[].name")
                echo "web"
                echo "api"
                echo "database"
                ;;
            ".has(.database)")
                echo "true"
                ;;
            ".database.host")
                echo "localhost"
                ;;
            ".database.port")
                echo "5432"
                ;;
            ".database | .host + \":\" + (.port | tostring)")
                echo "localhost:5432"
                ;;
            ". + {\"new_key\": \"new_value\"}")
                echo "environment:"
                echo "  type: production"
                echo "  description: Production environment"
                echo "new_key: new_value"
                ;;
            ".environment.type = \"staging\"")
                echo "environment:"
                echo "  type: staging"
                echo "  description: Production environment"
                ;;
            "keys")
                echo "environment"
                echo "services"
                echo "database"
                ;;
            ". |= . + {\"new_section\": {\"enabled\": true}}")
                echo "environment:"
                echo "  type: production"
                echo "services: []"
                echo "new_section:"
                echo "  enabled: true"
                ;;
            ".database // null")
                echo "host: localhost"
                echo "port: 5432"
                ;;
            ".services | map(select(.replicas > 2))")
                echo "- name: web"
                echo "  replicas: 3"
                ;;
            "*")
                echo "environment:"
                echo "  type: production"
                echo "services:"
                echo "  - name: web"
                echo "    version: \"1.0.0\""
                echo "database:"
                echo "  host: localhost"
                echo "  port: 5432"
                ;;
            *)
                # Generic mock response for unknown expressions
                echo "mock_yq_output_for_$expression"
                ;;
        esac
        return 0
        ;;
    *)
        # Default yq behavior for YAML processing
        local expression="$1"
        shift

        if [[ "$MOCK_MODE" == "fail" ]]; then
            echo "yq: Error: bad expression: $expression" >&2
            return 1
        fi

        # Mock common yq filters (same as eval)
        case "$expression" in
            ".environment.type")
                echo "production"
                ;;
            ".environment.description")
                echo "Production environment"
                ;;
            ".services[]")
                echo "web"
                echo "api"
                ;;
            ".services | length")
                echo "2"
                ;;
            ".")
                if [[ -t 0 ]]; then
                    # Reading from file argument
                    local file="$1"
                    if [[ -f "$file" ]]; then
                        cat "$file"
                    else
                        echo "environment:"
                        echo "  type: production"
                        echo "services: []"
                    fi
                else
                    # Reading from stdin
                    cat
                fi
                ;;
            *)
                # Generic mock response for unknown expressions
                if [[ -t 0 ]]; then
                    echo "mock_yq_output_for_$expression"
                else
                    echo "mock_yq_output"
                fi
                ;;
        esac
        return 0
        ;;
esac
EOF

    chmod +x "$mock_bin/yq"
}

# Configure CI/CD tool mocks behavior
configure_cicd_tool_mocks() {
    local mode="${1:-success}"
    local mise_version="${2:-2024.1.1}"
    local sops_version="${3:-3.8.1}"
    local age_version="${4:-v1.1.1}"
    local jq_version="${5:-jq-1.6}"
    local yq_version="${6:-yq version 4.35.2}"

    export MISE_MOCK_MODE="$mode"
    export SOPS_MOCK_MODE="$mode"
    export AGE_MOCK_MODE="$mode"
    export JQ_MOCK_MODE="$mode"
    export YQ_MOCK_MODE="$mode"

    export MISE_MOCK_VERSION="$mise_version"
    export SOPS_MOCK_VERSION="$sops_version"
    export AGE_MOCK_VERSION="$age_version"
    export JQ_MOCK_VERSION="$jq_version"
    export YQ_MOCK_VERSION="$yq_version"
}

# Set CI/CD tool mocks to failure mode
set_cicd_tool_mocks_failure() {
    configure_cicd_tool_mocks "fail"
}

# Clean up CI/CD tool mocks
cleanup_cicd_tool_mocks() {
    unset MISE_MOCK_MODE SOPS_MOCK_MODE AGE_MOCK_MODE JQ_MOCK_MODE YQ_MOCK_MODE
    unset MISE_MOCK_VERSION SOPS_MOCK_VERSION AGE_MOCK_VERSION JQ_MOCK_VERSION YQ_MOCK_VERSION
}

# Create all CI/CD tool mocks
create_all_cicd_tool_mocks() {
    local mock_bin="${1:-$BATS_TEST_TMPDIR/bin}"
    local mock_mode="${2:-success}"

    create_mise_mock "$mock_bin" "$mock_mode"
    create_sops_mock "$mock_bin" "$mock_mode"
    create_age_mock "$mock_bin" "$mock_mode"
    create_jq_mock "$mock_bin" "$mock_mode"
    create_yq_mock "$mock_bin" "$mock_mode"
}

# Helper functions for common scenarios
setup_cicd_tools_for_development() {
    configure_cicd_tool_mocks "success" "2024.1.1" "3.8.1" "v1.1.1" "jq-1.6" "yq version 4.35.2"
}

setup_cicd_tools_for_production() {
    configure_cicd_tool_mocks "success" "2024.1.1" "3.8.1" "v1.1.1" "jq-1.6" "yq version 4.35.2"
    export MISE_MOCK_PROFILE="production"
}

setup_cicd_tools_for_encryption_failure() {
    configure_cicd_tool_mocks "fail"
    export SOPS_MOCK_MODE="fail"
    export AGE_MOCK_MODE="fail"
}

# Mock tool detection functions
detect_cicd_tool() {
    if command -v mise >/dev/null 2>&1; then
        echo "mise"
    elif command -v rtx >/dev/null 2>&1; then
        echo "rtx"
    elif command -v asdf >/dev/null 2>&1; then
        echo "asdf"
    else
        echo "none"
    fi
}

# Decrypt encrypted file using available tools
decrypt_secrets_file() {
    local file="$1"

    if command -v sops >/dev/null 2>&1; then
        sops -d "$file"
    elif command -v age >/dev/null 2>&1; then
        age -d -i ~/.age/identity.txt "$file"
    else
        echo "No decryption tool available"
        return 1
    fi
}