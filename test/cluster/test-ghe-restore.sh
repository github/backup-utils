#!/bin/sh
# ghe-restore command tests in a cluster

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

setup_remote_cluster

begin_test "cluster: ghe-restore from 2.4.0 snapshot"
(
    set -e
    rm -rf "$GHE_REMOTE_ROOT_DIR"
    setup_remote_metadata

    # set restore host environ var
    GHE_RESTORE_HOST=127.0.0.1
    export GHE_RESTORE_HOST

    # create file used to determine if instance is in maintenance mode.
    mkdir -p "$GHE_REMOTE_DATA_DIR/github/current/public/system"
    touch "$GHE_REMOTE_DATA_DIR/github/current/public/system/maintenance.html"

    # run ghe-restore and write output to file for asserting against
    if ghe-restore -v -f > "$TRASHDIR/restore-out" 2>&1; then
        cat "$TRASHDIR/restore-out"
        : ghe-restore should have exited non-zero
        false
    fi

    # for debugging
    cat "$TRASHDIR/restore-out"

    # verify connect to right host
    grep -q "Error: Snapshot must be from" "$TRASHDIR/restore-out"
)
end_test
