#!/usr/bin/env bash
# ghe-host-check command tests

# Bring in testlib
# shellcheck source=test/testlib.sh
. "$(dirname "$0")/testlib.sh"

begin_test "ghe-host-check"
(
  set -e
  ghe-host-check

  ghe-host-check | grep OK
  ghe-host-check | grep localhost
)
end_test


begin_test "ghe-host-check with host arg"
(
  set -e
  ghe-host-check example.com

  ghe-host-check example.com | grep OK
  ghe-host-check example.com | grep example.com
)
end_test

begin_test "ghe-host-check honours --version flag"
(
  set -e

  # Make sure a partial version string is returned
  ghe-host-check --version | grep "GitHub backup-utils v"

)
end_test

begin_test "ghe-host-check honours --help and -h flags"
(
  set -e

  arg_help=$(ghe-host-check --help | grep -o 'Usage: ghe-host-check')
  arg_h=$(ghe-host-check -h | grep -o 'Usage: ghe-host-check')

  # Make sure a Usage: string is returned and that it's the same for -h and --help
  [ "$arg_help" = "$arg_h" ] && echo $arg_help | grep -q "Usage: ghe-host-check"

)
end_test

begin_test "ghe-host-check detects unsupported GitHub Enterprise versions"
(
  set -e
  ! GHE_TEST_REMOTE_VERSION=11.340.36 ghe-host-check
  ! GHE_TEST_REMOTE_VERSION=2.10.0 ghe-host-check
  GHE_TEST_REMOTE_VERSION=2.11.0 ghe-host-check
  GHE_TEST_REMOTE_VERSION=2.12.0 ghe-host-check
  GHE_TEST_REMOTE_VERSION=2.13.999 ghe-host-check
  GHE_TEST_REMOTE_VERSION=2.13.999gm1 ghe-host-check
  ! GHE_TEST_REMOTE_VERSION=2.9999.1521793591.performancetest ghe-host-check
  GHE_TEST_REMOTE_VERSION=3.0.0 ghe-host-check
)
end_test
