#!/usr/bin/env bash
# Fixture hook: runs after ci-10-compile.sh (via END trap)
# Demonstrates: post-step reporting
echo "Hook: end_10_report.sh" >&2
echo "Hook: compile step completed, reporting artifact size" >&2
