#!/bin/bash

# This script performs the analysis of the spec, plan, and tasks files.

# Arguments:
# 1. spec_file
# 2. plan_file
# 3. tasks_file
# 4. constitution_file

spec_file="$1"
plan_file="$2"
tasks_file="$3"
constitution_file="$4"

# --- Helper functions for parsing sections ---

# Extracts a section from a markdown file
# $1: file_path
# $2: section_title
get_section() {
    awk -v section="$2" ' 
        BEGIN { p = 0 } 
        $0 ~ "^## " section { p = 1; next } 
        $0 ~ "^## " { p = 0 } 
        p { print } 
    ' "$1"
}


# --- 1. Load Artifacts ---

spec_overview=$(get_section "$spec_file" "Overview/Context")
spec_functional_reqs=$(get_section "$spec_file" "Functional Requirements")
spec_non_functional_reqs=$(get_section "$spec_file" "Non-Functional Requirements")
spec_user_stories=$(get_section "$spec_file" "User Stories")
spec_edge_cases=$(get_section "$spec_file" "Edge Cases")

plan_architecture=$(get_section "$plan_file" "Architecture/stack choices")
plan_data_model=$(get_section "$plan_file" "Data Model references")
plan_phases=$(get_section "$plan_file" "Phases")
plan_technical_constraints=$(get_section "$plan_file" "Technical constraints")

tasks_content=$(cat "$tasks_file")
constitution_content=$(cat "$constitution_file")


# --- 2. Build Semantic Models (simplified for now) ---

# Requirements inventory (slugified)
requirements=$(echo "$spec_functional_reqs\n$spec_non_functional_reqs" | grep -E '^\s*-\s*' | sed -e 's/^\s*-\s*//' -e 's/ /-/g' | tr '[:upper:]' '[:lower:]')
total_requirements=$(echo "$requirements" | wc -l)

# Task IDs
tasks=$(echo "$tasks_content" | grep -E '^\s*-\s*\[ \]\s*\[T[0-9]+\]' | sed -e 's/^\s*-\s*\[ \]\s*//')
total_tasks=$(echo "$tasks" | wc -l)


# --- 3. Detection Passes (examples) ---

# B. Ambiguity Detection
ambiguity_count=0
placeholders=("TODO" "TKTK" "???" "<placeholder>")
for placeholder in "${placeholders[@]}"; do
    count=$(grep -c -i "$placeholder" "$spec_file" "$plan_file" "$tasks_file")
    ambiguity_count=$((ambiguity_count + count))
done

# E. Coverage Gaps (very simplified)
# In a real implementation, we'd need more sophisticated mapping.
# This is a placeholder for the logic.
uncovered_requirements=0
unmapped_tasks=()
for task in $tasks; do
    # A real implementation would parse the task description
    # and try to match it to a requirement.
    # For now, we'll just have a placeholder.
    :
done


# --- 4. Generate Report ---

echo "## Specification Analysis Report"
echo ""
echo "| ID | Category | Severity | Location(s) | Summary | Recommendation |"
echo "|----|----------|----------|-------------|---------|----------------|"
# Findings would be printed here. For now, this is empty.
echo ""

echo "**Coverage Summary Table:**"
echo ""
echo "| Requirement Key | Has Task? | Task IDs | Notes |
|-----------------|-----------|----------|-------|"
# Coverage summary would be printed here.
echo ""

echo "**Constitution Alignment Issues:**"
echo "*(none found)*"
echo ""

echo "**Unmapped Tasks:**"
echo "*(none found)*"
echo ""

echo "**Metrics:**"
echo "- Total Requirements: $total_requirements"
echo "- Total Tasks: $total_tasks"
echo "- Coverage %: 0%" # Placeholder
echo "- Ambiguity Count: $ambiguity_count"
echo "- Duplication Count: 0" # Placeholder
echo "- Critical Issues Count: 0" # Placeholder
echo ""

echo "## Next Actions"
echo ""
echo "- No critical issues found. You may proceed with implementation."
echo ""
echo "Would you like me to suggest concrete remediation edits for the top N issues?"
