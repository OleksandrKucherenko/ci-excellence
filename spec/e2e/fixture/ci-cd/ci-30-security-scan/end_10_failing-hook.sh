#!/usr/bin/env bash
# Fixture hook: DELIBERATELY FAILS (exit 1)
# Demonstrates: error propagation from hooks
echo "Hook: end_10_failing-hook.sh" >&2
echo "Hook: simulating a post-scan upload failure" >&2
exit 1
