#!/usr/bin/env bash
# ghe-cluster-nodes command tests

# Bring in testlib
. $(dirname "$0")/testlib.sh

# Setup backup snapshot data dir and remote repositories dir locations to use
# the per-test temp space.
GHE_DATA_DIR="$TRASHDIR/data"
GHE_REMOTE_DATA_DIR="$TRASHDIR/remote"
export GHE_DATA_DIR GHE_REMOTE_DATA_DIR
# Create a uuid file
mkdir -p "$GHE_REMOTE_DATA_USER_DIR/common"
echo "fake-uuid" > "$GHE_REMOTE_DATA_USER_DIR/common/uuid"

begin_test "ghe-cluster-nodes should return both uuids for git-server"
(
    set -e
    setup_remote_cluster

    output="$(ghe-cluster-nodes "$GHE_HOSTNAME" "git-server")"
    echo "$output"
    [ "git-server-05cbcd42-f519-11e6-b6c9-002bd51dfa77 git-server-08d94884-f519-11e6-88a1-0063a7c33551 " = "$output" ]
)
end_test

begin_test "ghe-cluster-nodes should return one uuid for a single node"
(
    set -e

    # Ensure not a cluster
    rm -rf "$GHE_REMOTE_ROOT_DIR/etc/github/cluster"

    output="$(ghe-cluster-nodes "$GHE_HOSTNAME" "git-server")"
    echo "$output"
    [ "git-server-fake-uuid" = "$output" ]
)
end_test
