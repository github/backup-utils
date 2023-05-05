#!/usr/bin/env bash
# ghe-rsync-feature-checker command tests

TESTS_DIR="$PWD/$(dirname "$0")"
# Bring in testlib.
# shellcheck source=test/testlib.sh
. "$TESTS_DIR/testlib.sh"

## testing for known supported command help with and without leading dashes

begin_test "Testing ghe-rsync-feature-checker with known supported command --help"
(
    set -e

    # Test ghe-rsync-feature-checker command
    ghe-rsync-feature-checker --help | grep -q "true"
)
end_test

begin_test "Testing ghe-rsync-feature-checker with known unsupported command -help"
(
    set -e

    # Test ghe-rsync-feature-checker command
    ghe-rsync-feature-checker -help | grep -q "false"
)
end_test

begin_test "Testing ghe-rsync-feature-checker with known supported command help"
(
    set -e

    # Test ghe-rsync-feature-checker command
    ghe-rsync-feature-checker help | grep -q "true"
)
end_test

## testing with known unsupported command not-an-actual-feature with and without leading dashes

begin_test "Testing ghe-rsync-feature-checker with known unsupported command --not-an-actual-feature"
(
    set -e

    # Test ghe-rsync-feature-checker command 
    ghe-rsync-feature-checker --not-an-actual-feature | grep -q "false"
    
)
end_test

begin_test "Testing ghe-rsync-feature-checker with known unsupported command -not-an-actual-feature"
(
    set -e

    # Test ghe-rsync-feature-checker command 
    ghe-rsync-feature-checker -not-an-actual-feature | grep -q "false"
    
)
end_test

begin_test "Testing ghe-rsync-feature-checker with known unsupported command not-an-actual-feature"
(
    set -e

    # Test ghe-rsync-feature-checker command
    ghe-rsync-feature-checker not-an-actual-feature | grep -q "false"
)
end_test

## testing with known supported command partial with and without leading dashes

begin_test "Testing ghe-rsync-feature-checker with known supported command --partial"
(
    set -e

    # Test ghe-rsync-feature-checker command
    ghe-rsync-feature-checker --partial | grep -q "true"
)
end_test

begin_test "Testing ghe-rsync-feature-checker with known supported command partial"
(
    set -e

    # Test ghe-rsync-feature-checker command
    ghe-rsync-feature-checker partial | grep -q "true"
)
end_test

## testing with known supported command -v with and without leading dashes

begin_test "Testing ghe-rsync-feature-checker with known supported command -v"
(
    set -e

    # Test ghe-rsync-feature-checker command
    ghe-rsync-feature-checker -v | grep -q "true"
)
end_test

begin_test "Testing ghe-rsync-feature-checker with known supported command v"
(
    set -e

    # Test ghe-rsync-feature-checker command
    ghe-rsync-feature-checker v | grep -q "true"
)
end_test

## testing with known supported command --verbose with and without leading dashes

begin_test "Testing ghe-rsync-feature-checker with known supported command --verbose"
(
    set -e

    # Test ghe-rsync-feature-checker command
    ghe-rsync-feature-checker --verbose | grep -q "true"
)
end_test

begin_test "Testing ghe-rsync-feature-checker with known unsupported command -verbose"
(
    set -e

    # Test ghe-rsync-feature-checker command
    ghe-rsync-feature-checker -verbose | grep -q "false"
)
end_test

begin_test "Testing ghe-rsync-feature-checker with known supported command verbose"
(
    set -e

    # Test ghe-rsync-feature-checker command
    ghe-rsync-feature-checker verbose | grep -q "true"
)
end_test

## testing with known supported command ignore-missing-args with and without leading dashes

begin_test "Testing ghe-rsync-feature-checker with known supported command --ignore-missing-args"
(
    set -e

    # Test ghe-rsync-feature-checker command
    ghe-rsync-feature-checker "--ignore-missing-args" | grep -q "true"
)
end_test

begin_test "Testing ghe-rsync-feature-checker with known supported command ignore-missing-args"
(
    set -e

    # Test ghe-rsync-feature-checker command
    ghe-rsync-feature-checker "ignore-missing-args" | grep -q "true"
)
end_test
