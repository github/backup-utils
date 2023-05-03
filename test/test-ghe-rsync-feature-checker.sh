#!/usr/bin/env bash
# ghe-rsync-feature-checker command tests

TESTS_DIR="$PWD/$(dirname "$0")"
# Bring in testlib.
# shellcheck source=test/testlib.sh
. "$TESTS_DIR/testlib.sh"

begin_test "ghe-rsync-feature-checker for know command `--help`"
(
  set -e

  # Test ghe-rsync-feature-checker command
    ghe-rsync-feature-checker "--help" | grep -q "true"
)
end_test

begin_test "ghe-rsync-feature-checker for know command `help`"
(
    set -e

    # Test ghe-rsync-feature-checker command
    ghe-rsync-feature-checker "help" | grep -q "true"
)
end_test

begin_test "ghe-rsync-feature-checker for known unsupported command `--ignore-missing-args`"
(
    set -e

    # Test ghe-rsync-feature-checker command
    ghe-rsync-feature-checker "--ignore-missing-args" | grep -q "false"
)
end_test

begin_test "ghe-rsync-feature-checker for known unsupported command `ignore-missing-args`"
(
    set -e

    # Test ghe-rsync-feature-checker command
    ghe-rsync-feature-checker "ignore-missing-args" | grep -q "false"
)
end_test