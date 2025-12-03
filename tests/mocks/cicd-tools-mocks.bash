#!/usr/bin/env bash
# CI/CD Tools Mocks Library for BATS Testing
# Provides comprehensive mock implementations for CI/CD tools

# Create mise mock with profile management
create_mise_mock() {
    local mock_bin="${1:-$BATS_TEST_TMPDIR/bin}"
    local mock_mode="${2:-success}"

    mkdir -p "$mock_bin"

    cat > "${mock_bin}/mise" << 'EOF'
#!/bin/bash
# Comprehensive mise mock for testing

MOCK_MODE="${MISE_MOCK_MODE:-success}"
MOCK_PROFILE="${DEPLOYMENT_PROFILE:-local}"

case "$1" in
    "profile")
        case "$2" in
            "current")
                echo "$MOCK_PROFILE"
                ;;
            "list")
                echo "PROFILE     TYPE"
                echo "local       local"
                echo "development development"
                echo "staging     remote"
                echo "production  remote"
                ;;
            "activate")
                export DEPLOYMENT_PROFILE="$3"
                echo "Activated profile: $3"
                ;;
            "show"|"remove"|"delete"|"create")
                echo "Mock mise profile $2 $3"
                ;;
            *)
                echo "Unknown mise profile command: mise profile $2"
                exit 1
                ;;
        esac
        ;;
    "completion")
        case "$2" in
            "zsh")
                echo '#compdef mise'
                ;;
            "bash")
                echo '_mise() { echo "mise completion"; }'
                ;;
            *)
                ;;
        esac
        ;;
    "tasks")
        case "$2" in
            "--list")
                echo "TASK        DESCRIPTION"
                echo "test        Run tests"
                echo "lint        Lint code"
                echo "format      Format code"
                echo "validate    Validate configuration"
                echo "build       Build project"
                echo "deploy      Deploy application"
                ;;
            "run")
                shift 2
                if [[ "${MOCK_MODE}" == "fail" ]]; then
                    echo "Task failed: $*" >&2
                    exit 1
                fi
                echo "Running task: $*"
                ;;
            *)
                echo "Unknown mise tasks command: mise tasks $2"
                exit 1
                ;;
        esac
        ;;
    "run"|"exec")
        shift 1
        if [[ "${MOCK_MODE}" == "fail" ]]; then
            echo "Command failed: mise $*" >&2
            exit 1
        fi
        echo "Mock mise $*"
        ;;
    "--version")
        echo "mise 2024.1.1"
        ;;
    *)
        echo "Mock mise command: mise $*"
        ;;
esac
EOF
    chmod +x "${mock_bin}/mise"
}

# Create sops mock for secret management
create_sops_mock() {
    local mock_bin="${1:-$BATS_TEST_TMPDIR/bin}"

    mkdir -p "$mock_bin"

    cat > "${mock_bin}/sops" << 'EOF'
#!/bin/bash
# Mock sops for secret management

MOCK_MODE="${SOPS_MOCK_MODE:-success}"

case "$1" in
    "--version")
        echo "sops 3.8.1"
        ;;
    "--encrypt"|-e)
        if [[ "${MOCK_MODE}" == "fail" ]]; then
            echo "Encryption failed" >&2
            exit 1
        fi
        if [[ -f "$2" ]]; then
            echo "Encrypted $2 successfully"
        else
            echo "File not found: $2" >&2
            exit 1
        fi
        ;;
    "--decrypt"|-d)
        if [[ "${MOCK_MODE}" == "fail" ]]; then
            echo "Decryption failed" >&2
            exit 1
        fi
        if [[ -f "$2" ]]; then
            # Decrypt to mock content
            case "$2" in
                *.yaml|*.yml)
                    echo "mock_decrypted_content: true"
                    echo "secret_value: decrypted_secret"
                    ;;
                *.json)
                    echo '{"mock_decrypted_content": true, "secret_value": "decrypted_secret"}'
                    ;;
                *)
                    echo "mock_decrypted_content"
                    ;;
            esac
        else
            echo "File not found: $2" >&2
            exit 1
        fi
        ;;
    "--output")
        if [[ "$3" == "--encrypt" ]]; then
            if [[ "${MOCK_MODE}" == "fail" ]]; then
                echo "Encryption failed" >&2
                exit 1
            fi
            echo "Encrypted $4 to $2"
        else
            echo "Mock sops $*"
        fi
        ;;
    *)
        echo "Mock sops $*"
        ;;
esac
EOF
    chmod +x "${mock_bin}/sops"
}

# Create security tools mocks (gitleaks, trufflehog)
create_security_tools_mocks() {
    local mock_bin="${1:-$BATS_TEST_TMPDIR/bin}"

    mkdir -p "$mock_bin"

    # Gitleaks mock
    cat > "${mock_bin}/gitleaks" << 'EOF'
#!/bin/bash
# Mock gitleaks for secret scanning

MOCK_MODE="${GITLEAKS_MOCK_MODE:-success}"
MOCK_FIND_SECRETS="${GITLEAKS_FIND_SECRETS:-false}"

case "$1" in
    "--version")
        echo "gitleaks version v8.18.2"
        ;;
    "detect")
        shift
        while [[ $# -gt 0 ]]; do
            case "$1" in
                "--source")
                    local source="$2"
                    shift 2
                    ;;
                "--report-path")
                    local report="$2"
                    shift 2
                    ;;
                *)
                    shift
                    ;;
            esac
        done

        if [[ "${MOCK_MODE}" == "fail" ]]; then
            echo "Gitleaks execution failed" >&2
            exit 1
        fi

        if [[ "${MOCK_FIND_SECRETS}" == "true" ]]; then
            echo "WARNING: secrets found in repository"
            echo "  - Found AWS key in file: config/production.yaml"
            echo "  - Found password in file: scripts/setup.sh"
            exit 1
        else
            echo "No secrets found"
            exit 0
        fi
        ;;
    "protect")
        echo "Gitleaks protect mode - scanning for secrets"
        if [[ "${MOCK_FIND_SECRETS}" == "true" ]]; then
            echo "Secrets detected! Use gitleaks detect for details."
            exit 1
        fi
        ;;
    *)
        echo "Mock gitleaks $*"
        ;;
esac
EOF
    chmod +x "${mock_bin}/gitleaks"

    # Trufflehog mock
    cat > "${mock_bin}/trufflehog" << 'EOF'
#!/bin/bash
# Mock trufflehog for secret scanning

MOCK_MODE="${TRUFFLEHOG_MOCK_MODE:-success}"
MOCK_FIND_SECRETS="${TRUFFLEHOG_FIND_SECRETS:-false}"

case "$1" in
    "--version")
        echo "trufflehog v3.81.0"
        ;;
    "filesystem")
        shift
        local directory="."
        while [[ $# -gt 0 ]]; do
            case "$1" in
                "--json")
                    local json_output=true
                    shift
                    ;;
                "--entropy")
                    shift
                    ;;
                *)
                    directory="$1"
                    shift
                    ;;
            esac
        done

        if [[ "${MOCK_MODE}" == "fail" ]]; then
            echo "Trufflehog scan failed" >&2
            exit 1
        fi

        if [[ "${MOCK_FIND_SECRETS}" == "true" ]]; then
            if [[ "${json_output}" == "true" ]]; then
                echo '{"detector":"aws","source":{"file":"config.yaml","commit":"abc123"},"raw":"AKIA...","verified":true}'
            else
                echo "Found secret in ${directory}/config.yaml"
                echo "Detector: AWS Access Key"
                echo "Verified: true"
            fi
            exit 1
        else
            if [[ "${json_output}" == "true" ]]; then
                echo "[]"
            else
                echo "No secrets found"
            fi
            exit 0
        fi
        ;;
    "git")
        echo "Scanning git repository for secrets"
        if [[ "${MOCK_FIND_SECRETS}" == "true" ]]; then
            echo "Found secrets in git history"
            exit 1
        fi
        ;;
    *)
        echo "Mock trufflehog $*"
        ;;
esac
EOF
    chmod +x "${mock_bin}/trufflehog"
}

# Create shell tool mocks (shellcheck, shfmt)
create_shell_tools_mocks() {
    local mock_bin="${1:-$BATS_TEST_TMPDIR/bin}"

    mkdir -p "$mock_bin"

    # Shellcheck mock
    cat > "${mock_bin}/shellcheck" << 'EOF'
#!/bin/bash
# Mock shellcheck for shell script linting

MOCK_MODE="${SHELLCHECK_MOCK_MODE:-success}"
MOCK_FIND_ISSUES="${SHELLCHECK_FIND_ISSUES:-false}"

case "$1" in
    "--version")
        echo "ShellCheck - v0.9.0"
        ;;
    "--help"|"-h")
        echo "Usage: shellcheck [OPTIONS] FILES..."
        echo "Check shell scripts for issues"
        ;;
    *)
        local files=()
        while [[ $# -gt 0 ]]; do
            if [[ "$1" == --* ]]; then
                shift
            else
                files+=("$1")
                shift
            fi
        done

        if [[ ${#files[@]} -eq 0 ]]; then
            echo "shellcheck: no input files" >&2
            exit 1
        fi

        if [[ "${MOCK_MODE}" == "fail" ]]; then
            echo "Shellcheck execution failed" >&2
            exit 1
        fi

        if [[ "${MOCK_FIND_ISSUES}" == "true" ]]; then
            for file in "${files[@]}"; do
                echo "In ${file} line 1:"
                echo "SC2034: VAR appears unused. Verify use or consider exporting."
            done
            exit 1
        else
            for file in "${files[@]}"; do
                echo "${file}: OK"
            done
            exit 0
        fi
        ;;
esac
EOF
    chmod +x "${mock_bin}/shellcheck"

    # shfmt mock
    cat > "${mock_bin}/shfmt" << 'EOF'
#!/bin/bash
# Mock shfmt for shell script formatting

MOCK_MODE="${SHFMT_MOCK_MODE:-success}"
MOCK_FORMAT_ISSUES="${SHFMT_FORMAT_ISSUES:-false}"

case "$1" in
    "--version")
        echo "v3.6.0"
        ;;
    "--help"|"-h")
        echo "Usage: shfmt [flags] [path...]"
        echo "Shell script formatter"
        ;;
    "-l")
        # Check mode - list files that need formatting
        shift
        if [[ "${MOCK_FORMAT_ISSUES}" == "true" ]]; then
            for file in "$@"; do
                if [[ "$file" == *.sh ]]; then
                    echo "$file"
                fi
            done
            exit 1
        else
            exit 0
        fi
        ;;
    "-d")
        # Diff mode - show formatting differences
        shift
        if [[ "${MOCK_FORMAT_ISSUES}" == "true" ]]; then
            for file in "$@"; do
                if [[ "$file" == *.sh ]]; then
                    echo "Mock format diff for $file"
                    echo "--- $file"
                    echo "+++ $file"
                    echo "@@ -1,3 +1,3 @@"
                    echo "-echo 'old format'"
                    echo "+echo 'new format'"
                fi
            done
            exit 1
        else
            exit 0
        fi
        ;;
    "-w")
        # Write mode - format files in-place
        shift
        if [[ "${MOCK_MODE}" == "fail" ]]; then
            echo "Failed to format files" >&2
            exit 1
        fi
        for file in "$@"; do
            echo "Formatted $file"
        done
        ;;
    *)
        # Default formatting check
        if [[ "${MOCK_FORMAT_ISSUES}" == "true" ]]; then
            echo "Formatting issues found"
            exit 1
        else
            exit 0
        fi
        ;;
esac
EOF
    chmod +x "${mock_bin}/shfmt"
}

# Create Docker mock
create_docker_mock() {
    local mock_bin="${1:-$BATS_TEST_TMPDIR/bin}"

    mkdir -p "$mock_bin"

    cat > "${mock_bin}/docker" << 'EOF'
#!/bin/bash
# Mock docker for container operations

MOCK_MODE="${DOCKER_MOCK_MODE:-success}"
MOCK_IMAGE_EXISTS="${DOCKER_IMAGE_EXISTS:-true}"
MOCK_CONTAINER_RUNNING="${DOCKER_CONTAINER_RUNNING:-false}"

case "$1" in
    "--version")
        echo "Docker version 24.0.6, build ed223bc"
        ;;
    "build")
        shift
        local tag="latest"
        while [[ $# -gt 0 ]]; do
            case "$1" in
                "-t")
                    tag="$2"
                    shift 2
                    ;;
                *)
                    shift
                    ;;
            esac
        done

        if [[ "${MOCK_MODE}" == "fail" ]]; then
            echo "Docker build failed" >&2
            exit 1
        fi

        echo "Building image with tag: $tag"
        echo "Successfully built image"
        ;;
    "push")
        local image="$2"
        if [[ "${MOCK_MODE}" == "fail" ]]; then
            echo "Failed to push $image" >&2
            exit 1
        fi
        echo "Pushing image: $image"
        echo "Successfully pushed $image"
        ;;
    "pull")
        local image="$2"
        if [[ "${MOCK_MODE}" == "fail" ]]; then
            echo "Failed to pull $image" >&2
            exit 1
        fi
        echo "Pulling image: $image"
        echo "Successfully pulled $image"
        ;;
    "run")
        shift
        local image="$1"
        if [[ "${MOCK_MODE}" == "fail" ]]; then
            echo "Failed to run container: $image" >&2
            exit 1
        fi
        echo "Running container: $image"
        echo "Container started successfully"
        ;;
    "ps")
        if [[ "${MOCK_CONTAINER_RUNNING}" == "true" ]]; then
            echo "CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS"
            echo "abc123         nginx     nginx      1h ago    Up 1h     80->8080"
        else
            echo "CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS"
            echo "No containers running"
        fi
        ;;
    "images")
        if [[ "${MOCK_IMAGE_EXISTS}" == "true" ]]; then
            echo "REPOSITORY   TAG       IMAGE ID   CREATED   SIZE"
            echo "test-app     latest    abc123     1h ago    100MB"
        else
            echo "REPOSITORY   TAG       IMAGE ID   CREATED   SIZE"
            echo "No images found"
        fi
        ;;
    *)
        echo "Mock docker $*"
        ;;
esac
EOF
    chmod +x "${mock_bin}/docker"
}

# Create kubectl mock
create_kubectl_mock() {
    local mock_bin="${1:-$BATS_TEST_TMPDIR/bin}"

    mkdir -p "$mock_bin"

    cat > "${mock_bin}/kubectl" << 'EOF'
#!/bin/bash
# Mock kubectl for Kubernetes operations

MOCK_MODE="${KUBECTL_MOCK_MODE:-success}"
MOCK_CLUSTER_READY="${KUBECTL_CLUSTER_READY:-true}"
MOCK_PODS_RUNNING="${KUBECTL_PODS_RUNNING:-true}"

case "$1" in
    "--version")
        echo "Client Version: v1.28.3"
        echo "Kustomize Version: v5.0.4"
        echo "Server Version: v1.28.3"
        ;;
    "cluster-info")
        if [[ "${MOCK_CLUSTER_READY}" == "true" ]]; then
            echo "Kubernetes control plane is running"
            echo "CoreDNS is running"
            echo "kubelet is running"
        else
            echo "Unable to connect to the server" >&2
            exit 1
        fi
        ;;
    "get")
        shift
        local resource_type="$1"
        local resource_name="$2"
        local namespace="default"

        # Parse options
        while [[ $# -gt 0 ]]; do
            case "$1" in
                "-n"|"--namespace")
                    namespace="$2"
                    shift 2
                    ;;
                *)
                    shift
                    ;;
            esac
        done

        if [[ "${MOCK_MODE}" == "fail" ]]; then
            echo "Failed to get $resource_type $resource_name" >&2
            exit 1
        fi

        case "$resource_type" in
            "pods"|"po")
                if [[ "${MOCK_PODS_RUNNING}" == "true" ]]; then
                    echo "NAME    READY   STATUS    RESTARTS   AGE"
                    echo "app-1   1/1     Running   0          1h"
                else
                    echo "NAME    READY   STATUS    RESTARTS   AGE"
                    echo "No resources found"
                fi
                ;;
            "deployments"|"deploy")
                echo "NAME    READY   UP-TO-DATE   AVAILABLE   AGE"
                echo "app     1/1     1            1           1h"
                ;;
            "services"|"svc")
                echo "NAME    TYPE       CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE"
                echo "app     ClusterIP  10.0.0.1     <none>        80/TCP    1h"
                ;;
            *)
                echo "Unknown resource type: $resource_type" >&2
                exit 1
                ;;
        esac
        ;;
    "apply"|"create"|"delete")
        shift
        echo "kubectl $1 operation completed successfully"
        ;;
    "logs")
        shift
        local pod="$1"
        echo "Mock logs for pod: $pod"
        echo "Application started successfully"
        echo "Health check passed"
        ;;
    *)
        echo "Mock kubectl $*"
        ;;
esac
EOF
    chmod +x "${mock_bin}/kubectl"
}