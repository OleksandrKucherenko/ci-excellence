#!/usr/bin/env bash
# Fixture hook: runs before ci-10-unit-tests.sh
# Demonstrates: test fixture setup
echo "Hook: begin_00_setup-fixtures.sh" >&2
echo "Hook: setting up test database and fixtures" >&2
echo "contract:env:TEST_DB_URL=sqlite:///tmp/test.db"
