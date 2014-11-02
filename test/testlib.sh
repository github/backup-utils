#!/bin/sh
# Usage: . testlib.sh
# Simple shell command language test library.
#
# Tests must follow the basic form:
#
#   begin_test "the thing"
#   (
#        set -e
#        echo "hello"
#        false
#   )
#   end_test
#
# When a test fails its stdout and stderr are shown.
#
# Note that tests must `set -e' within the subshell block or failed assertions
# will not cause the test to fail and the result may be misreported.
#
# Copyright (c) 2011-14 by Ryan Tomayko <http://tomayko.com>
# License: MIT
set -e

# Setting basic paths
ROOTDIR="$(cd $(dirname "$0")/.. && pwd)"
PATH="$ROOTDIR/test/bin:$ROOTDIR/bin:$ROOTDIR/share/github-backup-utils:$PATH"

# create a temporary work space
TMPDIR="$ROOTDIR/test/tmp"
TRASHDIR="$TMPDIR/$(basename "$0")-$$"

# Set GIT_{AUTHOR,COMMITTER}_{NAME,EMAIL}
# This removes the assumption that a git config that specifies these is present.
export GIT_AUTHOR_NAME=make GIT_AUTHOR_EMAIL=make GIT_COMMITTER_NAME=make GIT_COMMITTER_EMAIL=make

# Point commands at the test backup.config file
GHE_BACKUP_CONFIG="$ROOTDIR/test/backup.config"
GHE_DATA_DIR="$TRASHDIR/data"
GHE_REMOTE_DATA_DIR="$TRASHDIR/remote"
GHE_REMOTE_ROOT_DIR="$TRASHDIR/root"
export GHE_BACKUP_CONFIG GHE_DATA_DIR GHE_REMOTE_DATA_DIR GHE_REMOTE_ROOT_DIR

# The default remote appliance version. This may be set in the environment prior
# to invoking tests to emulate a different remote vm version.
: ${GHE_TEST_REMOTE_VERSION:=11.10.344}
export GHE_TEST_REMOTE_VERSION

# Source in the backup config and set GHE_REMOTE_XXX variables based on the
# remote version established above or in the environment.
. ghe-backup-config
ghe_parse_remote_version "$GHE_TEST_REMOTE_VERSION"
ghe_remote_version_config "$GHE_TEST_REMOTE_VERSION"

# Unset special variables meant to be inherited by individual ghe-backup or
# ghe-restore process groups
unset GHE_SNAPSHOT_TIMESTAMP

# keep track of num tests and failures
tests=0
failures=0

# this runs at process exit
atexit () {
    res=$?
    [ -z "$KEEPTRASH" ] && rm -rf "$TRASHDIR"
    if [ $failures -gt 0 ]
    then exit 1
    elif [ $res -ne 0 ]
    then exit $res
    else exit 0
    fi
}

# create the trash dir and data dirs
trap "atexit" EXIT
mkdir -p "$TRASHDIR" "$GHE_DATA_DIR" "$GHE_REMOTE_DATA_DIR" "$GHE_REMOTE_DATA_USER_DIR"
cd "$TRASHDIR"

# Put remote metadata file in place for ghe-host-check which runs with pretty
# much everything. You can pass a version number in the first argument to test
# with different remote versions.
setup_remote_metadata () {
    mkdir -p "$GHE_REMOTE_DATA_DIR" "$GHE_REMOTE_DATA_USER_DIR"
    mkdir -p "$(dirname "$GHE_REMOTE_METADATA_FILE")"

    if [ "$GHE_VERSION_MAJOR" -ge 2 ]; then
        mkdir -p "$GHE_REMOTE_DATA_USER_DIR/common"
        mkdir -p "$GHE_REMOTE_ROOT_DIR/etc/github"
    fi

    echo '
    {
      "timestamp": "Wed Jul 30 13:48:52 +0000 2014",
      "version": "'${1:-$GHE_TEST_REMOTE_VERSION}'"
    }
    ' > "$GHE_REMOTE_METADATA_FILE"
}
setup_remote_metadata

setup_remote_license () {
    mkdir -p "$(dirname "$GHE_REMOTE_LICENSE_FILE")"
    echo "fake license data" > "$GHE_REMOTE_LICENSE_FILE"
}
setup_remote_license


# Mark the beginning of a test. A subshell should immediately follow this
# statement.
begin_test () {
    test_status=$?
    [ -n "$test_description" ] && end_test $test_status
    unset test_status

    tests=$(( tests + 1 ))
    test_description="$1"

    exec 3>&1 4>&2
    out="$TRASHDIR/out"
    exec 1>"$out" 2>&1

    # allow the subshell to exit non-zero without exiting this process
    set -x +e
}

report_failure () {
  msg=$1
  desc=$2
  failures=$(( failures + 1 ))
  printf "test: %-73s $msg\n" "$desc ..."
  (
      sed 's/^/    /' <"$TRASHDIR/out" |
      grep -a -v -e '^\+ end_test' -e '^+ set +x' <"$TRASHDIR/out" |
          sed 's/[+] test_status=/test failed. last command exited with /' |
          sed 's/^/    /'
  ) 1>&2
}

# Mark the end of a test.
end_test () {
    test_status="${1:-$?}"
    set +x -e
    exec 1>&3 2>&4

    if [ "$test_status" -eq 0 ]; then
      printf "test: %-60s OK\n" "$test_description ..."
    else
      report_failure "FAILED" "$test_description ..."
    fi
    unset test_description
}
