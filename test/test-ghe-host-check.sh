#!/usr/bin/env bash
# ghe-host-check command tests

# Bring in testlib
. $(dirname "$0")/testlib.sh

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
