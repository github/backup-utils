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

begin_test "ghe-backup-config ghe_parse_remote_version v11.10.x series"
(
    set -e

    ghe_parse_remote_version "v11.10.343"
    [ "$GHE_VERSION_MAJOR" = "1" ]
    [ "$GHE_VERSION_MINOR" = "0" ]
    [ "$GHE_VERSION_PATCH" = "343" ]

    ghe_parse_remote_version "11.10.343"
    [ "$GHE_VERSION_MAJOR" = "1" ]
    [ "$GHE_VERSION_MINOR" = "0" ]
    [ "$GHE_VERSION_PATCH" = "343" ]

    ghe_parse_remote_version "v11.10.340.ldapfix1"
    [ "$GHE_VERSION_MAJOR" = "1" ]
    [ "$GHE_VERSION_MINOR" = "0" ]
    [ "$GHE_VERSION_PATCH" = "340" ]

    ghe_parse_remote_version "v11.10.340pre"
    [ "$GHE_VERSION_MAJOR" = "1" ]
    [ "$GHE_VERSION_MINOR" = "0" ]
    [ "$GHE_VERSION_PATCH" = "340" ]

    ghe_parse_remote_version "v11.10.12"
    [ "$GHE_VERSION_MAJOR" = "1" ]
    [ "$GHE_VERSION_MINOR" = "0" ]
    [ "$GHE_VERSION_PATCH" = "12" ]
)
end_test

begin_test "ghe-backup-config ghe_parse_remote_version v2.x series"
(
    set -e

    ghe_parse_remote_version "v2.0.0"
    [ "$GHE_VERSION_MAJOR" = "2" ]
    [ "$GHE_VERSION_MINOR" = "0" ]
    [ "$GHE_VERSION_PATCH" = "0" ]

    ghe_parse_remote_version "2.0.0"
    [ "$GHE_VERSION_MAJOR" = "2" ]
    [ "$GHE_VERSION_MINOR" = "0" ]
    [ "$GHE_VERSION_PATCH" = "0" ]

    ghe_parse_remote_version "v2.1.5"
    [ "$GHE_VERSION_MAJOR" = "2" ]
    [ "$GHE_VERSION_MINOR" = "1" ]
    [ "$GHE_VERSION_PATCH" = "5" ]

    ghe_parse_remote_version "v2.1.5.ldapfix1"
    [ "$GHE_VERSION_MAJOR" = "2" ]
    [ "$GHE_VERSION_MINOR" = "1" ]
    [ "$GHE_VERSION_PATCH" = "5" ]

    ghe_parse_remote_version "v2.1.5pre"
    [ "$GHE_VERSION_MAJOR" = "2" ]
    [ "$GHE_VERSION_MINOR" = "1" ]
    [ "$GHE_VERSION_PATCH" = "5" ]
)
end_test
