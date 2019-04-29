#!/usr/bin/env bash
# ghe-backup command tests

# Bring in testlib
# shellcheck source=test/testlib.sh
. "$(dirname "$0")/testlib.sh"

# Create the backup data dir and fake remote repositories dirs
mkdir -p "$GHE_DATA_DIR" "$GHE_REMOTE_DATA_USER_DIR"

setup_test_data $GHE_REMOTE_DATA_USER_DIR

begin_test "ghe-backup first snapshot"
(
  set -e

  # check that no current symlink exists yet
  [ ! -d "$GHE_DATA_DIR/current" ]

  # run it
  ghe-backup -v

  verify_all_backedup_data
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

  verify_all_backedup_data
)
end_test

begin_test "ghe-backup logs the benchmark"
(
  set -e

  # wait a second for snapshot timestamp
  sleep 1

  export BM_TIMESTAMP=foo

  ghe-backup

  [ "$(grep took $GHE_DATA_DIR/current/benchmarks/benchmark.foo.log | wc -l)" -gt 1 ]
)
end_test

begin_test "ghe-backup with relative data dir path"
(
  set -e

  # wait a second for snapshot timestamp
  sleep 1

  # generate a timestamp
  GHE_SNAPSHOT_TIMESTAMP="relative-$(date +"%Y%m%dT%H%M%S")"
  export GHE_SNAPSHOT_TIMESTAMP

  # change working directory to the root directory
  cd $ROOTDIR

  # run it
  GHE_DATA_DIR=$(echo $GHE_DATA_DIR | sed 's|'$ROOTDIR'/||') ghe-backup

  # check that current symlink points to new snapshot
  [ "$(ls -ld "$GHE_DATA_DIR/current" | sed 's/.*-> //')" = "$GHE_SNAPSHOT_TIMESTAMP" ]

  verify_all_backedup_data
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

begin_test "ghe-backup without management console password"
(
  set -e

  git config -f "$GHE_REMOTE_DATA_USER_DIR/common/secrets.conf" secrets.manage ""
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
  ghe-backup | grep -q "Repos verified: 6, Errors: 1, Took:"
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

  tmpdir=$(mktemp -d "$TRASHDIR/foo.XXXXXX")

  # If user is running the tests extracted from a release tarball, git clone will fail.
  if GIT_DIR="$ROOTDIR/.git" git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    git clone "$ROOTDIR" "$tmpdir/backup-utils"
    cd "$tmpdir/backup-utils"
    rm -rf .git
    ./bin/ghe-backup

    # Verify that ghe-backup wrote its version information to the host
    [ -f "$GHE_REMOTE_DATA_USER_DIR/common/backup-utils-version" ]
  else
    echo ".git directory not found, skipping ghe-backup not from a clone test"
  fi
)
end_test

begin_test "ghe-backup with leaked SSH host key detection for current backup"
(
  set -e

  # Rename ghe-export-ssh-keys to generate a fake ssh
  cd "$ROOTDIR/test/bin"
  mv "ghe-export-ssh-host-keys" "ghe-export-ssh-host-keys.orig"
  ln -s ghe-gen-fake-ssh-tar ghe-export-ssh-host-keys
  cd -

  # Inject the fingerprint into the blacklist
  export FINGERPRINT_BLACKLIST="98:d8:99:d3:be:c0:55:05:db:b0:53:2f:1f:ad:b3:60"

  # Run it
  output=$(ghe-backup -v)

  # Set the export ssh back
  mv "$ROOTDIR/test/bin/ghe-export-ssh-host-keys.orig" "$ROOTDIR/test/bin/ghe-export-ssh-host-keys"

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

begin_test "ghe-backup honours --version flag"
(
  set -e

  # Make sure a partial version string is returned
  ghe-backup --version | grep "GitHub backup-utils v"

)
end_test

begin_test "ghe-backup honours --help and -h flags"
(
  set -e

  arg_help=$(ghe-backup --help | grep -o 'Usage: ghe-backup')
  arg_h=$(ghe-backup -h | grep -o 'Usage: ghe-backup')

  # Make sure a Usage: string is returned and that it's the same for -h and --help
  [ "$arg_help" = "$arg_h" ] && echo $arg_help | grep -q "Usage: ghe-backup"

)
end_test

begin_test "ghe-backup exits early on unsupported version"
(
  set -e
  ! GHE_TEST_REMOTE_VERSION=2.10.0 ghe-backup -v
)
end_test

begin_test "ghe-backup-strategy returns rsync for HA backup"
(
  set -e
  touch "$GHE_REMOTE_ROOT_DIR/etc/github/repl-state"
  output="$(ghe-backup-strategy)"
  rm "$GHE_REMOTE_ROOT_DIR/etc/github/repl-state"
  [ "$output" = "rsync" ]
)
end_test

# Reset data for sub-subsequent tests
rm -rf $GHE_REMOTE_DATA_USER_DIR
setup_test_data $GHE_REMOTE_DATA_USER_DIR

begin_test "ghe-backup cluster"
(
  set -e
  setup_remote_cluster

  if ! ghe-backup -v > "$TRASHDIR/backup-out" 2>&1; then
    cat "$TRASHDIR/backup-out"
    : ghe-restore should have exited successfully
    false
  fi

  cat "$TRASHDIR/backup-out"

  # verify data was copied from multiple nodes
  # repositories
  grep -q "repositories from git-server-fake-uuid" "$TRASHDIR/backup-out"
  grep -q "repositories from git-server-fake-uuid1" "$TRASHDIR/backup-out"
  grep -q "repositories from git-server-fake-uuid2" "$TRASHDIR/backup-out"

  # storage
  grep -q "objects from storage-server-fake-uuid" "$TRASHDIR/backup-out"
  grep -q "objects from storage-server-fake-uuid1" "$TRASHDIR/backup-out"
  grep -q "objects from storage-server-fake-uuid2" "$TRASHDIR/backup-out"

  # pages
  grep -q "Starting backup for host: pages-server-fake-uuid" "$TRASHDIR/backup-out"
  grep -q "Starting backup for host: pages-server-fake-uuid1" "$TRASHDIR/backup-out"
  grep -q "Starting backup for host: pages-server-fake-uuid2" "$TRASHDIR/backup-out"

  # verify cluster.conf backed up
  [ -f "$GHE_DATA_DIR/current/cluster.conf" ]
  grep -q "fake cluster config" "$GHE_DATA_DIR/current/cluster.conf"

  verify_all_backedup_data
)
end_test

begin_test "ghe-backup not missing directories or files on source appliance"
(
    # Tests the scenario where the database and on disk state are consistent.
    set -e

    if ! ghe-backup -v > "$TRASHDIR/backup-out" 2>&1; then
      cat "$TRASHDIR/backup-out"
      : ghe-backup should have completed successfully
      false
    fi

    # Ensure the output doesn't contain the warnings
    grep -q "Warning: One or more repository networks and/or gists were not found on the source appliance." "$TRASHDIR/backup-out" && exit 1
    grep -q "Warning: One or more storage objects were not found on the source appliance." "$TRASHDIR/backup-out" && exit 1

    verify_all_backedup_data
)
end_test

begin_test "ghe-backup missing directories or files on source appliance"
(
    # Tests the scenario where something exists in the database, but not on disk.
    set -e

    rm -rf $GHE_REMOTE_DATA_USER_DIR/repositories/1
    rm -rf $GHE_REMOTE_DATA_USER_DIR/storage/e/ed/1a/ed1aa60f0706cefde8ba2b3be662d3a0e0e1fbc94a52a3201944684cc0c5f244

    if ! ghe-backup -v > "$TRASHDIR/backup-out" 2>&1; then
      cat "$TRASHDIR/backup-out"
      : ghe-backup should have completed successfully
      false
    fi

    # Check the output for the warnings
    grep -q "Warning: One or more repository networks and/or gists were not found on the source appliance." "$TRASHDIR/backup-out"
    grep -q "\-1/23/bb/4c/gist" "$TRASHDIR/backup-out"
    grep -q "\-1/nw/23/bb/4c/2345" "$TRASHDIR/backup-out"
    grep -q "Warning: One or more storage objects were not found on the source appliance." "$TRASHDIR/backup-out"
    grep -q "\-e/ed/1a/ed1aa60f0706cefde8ba2b3be662d3a0e0e1fbc94a52a3201944684cc0c5f244" "$TRASHDIR/backup-out"

    verify_all_backedup_data
)
end_test
