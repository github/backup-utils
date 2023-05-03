#!/usr/bin/env bash
# ghe-rsync-feature-checker command tests

TESTS_DIR="$PWD/$(dirname "$0")"
# Bring in testlib.
# shellcheck source=test/testlib.sh
. "$TESTS_DIR/testlib.sh"


# Test ghe-rsync-feature-checker command
ghe-rsync-feature-checker "--help" | grep -q "true"
ghe-rsync-feature-checker "help" | grep -q "true"
ghe-rsync-feature-checker "--ignore-missing-args" | grep -q "false"
ghe-rsync-feature-checker "ignore-missing-args" | grep -q "false"