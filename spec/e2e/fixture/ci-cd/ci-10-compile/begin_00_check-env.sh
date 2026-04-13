#!/usr/bin/env bash
# Fixture hook: runs before ci-10-compile.sh
# Demonstrates: env var verification and contract-based env injection
echo "Hook: begin_00_check-env.sh" >&2
if [ -z "${CI_VERSION:-}" ]; then
  echo "contract:exit:1"
  echo "Hook error: CI_VERSION not set" >&2
  exit 1
fi
echo "contract:env:HOOK_COMPILE_CHECKED=true"
echo "Hook: CI_VERSION=${CI_VERSION} verified" >&2
