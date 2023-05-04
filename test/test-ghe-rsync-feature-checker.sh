#!/usr/bin/env bash
# ghe-rsync-feature-checker.sh  command tests

TESTS_DIR="$PWD/$(dirname "$0")"
# Bring in testlib.
# shellcheck source=test/testlib.sh
. "$TESTS_DIR/testlib.sh"

begin_test "ghe-rsync-feature-checker.sh  for know command --help"
(
  set -e

  # Test ghe-rsync-feature-checker.sh  command
    ghe-rsync-feature-checker.sh --help | grep -q "true"
)
end_test

begin_test "ghe-rsync-feature-checker.sh  for know command help"
(
    set -e

    # Test ghe-rsync-feature-checker.sh  command
    ghe-rsync-feature-checker.sh  "help" | grep -q "true"
)
end_test

begin_test "ghe-rsync-feature-checker.sh  for known unsupported command --ignore-missing-args"
(
    set -e

    # Test ghe-rsync-feature-checker.sh  command
    ghe-rsync-feature-checker.sh  "--ignore-missing-args" | grep -q "false"
)
end_test

begin_test "ghe-rsync-feature-checker.sh  for known unsupported command ignore-missing-args"
(
    set -e

    # Test ghe-rsync-feature-checker.sh  command
    ghe-rsync-feature-checker.sh  "ignore-missing-args" | grep -q "false"
)
end_test