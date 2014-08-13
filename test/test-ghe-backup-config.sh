#!/bin/sh
# ghe-backup-config lib tests

# Bring in testlib
. $(dirname "$0")/testlib.sh


# Setup backup snapshot data dir and remote repositories dir locations to use
# the per-test temp space.
GHE_DATA_DIR="$TRASHDIR/data"
GHE_REMOTE_DATA_DIR="$TRASHDIR/remote"
export GHE_DATA_DIR GHE_REMOTE_DATA_DIR

# Source in the config script
. "$ROOTDIR/libexec/ghe-backup-config"

begin_test "ghe-backup-config ssh_host_part"
(
    set -e
    [ $(ssh_host_part "github.example.com") = "github.example.com" ]
    [ $(ssh_host_part "github.example.com:22") = "github.example.com" ]
    [ $(ssh_host_part "github.example.com:5000") = "github.example.com" ]
    [ $(ssh_host_part "git@github.example.com:5000") = "git@github.example.com" ]
)
end_test


begin_test "ghe-backup-config ssh_port_part"
(
    set -e
    [ $(ssh_port_part "github.example.com") = "22" ]
    [ $(ssh_port_part "github.example.com:22") = "22" ]
    [ $(ssh_port_part "github.example.com:5000") = "5000" ]
    [ $(ssh_port_part "git@github.example.com:5000") = "5000" ]
)
end_test
