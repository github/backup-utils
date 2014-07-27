#!/bin/sh
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
