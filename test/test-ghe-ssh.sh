#!/usr/bin/env bash
# ghe-ssh command tests

# Bring in testlib
# shellcheck source=test/testlib.sh
. "$(dirname "$0")/testlib.sh"

# Setup backup snapshot data dir and remote repositories dir locations to use
# the per-test temp space.
GHE_DATA_DIR="$TRASHDIR/data"
GHE_REMOTE_DATA_DIR="$TRASHDIR/remote"
export GHE_DATA_DIR GHE_REMOTE_DATA_DIR

# Source in config file for hostname
. "$GHE_BACKUP_CONFIG"

begin_test "ghe-ssh simple command works"
(
  set -e

  output="$(ghe-ssh "$GHE_HOSTNAME" "echo hello there")"
  [ "hello there" = "$output" ]
)
end_test


begin_test "ghe-ssh complex command works"
(
  set -e

  comm="
    echo hello
    echo there
  "

  output="$(echo "$comm" | ghe-ssh "$GHE_HOSTNAME" /bin/sh)"
  [ "$(echo "$output" | wc -l)" -eq 2 ]
)
end_test


begin_test "ghe-ssh when complex command given to simple form"
(
  set -e

  ! ghe-ssh "$GHE_HOSTNAME" "echo hello | wc -l"
  ! ghe-ssh "$GHE_HOSTNAME" "echo hello ; wc -l"
  ! ghe-ssh "$GHE_HOSTNAME" "
    echo hello
    echo goodbye
  "
)
end_test
