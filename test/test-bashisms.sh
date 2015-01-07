#!/bin/sh
# bashisms tests

# Bring in testlib
. $(dirname "$0")/testlib.sh

begin_test "ghe-* bashisms"
(
    set -e
    checkbashisms -f "$ROOTDIR/bin/ghe-"*
)
end_test
