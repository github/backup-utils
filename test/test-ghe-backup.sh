#!/bin/sh
# ghe-backup command tests

# Bring in testlib
. $(dirname "$0")/testlib.sh

# Setup backup snapshot data dir and remote repositories dir locations to use
# the per-test temp space.
GHE_DATA_DIR="$TRASHDIR/data"
GHE_REMOTE_DATA_DIR="$TRASHDIR/remote/repositories"
export GHE_DATA_DIR GHE_REMOTE_DATA_DIR

# Create the backup data dir and fake remote repositories dirs
mkdir -p "$GHE_DATA_DIR" "$GHE_REMOTE_DATA_DIR"

# Create some test repositories in the remote repositories dir
cd "$GHE_REMOTE_DATA_DIR"
mkdir alice bob
mkdir alice/repo1.git alice/repo2.git bob/repo3.git

# Initialize test repositories with a fake commit
for repo in */*.git; do
    git init -q --bare "$repo"
    git --git-dir="$repo" --work-tree=. commit -q --allow-empty -m 'test commit'
done

begin_test "ghe-backup first snapshot"
(
    set -e

    # check that no current symlink exists yet
    [ ! -d "$GHE_DATA_DIR/current" ]

    # run it
    ghe-backup

    # check that current symlink was created
    [ -d "$GHE_DATA_DIR/current" ]

    # check that repositories directory was created
    [ -d "$GHE_DATA_DIR/current/repositories" ]

    # check that pages data was backed up
    [ "$(cat $GHE_DATA_DIR/current/pages.tar)" = "fake ghe-export-pages data" ]

    # check that mysql data was backed up
    [ "$(gzip -dc < $GHE_DATA_DIR/current/mysql.sql.gz)" = "fake ghe-export-mysql data" ]

    # check that redis data was backed up
    [ "$(cat $GHE_DATA_DIR/current/redis.rdb)" = "fake ghe-export-redis data" ]

    # check that ssh public keys were backed up
    [ "$(cat $GHE_DATA_DIR/current/authorized-keys.json)" = "fake ghe-export-authorized-keys data" ]

    # check that ssh host key was backed up
    [ "$(cat $GHE_DATA_DIR/current/ssh-host-keys.tar)" = "fake ghe-export-ssh-host-keys data" ]

    # check that ES indices were backed up
    [ "$(cat $GHE_DATA_DIR/current/es-indices.tar)" = "fake ghe-export-es-indices data" ]

    # verify all repository data was transferred
    diff -ru "$GHE_REMOTE_DATA_DIR" "$GHE_DATA_DIR/current/repositories"
)
end_test


begin_test "ghe-backup subsequent snapshot"
(
    set -e

    # wait a second for snapshot timestamp
    sleep 1

    # check that no current symlink exists yet
    [ -d "$GHE_DATA_DIR/current" ]

    # grab the first snapshot number so we can compare after
    first_snapshot=$(ls -ld "$GHE_DATA_DIR/current" | sed 's/.* -> //')

    # run it
    ghe-backup

    # check that current symlink points to new snapshot
    this_snapshot=$(ls -ld "$GHE_DATA_DIR/current" | sed 's/.* -> //')
    [ "$first_snapshot" != "$this_snapshot" ]

    # check that current symlink was created
    [ -d "$GHE_DATA_DIR/current" ]

    # check that repositories directory was created
    [ -d "$GHE_DATA_DIR/current/repositories" ]

    # check that pages data was backed up
    [ "$(cat $GHE_DATA_DIR/current/pages.tar)" = "fake ghe-export-pages data" ]

    # check that mysql data was backed up
    [ "$(gzip -dc < $GHE_DATA_DIR/current/mysql.sql.gz)" = "fake ghe-export-mysql data" ]

    # check that redis data was backed up
    [ "$(cat $GHE_DATA_DIR/current/redis.rdb)" = "fake ghe-export-redis data" ]

    # check that ssh public keys were backed up
    [ "$(cat $GHE_DATA_DIR/current/authorized-keys.json)" = "fake ghe-export-authorized-keys data" ]

    # check that ssh host key was backed up
    [ "$(cat $GHE_DATA_DIR/current/ssh-host-keys.tar)" = "fake ghe-export-ssh-host-keys data" ]

    # check that ES indices were backed up
    [ "$(cat $GHE_DATA_DIR/current/es-indices.tar)" = "fake ghe-export-es-indices data" ]

    # verify all repository data was transferred
    diff -ru "$GHE_REMOTE_DATA_DIR" "$GHE_DATA_DIR/current/repositories"
)
end_test
