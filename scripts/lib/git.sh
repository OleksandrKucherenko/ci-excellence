#!/bin/bash
# Git utilities library for CI scripts

# Validate git repository
validate_git_repo() {
    if ! git rev-parse --git-dir &> /dev/null; then
        log_error "Not in a git repository"
        return 1
    fi

    if ! git rev-parse --verify HEAD &> /dev/null; then
        log_error "Git repository has no commits"
        return 1
    fi

    return 0
}

# Get current git information
get_git_info() {
    local commit_hash
    local branch_name
    local tag_name
    local remote_url
    local commit_message

    commit_hash=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
    branch_name=$(git branch --show-current 2>/dev/null || echo "unknown")
    tag_name=$(git describe --tags --exact-match 2>/dev/null || echo "")
    remote_url=$(git remote get-url origin 2>/dev/null || echo "unknown")
    commit_message=$(git log -1 --pretty=format:"%s" 2>/dev/null || echo "unknown")

    echo "commit=$commit_hash"
    echo "branch=$branch_name"
    echo "tag=$tag_name"
    echo "remote=$remote_url"
    echo "message=$commit_message"
}

# Check if commit is tagged
is_commit_tagged() {
    local commit_hash="${1:-HEAD}"

    if git describe --tags --exact-match "$commit_hash" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Get tags for commit
get_commit_tags() {
    local commit_hash="${1:-HEAD}"

    git tag --points-at "$commit_hash" 2>/dev/null || true
}

# Create git tag with atomic operation
create_git_tag() {
    local tag_name="$1"
    local commit_hash="${2:-HEAD}"
    local message="${3:-Tag $tag_name}"
    local force="${4:-false}"

    log_info "Creating git tag: $tag_name"

    if ! git rev-parse --verify "$commit_hash" &> /dev/null; then
        log_error "Invalid commit: $commit_hash"
        return 1
    fi

    local tag_args=()
    if [[ "$force" == "true" ]]; then
        tag_args+=("-f")
    fi

    if [[ -n "$message" ]]; then
        tag_args+=("-m" "$message")
    fi

    if git tag "${tag_args[@]}" "$tag_name" "$commit_hash"; then
        log_success "Git tag created: $tag_name"
        return 0
    else
        log_error "Failed to create git tag: $tag_name"
        return 1
    fi
}

# Delete git tag
delete_git_tag() {
    local tag_name="$1"
    local remote="${2:-origin}"

    log_info "Deleting git tag: $tag_name"

    # Delete local tag
    if git tag -d "$tag_name" 2>/dev/null; then
        log_info "Local tag deleted: $tag_name"
    else
        log_warn "Local tag not found: $tag_name"
    fi

    # Delete remote tag
    if git ls-remote --tags "$remote" | grep -q "refs/tags/$tag_name$"; then
        if git push "$remote" --delete "refs/tags/$tag_name" 2>/dev/null; then
            log_info "Remote tag deleted: $tag_name"
        else
            log_error "Failed to delete remote tag: $tag_name"
            return 1
        fi
    else
        log_info "Remote tag not found: $tag_name"
    fi

    return 0
}

# Push git tag to remote
push_git_tag() {
    local tag_name="$1"
    local remote="${2:-origin}"

    log_info "Pushing git tag to $remote: $tag_name"

    if git push "$remote" "$tag_name"; then
        log_success "Git tag pushed: $tag_name"
        return 0
    else
        log_error "Failed to push git tag: $tag_name"
        return 1
    fi
}

# Get commit history between two points
get_commit_history() {
    local start_commit="${1:-}"
    local end_commit="${2:-HEAD}"
    local limit="${3:-20}"

    local git_log_cmd="git log"

    if [[ -n "$start_commit" ]]; then
        git_log_cmd="$git_log_cmd $start_commit..$end_commit"
    else
        git_log_cmd="$git_log_cmd -n $limit $end_commit"
    fi

    $git_log_cmd --pretty=format:"%H|%s|%an|%ad" --date=iso
}

# Get changed files between commits
get_changed_files() {
    local start_commit="${1:-HEAD~1}"
    local end_commit="${2:-HEAD}"

    git diff --name-only "$start_commit" "$end_commit" 2>/dev/null || true
}

# Check if file changed in commit range
file_changed_in_range() {
    local file_path="$1"
    local start_commit="${2:-HEAD~1}"
    local end_commit="${3:-HEAD}"

    if git diff --name-only "$start_commit" "$end_commit" | grep -q "^$file_path$"; then
        return 0
    else
        return 1
    fi
}

# Get git diff summary
get_diff_summary() {
    local start_commit="${1:-HEAD~1}"
    local end_commit="${2:-HEAD}"

    git diff --stat "$start_commit" "$end_commit" 2>/dev/null || true
}

# Create git revert commit
revert_git_commit() {
    local commit_hash="$1"
    local message="${2:-Revert $commit_hash}"

    log_info "Reverting git commit: $commit_hash"

    if ! git rev-parse --verify "$commit_hash" &> /dev/null; then
        log_error "Invalid commit: $commit_hash"
        return 1
    fi

    if git revert --no-edit -m 1 "$commit_hash"; then
        log_success "Commit reverted: $commit_hash"
        return 0
    else
        log_error "Failed to revert commit: $commit_hash"
        return 1
    fi
}

# Create git cherry-pick
cherry_pick_git_commit() {
    local commit_hash="$1"

    log_info "Cherry-picking git commit: $commit_hash"

    if ! git rev-parse --verify "$commit_hash" &> /dev/null; then
        log_error "Invalid commit: $commit_hash"
        return 1
    fi

    if git cherry-pick "$commit_hash"; then
        log_success "Commit cherry-picked: $commit_hash"
        return 0
    else
        log_error "Failed to cherry-pick commit: $commit_hash"
        return 1
    fi
}

# Get git repository status
get_git_status() {
    local status_output
    status_output=$(git status --porcelain 2>/dev/null || true)

    local modified_files=0
    local added_files=0
    local deleted_files=0
    local untracked_files=0

    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            local status_char="${line:0:1}"
            case "$status_char" in
                "M"|"m")
                    ((modified_files++))
                    ;;
                "A"|"a")
                    ((added_files++))
                    ;;
                "D"|"d")
                    ((deleted_files++))
                    ;;
                "?"|"!")
                    ((untracked_files++))
                    ;;
            esac
        fi
    done <<< "$status_output"

    echo "modified=$modified_files"
    echo "added=$added_files"
    echo "deleted=$deleted_files"
    echo "untracked=$untracked_files"
    echo "total=$((modified_files + added_files + deleted_files + untracked_files))"
}

# Check if working directory is clean
is_working_directory_clean() {
    local status_output
    status_output=$(git status --porcelain 2>/dev/null || true)

    if [[ -z "$status_output" ]]; then
        return 0
    else
        return 1
    fi
}

# Stash changes
stash_git_changes() {
    local message="${1:-Auto-stash at $(date)}"

    log_info "Stashing git changes"

    if git stash push -m "$message"; then
        log_success "Changes stashed"
        return 0
    else
        log_error "Failed to stash changes"
        return 1
    fi
}

# Pop stashed changes
pop_stashed_changes() {
    local stash_index="${1:-0}"

    log_info "Popping stashed changes: $stash_index"

    if git stash pop "stash@{$stash_index}"; then
        log_success "Stashed changes restored"
        return 0
    else
        log_error "Failed to pop stashed changes"
        return 1
    fi
}

# Get git remotes
get_git_remotes() {
    git remote -v 2>/dev/null || true
}

# Check if remote exists
remote_exists() {
    local remote_name="$1"

    if git remote get-url "$remote_name" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Get remote URL
get_remote_url() {
    local remote_name="${1:-origin}"

    git remote get-url "$remote_name" 2>/dev/null || echo ""
}

# Fetch from remote
fetch_from_remote() {
    local remote="${1:-origin}"
    local branch="${2:-}"

    log_info "Fetching from remote: $remote"

    local fetch_cmd="git fetch $remote"
    if [[ -n "$branch" ]]; then
        fetch_cmd="$fetch_cmd $branch"
    fi

    if $fetch_cmd; then
        log_success "Fetched from $remote"
        return 0
    else
        log_error "Failed to fetch from $remote"
        return 1
    fi
}

# Push to remote
push_to_remote() {
    local remote="${1:-origin}"
    local branch="${2:-$(git branch --show-current 2>/dev/null || echo 'main')}"
    local force="${3:-false}"

    log_info "Pushing to remote: $remote/$branch"

    local push_cmd="git push $remote $branch"
    if [[ "$force" == "true" ]]; then
        push_cmd="$push_cmd --force"
    fi

    if $push_cmd; then
        log_success "Pushed to $remote/$branch"
        return 0
    else
        log_error "Failed to push to $remote/$branch"
        return 1
    fi
}

# Get git blame information
get_git_blame() {
    local file_path="$1"
    local line_number="${2:-}"

    if [[ ! -f "$file_path" ]]; then
        log_error "File not found: $file_path"
        return 1
    fi

    local blame_cmd="git blame $file_path"
    if [[ -n "$line_number" ]]; then
        blame_cmd="$blame_cmd -L $line_number,$line_number"
    fi

    $blame_cmd 2>/dev/null || true
}

# Get commit message
get_commit_message() {
    local commit_hash="${1:-HEAD}"

    git log -1 --pretty=format:"%s%n%b" "$commit_hash" 2>/dev/null || echo ""
}

# Get commit author
get_commit_author() {
    local commit_hash="${1:-HEAD}"

    git log -1 --pretty=format:"%an <%ae>" "$commit_hash" 2>/dev/null || echo "Unknown"
}

# Get commit date
get_commit_date() {
    local commit_hash="${1:-HEAD}"
    local format="${2:-iso}"

    git log -1 --date="$format" --pretty=format:"%ad" "$commit_hash" 2>/dev/null || echo ""
}

# Check if commit is merge commit
is_merge_commit() {
    local commit_hash="${1:-HEAD}"

    if git show --summary "$commit_hash" 2>/dev/null | grep -q "^Merge:"; then
        return 0
    else
        return 1
    fi
}

# Get merge commit parents
get_merge_parents() {
    local commit_hash="${1:-HEAD}"

    git rev-list --parents -n 1 "$commit_hash" 2>/dev/null | cut -d' ' -f2- || true
}

# Initialize git repository
init_git_repo() {
    local repo_path="${1:-.}"

    if [[ -d "$repo_path" ]]; then
        cd "$repo_path" || return 1

        if [[ ! -d ".git" ]]; then
            log_info "Initializing git repository: $repo_path"
            if git init; then
                log_success "Git repository initialized"
                return 0
            else
                log_error "Failed to initialize git repository"
                return 1
            fi
        else
            log_info "Git repository already exists"
            return 0
        fi
    else
        log_error "Directory not found: $repo_path"
        return 1
    fi
}