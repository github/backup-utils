#!/bin/sh
# ghe-backup command tests

# Bring in testlib
. $(dirname "$0")/testlib.sh

# Create the backup data dir and fake remote repositories dirs
mkdir -p "$GHE_DATA_DIR" "$GHE_REMOTE_DATA_USER_DIR"

# Create some fake pages data in the remote data directory
mkdir -p "$GHE_REMOTE_DATA_USER_DIR/pages"
cd "$GHE_REMOTE_DATA_USER_DIR/pages"
mkdir -p alice bob
touch alice/index.html bob/index.html

# Create a fake manage password file
mkdir -p "$GHE_REMOTE_DATA_USER_DIR/common"
echo "fake password hash data" > "$GHE_REMOTE_DATA_USER_DIR/common/manage-password"

# Create some fake hookshot data in the remote data directory
if [ "$GHE_VERSION_MAJOR" -ge 2 ]; then
    mkdir -p "$GHE_REMOTE_DATA_USER_DIR/hookshot"
    cd "$GHE_REMOTE_DATA_USER_DIR/hookshot"
    mkdir -p repository-123 repository-456
    touch repository-123/test.bpack repository-456/test.bpack
fi

# Create some fake alambic data in the remote data directory
if [ "$GHE_VERSION_MAJOR" -ge 2 ]; then
    mkdir -p "$GHE_REMOTE_DATA_USER_DIR/alambic_assets/github-enterprise-assets/0000"
    touch "$GHE_REMOTE_DATA_USER_DIR/alambic_assets/github-enterprise-assets/0000/test.png"

    mkdir -p "$GHE_REMOTE_DATA_USER_DIR/alambic_assets/github-enterprise-releases/0001"
    touch "$GHE_REMOTE_DATA_USER_DIR/alambic_assets/github-enterprise-releases/0001/1ed78298-522b-11e3-9dc0-22eed1f8132d"
fi

# Create some fake elasticsearch data in the remote data directory
mkdir -p "$GHE_REMOTE_DATA_USER_DIR/elasticsearch"
cd "$GHE_REMOTE_DATA_USER_DIR/elasticsearch"
mkdir -p gh-enterprise-es/node/0
touch gh-enterprise-es/node/0/stuff1
touch gh-enterprise-es/node/0/stuff2

if [ "$GHE_VERSION_MAJOR" -eq 1 ]; then
    echo "fake ES yml file" > elasticsearch.yml
fi

# Create some test repositories in the remote repositories dir
mkdir "$GHE_REMOTE_DATA_USER_DIR/repositories"
cd "$GHE_REMOTE_DATA_USER_DIR/repositories"
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

    # check that the version file was written
    [ -f "$GHE_DATA_DIR/current/version" ]
    [ $(cat "$GHE_DATA_DIR/current/version") = "v$GHE_TEST_REMOTE_VERSION" ]

    # check that the strategy file was written
    [ -f "$GHE_DATA_DIR/current/strategy" ]
    [ $(cat "$GHE_DATA_DIR/current/strategy") = "rsync" ]

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
    [ "$(cat "$GHE_DATA_DIR/current/redis.rdb")" = "fake redis data" ]

    # check that ssh public keys were backed up
    [ "$(cat "$GHE_DATA_DIR/current/authorized-keys.json")" = "fake ghe-export-authorized-keys data" ]

    # check that ssh host key was backed up
    [ "$(cat "$GHE_DATA_DIR/current/ssh-host-keys.tar")" = "fake ghe-export-ssh-host-keys data" ]

    # verify all repository data was transferred
    diff -ru "$GHE_REMOTE_DATA_USER_DIR/repositories" "$GHE_DATA_DIR/current/repositories"

    # verify all pages data was transferred
    diff -ru "$GHE_REMOTE_DATA_USER_DIR/pages" "$GHE_DATA_DIR/current/pages"

    # verify all ES data was transferred from live directory
    diff -ru "$GHE_REMOTE_DATA_USER_DIR/elasticsearch" "$GHE_DATA_DIR/current/elasticsearch"

    # verify manage-password file was backed up under v2.x VMs
    if [ "$GHE_VERSION_MAJOR" -ge 2 ]; then
        [ "$(cat "$GHE_DATA_DIR/current/manage-password")" = "fake password hash data" ]
    fi

    if [ "$GHE_VERSION_MAJOR" -ge 2 ]; then
        # verify all hookshot user data was transferred
        diff -ru "$GHE_REMOTE_DATA_USER_DIR/hookshot" "$GHE_DATA_DIR/current/hookshot"

        # verify all alambic assets user data was transferred
        diff -ru "$GHE_REMOTE_DATA_USER_DIR/alambic_assets" "$GHE_DATA_DIR/current/alambic_assets"
    fi
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
    [ "$(cat "$GHE_DATA_DIR/current/redis.rdb")" = "fake redis data" ]

    # check that ssh public keys were backed up
    [ "$(cat "$GHE_DATA_DIR/current/authorized-keys.json")" = "fake ghe-export-authorized-keys data" ]

    # check that ssh host key was backed up
    [ "$(cat "$GHE_DATA_DIR/current/ssh-host-keys.tar")" = "fake ghe-export-ssh-host-keys data" ]

    # verify all repository data was transferred
    diff -ru "$GHE_REMOTE_DATA_USER_DIR/repositories" "$GHE_DATA_DIR/current/repositories"

    # verify all pages data was transferred
    diff -ru "$GHE_REMOTE_DATA_USER_DIR/pages" "$GHE_DATA_DIR/current/pages"

    # verify all ES data was transferred from live directory
    diff -ru "$GHE_REMOTE_DATA_USER_DIR/elasticsearch" "$GHE_DATA_DIR/current/elasticsearch"

    # verify manage-password file was backed up under v2.x VMs
    if [ "$GHE_VERSION_MAJOR" -ge 2 ]; then
        [ "$(cat "$GHE_DATA_DIR/current/manage-password")" = "fake password hash data" ]
    fi

    if [ "$GHE_VERSION_MAJOR" -ge 2 ]; then
        # verify all hookshot user data was transferred
        diff -ru "$GHE_REMOTE_DATA_USER_DIR/hookshot" "$GHE_DATA_DIR/current/hookshot"

        # verify all alambic assets user data was transferred
        diff -ru "$GHE_REMOTE_DATA_USER_DIR/alambic_assets" "$GHE_DATA_DIR/current/alambic_assets"
    fi
)
end_test


begin_test "ghe-backup tarball strategy"
(
    set -e

    # wait a second for snapshot timestamp
    sleep 1

    # run backup with tarball strategy
    GHE_BACKUP_STRATEGY="tarball" ghe-backup

    # check that the strategy file was written
    [ -f "$GHE_DATA_DIR/current/strategy" ]
    [ $(cat "$GHE_DATA_DIR/current/strategy") = "tarball" ]

    # check that repositories tarball exists
    [ -f "$GHE_DATA_DIR/current/repositories.tar" ]

    # check repositories tarball data
    [ "$(cat "$GHE_DATA_DIR/current/repositories.tar")" = "fake ghe-export-repositories data" ]

    # check ES tarball data. Supported under v1.x VMs only.
    if [ "$GHE_VERSION_MAJOR" -eq 1 ]; then
        [ "$(cat "$GHE_DATA_DIR/current/elasticsearch.tar")" = "fake ghe-export-es-indices data" ]
    fi

    # check that repositories directory doesnt exist
    [ ! -d "$GHE_DATA_DIR/current/repositories" ]

)
end_test

begin_test "ghe-backup fails fast when other run in progress"
(
    set -e

    ln -s 1 "$GHE_DATA_DIR/in-progress"
    ! ghe-backup

    unlink "$GHE_DATA_DIR/in-progress"
)
end_test

begin_test "ghe-backup without manage-password file"
(
    set -e

    unlink "$GHE_REMOTE_DATA_USER_DIR/common/manage-password"
    ghe-backup

    [ ! -f "$GHE_DATA_DIR/current/manage-password" ]
)
end_test
