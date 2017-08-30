#!/usr/bin/env bash
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

if [ "$GHE_VERSION_MAJOR" -ge 2 ]; then
    # Create some fake data in the remote data directory
    mkdir -p "$GHE_REMOTE_DATA_USER_DIR/hookshot"
    cd "$GHE_REMOTE_DATA_USER_DIR/hookshot"
    mkdir -p repository-123 repository-456
    touch repository-123/test.bpack repository-456/test.bpack

    # Create some fake hooks in the remote data directory
    mkdir -p "$GHE_REMOTE_DATA_USER_DIR/git-hooks/environments/tarballs"
    mkdir -p "$GHE_REMOTE_DATA_USER_DIR/git-hooks/repos"

    cd "$GHE_REMOTE_DATA_USER_DIR/git-hooks/environments"
    mkdir -p 123/abcdef 456/fed314
    touch 123/abcdef/script.sh 456/fed314/foo.sh

    cd "$GHE_REMOTE_DATA_USER_DIR/git-hooks/environments/tarballs"
    mkdir -p 123/abcdef 456/fed314
    touch 123/abcdef/script.tar.gz 456/fed314/foo.tar.gz

    cd "$GHE_REMOTE_DATA_USER_DIR/git-hooks/repos"
    mkdir -p 321 654
    touch 321/script.sh 654/foo.sh

    # Create some fake alambic data in the remote data directory
    mkdir -p "$GHE_REMOTE_DATA_USER_DIR/alambic_assets/github-enterprise-assets/0000"
    touch "$GHE_REMOTE_DATA_USER_DIR/alambic_assets/github-enterprise-assets/0000/test.png"

    mkdir -p "$GHE_REMOTE_DATA_USER_DIR/alambic_assets/github-enterprise-releases/0001"
    touch "$GHE_REMOTE_DATA_USER_DIR/alambic_assets/github-enterprise-releases/0001/1ed78298-522b-11e3-9dc0-22eed1f8132d"

    # Create a fake UUID
    echo "fake uuid" > "$GHE_REMOTE_DATA_USER_DIR/common/uuid"

    # Create fake audit log migration sentinel file
    touch "$GHE_REMOTE_DATA_USER_DIR/common/es-scan-complete"
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
mkdir alice/repo1.git alice/repo2.git bob/repo3.git alice/broken.git

# Initialize test repositories with a fake commit
for repo in */*.git; do
    git init -q --bare "$repo"
    git --git-dir="$repo" --work-tree=. commit -q --allow-empty -m 'test commit'
done
# Break a repo to test fsck
rm -f alice/broken.git/objects/4b/825dc642cb6eb9a060e54bf8d69288fbee4904

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

        # verify all hookshot user data was transferred
        diff -ru "$GHE_REMOTE_DATA_USER_DIR/hookshot" "$GHE_DATA_DIR/current/hookshot"

        # verify all git hooks tarballs were transferred
        diff -ru "$GHE_REMOTE_DATA_USER_DIR/git-hooks/environments/tarballs" "$GHE_DATA_DIR/current/git-hooks/environments/tarballs"

        # verify the extracted environments were not transferred
        ! diff -ru "$GHE_REMOTE_DATA_USER_DIR/git-hooks/environments" "$GHE_DATA_DIR/current/git-hooks/environments"

        # verify the extracted repositories were transferred
        diff -ru "$GHE_REMOTE_DATA_USER_DIR/git-hooks/repos" "$GHE_DATA_DIR/current/git-hooks/repos"

        # verify all alambic assets user data was transferred
        diff -ru "$GHE_REMOTE_DATA_USER_DIR/alambic_assets" "$GHE_DATA_DIR/current/alambic_assets"

        # verify the UUID was transferred
        diff -ru "$GHE_REMOTE_DATA_USER_DIR/common/uuid" "$GHE_DATA_DIR/current/uuid"

        # check that ca certificates were backed up
        [ "$(cat "$GHE_DATA_DIR/current/ssl-ca-certificates.tar")" = "fake ghe-export-ssl-ca-certificates data" ]

        # verify the audit log migration sentinel file has been created
        [ -f "$GHE_DATA_DIR/current/es-scan-complete" ]
    fi

    # verify that ghe-backup wrote its version information to the host
    [ -f "$GHE_REMOTE_DATA_USER_DIR/common/backup-utils-version" ]
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

        # verify all hookshot user data was transferred
        diff -ru "$GHE_REMOTE_DATA_USER_DIR/hookshot" "$GHE_DATA_DIR/current/hookshot"

        # verify all git hooks tarballs were transferred
        diff -ru "$GHE_REMOTE_DATA_USER_DIR/git-hooks/environments/tarballs" "$GHE_DATA_DIR/current/git-hooks/environments/tarballs"

        # verify the extracted environments were not transferred
        ! diff -ru "$GHE_REMOTE_DATA_USER_DIR/git-hooks/environments" "$GHE_DATA_DIR/current/git-hooks/environments"

        # verify the extracted repositories were transferred
        diff -ru "$GHE_REMOTE_DATA_USER_DIR/git-hooks/repos" "$GHE_DATA_DIR/current/git-hooks/repos"

        # verify all alambic assets user data was transferred
        diff -ru "$GHE_REMOTE_DATA_USER_DIR/alambic_assets" "$GHE_DATA_DIR/current/alambic_assets"

        # verify the UUID was transferred
        diff -ru "$GHE_REMOTE_DATA_USER_DIR/common/uuid" "$GHE_DATA_DIR/current/uuid"

        # check that ca certificates were backed up
        [ "$(cat "$GHE_DATA_DIR/current/ssl-ca-certificates.tar")" = "fake ghe-export-ssl-ca-certificates data" ]

        # verify the audit log migration sentinel file has been created
        [ -f "$GHE_DATA_DIR/current/es-scan-complete" ]
    fi
)
end_test

begin_test "ghe-backup logs the benchmark"
(
  set -e

  # wait a second for snapshot timestamp
  sleep 1

  export BM_TIMESTAMP=foo

  ghe-backup

  [ $(grep took $GHE_DATA_DIR/current/benchmarks/benchmark.foo.log | wc -l) -gt 1 ]
)
end_test

begin_test "ghe-backup with relative data dir path"
(
    set -e

    # wait a second for snapshot timestamp
    sleep 1

    # generate a timestamp
    export GHE_SNAPSHOT_TIMESTAMP="relative-$(date +"%Y%m%dT%H%M%S")"

    # change working directory to the root directory
    cd $ROOTDIR

    # run it
    GHE_DATA_DIR=$(echo $GHE_DATA_DIR | sed 's|'$ROOTDIR'/||') ghe-backup

    # check that current symlink points to new snapshot
    ls -ld "$GHE_DATA_DIR/current" | grep -q "$GHE_SNAPSHOT_TIMESTAMP"

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

        # verify all hookshot user data was transferred
        diff -ru "$GHE_REMOTE_DATA_USER_DIR/hookshot" "$GHE_DATA_DIR/current/hookshot"

        # verify all git hooks tarballs were transferred
        diff -ru "$GHE_REMOTE_DATA_USER_DIR/git-hooks/environments/tarballs" "$GHE_DATA_DIR/current/git-hooks/environments/tarballs"

        # verify the extracted environments were not transferred
        ! diff -ru "$GHE_REMOTE_DATA_USER_DIR/git-hooks/environments" "$GHE_DATA_DIR/current/git-hooks/environments"

        # verify the extracted repositories were transferred
        diff -ru "$GHE_REMOTE_DATA_USER_DIR/git-hooks/repos" "$GHE_DATA_DIR/current/git-hooks/repos"

        # verify all alambic assets user data was transferred
        diff -ru "$GHE_REMOTE_DATA_USER_DIR/alambic_assets" "$GHE_DATA_DIR/current/alambic_assets"

        # verify the UUID was transferred
        diff -ru "$GHE_REMOTE_DATA_USER_DIR/common/uuid" "$GHE_DATA_DIR/current/uuid"

        # check that ca certificates were backed up
        [ "$(cat "$GHE_DATA_DIR/current/ssl-ca-certificates.tar")" = "fake ghe-export-ssl-ca-certificates data" ]

        # verify the audit log migration sentinel file has been created
        [ -f "$GHE_DATA_DIR/current/es-scan-complete" ]
    fi

    # verify that ghe-backup wrote its version information to the host
    [ -f "$GHE_REMOTE_DATA_USER_DIR/common/backup-utils-version" ]
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

begin_test "ghe-backup fails fast when old style run in progress"
(
    set -e

    ln -s 1 "$GHE_DATA_DIR/in-progress"
    ! ghe-backup

    unlink "$GHE_DATA_DIR/in-progress"
)
end_test

begin_test "ghe-backup cleans up stale in-progress file"
(
    set -e

    echo "20150928T153353 99999" > "$GHE_DATA_DIR/in-progress"
    ghe-backup

    [ ! -f "$GHE_DATA_DIR/in-progress" ]
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

begin_test "ghe-backup empty hookshot directory"
(
  set -e

  rm -rf $GHE_REMOTE_DATA_USER_DIR/hookshot/repository-*
  rm -rf $GHE_DATA_DIR/current/hookshot/repository-*
  ghe-backup

  # Check that the "--link-dest arg does not exist" message hasn't occurred.
  [ ! "$(grep "[l]ink-dest arg does not exist" $TRASHDIR/out)" ]
)
end_test

begin_test "ghe-backup empty git-hooks directory"
(
  set -e

  rm -rf $GHE_REMOTE_DATA_USER_DIR/git-hooks/*
  rm -rf $GHE_DATA_DIR/current/git-hooks/*
  ghe-backup

  # Check that the "--link-dest arg does not exist" message hasn't occurred.
  [ ! "$(grep "[l]ink-dest arg does not exist" $TRASHDIR/out)" ]
)
end_test

begin_test "ghe-backup fsck"
(
  set -e

  export GHE_BACKUP_FSCK=yes
  ghe-backup | grep -q "Repos verified: 4, Errors: 1, Took:"
  # Verbose mode disabled by default
  ! ghe-backup | grep -q "missing tree 4b825dc642cb6eb9a060e54bf8d69288fbee4904"
  ghe-backup -v | grep -q "missing tree 4b825dc642cb6eb9a060e54bf8d69288fbee4904"

  export GHE_BACKUP_FSCK=no
  ! ghe-backup | grep -q "Repos verified:"
)
end_test

begin_test "ghe-backup stores version when not run from a clone"
(
  set -e

  # Make sure this doesn't exist
  rm -f "$GHE_REMOTE_DATA_USER_DIR/common/backup-utils-version"

  tmpdir=$(mktemp -d $TRASHDIR/foo.XXXXXX)
  git clone $ROOTDIR $tmpdir/backup-utils
  cd $tmpdir/backup-utils
  rm -rf .git
  ./bin/ghe-backup

  # verify that ghe-backup wrote its version information to the host
  [ -f "$GHE_REMOTE_DATA_USER_DIR/common/backup-utils-version" ]
)
end_test

begin_test "ghe-backup stores verbose output in a file when GHE_VERBOSE_LOG is set"
(
  set -e

  verbose_log=$(mktemp $TRASHDIR/verbose-test.XXXXXX)
  export GHE_VERBOSE_LOG="$verbose_log"

  ghe-backup -v
  [ -s "$verbose_log" ]
)
end_test

begin_test "ghe-backup with leaked SSH host key detection for current backup"
(
  set -e

  SHARED_UTILS_PATH=$(dirname $(which ghe-detect-leaked-ssh-keys))
  # Inject the fingerprint into the blacklist
  echo 98:d8:99:d3:be:c0:55:05:db:b0:53:2f:1f:ad:b3:60 >> "$SHARED_UTILS_PATH/ghe-ssh-leaked-host-keys-list.txt"

  # Re-link ghe-export-ssh-keys to generate a fake ssh
  unlink  "$ROOTDIR/test/bin/ghe-export-ssh-host-keys"
  cd "$ROOTDIR/test/bin"
  ln -s ghe-gen-fake-ssh-tar ghe-export-ssh-host-keys
  cd -

  # Run it
  output=$(ghe-backup -v)

  # Set the export ssh link back
  unlink  "$ROOTDIR/test/bin/ghe-export-ssh-host-keys"
  cd "$ROOTDIR/test/bin"
  ln -s ghe-fake-export-command ghe-export-ssh-host-keys
  cd -

  # Test the output for leaked key detection
  echo $output| grep "The current backup contains leaked SSH host keys"

)
end_test

begin_test "ghe-backup with no leaked keys"
(
  set -e

  # Make sure there are no leaked key messages
  ! ghe-backup -v | grep "Leaked key"

)
end_test
