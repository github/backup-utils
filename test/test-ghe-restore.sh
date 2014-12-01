#!/bin/sh
# ghe-restore command tests

# Bring in testlib
. $(dirname "$0")/testlib.sh

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

# Create some fake hookshot data in the remote data directory
if [ "$GHE_VERSION_MAJOR" -ge 2 ]; then
    mkdir -p "$GHE_DATA_DIR/1/hookshot"
    cd "$GHE_DATA_DIR/1/hookshot"
    mkdir -p repository-123 repository-456
    touch repository-123/test.bpack repository-456/test.bpack
fi

# Create some fake alambic data in the remote data directory
if [ "$GHE_VERSION_MAJOR" -ge 2 ]; then
    mkdir -p "$GHE_DATA_DIR/1/alambic_assets/github-enterprise-assets/0000"
    touch "$GHE_DATA_DIR/1/alambic_assets/github-enterprise-assets/0000/test.png"

    mkdir -p "$GHE_DATA_DIR/1/alambic_assets/github-enterprise-releases/0001"
    touch "$GHE_DATA_DIR/1/alambic_assets/github-enterprise-releases/0001/1ed78298-522b-11e3-9dc0-22eed1f8132d"
fi

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
echo "fake ghe-export-settings data" > "$GHE_DATA_DIR/current/settings.json"
echo "fake license data" > "$GHE_DATA_DIR/current/enterprise.ghl"
echo "fake manage password hash data" > "$GHE_DATA_DIR/current/manage-password"
echo "rsync" > "$GHE_DATA_DIR/current/strategy"

begin_test "ghe-restore into configured vm"
(
    set -e
    rm -rf "$GHE_REMOTE_DATA_DIR"
    setup_remote_metadata

    # create file used to determine if instance has been configured.
    if [ "$GHE_VERSION_MAJOR" -le 1 ]; then
        touch "$GHE_REMOTE_DATA_DIR/enterprise/dna.json"
    else
        touch "$GHE_REMOTE_ROOT_DIR/etc/github/configured"
    fi

    # create file used to determine if instance is in maintenance mode.
    mkdir -p "$GHE_REMOTE_DATA_DIR/github/current/public/system"
    touch "$GHE_REMOTE_DATA_DIR/github/current/public/system/maintenance.html"

    # set restore host environ var
    GHE_RESTORE_HOST=127.0.0.1
    export GHE_RESTORE_HOST

    # run ghe-restore and write output to file for asserting against
    if ! ghe-restore -v -f > "$TRASHDIR/restore-out" 2>&1; then
        cat "$TRASHDIR/restore-out"
        : ghe-restore should have exited non-zero
        false
    fi

    # for debugging
    cat "$TRASHDIR/restore-out"

    # verify connect to right host
    grep -q "Connect 127.0.0.1:22 OK" "$TRASHDIR/restore-out"

    # verify all import scripts were run
    grep -q "alice/index.html" "$TRASHDIR/restore-out"
    grep -q "fake ghe-export-mysql data" "$TRASHDIR/restore-out"
    grep -q "fake ghe-export-redis data" "$TRASHDIR/restore-out"
    grep -q "fake ghe-export-authorized-keys data" "$TRASHDIR/restore-out"
    grep -q "fake ghe-export-ssh-host-keys data" "$TRASHDIR/restore-out"

    # verify settings import was *not* run due to instance already being
    # configured.
    ! grep -q "fake ghe-export-settings data" "$TRASHDIR/restore-out"

    # verify all repository data was transferred to the restore location
    diff -ru "$GHE_DATA_DIR/current/repositories" "$GHE_REMOTE_DATA_USER_DIR/repositories"

    # verify all pages data was transferred to the restore location
    diff -ru "$GHE_DATA_DIR/current/pages" "$GHE_REMOTE_DATA_USER_DIR/pages"

    if [ "$GHE_VERSION_MAJOR" -ge 2 ]; then
        # verify all hookshot user data was transferred
        diff -ru "$GHE_DATA_DIR/current/hookshot" "$GHE_REMOTE_DATA_USER_DIR/hookshot"

        # verify all alambic assets user data was transferred
        diff -ru "$GHE_DATA_DIR/current/alambic_assets" "$GHE_REMOTE_DATA_USER_DIR/alambic_assets"
    fi
)
end_test

begin_test "ghe-restore aborts without user verification"
(
    set -e
    rm -rf "$GHE_REMOTE_DATA_DIR"
    setup_remote_metadata

    # create file used to determine if instance has been configured.
    if [ "$GHE_VERSION_MAJOR" -le 1 ]; then
        touch "$GHE_REMOTE_DATA_DIR/enterprise/dna.json"
    else
        touch "$GHE_REMOTE_ROOT_DIR/etc/github/configured"
    fi

    # create file used to determine if instance is in maintenance mode.
    mkdir -p "$GHE_REMOTE_DATA_DIR/github/current/public/system"
    touch "$GHE_REMOTE_DATA_DIR/github/current/public/system/maintenance.html"

    # set restore host environ var
    GHE_RESTORE_HOST=127.0.0.1
    export GHE_RESTORE_HOST

    # run ghe-restore and write output to file for asserting against
    if echo "no" | ghe-restore -v > "$TRASHDIR/restore-out" 2>&1; then
        cat "$TRASHDIR/restore-out"
        false # ghe-restore should have exited non-zero
    fi

    grep -q "Restore aborted" "$TRASHDIR/restore-out"
)
end_test

begin_test "ghe-restore accepts user verification"
(
    set -e
    rm -rf "$GHE_REMOTE_DATA_DIR"
    setup_remote_metadata

    # create file used to determine if instance has been configured.
    if [ "$GHE_VERSION_MAJOR" -le 1 ]; then
        touch "$GHE_REMOTE_DATA_DIR/enterprise/dna.json"
    else
        touch "$GHE_REMOTE_ROOT_DIR/etc/github/configured"
    fi

    # create file used to determine if instance is in maintenance mode.
    mkdir -p "$GHE_REMOTE_DATA_DIR/github/current/public/system"
    touch "$GHE_REMOTE_DATA_DIR/github/current/public/system/maintenance.html"

    # set restore host environ var
    GHE_RESTORE_HOST=127.0.0.1
    export GHE_RESTORE_HOST

    # run ghe-restore and write output to file for asserting against
    if ! echo "yes" | ghe-restore -v > "$TRASHDIR/restore-out" 2>&1; then
        cat "$TRASHDIR/restore-out"
        false # ghe-restore should have accepted the input
    fi
)
end_test

begin_test "ghe-restore -c into unconfigured vm"
(
    set -e
    rm -rf "$GHE_REMOTE_DATA_DIR"
    setup_remote_metadata

    # set restore host environ var
    GHE_RESTORE_HOST=127.0.0.1
    export GHE_RESTORE_HOST

    # create file used to determine if instance is in maintenance mode.
    mkdir -p "$GHE_REMOTE_DATA_DIR/github/current/public/system"
    touch "$GHE_REMOTE_DATA_DIR/github/current/public/system/maintenance.html"

    # run ghe-restore and write output to file for asserting against
    if ! ghe-restore -v -f -c > "$TRASHDIR/restore-out" 2>&1; then
        cat "$TRASHDIR/restore-out"
        false
    fi

    # verify connect to right host
    grep -q "Connect 127.0.0.1:22 OK" "$TRASHDIR/restore-out"

    # verify all import scripts were run
    grep -q "alice/index.html" "$TRASHDIR/restore-out"
    grep -q "fake ghe-export-mysql data" "$TRASHDIR/restore-out"
    grep -q "fake ghe-export-redis data" "$TRASHDIR/restore-out"
    grep -q "fake ghe-export-authorized-keys data" "$TRASHDIR/restore-out"
    grep -q "fake ghe-export-ssh-host-keys data" "$TRASHDIR/restore-out"

    # verify settings were imported
    grep -q "fake ghe-export-settings data" "$TRASHDIR/restore-out"

    # verify all repository data was transferred to the restore location
    diff -ru "$GHE_DATA_DIR/current/repositories" "$GHE_REMOTE_DATA_USER_DIR/repositories"

    # verify all pages data was transferred to the restore location
    diff -ru "$GHE_DATA_DIR/current/pages" "$GHE_REMOTE_DATA_USER_DIR/pages"

    if [ "$GHE_VERSION_MAJOR" -ge 2 ]; then
        # verify all hookshot user data was transferred
        diff -ru "$GHE_DATA_DIR/current/hookshot" "$GHE_REMOTE_DATA_USER_DIR/hookshot"

        # verify all alambic assets user data was transferred
        diff -ru "$GHE_DATA_DIR/current/alambic_assets" "$GHE_REMOTE_DATA_USER_DIR/alambic_assets"
    fi
)
end_test

begin_test "ghe-restore into unconfigured vm"
(
    set -e
    rm -rf "$GHE_REMOTE_DATA_DIR"
    setup_remote_metadata

    # set restore host environ var
    GHE_RESTORE_HOST=127.0.0.1
    export GHE_RESTORE_HOST

    # create file used to determine if instance is in maintenance mode.
    mkdir -p "$GHE_REMOTE_DATA_DIR/github/current/public/system"
    touch "$GHE_REMOTE_DATA_DIR/github/current/public/system/maintenance.html"

    if [ "$GHE_VERSION_MAJOR" -le 1 ]; then
        # run ghe-restore and write output to file for asserting against
        # this should fail due to the appliance being in an unconfigured state
        ! ghe-restore -v > "$TRASHDIR/restore-out" 2>&1

        cat $TRASHDIR/restore-out

        # verify that ghe-restore failed due to the appliance not being configured
        grep -q -e "Error: $GHE_RESTORE_HOST not configured" "$TRASHDIR/restore-out"
    else
        # under version >= 2.0, ghe-restore into an unconfigured vm implies -c
        ghe-restore -v -f -c > "$TRASHDIR/restore-out" 2>&1
        cat "$TRASHDIR/restore-out"

        # verify connect to right host
        grep -q "Connect 127.0.0.1:22 OK" "$TRASHDIR/restore-out"

        # verify all import scripts were run
        grep -q "alice/index.html" "$TRASHDIR/restore-out"
        grep -q "fake ghe-export-mysql data" "$TRASHDIR/restore-out"
        grep -q "fake ghe-export-redis data" "$TRASHDIR/restore-out"
        grep -q "fake ghe-export-authorized-keys data" "$TRASHDIR/restore-out"
        grep -q "fake ghe-export-ssh-host-keys data" "$TRASHDIR/restore-out"

        # verify settings were imported
        grep -q "fake ghe-export-settings data" "$TRASHDIR/restore-out"

        # verify all repository data was transferred to the restore location
        diff -ru "$GHE_DATA_DIR/current/repositories" "$GHE_REMOTE_DATA_USER_DIR/repositories"

        # verify all pages data was transferred to the restore location
        diff -ru "$GHE_DATA_DIR/current/pages" "$GHE_REMOTE_DATA_USER_DIR/pages"

        if [ "$GHE_VERSION_MAJOR" -ge 2 ]; then
            # verify all hookshot user data was transferred
            diff -ru "$GHE_DATA_DIR/current/hookshot" "$GHE_REMOTE_DATA_USER_DIR/hookshot"

            # verify all alambic assets user data was transferred
            diff -ru "$GHE_DATA_DIR/current/alambic_assets" "$GHE_REMOTE_DATA_USER_DIR/alambic_assets"
        fi
    fi
)
end_test

begin_test "ghe-restore with host arg"
(
    set -e
    rm -rf "$GHE_REMOTE_DATA_DIR"
    setup_remote_metadata

    # create file used to determine if instance has been configured.
    if [ "$GHE_VERSION_MAJOR" -le 1 ]; then
        touch "$GHE_REMOTE_DATA_DIR/enterprise/dna.json"
    else
        touch "$GHE_REMOTE_ROOT_DIR/etc/github/configured"
    fi

    # create file used to determine if instance is in maintenance mode.
    mkdir -p "$GHE_REMOTE_DATA_DIR/github/current/public/system"
    touch "$GHE_REMOTE_DATA_DIR/github/current/public/system/maintenance.html"

    # set restore host environ var
    GHE_RESTORE_HOST=127.0.0.1
    export GHE_RESTORE_HOST

    # run it
    output="$(ghe-restore -f localhost)" || false

    # verify host arg overrides configured restore host
    echo "$output" | grep -q 'Connect localhost:22 OK'

    # verify repository data was transferred to the restore location
    diff -ru "$GHE_DATA_DIR/current/repositories" "$GHE_REMOTE_DATA_USER_DIR/repositories"

    # verify all pages data was transferred to the restore location
    diff -ru "$GHE_DATA_DIR/current/pages" "$GHE_REMOTE_DATA_USER_DIR/pages"

    if [ "$GHE_VERSION_MAJOR" -ge 2 ]; then
        # verify all hookshot user data was transferred
        diff -ru "$GHE_DATA_DIR/current/hookshot" "$GHE_REMOTE_DATA_USER_DIR/hookshot"

        # verify all alambic assets user data was transferred
        diff -ru "$GHE_DATA_DIR/current/alambic_assets" "$GHE_REMOTE_DATA_USER_DIR/alambic_assets"
    fi
)
end_test

begin_test "ghe-restore no host arg or configured restore host"
(
    set -e
    rm -rf "$GHE_REMOTE_DATA_DIR"
    setup_remote_metadata

    # create file used to determine if instance has been configured.
    if [ "$GHE_VERSION_MAJOR" -le 1 ]; then
        touch "$GHE_REMOTE_DATA_DIR/enterprise/dna.json"
    else
        touch "$GHE_REMOTE_ROOT_DIR/etc/github/configured"
    fi

    # create file used to determine if instance is in maintenance mode.
    mkdir -p "$GHE_REMOTE_DATA_DIR/github/current/public/system"
    touch "$GHE_REMOTE_DATA_DIR/github/current/public/system/maintenance.html"

    # unset configured restore host
    unset GHE_RESTORE_HOST

    # verify running ghe-restore fails
    ! ghe-restore -f
)
end_test

begin_test "ghe-restore with no pages backup"
(
    set -e
    rm -rf "$GHE_REMOTE_DATA_DIR"
    setup_remote_metadata

    # create file used to determine if instance has been configured.
    if [ "$GHE_VERSION_MAJOR" -le 1 ]; then
        touch "$GHE_REMOTE_DATA_DIR/enterprise/dna.json"
    else
        touch "$GHE_REMOTE_ROOT_DIR/etc/github/configured"
    fi

    # create file used to determine if instance is in maintenance mode.
    mkdir -p "$GHE_REMOTE_DATA_DIR/github/current/public/system"
    touch "$GHE_REMOTE_DATA_DIR/github/current/public/system/maintenance.html"

    # remove pages data
    rm -rf "$GHE_DATA_DIR/1/pages"

    # run it
    ghe-restore -v -f localhost
)
end_test

begin_test "ghe-restore with tarball strategy"
(
    set -e
    rm -rf "$GHE_REMOTE_DATA_DIR"
    setup_remote_metadata

    # create file used to determine if instance has been configured.
    if [ "$GHE_VERSION_MAJOR" -le 1 ]; then
        touch "$GHE_REMOTE_DATA_DIR/enterprise/dna.json"
    else
        touch "$GHE_REMOTE_ROOT_DIR/etc/github/configured"
    fi

    # create file used to determine if instance is in maintenance mode.
    mkdir -p "$GHE_REMOTE_DATA_DIR/github/current/public/system"
    touch "$GHE_REMOTE_DATA_DIR/github/current/public/system/maintenance.html"

    # run it
    echo "tarball" > "$GHE_DATA_DIR/current/strategy"
    output=$(ghe-restore -v -f localhost)

    # verify ghe-import-repositories was run on remote side with fake tarball
    echo "$output" | grep -q 'fake ghe-export-repositories data'
)
end_test
