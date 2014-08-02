#!/bin/sh
# ghe-restore command tests

# Bring in testlib
. $(dirname "$0")/testlib.sh

# Setup backup snapshot data dir and remote repositories dir locations to use
# the per-test temp space.
GHE_DATA_DIR="$TRASHDIR/data"
GHE_REMOTE_DATA_DIR="$TRASHDIR/remote/data"
export GHE_DATA_DIR GHE_REMOTE_DATA_DIR

# Create the backup data dir and fake remote repositories dirs
mkdir -p "$GHE_DATA_DIR" "$GHE_REMOTE_DATA_DIR"

# Add some fake pages data to the snapshot
mkdir -p "$GHE_DATA_DIR/1/pages"
cd "$GHE_DATA_DIR/1/pages"
mkdir -p alice bob
touch alice/index.html bob/index.html

# Add some fake elasticsearch data to the snapshot
mkdir -p "$GHE_DATA_DIR/1/elasticsearch"
cd "$GHE_DATA_DIR/1/elasticsearch"
echo "fake ES yml file" > elasticsearch.yml
mkdir -p gh-enterprise-es/node/0
touch gh-enterprise-es/node/0/stuff1
touch gh-enterprise-es/node/0/stuff2

# Add some fake repositories to the snapshot
mkdir -p "$GHE_DATA_DIR/1/repositories"
cd "$GHE_DATA_DIR/1/repositories"
mkdir alice bob
mkdir alice/repo1.git alice/repo2.git bob/repo3.git

# Initialize test repositories with a fake commit
for repo in */*.git; do
    git init -q --bare "$repo"
    git --git-dir="$repo" --work-tree=. commit -q --allow-empty -m 'test commit'
done

# Make the current symlink
ln -s 1 "$GHE_DATA_DIR/current"

# create a fake backups for each datastore
echo "fake ghe-export-pages data" > "$GHE_DATA_DIR/current/pages.tar"
echo "fake ghe-export-mysql data" | gzip > "$GHE_DATA_DIR/current/mysql.sql.gz"
echo "fake ghe-export-redis data" > "$GHE_DATA_DIR/current/redis.rdb"
echo "fake ghe-export-authorized-keys data" > "$GHE_DATA_DIR/current/authorized-keys.json"
echo "fake ghe-export-es-indices data" > "$GHE_DATA_DIR/current/elasticsearch.tar"
echo "fake ghe-export-ssh-host-keys data" > "$GHE_DATA_DIR/current/ssh-host-keys.tar"
echo "fake ghe-export-repositories data" > "$GHE_DATA_DIR/current/repositories.tar"

begin_test "ghe-restore"
(
    set -e

    # set restore host environ var
    GHE_RESTORE_HOST=127.0.0.1
    export GHE_RESTORE_HOST

    # run it
    output="$(ghe-restore -v)" || false

    # verify connect to right host
    echo "$output" | grep -q 'Connect 127.0.0.1 OK'

    # verify all import scripts were run
    echo "$output" | grep -q 'alice/index.html'
    echo "$output" | grep -q 'fake ghe-export-mysql data'
    echo "$output" | grep -q 'fake ghe-export-redis data'
    echo "$output" | grep -q 'fake ghe-export-authorized-keys data'
    echo "$output" | grep -q 'fake ghe-export-ssh-host-keys data'
    echo "$output" | grep -q 'ghe-import-es-indices'

    # verify all repository data was transferred to the restore location
    diff -ru "$GHE_DATA_DIR/current/repositories" "$GHE_REMOTE_DATA_DIR/repositories"

    # verify all pages data was transferred to the restore location
    diff -ru "$GHE_DATA_DIR/current/pages" "$GHE_REMOTE_DATA_DIR/pages"
)
end_test

begin_test "ghe-restore with host arg"
(
    set -e
    rm -rf "$GHE_REMOTE_DATA_DIR"
    mkdir -p "$GHE_REMOTE_DATA_DIR"

    # set restore host environ var
    GHE_RESTORE_HOST=127.0.0.1
    export GHE_RESTORE_HOST

    # run it
    output="$(ghe-restore localhost)" || false

    # verify host arg overrides configured restore host
    echo "$output" | grep -q 'Connect localhost OK'

    # verify repository data was transferred to the restore location
    diff -ru "$GHE_DATA_DIR/current/repositories" "$GHE_REMOTE_DATA_DIR/repositories"

    # verify all pages data was transferred to the restore location
    diff -ru "$GHE_DATA_DIR/current/pages" "$GHE_REMOTE_DATA_DIR/pages"
)
end_test

begin_test "ghe-restore with tarball strategy"
(
    set -e
    rm -rf "$GHE_REMOTE_DATA_DIR"
    mkdir -p "$GHE_REMOTE_DATA_DIR"

    # run it
    output=$(/usr/bin/env GHE_BACKUP_STRATEGY="tarball" ghe-restore -v localhost)

    # verify ghe-import-repositories was run on remote side with fake tarball
    echo "$output" | grep -q 'fake ghe-export-repositories data'
)
end_test

begin_test "ghe-restore no host arg or configured restore host"
(
    set -e

    # unset configured restore host
    unset GHE_RESTORE_HOST

    # verify running ghe-restore fails
    ! ghe-restore
)
end_test
