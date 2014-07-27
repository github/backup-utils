#!/bin/sh
# ghe-rsync-backup command tests

# Bring in testlib
. $(dirname "$0")/testlib.sh

# Setup backup snapshot data dir and remote repositories dir locations to use
# the per-test temp space.
GHE_DATA_DIR="$TRASHDIR/data"
GHE_REMOTE_DATA_DIR="$TRASHDIR/remote/repositories"
export GHE_DATA_DIR GHE_REMOTE_DATA_DIR

# Create the backup data dir and fake remote repositories dirs
mkdir -p "$GHE_DATA_DIR" "$GHE_REMOTE_DATA_DIR"
mkdir -p "$TRASHDIR/hooks"

# Create some test repositories in the remote repositories dir
cd "$GHE_REMOTE_DATA_DIR"
mkdir alice bob
mkdir alice/repo1.git alice/repo2.git bob/repo3.git

# Initialize test repositories with a fake commit
for repo in */*.git; do
    git init -q --bare "$repo"
    git --git-dir="$repo" --work-tree=. commit -q --allow-empty -m 'test commit'
    rm -rf "$repo/hooks"
    ln -s "$TRASHDIR/hooks" "$repo/hooks"
done

# Generate a packed-refs file in repo1
git --git-dir="alice/repo1.git" pack-refs

# Generate a pack in repo2
git --git-dir="alice/repo2.git" repack -q

# Add some fake svn data to repo3
echo "fake svn history data" > bob/repo3.git/svn.history.msgpack
mkdir bob/repo3.git/svn_data
echo "fake property history data" > bob/repo3.git/svn_data/property_history.msgpack

begin_test "ghe-rsync-backup first snapshot"
(
    set -e

    # force snapshot number instead of generating a timestamp
    GHE_SNAPSHOT_TIMESTAMP=1
    export GHE_SNAPSHOT_TIMESTAMP

    # run it
    ghe-rsync-backup

    # check that repositories directory was created
    [ -d "$GHE_DATA_DIR/1/repositories" ]

    # check that packed-refs file was transferred
    [ -f "$GHE_DATA_DIR/1/repositories/alice/repo1.git/packed-refs" ]

    # check that a pack file was transferred
    [ -f "$GHE_DATA_DIR"/1/repositories/alice/repo2.git/objects/pack/*.pack ]

    # check that svn data was transferred
    [ -f "$GHE_DATA_DIR"/1/repositories/bob/repo3.git/svn.history.msgpack ]
    [ -f "$GHE_DATA_DIR"/1/repositories/bob/repo3.git/svn_data/property_history.msgpack ]

    # verify all repository data was transferred
    diff -ru "$GHE_REMOTE_DATA_DIR" "$GHE_DATA_DIR/1/repositories"
)
end_test


begin_test "ghe-rsync-backup subsequent snapshot"
(
    set -e

    # force snapshot number instead of generating a timestamp
    GHE_SNAPSHOT_TIMESTAMP=2
    export GHE_SNAPSHOT_TIMESTAMP

    # make current symlink point to previous increment
    ln -s 1 "$GHE_DATA_DIR/current"

    # run it
    ghe-rsync-backup

    # check that repositories directory was created
    snapshot="$GHE_DATA_DIR/2/repositories"
    [ -d "$snapshot" ]

    # verify hard links used for existing files
    inode1=$(ls -i "$GHE_DATA_DIR/1/repositories/alice/repo1.git/packed-refs" | awk '{ print $1; }')
    inode2=$(ls -i "$GHE_DATA_DIR/2/repositories/alice/repo1.git/packed-refs" | awk '{ print $1; }')
    [ "$inode1" = "$inode2" ]

    # verify all repository data exists in the increment
    diff -ru "$GHE_REMOTE_DATA_DIR" "$GHE_DATA_DIR/2/repositories"
)
end_test


begin_test "ghe-rsync-backup handles __special__ data dirs"
(
    set -e

    # force snapshot number instead of generating a timestamp
    GHE_SNAPSHOT_TIMESTAMP=3
    export GHE_SNAPSHOT_TIMESTAMP

    # create the excluded __nodeload_archives__ dir on the remote side
    mkdir "$GHE_REMOTE_DATA_DIR/__nodeload_archives__"
    touch "$GHE_REMOTE_DATA_DIR/__nodeload_archives__/something.tar.gz"

    # create the included __purgatory__ dir on the remote side
    mkdir -p "$GHE_REMOTE_DATA_DIR/__purgatory__/123.git"
    git init --bare -q "$GHE_REMOTE_DATA_DIR/__purgatory__/123.git"
    git --git-dir="$GHE_REMOTE_DATA_DIR/__purgatory__/123.git" --work-tree=. \
        commit --allow-empty -m 'test commit'

    # run it
    ghe-rsync-backup

    # check that repositories directory was created
    snapshot="$GHE_DATA_DIR/3/repositories"
    [ -d "$snapshot" ]

    # check that excluded special dir was not transferred
    [ ! -d "$snapshot/__nodeload_archives__" ]

    # check that included special dir was not transferred
    [ -d "$snapshot/__purgatory__" ]

    # check that all files were transferred under included dir
    [ -f "$snapshot/__purgatory__/123.git/description" ]

    # fsck the repo to make sure everything was transferred
    git --git-dir="$snapshot/__purgatory__/123.git" fsck
)
end_test

begin_test "ghe-rsync-backup excludes tmp packs and objects"
(
    set -e

    # force snapshot number instead of generating a timestamp
    GHE_SNAPSHOT_TIMESTAMP=4
    export GHE_SNAPSHOT_TIMESTAMP

    # create a tmp pack to emulate a pack being written to
    touch "$GHE_REMOTE_DATA_DIR/alice/repo1.git/objects/pack/tmp_pack_1234"

    # run it
    ghe-rsync-backup

    # check that repositories directory was created
    snapshot="$GHE_DATA_DIR/4/repositories"
    [ -d "$snapshot" ]

    # check that tmp pack was not transferred
    [ ! -d "$snapshot/alice/repo1.git/objects/pack/tmp_pack_1234" ]
)
end_test
