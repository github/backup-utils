#!/usr/bin/env bash
# ghe-backup command tests

TESTS_DIR="$PWD/$(dirname "$0")"
# Bring in testlib.
# shellcheck source=test/testlib.sh
. "$TESTS_DIR/testlib.sh"

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

  verify_progress_cleanup_process
)
end_test

begin_test "ghe-backup incremental"
(
  set -e
  sleep 1

  setup_incremental_backup_config

  # check that no current symlink exists yet
  [ -d "$GHE_DATA_DIR/current" ]
 
  # run it
  # this time expect full backup
  GHE_TEST_REMOTE_VERSION=3.10.0 ghe-backup -i

  # check metadata files are created
  [ -e "$GHE_DATA_DIR/inc_full_backup" ]
  [ -e "$GHE_DATA_DIR/inc_snapshot_data" ]

  # check the metadata
  expected_full_backup=$(wc -l < "$GHE_DATA_DIR/inc_full_backup")
  expected_incremental_backup=$(wc -l < "$GHE_DATA_DIR/inc_snapshot_data")
  # should have 1 full backup and 0 incremental backup
  [ $expected_full_backup -eq 1 ]
  [ $expected_incremental_backup -eq 0 ]

  # re-run
  # this time expect incremental backup
  GHE_TEST_REMOTE_VERSION=3.10.0 ghe-backup -i

  expected_full_backup=$(wc -l < "$GHE_DATA_DIR/inc_full_backup")
  expected_incremental_backup=$(wc -l < "$GHE_DATA_DIR/inc_snapshot_data")
  # should have 1 full backup and 1 incremental backup
  [ $expected_full_backup -eq 1 ]
  [ $expected_incremental_backup -eq 1 ]

  # re-run
  # this time expect yet another incremental backup
  GHE_TEST_REMOTE_VERSION=3.10.0 ghe-backup -i

  expected_full_backup=$(wc -l < "$GHE_DATA_DIR/inc_full_backup")
  expected_incremental_backup=$(wc -l < "$GHE_DATA_DIR/inc_snapshot_data")
  # should have 1 full backup and 2 incremental backup
  [ $expected_full_backup -eq 1 ]
  [ $expected_incremental_backup -eq 2 ]
)
end_test

begin_test "ghe-backup incremental without config"
(
  set -e
  sleep 1

  # set incorrect config for incremental backup
  ghe-ssh "$GHE_HOSTNAME" -- 'ghe-config mysql.backup.binary false'
  export GHE_INCREMENTAL_MAX_BACKUPS=1

  # check ghe-backup fails
  ! GHE_TEST_REMOTE_VERSION=3.10.0 ghe-backup -i
)
end_test

begin_test "ghe-backup performs proper version check"
(
  set -e
  sleep 1

  setup_incremental_backup_config

  #check ghe-backup fails
  ! GHE_TEST_REMOTE_VERSION=3.9.0 ghe-backup -i
  ! GHE_TEST_REMOTE_VERSION=3.8.0 ghe-backup -i
  ! GHE_TEST_REMOTE_VERSION=2.2.0 ghe_backup -i
)

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

begin_test "ghe-backup without password pepper"
(
  set -e

  git config -f "$GHE_REMOTE_DATA_USER_DIR/common/secrets.conf" secrets.github.user-password-secrets ""
  ghe-backup

  [ ! -f "$GHE_DATA_DIR/current/password-pepper" ]
)
end_test

# before the introduction of multiuser auth
begin_test "ghe-backup management console does not backup argon secret"
(
  set -e

  GHE_REMOTE_VERSION=2.1.10 ghe-backup -v | grep -q "management console argon2 secret not set" && exit 1
  [ ! -f "$GHE_DATA_DIR/current/manage-argon-secret" ]

  GHE_REMOTE_VERSION=3.6.1 ghe-backup -v | grep -q "management console argon2 secret not set" && exit 1
  [ ! -f "$GHE_DATA_DIR/current/manage-argon-secret" ]

  GHE_REMOTE_VERSION=3.7.10 ghe-backup -v | grep -q "management console argon2 secret not set" && exit 1
  [ ! -f "$GHE_DATA_DIR/current/manage-argon-secret" ]

  GHE_REMOTE_VERSION=3.8.2 ghe-backup -v | grep -q "management console argon2 secret not set" && exit 1
  [ ! -f "$GHE_DATA_DIR/current/manage-argon-secret" ]
)
end_test

# multiuser auth introduced in ghes version 3.8
begin_test "ghe-backup management console backs up argon secret"
(
  set -e

  git config -f "$GHE_REMOTE_DATA_USER_DIR/common/secrets.conf" secrets.manage-auth.argon-secret "fake pw"
  GHE_REMOTE_VERSION=3.8.0 ghe-backup

  [ "$(cat "$GHE_DATA_DIR/current/manage-argon-secret")" = "fake pw" ]

  rm -rf "$GHE_DATA_DIR/current"

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

  export GHE_GEN_FAKE_SSH_TAR="yes"

  # Inject the fingerprint into the blacklist
  export FINGERPRINT_BLACKLIST="98:d8:99:d3:be:c0:55:05:db:b0:53:2f:1f:ad:b3:60"

  # Run it
  output=$(ghe-backup -v)

  unset GHE_GEN_FAKE_SSH_TAR

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
    : ghe-backup should have exited successfully
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

begin_test "ghe-backup has default cadence configured"
(
  set -e
  enable_actions

  [ -n "$GHE_MSSQL_BACKUP_CADENCE" ]
)
end_test

# Override backup cadence for testing purposes
GHE_MSSQL_BACKUP_CADENCE=10,5,1
export GHE_MSSQL_BACKUP_CADENCE
setup_actions_test_data "$GHE_REMOTE_DATA_USER_DIR"
setup_minio_test_data "$GHE_REMOTE_DATA_USER_DIR"

begin_test "ghe-backup takes full backup on first run"
(
  # This test is required to run following tests
  # It helps create "current" directory as symlink
  # setup_mssql_backup_file uses "current"
  set -e
  enable_actions
  enable_minio

  rm -rf "$GHE_REMOTE_DATA_USER_DIR"/mssql/backups/*
  rm -rf "$GHE_DATA_DIR"/current/mssql/*
  output=$(ghe-backup -v)
  echo "$output" | grep "Taking first full backup"
  echo "$output" | grep "fake ghe-export-mssql data"
)
end_test

begin_test "ghe-backup takes full backup upon expiration"
(
  set -e
  enable_actions
  enable_minio
  setup_mssql_stubs

  setup_mssql_backup_file "full_mssql" 11 "bak"

  output=$(ghe-backup -v)
  echo "$output" | grep "Taking full backup"
  ! echo "$output" | grep "Creating hard link to full_mssql@"
)
end_test

begin_test "ghe-backup takes diff backup upon expiration"
(
  set -e
  enable_actions
  enable_minio
  setup_mssql_stubs

  setup_mssql_backup_file "full_mssql" 7 "bak"

  output=$(ghe-backup -v)
  echo "$output" | grep "Taking diff backup"
  echo "$output" | grep -E "Creating hard link to full_mssql@[0-9]{8}T[0-9]{6}\.bak"
  ! echo "$output" | grep -E "Creating hard link to full_mssql@[0-9]{8}T[0-9]{6}\.log"
)
end_test

begin_test "ghe-backup takes transaction backup upon expiration"
(
  set -e
  enable_actions
  setup_mssql_stubs

  setup_mssql_backup_file "full_mssql" 3 "bak"

  output=$(ghe-backup -v)
  echo "$output" | grep "Taking transaction backup"
  echo "$output" | grep -E "Creating hard link to full_mssql@[0-9]{8}T[0-9]{6}\.bak"
  echo "$output" | grep -E "Creating hard link to full_mssql@[0-9]{8}T[0-9]{6}\.log"
)
end_test

begin_test "ghe-backup warns if database names mismatched"
(
  set -e
  enable_actions

  rm -rf "$GHE_DATA_DIR/current/mssql"
  mkdir -p "$GHE_DATA_DIR/current/mssql"

  setup_mssql_stubs
  export REMOTE_DBS="full_mssql_1 full_mssql_2 full_mssql_3"

  add_mssql_backup_file "full_mssql_1" 3 "bak"
  add_mssql_backup_file "full_mssql_4" 3 "diff"
  add_mssql_backup_file "full_mssql_5" 3 "log"

  output=$(ghe-backup -v || true)
  ! echo "$output" | grep -E "Taking .* backup"
  echo "$output" | grep "Warning: Found following 2 backup files"
)
end_test

begin_test "ghe-backup upgrades diff backup to full if diff base mismatch"
(
  set -e
  enable_actions
  setup_mssql_stubs
  export FULL_BACKUP_FILE_LSN=100
  export DIFFERENTIAL_BASE_LSN=101 # some other full backup interfered and moved up the diff base!

  setup_mssql_backup_file "full_mssql" 7 "bak"

  output=$(ghe-backup -v)
  echo "$output" | grep "Taking a full backup instead of a diff backup"
  echo "$output" | grep "Taking full backup"
)
end_test

begin_test "ghe-backup upgrades transaction backup to full if LSN chain break"
(
  set -e
  enable_actions
  setup_mssql_stubs
  export LOG_BACKUP_FILE_LAST_LSN=100
  export NEXT_LOG_BACKUP_STARTING_LSN=101 # some other log backup interfered and stole 1 LSN!

  setup_mssql_backup_file "full_mssql" 3 "bak"

  output=$(ghe-backup -v)
  echo "$output" | grep "Taking a full backup instead of a transaction backup"
  echo "$output" | grep "Taking full backup"
)
end_test

begin_test "ghe-backup takes backup of Kredz settings"
(
  set -e

  required_secrets=(
    "secrets.kredz.credz-hmac-secret"
  )

  for secret in "${required_secrets[@]}"; do
    ghe-ssh "$GHE_HOSTNAME" -- ghe-config "$secret" "foo"
  done

  ghe-backup

  required_files=(
    "kredz-credz-hmac"
  )

  for file in "${required_files[@]}"; do
    [ "$(cat "$GHE_DATA_DIR/current/$file")" = "foo" ]
  done

)
end_test

begin_test "ghe-backup takes backup of kredz-varz settings"
(
  set -e

  required_secrets=(
    "secrets.kredz.varz-hmac-secret"
  )

  for secret in "${required_secrets[@]}"; do
    ghe-ssh "$GHE_HOSTNAME" -- ghe-config "$secret" "foo"
  done

  ghe-backup

  required_files=(
    "kredz-varz-hmac"
  )

  for file in "${required_files[@]}"; do
    [ "$(cat "$GHE_DATA_DIR/current/$file")" = "foo" ]
  done

)
end_test

begin_test "ghe-backup takes backup of encrypted column encryption keying material and create encrypted column current encryption key for versions 3.7.0+"
(
  set -e

  required_secrets=(
    "secrets.github.encrypted-column-keying-material"
  )

  for secret in "${required_secrets[@]}"; do
    ghe-ssh "$GHE_HOSTNAME" -- ghe-config "$secret" "foo"
  done

  # GHES version 3.7.0
  GHE_REMOTE_VERSION=3.7.0
  export GHE_REMOTE_VERSION

  ghe-backup

  required_files=(
    "encrypted-column-encryption-keying-material"
    "encrypted-column-current-encryption-key"
  )

  for file in "${required_files[@]}"; do
    [ "$(cat "$GHE_DATA_DIR/current/$file")" = "foo" ]
  done

  # GHES version 3.8.0
  GHE_REMOTE_VERSION=3.8.0
  export GHE_REMOTE_VERSION

  ghe-backup

  required_files=(
    "encrypted-column-encryption-keying-material"
    "encrypted-column-current-encryption-key"
  )

  for file in "${required_files[@]}"; do
    [ "$(cat "$GHE_DATA_DIR/current/$file")" = "foo" ]
  done

  # GHES version 3.9.0
  GHE_REMOTE_VERSION=3.9.0
  export GHE_REMOTE_VERSION

  ghe-backup

  required_files=(
    "encrypted-column-current-encryption-key"
  )

  for file in "${required_files[@]}"; do
    [ "$(cat "$GHE_DATA_DIR/current/$file")" = "foo" ]
  done

)
end_test

begin_test "ghe-backup takes backup of encrypted column encryption keying material and encrypted column current encryption key accounting for multiple encryption keying materials for versions 3.7.0+"
(
  set -e

  required_secrets=(
    "secrets.github.encrypted-column-keying-material"
  )

  for secret in "${required_secrets[@]}"; do
    echo "ghe-config '$secret' 'foo;bar'" |
    ghe-ssh "$GHE_HOSTNAME" -- /bin/bash
  done

  # GHES version 3.7.0
  GHE_REMOTE_VERSION=3.7.0
  export GHE_REMOTE_VERSION

  ghe-backup

  required_files=(
    "encrypted-column-encryption-keying-material"
  )

  for file in "${required_files[@]}"; do
    [ "$(cat "$GHE_DATA_DIR/current/$file")" = "foo;bar" ]
  done

  required_files_current_encryption_key=(
    "encrypted-column-current-encryption-key"
  )

  for file in "${required_files_current_encryption_key[@]}"; do
    [ "$(cat "$GHE_DATA_DIR/current/$file")" = "bar" ]
  done


 # GHES version 3.8.0
  GHE_REMOTE_VERSION=3.8.0
  export GHE_REMOTE_VERSION

  ghe-backup

  required_files=(
    "encrypted-column-encryption-keying-material"
  )

  for file in "${required_files[@]}"; do
    [ "$(cat "$GHE_DATA_DIR/current/$file")" = "foo;bar" ]
  done

  required_files_current_encryption_key=(
    "encrypted-column-current-encryption-key"
  )

  for file in "${required_files_current_encryption_key[@]}"; do
    [ "$(cat "$GHE_DATA_DIR/current/$file")" = "bar" ]
  done


  # GHES version 3.9.0
  GHE_REMOTE_VERSION=3.9.0
  export GHE_REMOTE_VERSION

  ghe-backup

  required_files=(
    "encrypted-column-encryption-keying-material"
  )

  for file in "${required_files[@]}"; do
    [ "$(cat "$GHE_DATA_DIR/current/$file")" = "foo;bar" ]
  done

  required_files_current_encryption_key=(
    "encrypted-column-current-encryption-key"
  )

  for file in "${required_files_current_encryption_key[@]}"; do
    [ "$(cat "$GHE_DATA_DIR/current/$file")" = "bar" ]
  done

)
end_test

begin_test "ghe-backup does not take backups of secret scanning encrypted secrets encryption keys on versions below 3.8.0"
(
  set -e

  required_secrets=(
    "secrets.secret-scanning.encrypted-secrets-current-storage-key"
    "secrets.secret-scanning.encrypted-secrets-delimited-storage-keys"
    "secrets.secret-scanning.encrypted-secrets-current-shared-transit-key"
    "secrets.secret-scanning.encrypted-secrets-delimited-shared-transit-keys"
  )

  for secret in "${required_secrets[@]}"; do
    ghe-ssh "$GHE_HOSTNAME" -- ghe-config "$secret" "foo"
  done

  GHE_REMOTE_VERSION=3.7.0 ghe-backup -v | grep -q "secret scanning encrypted secrets" && exit 1

  required_files=(
    "secret-scanning-encrypted-secrets-current-storage-key"
    "secret-scanning-encrypted-secrets-delimited-storage-keys"
    "secret-scanning-encrypted-secrets-current-shared-transit-key"
    "secret-scanning-encrypted-secrets-delimited-shared-transit-keys"
  )

  for file in "${required_files[@]}"; do
    [ "$(cat "$GHE_DATA_DIR/current/$file")" = "" ]
  done
)
end_test

begin_test "ghe-backup takes backup of secret scanning encrypted secrets encryption keys on versions 3.8.0+"
(
  set -e

  required_secrets=(
    "secrets.secret-scanning.encrypted-secrets-current-storage-key"
    "secrets.secret-scanning.encrypted-secrets-delimited-storage-keys"
    "secrets.secret-scanning.encrypted-secrets-current-shared-transit-key"
    "secrets.secret-scanning.encrypted-secrets-delimited-shared-transit-keys"
  )

  for secret in "${required_secrets[@]}"; do
    ghe-ssh "$GHE_HOSTNAME" -- ghe-config "$secret" "foo"
  done

  GHE_REMOTE_VERSION=3.8.0 ghe-backup

  required_files=(
    "secret-scanning-encrypted-secrets-current-storage-key"
    "secret-scanning-encrypted-secrets-delimited-storage-keys"
    "secret-scanning-encrypted-secrets-current-shared-transit-key"
    "secret-scanning-encrypted-secrets-delimited-shared-transit-keys"
  )

  for file in "${required_files[@]}"; do
    [ "$(cat "$GHE_DATA_DIR/current/$file")" = "foo" ]
  done
)
end_test

begin_test "ghe-backup does not take backups of secret scanning encrypted content encryption keys on versions below 3.11.0"
(
  set -e

  required_secrets=(
    "secrets.secret-scanning.secret-scanning-user-content-delimited-encryption-root-keys"
  )

  for secret in "${required_secrets[@]}"; do
    ghe-ssh "$GHE_HOSTNAME" -- ghe-config "$secret" "foo"
  done

  GHE_REMOTE_VERSION=3.10.0 ghe-backup -v | grep -q "secret scanning encrypted content" && exit 1

  required_files=(
    "secret-scanning-user-content-delimited-encryption-root-keys"
  )

  for file in "${required_files[@]}"; do
    [ "$(cat "$GHE_DATA_DIR/current/$file")" = "" ]
  done
)
end_test

begin_test "ghe-backup takes backup of secret scanning encrypted content encryption keys on versions 3.11.0+"
(
  set -e

  required_secrets=(
    "secret-scanning.secret-scanning-user-content-delimited-encryption-root-keys"
  )

  for secret in "${required_secrets[@]}"; do
    ghe-ssh "$GHE_HOSTNAME" -- ghe-config "$secret" "foo"
  done

  GHE_REMOTE_VERSION=3.11.0 ghe-backup

  required_files=(
    "secret-scanning-user-content-delimited-encryption-root-keys"
  )

  for file in "${required_files[@]}"; do
    [ "$(cat "$GHE_DATA_DIR/current/$file")" = "foo" ]
  done
)
end_test

begin_test "ghe-backup takes backup of Actions settings"
(
  set -e
  enable_actions

  # Prevent previous steps from leaking MSSQL backup files
  rm -rf "$GHE_DATA_DIR/current/mssql"
  mkdir -p "$GHE_DATA_DIR/current/mssql"

  required_secrets=(
    "secrets.actions.ConfigurationDatabaseSqlLogin"
    "secrets.actions.ConfigurationDatabaseSqlPassword"
    "secrets.actions.UrlSigningHmacKeyPrimary"
    "secrets.actions.UrlSigningHmacKeySecondary"
    "secrets.actions.OAuthS2SSigningCert"
    "secrets.actions.OAuthS2SSigningKey"
    "secrets.actions.OAuthS2SSigningCertThumbprint"
    "secrets.actions.PrimaryEncryptionCertificateThumbprint"
    "secrets.actions.S2SEncryptionCertificate"
    "secrets.actions.SecondaryEncryptionCertificateThumbprint"
    "secrets.actions.SpsValidationCertThumbprint"

    "secrets.launch.actions-secrets-private-key"
    "secrets.launch.deployer-hmac-secret"
    "secrets.launch.client-id"
    "secrets.launch.client-secret"
    "secrets.launch.receiver-webhook-secret"
    "secrets.launch.app-private-key"
    "secrets.launch.app-public-key"
    "secrets.launch.app-id"
    "secrets.launch.app-relay-id"
    "secrets.launch.action-runner-secret"
    "secrets.launch.token-oauth-key"
    "secrets.launch.token-oauth-cert"
    "secrets.launch.azp-app-cert"
    "secrets.launch.azp-app-private-key"

  )

  # these 5 were removed in later versions, so we extract them as best effort
  # - secrets.actions.FrameworkAccessTokenKeySecret
  # - secrets.actions.AADCertThumbprint
  # - secrets.actions.DelegatedAuthCertThumbprint
  # - secrets.actions.RuntimeServicePrincipalCertificate
  # - secrets.actions.ServicePrincipalCertificate
  # add one, to make sure it still gets copied
  required_secrets+=("secrets.actions.FrameworkAccessTokenKeySecret")

  for secret in "${required_secrets[@]}"; do
    ghe-ssh "$GHE_HOSTNAME" -- ghe-config "$secret" "foo"
  done

  ghe-backup

  required_files=(
    "actions-config-db-login"
    "actions-config-db-password"
    "actions-url-signing-hmac-key-primary"
    "actions-url-signing-hmac-key-secondary"
    "actions-oauth-s2s-signing-cert"
    "actions-oauth-s2s-signing-key"
    "actions-oauth-s2s-signing-cert-thumbprint"
    "actions-primary-encryption-cert-thumbprint"
    "actions-s2s-encryption-cert"
    "actions-secondary-encryption-cert-thumbprint"
    "actions-sps-validation-cert-thumbprint"

    "actions-launch-secrets-private-key"
    "actions-launch-deployer-hmac"
    "actions-launch-client-id"
    "actions-launch-client-secret"
    "actions-launch-receiver-webhook-secret"
    "actions-launch-app-private-key"
    "actions-launch-app-public-key"
    "actions-launch-app-id"
    "actions-launch-app-relay-id"
    "actions-launch-action-runner-secret"
    "actions-launch-azp-app-cert"
    "actions-launch-app-app-private-key"

  )

  # Add the one optional file we included tests for
  required_files+=("actions-framework-access-token")

  for file in "${required_files[@]}"; do
    [ "$(cat "$GHE_DATA_DIR/current/$file")" = "foo" ]
  done

  other_best_effort_files=(
    "actions-aad-cert-thumbprint"
    "actions-delegated-auth-cert-thumbprint"
    "actions-runtime-service-principal-cert"
    "actions-service-principal-cert"
  )

  for file in "${other_best_effort_files[@]}"; do
    [ ! -f "$GHE_DATA_DIR/current/$file" ]
  done

)
end_test

begin_test "ghe-backup takes backup of Actions files"
(
  set -e
  enable_actions

  output=$(ghe-backup -v)
  echo $output | grep "Transferring Actions files from"

  diff -ru "$GHE_REMOTE_DATA_USER_DIR/actions" "$GHE_DATA_DIR/current/actions"
)
end_test

# acceptance criteria is less then 2 seconds for 100,000 lines
begin_test "ghe-backup fix_paths_for_ghe_version performance tests - gists"
(
    set -e
    timeout 2 bash -c "
        source '$TESTS_DIR/../share/github-backup-utils/ghe-backup-config'
        GHE_REMOTE_VERSION=2.16.23
        seq 1 100000 | sed -e 's/$/ gist/' | fix_paths_for_ghe_version | grep -c gist
    "
)
end_test

# acceptance criteria is less then 2 seconds for 100,000 lines
begin_test "ghe-backup fix_paths_for_ghe_version performance tests - wikis"
(
    set -e
    timeout 2 bash -c "
        source '$TESTS_DIR/../share/github-backup-utils/ghe-backup-config'
        GHE_REMOTE_VERSION=2.16.23
        seq 1 100000 | sed -e 's/$/ wiki/' | fix_paths_for_ghe_version | grep -c '^\.$'
    "
)
end_test

# check fix_paths_for_ghe_version version thresholds
begin_test "ghe-backup fix_paths_for_ghe_version newer/older"
(
    set -e

    # modern versions keep foo/gist as foo/gist
    for ver in 2.16.23 v2.16.23 v2.17.14 v2.18.8 v2.19.3 v2.20.0 v3.0.0; do
        echo "## $ver, not gist"
        [ "$(bash -c "
            source '$TESTS_DIR/../share/github-backup-utils/ghe-backup-config'
            GHE_REMOTE_VERSION=$ver
            echo foo/bar | fix_paths_for_ghe_version
        ")" == "foo" ]

        echo "## $ver, gist"
        [ "$(bash -c "
            source '$TESTS_DIR/../share/github-backup-utils/ghe-backup-config'
            GHE_REMOTE_VERSION=$ver
            echo foo/gist | fix_paths_for_ghe_version
        ")" == "foo/gist" ]
    done

    # old versions change foo/gist to foo
    for ver in 1.0.0 bob a.b.c "" 1.2.16 2.0.0 v2.0.0 v2.15.123 v2.16.22 v2.17.13 v2.18.7 v2.19.2; do
        echo "## $ver, not gist"
        [ "$(bash -c "
            source '$TESTS_DIR/../share/github-backup-utils/ghe-backup-config'
            GHE_REMOTE_VERSION=$ver
            echo foo/bar | fix_paths_for_ghe_version
        ")" == "foo" ]

        echo "## $ver, gist"
        [ "$(bash -c "
            source '$TESTS_DIR/../share/github-backup-utils/ghe-backup-config'
            GHE_REMOTE_VERSION=$ver
            echo foo/gist | fix_paths_for_ghe_version
        ")" == "foo" ]
    done
)
end_test

# Check that information on system where backup-utils is installed is collected
begin_test "ghe-backup collects information on system where backup-utils is installed"
(
  set -e

  output=$(ghe-backup)
  echo "$output" | grep "Running on: $(cat /etc/issue.net)"
  echo "$output" | grep "CPUs: $(nproc)"
  echo "$output" | grep "Memory total/used/free+share/buff/cache:"

)
end_test

# Check that backup-utils manages track-progress folder correctly
begin_test "ghe-backup manages progress tracking files properly"
(
  set -e

  if [ -e /tmp/backup-utils-progress ]; then
    rm -rf /tmp/backup-utils-progress/*
  fi

  output=$(ghe-backup)
  echo "$output" | grep -v "mkdir: cannot create directory /tmp/backup-utils-progress: File exists"  

)
end_test