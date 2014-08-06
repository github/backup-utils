#!/bin/sh
# ghe-backup command tests

# Bring in testlib
. $(dirname "$0")/testlib.sh

# Write a fake license file for backup
GHE_REMOTE_LICENSE_FILE="$TRASHDIR/remote/enterprise.ghl"
export GHE_REMOTE_LICENSE_FILE
mkdir -p "$TRASHDIR/remote"
echo "fake license data" > "$GHE_REMOTE_LICENSE_FILE"

# Create the backup data dir and fake remote repositories dirs
mkdir -p "$GHE_DATA_DIR" "$GHE_REMOTE_DATA_DIR"

# Create some fake pages data in the snapshot
mkdir -p "$GHE_REMOTE_DATA_DIR/pages"
cd "$GHE_REMOTE_DATA_DIR/pages"
mkdir -p alice bob
touch alice/index.html bob/index.html

# Create some fake elasticsearch data in the snapshot
mkdir -p "$GHE_REMOTE_DATA_DIR/elasticsearch"
cd "$GHE_REMOTE_DATA_DIR/elasticsearch"
echo "fake ES yml file" > elasticsearch.yml
mkdir -p gh-enterprise-es/node/0
touch gh-enterprise-es/node/0/stuff1
touch gh-enterprise-es/node/0/stuff2

# Create some test repositories in the remote repositories dir
mkdir "$GHE_REMOTE_DATA_DIR/repositories"
cd "$GHE_REMOTE_DATA_DIR/repositories"
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
    ghe-backup -v

    # check that current symlink was created
    [ -d "$GHE_DATA_DIR/current" ]

    # check that settings were backed up
    [ "$(cat "$GHE_DATA_DIR/current/settings.json")" = "fake ghe-export-settings data" ]

    # check that license was backed up
    [ "$(cat "$GHE_DATA_DIR/current/enterprise.ghl")" = "fake license data" ]

    # check that repositories directory was created
    [ -d "$GHE_DATA_DIR/current/repositories" ]

    # check that pages data was backed up
    [ -f "$GHE_DATA_DIR/current/pages/alice/index.html" ]

    # check that mysql data was backed up
    [ "$(gzip -dc < "$GHE_DATA_DIR/current/mysql.sql.gz")" = "fake ghe-export-mysql data" ]

    # check that redis data was backed up
    [ "$(cat "$GHE_DATA_DIR/current/redis.rdb")" = "fake ghe-export-redis data" ]

    # check that ssh public keys were backed up
    [ "$(cat "$GHE_DATA_DIR/current/authorized-keys.json")" = "fake ghe-export-authorized-keys data" ]

    # check that ssh host key was backed up
    [ "$(cat "$GHE_DATA_DIR/current/ssh-host-keys.tar")" = "fake ghe-export-ssh-host-keys data" ]

    # verify all repository data was transferred
    diff -ru "$GHE_REMOTE_DATA_DIR/repositories" "$GHE_DATA_DIR/current/repositories"

    # verify all pages data was transferred
    diff -ru "$GHE_REMOTE_DATA_DIR/pages" "$GHE_DATA_DIR/current/pages"

    # verify all ES data was transferred
    diff -ru "$GHE_REMOTE_DATA_DIR/elasticsearch" "$GHE_DATA_DIR/current/elasticsearch"
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

    # check that settings were backed up
    [ "$(cat "$GHE_DATA_DIR/current/settings.json")" = "fake ghe-export-settings data" ]

    # check that license was backed up
    [ "$(cat "$GHE_DATA_DIR/current/enterprise.ghl")" = "fake license data" ]

    # check that repositories directory was created
    [ -d "$GHE_DATA_DIR/current/repositories" ]

    # check that pages data was backed up
    [ -f "$GHE_DATA_DIR/current/pages/alice/index.html" ]

    # check that mysql data was backed up
    [ "$(gzip -dc < "$GHE_DATA_DIR/current/mysql.sql.gz")" = "fake ghe-export-mysql data" ]

    # check that redis data was backed up
    [ "$(cat "$GHE_DATA_DIR/current/redis.rdb")" = "fake ghe-export-redis data" ]

    # check that ssh public keys were backed up
    [ "$(cat "$GHE_DATA_DIR/current/authorized-keys.json")" = "fake ghe-export-authorized-keys data" ]

    # check that ssh host key was backed up
    [ "$(cat "$GHE_DATA_DIR/current/ssh-host-keys.tar")" = "fake ghe-export-ssh-host-keys data" ]

    # verify all repository data was transferred
    diff -ru "$GHE_REMOTE_DATA_DIR/repositories" "$GHE_DATA_DIR/current/repositories"

    # verify all pages data was transferred
    diff -ru "$GHE_REMOTE_DATA_DIR/pages" "$GHE_DATA_DIR/current/pages"

    # verify all ES data was transferred
    diff -ru "$GHE_REMOTE_DATA_DIR/elasticsearch" "$GHE_DATA_DIR/current/elasticsearch"
)
end_test


begin_test "ghe-backup tarball strategy"
(
    set -e

    # wait a second for snapshot timestamp
    sleep 1

    # run backup with tarball strategy
    GHE_BACKUP_STRATEGY="tarball" ghe-backup

    # check that repositories tarball exists
    [ -f "$GHE_DATA_DIR/current/repositories.tar" ]

    # check repositories tarball data
    [ "$(cat "$GHE_DATA_DIR/current/repositories.tar")" = "fake ghe-export-repositories data" ]

    # check ES tarball data
    [ "$(cat "$GHE_DATA_DIR/current/elasticsearch.tar")" = "fake ghe-export-es-indices data" ]

    # check that repositories directory doesnt exist
    [ ! -d "$GHE_DATA_DIR/current/repositories" ]

)
end_test

begin_test "ghe-backup fails fast when other run in progress"
(
    set -e

    ln -s 1 "$GHE_DATA_DIR/in-progress"
    ! ghe-backup
)
end_test
