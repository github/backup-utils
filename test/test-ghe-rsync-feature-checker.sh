#!/usr/bin/env bash
# ghe-rsync-feature-checker.sh  command tests

TESTS_DIR="$PWD/$(dirname "$0")"
# Bring in testlib.
# shellcheck source=test/testlib.sh
. "$TESTS_DIR/testlib.sh"

## testing for known supported command help with and without leading dashes

begin_test "ghe-rsync-feature-checker.sh for know command --help"
(
  set -e

  # Test ghe-rsync-feature-checker.sh  command
    ghe-rsync-feature-checker.sh --help | grep -q "true"
)
end_test

begin_test "ghe-rsync-feature-checker.sh for know command help"
(
    set -e

    # Test ghe-rsync-feature-checker.sh  command
    ghe-rsync-feature-checker.sh help | grep -q "true"
)
end_test

## testing for known unsupported command not-an-actual-feature with and without leading dashes

begin_test "ghe-rsync-feature-checker.sh for known unsupported command --not-an-actual-feature"
(
    set -e

    # Test ghe-rsync-feature-checker.sh command 
    ghe-rsync-feature-checker.sh --not-an-actual-feature | grep -q "false"
    
)
end_test

begin_test "ghe-rsync-feature-checker.sh for known unsupported command not-an-actual-feature"
(
    set -e

    # Test ghe-rsync-feature-checker.sh command
    ghe-rsync-feature-checker.sh not-an-actual-feature | grep -q "false"
)
end_test

## testing for known supported command partial with and without leading dashes

begin_test "ghe-rsync-feature-checker.sh for know command --partial"
(
    set -e

    # Test ghe-rsync-feature-checker.sh command
    ghe-rsync-feature-checker.sh --partial | grep -q "true"
)
end_test

begin_test "ghe-rsync-feature-checker.sh for know command partial"
(
    set -e

    # Test ghe-rsync-feature-checker.sh command
    ghe-rsync-feature-checker.sh partial | grep -q "true"
)
end_test

## testing for known supported command -v with and without leading dashes

begin_test "ghe-rsync-feature-checker.sh for know command -v"
(
    set -e

    # Test ghe-rsync-feature-checker.sh command
    ghe-rsync-feature-checker.sh -v | grep -q "true"
)
end_test

begin_test "ghe-rsync-feature-checker.sh for know command -v"
(
    set -e

    # Test ghe-rsync-feature-checker.sh command
    ghe-rsync-feature-checker.sh v | grep -q "true"
)
end_test

## testing for known supported command --verbose with and without leading dashes

begin_test "ghe-rsync-feature-checker.sh for know command --verbose"
(
    set -e

    # Test ghe-rsync-feature-checker.sh command
    ghe-rsync-feature-checker.sh --verbose | grep -q "true"
)
end_test

begin_test "ghe-rsync-feature-checker.sh for know command verbose"
(
    set -e

    # Test ghe-rsync-feature-checker.sh command
    ghe-rsync-feature-checker.sh verbose | grep -q "true"
)
end_test