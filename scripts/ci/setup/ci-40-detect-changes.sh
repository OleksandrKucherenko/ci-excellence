#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_ci-common.sh"

# CI Script: Detect Changes
# Purpose: Compute which "change gates" fire for the current diff so that
#   workflows can skip jobs whose inputs did not change. Gates come from two
#   layers: workspaces auto-discovered from the monorepo folder structure
#   (with dependency edges read from graph-metadata.json or package.json),
#   then user-defined rules merged on top (config/detect-changes.rules).
#   A gate fires when any file under any gate of its transitive dependency
#   closure changed between the base ref and HEAD.
# Hooks: begin, end (automatic)
#   ci-cd/ci-40-detect-changes/begin_*.sh - override CI_* inputs below via
#   the contract:env:NAME=VALUE protocol before detection runs
#
# Inputs (env):
#   CI_CHANGES_RULES      - rules file (default: config/detect-changes.rules)
#   CI_CHANGES_DISCOVER   - workspace roots to scan, space-separated
#                           ("none" disables; default: packages/ apps/
#                           services/ libs/ www/ or the rules "discover:")
#   CI_CHANGES_METADATA   - per-workspace metadata file priority (default:
#                           graph-metadata.json package.json, or "metadata:")
#   CI_BASE_SHA           - explicit git ref to diff against (optional)
#   CI_FORCE_ALL_GATES    - "true" turns every gate on without diffing
#   ENABLE_DETECT_CHANGES - any value but "true" turns every gate on
#   GITHUB_BASE_REF       - PR base branch, fallback when CI_BASE_SHA empty
#   GITHUB_EVENT_BEFORE   - push "before" SHA, fallback when CI_BASE_SHA empty
#
# Outputs (GITHUB_OUTPUT):
#   <gate>=true|false  - one per gate (discovered + rules)
#   any=true|false     - true when at least one gate fired
#   gates              - space-separated list of fired gates
#   gates_json         - same list as a JSON array (for fromJSON matrices)
#
# Fail-open: tag builds, unresolvable base (first commit, forced push,
# shallow clone), git failures and missing rules all turn every gate ON.
# Running too much is safe; silently skipping work is not.

echo:Setup "Detect Changes"

hooks:do begin "${BASH_SOURCE[0]##*/}"
hooks:flow:apply

# Resolve inputs after hooks so begin hooks can override them via contracts.
# shellcheck disable=SC2154 # _REPO_ROOT is set by _ci-common.sh
RULES_FILE="${CI_CHANGES_RULES:-${_REPO_ROOT}/config/detect-changes.rules}"
FORCE_ALL="${CI_FORCE_ALL_GATES:-false}"
DETECT_ENABLED="${ENABLE_DETECT_CHANGES:-true}"
DISCOVER_ROOTS_DEFAULT="packages/ apps/ services/ libs/ www/"
METADATA_FILES_DEFAULT="graph-metadata.json package.json"
DISCOVER_ROOTS=""
METADATA_FILES=""

ci:param setup "CI_CHANGES_RULES" "$RULES_FILE"
ci:optional setup "CI_CHANGES_DISCOVER"
ci:optional setup "CI_CHANGES_METADATA"
ci:optional setup "CI_BASE_SHA"
ci:param setup "CI_FORCE_ALL_GATES" "$FORCE_ALL"
ci:param setup "ENABLE_DETECT_CHANGES" "$DETECT_ENABLED"

# Gate registry. Patterns and edges are space-separated strings; edges hold
# raw refs (workspace package names or gate keys) resolved lazily so that
# rules may reference discovered gates and vice versa.
declare -A GATE_PATTERNS=() GATE_EDGES=() GATE_ALIAS=()
GATE_ORDER=()

# Sanitize a workspace dir/basename into a GITHUB_OUTPUT-safe gate key.
gates:key() {
  local s="${1//[^A-Za-z0-9_-]/_}"
  echo "$s"
}

gates:register() { # <key> -> ensures the gate exists, preserving order
  local key="$1"
  if [ -z "${GATE_PATTERNS[$key]+x}" ]; then
    GATE_PATTERNS[$key]=""
    GATE_EDGES[$key]=""
    GATE_ORDER+=("$key")
  fi
}

# Parse the rules file: directives (discover:/metadata:) and manual gates.
# Globbing must be off — pattern tokens like *.md would expand against CWD.
gates:parse_rules() {
  local line key rest token
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%%#*}"
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [ -z "$line" ] && continue
    if [[ "$line" != *:* ]]; then
      echo:Setup "  skipping malformed rule: ${line}"
      continue
    fi
    key="${line%%:*}"
    key="${key%"${key##*[![:space:]]}"}"
    rest="${line#*:}"
    case "$key" in
      discover) DISCOVER_ROOTS="${DISCOVER_ROOTS:-${rest}}" ;;
      metadata) METADATA_FILES="${METADATA_FILES:-${rest}}" ;;
      *)
        if ! [[ "$key" =~ ^[A-Za-z0-9_-]+$ ]]; then
          echo:Setup "  skipping invalid gate name: ${key}"
          continue
        fi
        gates:register "$key"
        # shellcheck disable=SC2086 # word splitting is the token parser
        for token in $rest; do
          if [[ "$token" == @* ]]; then
            GATE_EDGES[$key]+=" $token"
          else
            GATE_PATTERNS[$key]+=" $token"
          fi
        done
        ;;
    esac
  done <"$RULES_FILE"
}

# Extract "name<TAB>edge edge ..." from a workspace metadata file.
# package.json mode counts only workspace:/file:/link: dependencies as
# internal edges; any other metadata file (graph-metadata.json) is a
# dependency-graph subset by definition, so every key counts. Both modes
# add the top-level runtimeDependencies array (runtime HTTP/RPC edges that
# no bundler or lockfile can see).
gates:read_meta() { # <file> <mode:package|graph>
  local file="$1" mode="$2" filter
  if [ "$mode" = "package" ]; then
    filter='select(.value | type == "string" and (startswith("workspace:") or startswith("file:") or startswith("link:"))) | .key'
  else
    filter='.key'
  fi
  jq -r '. as $doc
    | ([ ((($doc.dependencies // {}) + ($doc.devDependencies // {})) | to_entries[] | '"$filter"'),
         (($doc.runtimeDependencies // [])[] | select(type == "string")) ]
       | unique) as $edges
    | "\($doc.name // "")\t\($edges | join(" "))"' "$file" 2>/dev/null
}

# Scan workspace roots one level deep and register a gate per workspace.
# Requires globbing ON (directory iteration) and jq.
gates:discover() {
  local root dir base meta meta_line name edges mode key i
  local -a disc_dirs=() disc_names=() disc_edges=()
  local -A base_count=()

  if ! command -v jq >/dev/null 2>&1; then
    echo:Setup "  jq not found - workspace discovery skipped, using rules only"
    return 0
  fi

  # shellcheck disable=SC2086 # roots are intentionally space-separated
  for root in $DISCOVER_ROOTS; do
    root="${root%/}"
    [ -d "$root" ] || continue
    for dir in "$root"/*/; do
      [ -d "$dir" ] || continue
      dir="${dir%/}"
      meta_line=""
      # shellcheck disable=SC2086
      for meta in $METADATA_FILES; do
        [ -f "$dir/$meta" ] || continue
        mode="graph"
        [ "$meta" = "package.json" ] && mode="package"
        if meta_line="$(gates:read_meta "$dir/$meta" "$mode")"; then
          break
        fi
        echo:Setup "  unreadable metadata ${dir}/${meta}, trying next"
        meta_line=""
      done
      [ -n "$meta_line" ] || continue
      name="${meta_line%%$'\t'*}"
      edges="${meta_line#*$'\t'}"
      disc_dirs+=("$dir")
      disc_names+=("$name")
      disc_edges+=("$edges")
      base="${dir##*/}"
      base_count[$base]=$((${base_count[$base]:-0} + 1))
    done
  done

  for i in "${!disc_dirs[@]}"; do
    dir="${disc_dirs[$i]}"
    base="${dir##*/}"
    if [ "${base_count[$base]}" -gt 1 ]; then
      key="$(gates:key "$dir")"
    else
      key="$(gates:key "$base")"
    fi
    gates:register "$key"
    GATE_PATTERNS[$key]+=" ${dir}/"
    GATE_EDGES[$key]+=" ${disc_edges[$i]}"
    [ -n "${disc_names[$i]}" ] && GATE_ALIAS[${disc_names[$i]}]="$key"
  done

  echo:Setup "  discovered ${#disc_dirs[@]} workspace(s) in: ${DISCOVER_ROOTS}"
}

# Resolve an edge ref (package name or gate key, with or without a leading
# "@" sigil) to a gate key. Unresolvable refs are external deps — dropped.
gates:resolve_ref() {
  local ref="$1" stripped="${1#@}"
  if [ -n "${GATE_ALIAS[$ref]+x}" ]; then
    echo "${GATE_ALIAS[$ref]}"
  elif [ -n "${GATE_ALIAS[$stripped]+x}" ]; then
    echo "${GATE_ALIAS[$stripped]}"
  elif [ -n "${GATE_PATTERNS[$stripped]+x}" ]; then
    echo "$stripped"
  else
    return 1
  fi
}

# Transitive closure of a gate over the dependency edges (iterative DFS).
gates:closure() {
  local -A visited=()
  local -a stack=("$1")
  local current ref key top
  while [ "${#stack[@]}" -gt 0 ]; do
    top=$((${#stack[@]} - 1))
    current="${stack[$top]}"
    unset "stack[$top]"
    [ -n "${visited[$current]+x}" ] && continue
    visited[$current]=1
    # shellcheck disable=SC2086
    for ref in ${GATE_EDGES[$current]:-}; do
      key="$(gates:resolve_ref "$ref")" || continue
      [ -n "${visited[$key]+x}" ] || stack+=("$key")
    done
  done
  echo "${!visited[@]}"
}

# Match one repo-relative path against one rules pattern.
gates:match() { # <file> <pattern>
  local file="$1" pattern="$2"
  if [[ "$pattern" == */ ]]; then
    [[ "$file" == "$pattern"* ]]
  else
    # shellcheck disable=SC2053 # unquoted RHS is intentional: glob match
    [[ "$file" == $pattern ]]
  fi
}

# Resolve the diff base: explicit > PR base branch > push before-SHA > HEAD~1.
gates:resolve_base() {
  local base="${CI_BASE_SHA:-}"
  if [[ "$base" =~ ^0+$ ]]; then base=""; fi # all-zero SHA = branch creation
  if [ -n "$base" ]; then
    echo "$base"
    return 0
  fi
  if [ -n "${GITHUB_BASE_REF:-}" ]; then
    echo "origin/${GITHUB_BASE_REF}"
    return 0
  fi
  base="${GITHUB_EVENT_BEFORE:-}"
  if [ -n "$base" ] && ! [[ "$base" =~ ^0+$ ]] &&
    git cat-file -e "${base}^{commit}" 2>/dev/null; then
    echo "$base"
    return 0
  fi
  if git rev-parse -q --verify "HEAD~1" >/dev/null 2>&1; then
    echo "HEAD~1"
    return 0
  fi
  return 1
}

# Emit every gate with the same state, plus the aggregate outputs.
gates:emit_all() { # <state> <reason>
  local state="$1" reason="$2" gate fired=() json=""
  echo:Setup "All gates ${state}: ${reason}"
  for gate in "${GATE_ORDER[@]}"; do
    ci:output setup "$gate" "$state"
    [ "$state" = "true" ] && fired+=("$gate")
  done
  if [ "${#fired[@]}" -gt 0 ]; then
    json="$(printf '"%s",' "${fired[@]}")"
  fi
  ci:output setup "any" "true"
  ci:output setup "gates" "${fired[*]:-}"
  ci:output setup "gates_json" "[${json%,}]"
  echo:Success "Detect Changes Done"
  exit 0
}

# ci:output writes to GITHUB_OUTPUT unconditionally — default it for local runs.
export GITHUB_OUTPUT="${GITHUB_OUTPUT:-/dev/null}"

# --- Build the gate registry (rules first for directives, then discovery) ---
set -f # patterns like *.md must not glob against the working tree
if [ -f "$RULES_FILE" ]; then
  gates:parse_rules
else
  echo:Setup "  rules file not found: ${RULES_FILE} (discovery only)"
fi
set +f

DISCOVER_ROOTS="${CI_CHANGES_DISCOVER:-${DISCOVER_ROOTS:-${DISCOVER_ROOTS_DEFAULT}}}"
METADATA_FILES="${CI_CHANGES_METADATA:-${METADATA_FILES:-${METADATA_FILES_DEFAULT}}}"
case "$DISCOVER_ROOTS" in none | false | off) DISCOVER_ROOTS="" ;; esac
[ -n "$DISCOVER_ROOTS" ] && gates:discover

if [ "${#GATE_ORDER[@]}" -eq 0 ]; then
  echo:Setup "No gates defined (no rules file, nothing discovered) - fail-open"
  gates:emit_all "true" "no gates to evaluate"
fi
echo:Setup "  gates: ${GATE_ORDER[*]}"

# --- Short-circuits that turn every gate on -------------------------------
if [ "$DETECT_ENABLED" != "true" ]; then
  gates:emit_all "true" "detection disabled (ENABLE_DETECT_CHANGES=${DETECT_ENABLED})"
fi
if [ "$FORCE_ALL" = "true" ]; then
  gates:emit_all "true" "forced (CI_FORCE_ALL_GATES=true)"
fi
if [[ "${GITHUB_REF:-}" == refs/tags/* ]]; then
  gates:emit_all "true" "tag build (${GITHUB_REF}) ships everything"
fi

# --- Diff ------------------------------------------------------------------
if ! BASE="$(gates:resolve_base)"; then
  gates:emit_all "true" "no diff base resolvable (first commit or shallow clone)"
fi
echo:Setup "  base: ${BASE}"

# Three-dot diff (merge-base) for the branch's own changes; two-dot fallback
# when no merge base exists (e.g. base from an unrelated history).
if ! DIFF_OUTPUT="$(git diff --name-only "${BASE}...HEAD" -- 2>/dev/null)"; then
  if ! DIFF_OUTPUT="$(git diff --name-only "${BASE}" HEAD -- 2>/dev/null)"; then
    gates:emit_all "true" "git diff failed for base '${BASE}'"
  fi
fi

CHANGED=()
[ -n "$DIFF_OUTPUT" ] && mapfile -t CHANGED <<<"$DIFF_OUTPUT"
echo:Setup "  changed files: ${#CHANGED[@]}"
for file in "${CHANGED[@]:0:50}"; do
  echo:Setup "    ${file}"
done
[ "${#CHANGED[@]}" -gt 50 ] && echo:Setup "    ... (truncated)"

# --- Evaluate gates ---------------------------------------------------------
set -f
FIRED=()
for gate in "${GATE_ORDER[@]}"; do
  closure="$(gates:closure "$gate")"
  closure_size=0
  state="false"
  detail=""
  # shellcheck disable=SC2086
  for member in $closure; do
    closure_size=$((closure_size + 1))
    [ "$state" = "true" ] && continue
    # shellcheck disable=SC2086
    for pattern in ${GATE_PATTERNS[$member]:-}; do
      for file in "${CHANGED[@]}"; do
        if gates:match "$file" "$pattern"; then
          state="true"
          detail="  (changed: ${file} via ${member}:${pattern})"
          break 2
        fi
      done
    done
  done
  echo:Setup "  ${gate}=${state} (closure: ${closure_size} gates)${detail}"
  ci:output setup "$gate" "$state"
  [ "$state" = "true" ] && FIRED+=("$gate")
done
set +f

ANY="false"
GATES_JSON=""
if [ "${#FIRED[@]}" -gt 0 ]; then
  ANY="true"
  GATES_JSON="$(printf '"%s",' "${FIRED[@]}")"
fi
ci:output setup "any" "$ANY"
ci:output setup "gates" "${FIRED[*]:-}"
ci:output setup "gates_json" "[${GATES_JSON%,}]"

echo:Success "Detect Changes Done"
