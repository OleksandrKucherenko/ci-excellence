#!/usr/bin/env bash
# Git Command Mocks Library for BATS Testing
# Provides comprehensive mock implementations for git commands used across tests

# Create git mock with comprehensive functionality
create_git_mock() {
    local mock_bin="${1:-$BATS_TEST_TMPDIR/bin}"
    local mock_mode="${2:-success}"

    mkdir -p "$mock_bin"

    cat > "$mock_bin/git" << 'EOF'
#!/bin/bash
# Comprehensive git mock for testing

# Default behavior
MOCK_MODE="${GIT_MOCK_MODE:-success}"
MOCK_BRANCH="${GIT_MOCK_BRANCH:-main}"
MOCK_SHA="${GIT_MOCK_SHA:-abc123def4567890abcdef1234567890abcdef12}"
MOCK_TAG="${GIT_MOCK_TAG:-v1.0.0}"
MOCK_REMOTE="${GIT_MOCK_REMOTE:-origin}"
MOCK_HAS_CHANGES="${GIT_HAS_CHANGES:-false}"
MOCK_IS_CLEAN="${GIT_IS_CLEAN:-true}"

# Handle git commands
case "$1" in
    "init")
        echo "Initialized git repository"
        return 0
        ;;
    "config")
        echo "Set config $2=$3"
        return 0
        ;;
    "status")
        if [[ "$MOCK_HAS_CHANGES" == "true" ]]; then
            echo "On branch $MOCK_BRANCH"
            echo "Changes not staged for commit:"
            echo "  modified:   test-file.txt"
            return 1
        else
            echo "On branch $MOCK_BRANCH"
            echo "nothing to commit, working tree clean"
            return 0
        fi
        ;;
    "add")
        echo "Added files to staging area"
        return 0
        ;;
    "commit")
        echo "[$MOCK_BRANCH $MOCK_SHA] Test commit message"
        return 0
        ;;
    "push")
        echo "Pushed to $MOCK_REMOTE $MOCK_BRANCH"
        return 0
        ;;
    "pull")
        echo "Pulled from $MOCK_REMOTE $MOCK_BRANCH"
        return 0
        ;;
    "branch")
        case "$2" in
            "--show-current")
                echo "$MOCK_BRANCH"
                ;;
            "-a"|"--all")
                echo "* $MOCK_BRANCH"
                echo "  develop"
                echo "  feature/test"
                ;;
            "-D"|--delete)
                echo "Deleted branch $3"
                ;;
            *)
                echo "* $MOCK_BRANCH"
                echo "  develop"
                echo "  feature/test"
                ;;
        esac
        return 0
        ;;
    "checkout")
        if [[ "$2" == "-b" ]]; then
            MOCK_BRANCH="$3"
            echo "Switched to a new branch '$3'"
        else
            MOCK_BRANCH="$2"
            echo "Switched to branch '$2'"
        fi
        return 0
        ;;
    "merge")
        echo "Merge branch '$2' into $MOCK_BRANCH"
        return 0
        ;;
    "tag")
        case "$2" in
            "-l"|--list)
                echo "$MOCK_TAG"
                echo "v1.1.0"
                echo "v2.0.0"
                ;;
            "-a"|"--annotate")
                if [[ "$3" == "v"[0-9]* ]]; then
                    echo "Created tag $3"
                    MOCK_TAG="$3"
                else
                    echo "Invalid tag format: $3" >&2
                    return 1
                fi
                ;;
            "-f"|"--force")
                echo "Updated tag $4"
                MOCK_TAG="$4"
                ;;
            "-d"|--delete)
                echo "Deleted tag $3"
                ;;
            *)
                echo "Available tags:"
                echo "$MOCK_TAG"
                echo "v1.1.0"
                echo "v2.0.0"
                ;;
        esac
        return 0
        ;;
    "log")
        case "$2" in
            "--oneline")
                echo "$MOCK_SHA Test commit message"
                echo "def4567890abcdef1234567890abcdef12abcdef Previous commit"
                ;;
            "--graph")
                echo "* $MOCK_SHA (HEAD -> $MOCK_BRANCH, tag: $MOCK_TAG) Test commit message"
                echo "* def4567890 (tag: v1.0.0) Previous commit"
                ;;
            *)
                echo "commit $MOCK_SHA"
                echo "Author: Test User <test@example.com>"
                echo "Date:   $(date '+%a %b %d %H:%M:%S %Y %z')"
                echo ""
                echo "    Test commit message"
                ;;
        esac
        return 0
        ;;
    "diff")
        if [[ "$2" == "--name-only" ]]; then
            echo "test-file.txt"
            echo "another-file.txt"
        else
            echo "diff --git a/test-file.txt b/test-file.txt"
            echo "index 1234567..abcdefg 100644"
            echo "--- a/test-file.txt"
            echo "+++ b/test-file.txt"
            echo "@@ -1,3 +1,3 @@"
            echo "-old line"
            echo "+new line"
        fi
        return 0
        ;;
    "show")
        if [[ -n "$2" ]]; then
            echo "commit $2"
            echo "Author: Test User <test@example.com>"
            echo "Date:   $(date '+%a %b %d %H:%M:%S %Y %z')"
            echo ""
            echo "    Commit details for $2"
        else
            echo "show $MOCK_SHA"
        fi
        return 0
        ;;
    "reset")
        case "$2" in
            "--hard")
                echo "HEAD is now at $MOCK_SHA Test commit message"
                ;;
            "--soft")
                echo "Reset to commit $3"
                ;;
            *)
                echo "Reset to $2"
                ;;
        esac
        return 0
        ;;
    "revert")
        echo "Revert commit $2"
        return 0
        ;;
    "stash")
        case "$2" in
            "push")
                echo "Saved working directory and index state WIP on $MOCK_BRANCH: $MOCK_SHA Test commit"
                ;;
            "pop")
                echo "On branch $MOCK_BRANCH"
                echo "Dropped refs/stash@{0}: $MOCK_SHA Test commit"
                ;;
            "list")
                echo "stash@{0}: WIP on $MOCK_BRANCH: $MOCK_SHA Test commit"
                ;;
            *)
                echo "Stash operation: $*"
                ;;
        esac
        return 0
        ;;
    "remote")
        case "$2" in
            "-v")
                echo "$MOCK_REMOTE  git@github.com:user/repo.git (fetch)"
                echo "$MOCK_REMOTE  git@github.com:user/repo.git (push)"
                ;;
            "add")
                echo "Added remote $3"
                ;;
            "remove"|"rm")
                echo "Removed remote $3"
                ;;
            *)
                echo "$MOCK_REMOTE"
                ;;
        esac
        return 0
        ;;
    "fetch")
        echo "Fetching from $MOCK_REMOTE"
        return 0
        ;;
    "clone")
        echo "Cloned repository from $2"
        return 0
        ;;
    "rev-parse")
        case "$2" in
            "--git-dir")
                echo ".git"
                ;;
            "--show-toplevel")
                echo "${FAKE_PROJECT_ROOT:-$(pwd)}"
                ;;
            "HEAD")
                echo "$MOCK_SHA"
                ;;
            "--abbrev-ref")
                case "$3" in
                    "HEAD")
                        echo "$MOCK_BRANCH"
                        ;;
                    *)
                        echo "$3"
                        ;;
                esac
                ;;
            "--short"|"--verify")
                echo "${MOCK_SHA:0:7}"
                ;;
            *)
                echo "$MOCK_SHA"
                ;;
        esac
        return 0
        ;;
    "describe")
        case "$2" in
            "--tags")
                echo "$MOCK_TAG"
                ;;
            "--abbrev=0")
                echo "$MOCK_TAG"
                ;;
            *)
                echo "$MOCK_TAG"
                ;;
        esac
        return 0
        ;;
    "ls-files")
        echo "test-file.txt"
        echo "another-file.txt"
        echo "script.sh"
        return 0
        ;;
    "ls-tree")
        echo "100644 blob abc1234567890abcdef1234567890abcdef12	test-file.txt"
        echo "100644 blob def1234567890abcdef1234567890abcdef12	another-file.txt"
        return 0
        ;;
    "check-ref-format")
        if [[ "$2" =~ ^(refs/heads/|refs/tags/) ]]; then
            return 0
        else
            return 1
        fi
        ;;
    "symbolic-ref")
        case "$2" in
            "--short")
                echo "$MOCK_BRANCH"
                ;;
            "HEAD")
                echo "refs/heads/$MOCK_BRANCH"
                ;;
            *)
                echo "refs/heads/$MOCK_BRANCH"
                ;;
        esac
        return 0
        ;;
    "update-index")
        return 0
        ;;
    "write-tree")
        echo "tree1234567890abcdef1234567890abcdef1234"
        return 0
        ;;
    "commit-tree")
        echo "$MOCK_SHA"
        return 0
        ;;
    "update-ref")
        return 0
        ;;
    "cherry-pick")
        echo "Cherry-picked commit $2"
        return 0
        ;;
    "rebase")
        case "$2" in
            "-i"|"--interactive")
                echo "Interactive rebase started"
                ;;
            *)
                echo "Rebased branch onto $2"
                ;;
        esac
        return 0
        ;;
    "bisect")
        case "$2" in
            "start")
                echo "Bisect started"
                ;;
            "good"|"bad")
                echo "Marked commit as $2"
                ;;
            *)
                echo "Bisect operation: $*"
                ;;
        esac
        return 0
        ;;
    "blame")
        echo "$MOCK_SHA (Test User $(date '+%Y-%m-%d') 1) $3"
        return 0
        ;;
    "grep")
        echo "test-file.txt:1:matching line"
        echo "another-file.txt:5:another match"
        return 0
        ;;
    "archive")
        echo "Created archive $2"
        return 0
        ;;
    "clean")
        echo "Removing test-file.txt"
        return 0
        ;;
    "submodule")
        case "$2" in
            "update")
                echo "Updated submodules"
                ;;
            "add")
                echo "Added submodule $3"
                ;;
            *)
                echo "Submodule operation: $*"
                ;;
        esac
        return 0
        ;;
    "worktree")
        case "$2" in
            "add")
                echo "Added worktree at $3"
                ;;
            "remove")
                echo "Removed worktree at $3"
                ;;
            *)
                echo "Worktree operation: $*"
                ;;
        esac
        return 0
        ;;
    *)
        echo "git $*"
        return 0
        ;;
esac
EOF

    chmod +x "$mock_bin/git"
}

# Configure git mock behavior
configure_git_mock() {
    local branch="${1:-main}"
    local sha="${2:-abc123def4567890abcdef1234567890abcdef12}"
    local tag="${3:-v1.0.0}"
    local remote="${4:-origin}"
    local has_changes="${5:-false}"

    export GIT_MOCK_BRANCH="$branch"
    export GIT_MOCK_SHA="$sha"
    export GIT_MOCK_TAG="$tag"
    export GIT_MOCK_REMOTE="$remote"
    export GIT_HAS_CHANGES="$has_changes"
}

# Set git mock to failure mode
set_git_mock_failure() {
    export GIT_MOCK_MODE="fail"

    local mock_bin="${1:-$BATS_TEST_TMPDIR/bin}"

    cat > "$mock_bin/git" << 'EOF'
#!/bin/bash
echo "git: mock failure mode" >&2
exit 1
EOF

    chmod +x "$mock_bin/git"
}

# Clean up git mock
cleanup_git_mock() {
    unset GIT_MOCK_MODE GIT_MOCK_BRANCH GIT_MOCK_SHA GIT_MOCK_TAG GIT_MOCK_REMOTE GIT_HAS_CHANGES
}

# Helper functions for common git scenarios
setup_git_repo_with_commits() {
    configure_git_mock "main" "abc123def4567890abcdef1234567890abcdef12" "v1.0.0" "origin" "false"
}

setup_git_repo_with_uncommitted_changes() {
    configure_git_mock "feature/test" "def4567890abcdef1234567890abcdef12def456" "v1.1.0-beta" "origin" "true"
}

setup_detached_git_head() {
    configure_git_mock "HEAD" "def4567890abcdef1234567890abcdef12def456" "v1.0.0" "origin" "false"
}

# Test-specific git mock configurations
setup_git_for_deployment_tests() {
    configure_git_mock "main" "deploy123abc456def789ghi012jkl345mno678pqr" "v2.1.0" "origin" "false"
}

setup_git_for_release_tests() {
    configure_git_mock "release" "release456def789ghi012jkl345mno678pqrstu901vwx" "v3.0.0" "origin" "false"
}