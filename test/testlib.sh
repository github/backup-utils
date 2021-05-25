#!/usr/bin/env bash
# Usage: . testlib.sh
# Simple shell command language test library.
#
# Tests must follow the basic form:
#
#   begin_test "the thing"
#   (
#      set -e
#      echo "hello"
#      false
#   )
#   end_test
#
# When a test fails its stdout and stderr are shown.
#
# Note that tests must `set -e' within the subshell block or failed assertions
# will not cause the test to fail and the result may be misreported.
#
# Copyright (c) 2011-14 by Ryan Tomayko <http://tomayko.com>
# License: MIT
set -e

# Setting basic paths
ROOTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
PATH="$ROOTDIR/test/bin:$ROOTDIR/bin:$ROOTDIR/share/github-backup-utils:$PATH"

# create a temporary work space
TMPDIR="$ROOTDIR/test/tmp"
TRASHDIR="$TMPDIR/$(basename "$0")-$$"

# Set GIT_{AUTHOR,COMMITTER}_{NAME,EMAIL}
# This removes the assumption that a git config that specifies these is present.
export GIT_AUTHOR_NAME=make GIT_AUTHOR_EMAIL=make GIT_COMMITTER_NAME=make GIT_COMMITTER_EMAIL=make

# Point commands at the test backup.config file
GHE_BACKUP_CONFIG="$ROOTDIR/test/backup.config"
GHE_DATA_DIR="$TRASHDIR/data"
GHE_REMOTE_DATA_DIR="$TRASHDIR/remote/data"
GHE_REMOTE_ROOT_DIR="$TRASHDIR/remote"
export GHE_BACKUP_CONFIG GHE_DATA_DIR GHE_REMOTE_DATA_DIR GHE_REMOTE_ROOT_DIR

# The default remote appliance version. This may be set in the environment prior
# to invoking tests to emulate a different remote vm version.
: ${GHE_TEST_REMOTE_VERSION:=3.1.0.rc1}
export GHE_TEST_REMOTE_VERSION

# Source in the backup config and set GHE_REMOTE_XXX variables based on the
# remote version established above or in the environment.
# shellcheck source=share/github-backup-utils/ghe-backup-config
. "$( dirname "${BASH_SOURCE[0]}" )/../share/github-backup-utils/ghe-backup-config"
ghe_parse_remote_version "$GHE_TEST_REMOTE_VERSION"
ghe_remote_version_config "$GHE_TEST_REMOTE_VERSION"

# Unset special variables meant to be inherited by individual ghe-backup or
# ghe-restore process groups
unset GHE_SNAPSHOT_TIMESTAMP

# keep track of num tests and failures
tests=0
failures=0

# this runs at process exit
atexit () {
  res=$?

  [ -z "$KEEPTRASH" ] && rm -rf "$TRASHDIR"
  if [ $failures -gt 0 ]; then
    exit 1
  elif [ $res -ne 0 ]; then
    exit $res
  else
    exit 0
  fi
}

# create the trash dir and data dirs
trap "atexit" EXIT
mkdir -p "$TRASHDIR" "$GHE_DATA_DIR" "$GHE_REMOTE_DATA_DIR" "$GHE_REMOTE_DATA_USER_DIR"
cd "$TRASHDIR"

# Put remote metadata file in place for ghe-host-check which runs with pretty
# much everything. You can pass a version number in the first argument to test
# with different remote versions.
setup_remote_metadata () {
  mkdir -p "$GHE_REMOTE_DATA_DIR" "$GHE_REMOTE_DATA_USER_DIR"
  mkdir -p "$GHE_REMOTE_DATA_USER_DIR/common"
  mkdir -p "$GHE_REMOTE_ROOT_DIR/etc/github"
}
setup_remote_metadata

setup_remote_license () {
  mkdir -p "$(dirname "$GHE_REMOTE_LICENSE_FILE")"
  echo "fake license data" > "$GHE_REMOTE_LICENSE_FILE"
}
setup_remote_license

setup_remote_cluster () {
  mkdir -p "$GHE_REMOTE_ROOT_DIR/etc/github"
  touch "$GHE_REMOTE_ROOT_DIR/etc/github/cluster"
  echo "fake cluster config" > "$GHE_REMOTE_DATA_USER_DIR/common/cluster.conf"
}

# Put the necessary files in place to mimic a configured, or not, instance into
# maintenance mode.
#
# Pass anything as the first argument to "configure" the instance
setup_maintenance_mode () {
  configured=$1
  if [ -n "$configured" ]; then
    # create file used to determine if instance has been configured.
    touch "$GHE_REMOTE_ROOT_DIR/etc/github/configured"
  fi

  # create file used to determine if instance is in maintenance mode.
  mkdir -p "$GHE_REMOTE_DATA_DIR/github/current/public/system"
  touch "$GHE_REMOTE_DATA_DIR/github/current/public/system/maintenance.html"

  # Create fake remote repositories dir
  mkdir -p "$GHE_REMOTE_DATA_USER_DIR/repositories"
}

# Mark the beginning of a test. A subshell should immediately follow this
# statement.
begin_test () {
  test_status=$?
  [ -n "$test_description" ] && end_test $test_status
  unset test_status

  tests=$(( tests + 1 ))
  test_description="$1"

  exec 3>&1 4>&2
  out="$TRASHDIR/out"
  exec 1>"$out" 2>&1

  # allow the subshell to exit non-zero without exiting this process
  set -x +e
  before_time=$(date '+%s')
}

report_failure () {
  msg=$1
  desc=$2
  failures=$(( failures + 1 ))
  printf "test: %-73s $msg\\n" "$desc ..."
  (
    sed 's/^/    /' <"$TRASHDIR/out" |
    grep -a -v -e '^\+ end_test' -e '^+ set +x' - "$TRASHDIR/out" |
    sed 's/[+] test_status=/test failed. last command exited with /' |
    sed 's/^/    /'
  ) 1>&2
}

# Mark the end of a test.
end_test () {
  test_status="${1:-$?}"
  after_time=$(date '+%s')
  elapsed_time=$((after_time - before_time))
  set +x -e
  exec 1>&3 2>&4

  if [ "$test_status" -eq 0 ]; then
    printf "test: %-65s OK (${elapsed_time}s)\\n" "$test_description ..."
  elif [ "$test_status" -eq 254 ]; then
    printf "test: %-65s SKIPPED\\n" "$test_description ..."
  else
    report_failure "FAILED (${elapsed_time}s)" "$test_description ..."
  fi

  unset test_description
}

skip_test() {
  exit 254
}

# Create dummy data used for testing
# This same method can be used to generate the data used for testing backups
# and restores by passing in the appropriate location, for example:
#
# Testing backups: setup_test_data $GHE_REMOTE_DATA_USER_DIR
# Testing restores: setup_test_data "$GHE_DATA_DIR/1"
#
setup_test_data () {
  local loc=$1

  # Create some fake pages data in the remote data directory
  mkdir -p "$loc/pages"
  cd "$loc/pages"
  export pages1="4/c8/1e/72/2/legacy"
  export pages2="4/c1/6a/53/31/dd3a9a0faa88c714ef2dd638b67587f92f109f96"
  mkdir -p "$pages1" "$pages2"
  touch "$pages1/index.html" "$pages2/index.html"

  # Create a fake manage password file§
  mkdir -p "$GHE_REMOTE_DATA_USER_DIR/common"
  git config -f "$GHE_REMOTE_DATA_USER_DIR/common/secrets.conf" secrets.manage "fake password hash data"

  # Create a fake password pepper file
  mkdir -p "$GHE_REMOTE_DATA_USER_DIR/common"
  git config -f "$GHE_REMOTE_DATA_USER_DIR/common/secrets.conf" secrets.github.user-password-secrets "fake password pepper data"

  # Create some fake hooks in the remote data directory
  mkdir -p "$loc/git-hooks/environments/tarballs"
  mkdir -p "$loc/git-hooks/repos"

  cd "$loc/git-hooks/environments"
  mkdir -p 123/abcdef 456/fed314
  touch 123/abcdef/script.sh 456/fed314/foo.sh

  cd "$loc/git-hooks/environments/tarballs"
  mkdir -p 987/qwert 765/frodo
  tar -C "$loc/git-hooks/environments/123/abcdef/" -zcf "$loc/git-hooks/environments/tarballs/987/qwert/script.tar.gz" ./
  tar -C "$loc/git-hooks/environments/456/fed314/" -zcf "$loc/git-hooks/environments/tarballs/765/frodo/foo.tar.gz" ./

  cd "$loc/git-hooks/repos"
  mkdir -p 321 654
  touch 321/script.sh 654/foo.sh

  mkdir -p "$loc/storage/"
  cd "$loc/storage/"
  object1="2/20/e1"
  object2="8/80/76"
  object3="e/ed/1a"
  mkdir -p "$object1" "$object2" "$object3"
  touch "$object1/20e1b33c19d81f490716c470c0583772b05a153831d55441cc5e7711eda5a241"
  touch "$object2/80766a2b18a96b9a5927ebdd980dc8d0820bea7ff0897b1b119af4bf20974d32"
  touch "$object3/ed1aa60f0706cefde8ba2b3be662d3a0e0e1fbc94a52a3201944684cc0c5f244"

  common=
  if [ "$loc" = "$GHE_REMOTE_DATA_USER_DIR" ]; then
    common="common"
  fi
  # Create a fake UUID
  echo "fake-uuid" > "$loc/$common/uuid"

  # Create fake audit log migration sentinel file
  touch "$loc/$common/es-scan-complete"

  # Create some fake elasticsearch data in the remote data directory
  mkdir -p "$loc/elasticsearch/gh-enterprise-es/node/0"
  cd "$loc/elasticsearch"
  touch gh-enterprise-es/node/0/stuff1
  touch gh-enterprise-es/node/0/stuff2

  # Create fake audit-logs
  this_yr=$(date +"%Y")
  this_mth=$(date +"%-m")
  last_mth=$(( $this_mth - 1 ))
  last_yr=$this_yr
  if [ "$last_mth" = 0 ]; then
    last_mth=12
    last_yr=$(( $this_yr - 1 ))
  fi

  mkdir -p "$loc/audit-log/"
  cd "$loc/audit-log/"
  echo "fake audit log last yr last mth" | gzip > audit_log-1-$last_yr-$last_mth-1.gz
  echo "1" > audit_log-1-$last_yr-$last_mth-1.size
  echo "fake audit log this yr this mth" | gzip > audit_log-1-$this_yr-$this_mth-1.gz
  echo "1" > audit_log-1-$this_yr-$this_mth-1.size

  # Create some test repositories in the remote repositories dir
  mkdir -p "$loc/repositories/info"
  mkdir -p "$TRASHDIR/hooks"

  cd "$loc/repositories"
  echo "fake nw-layout" > info/nw-layout
  echo "fake svn-v4-upgrade" > info/svn-v4-upgraded

  repo1="0/nw/01/aa/3f/1234/1234.git"
  repo2="0/nw/01/aa/3f/1234/1235.git"
  repo3="1/nw/23/bb/4c/2345/broken.git"
  mkdir -p "$repo1" "$repo2" "$repo3"

  wiki1="0/nw/01/aa/3f/1234/1234.wiki.git"
  mkdir -p "$wiki1"

  gist1="0/01/aa/3f/gist/93069ad4c391b6203f183e147d52a97a.git"
  gist2="1/23/bb/4c/gist/1234.git"
  mkdir -p "$gist1" "$gist2"

  # Initialize test repositories with a fake commit
  while IFS= read -r -d '' repo; do
    git init -q --bare "$repo"
    git --git-dir="$repo" --work-tree=. commit -q --allow-empty -m 'test commit'
    rm -rf "$repo/hooks"
    ln -s "$TRASHDIR/hooks" "$repo/hooks"
  done <   <(find . -type d -name '*.git' -prune -print0)

  # Add some fake svn data to repo2
  echo "fake svn history data" > "$repo2/svn.history.msgpack"
  mkdir "$repo2/svn_data"
  echo "fake property history data" > "$repo2/svn_data/property_history.msgpack"

  # Break a repo to test fsck
  rm -f $repo3/objects/4b/825dc642cb6eb9a060e54bf8d69288fbee4904

  if [ "$loc" != "$GHE_REMOTE_DATA_USER_DIR" ]; then
    # create a fake backups for each datastore
    if ! $SKIP_MYSQL; then
      echo "fake ghe-export-mysql data" | gzip > "$loc/mysql.sql.gz"
    fi
    echo "fake ghe-export-redis data" > "$loc/redis.rdb"
    echo "fake ghe-export-authorized-keys data" > "$loc/authorized-keys.json"
    echo "fake ghe-export-ssh-host-keys data" > "$TRASHDIR/ssh-host-keys"
    tar -C $TRASHDIR -cf "$loc/ssh-host-keys.tar" ssh-host-keys
    echo "fake ghe-export-settings data" > "$loc/settings.json"
    echo "fake ghe-export-ssl-ca-certificates data" > "$loc/ssl-ca-certificates.tar"
    echo "fake license data" > "$loc/enterprise.ghl"
    echo "fake password hash data" > "$loc/manage-password"
    echo "fake password pepper data" > "$loc/password-pepper"
    echo "rsync" > "$loc/strategy"
    echo "$GHE_REMOTE_VERSION" >  "$loc/version"
  fi

  setup_minio_test_data "$GHE_DATA_DIR"
}

setup_actions_test_data() {
  local loc=$1

  if [ "$loc" != "$GHE_REMOTE_DATA_USER_DIR" ]; then
    mkdir -p "$loc/mssql"
    echo "fake ghe-export-mssql full data" > "$loc/mssql/mssql.bak"
    echo "fake ghe-export-mssql diff data" > "$loc/mssql/mssql.diff"
    echo "fake ghe-export-mssql tran data" > "$loc/mssql/mssql.log"
  else
    mkdir -p "$loc/mssql/backups"
    echo "fake mssql full data" > "$loc/mssql/backups/mssql.bak"
    echo "fake mssql diff data" > "$loc/mssql/backups/mssql.diff"
    echo "fake mssql tran data" > "$loc/mssql/backups/mssql.log"
  fi

  # Setup fake Actions data
  mkdir -p "$loc/actions/certificates"
  mkdir -p "$loc/actions/states"
  echo "fake actions certificate" > "$loc/actions/certificates/cert.cer"
  echo "fake actions state file" > "$loc/actions/states/actions_state"
}

cleanup_actions_test_data() {
  local loc=$1

  rm -rf "$loc/mssql"
  rm -rf "$loc/actions"
}

setup_minio_test_data() {
  local loc=$1

  mkdir -p "$loc/minio/"
  cd "$loc/minio/"
  bucket="packages"

  mkdir -p "$bucket"
  echo "an example blob" "$bucket/91dfa09f-1801-4e00-95ee-6b763d7da3e2"
}

cleanup_minio_test_data() {
  local loc=$1

  rm -rf "$loc/minio"
}

# A unified method to check everything backed up or restored during testing.
# Everything tested here should pass regardless of whether we're testing a backup
# or a restore.
verify_common_data() {
  # verify all repository data was transferred
  diff -ru "$GHE_REMOTE_DATA_USER_DIR/repositories" "$GHE_DATA_DIR/current/repositories"

  # verify all pages data was transferred
  diff -ru "$GHE_REMOTE_DATA_USER_DIR/pages" "$GHE_DATA_DIR/current/pages"

  # verify all git hooks tarballs were transferred
  diff -ru "$GHE_REMOTE_DATA_USER_DIR/git-hooks/environments/tarballs" "$GHE_DATA_DIR/current/git-hooks/environments/tarballs"

  # verify the extracted environments were not transferred
  ! diff -ru "$GHE_REMOTE_DATA_USER_DIR/git-hooks/environments" "$GHE_DATA_DIR/current/git-hooks/environments"

  # verify the extracted repositories were transferred
  diff -ru "$GHE_REMOTE_DATA_USER_DIR/git-hooks/repos" "$GHE_DATA_DIR/current/git-hooks/repos"

  if is_actions_enabled; then
    # verify mssql backups were transferred
    diff -ru "$GHE_REMOTE_DATA_USER_DIR/mssql/backups" "$GHE_DATA_DIR/current/mssql"
  fi

  if is_minio_enabled; then
    # verify minio object storge backups were transferred
    diff -ru "$GHE_REMOTE_DATA_USER_DIR/minio" "$GHE_DATA_DIR/minio"
  fi

  # tests that differ for cluster and single node backups and restores
  if [ "$(cat $GHE_DATA_DIR/current/strategy)" = "rsync" ]; then
    # verify the UUID was transferred
    diff -ru "$GHE_REMOTE_DATA_USER_DIR/common/uuid" "$GHE_DATA_DIR/current/uuid"

    # verify the audit log migration sentinel file has been created on 2.9 and above
    if [ "$GHE_VERSION_MAJOR" -eq 2 ] && [ "$GHE_VERSION_MINOR" -ge 9 ]; then
      diff -ru "$GHE_REMOTE_DATA_USER_DIR/common/es-scan-complete" "$GHE_DATA_DIR/current/es-scan-complete"
    fi
  fi
}

# A unified method to check everything backed up when performing a full backup
# during testing.
verify_all_backedup_data() {
  set -e
  # check that current symlink was created
  [ -d "$GHE_DATA_DIR/current" ]

  # check that the version file was written
  [ -f "$GHE_DATA_DIR/current/version" ]
  [ "$(cat "$GHE_DATA_DIR/current/version")" = "v$GHE_TEST_REMOTE_VERSION" ]

  # check that the strategy file was written
  [ -f "$GHE_DATA_DIR/current/strategy" ]

  # check that settings were backed up
  [ "$(cat "$GHE_DATA_DIR/current/settings.json")" = "fake ghe-export-settings data" ]

  # check that mysql data was backed up
  if ! $SKIP_MYSQL; then
    [ "$(gzip -dc < "$GHE_DATA_DIR/current/mysql.sql.gz")" = "fake ghe-export-mysql data" ]
  fi

  # check that redis data was backed up
  [ "$(cat "$GHE_DATA_DIR/current/redis.rdb")" = "fake redis data" ]

  # check that ssh public keys were backed up
  [ "$(cat "$GHE_DATA_DIR/current/authorized-keys.json")" = "fake ghe-export-authorized-keys data" ]

  # check that ssh host key was backed up
  [ "$(tar xfO "$GHE_DATA_DIR/current/ssh-host-keys.tar" ssh-host-keys)" = "fake ghe-export-ssh-host-keys data" ]

  # verify manage-password file was backed up
  [ "$(cat "$GHE_DATA_DIR/current/manage-password")" = "fake password hash data" ]

  # verify password pepper file was backed up
  [ "$(cat "$GHE_DATA_DIR/current/password-pepper")" = "fake password pepper data" ]

  # check that ca certificates were backed up
  [ "$(cat "$GHE_DATA_DIR/current/ssl-ca-certificates.tar")" = "fake ghe-export-ssl-ca-certificates data" ]

  if is_actions_enabled; then
    # check that mssql databases were backed up
    [ "$(cat "$GHE_DATA_DIR/current/mssql/mssql.bak")" = "fake mssql full data" ]
    [ "$(cat "$GHE_DATA_DIR/current/mssql/mssql.diff")" = "fake mssql diff data" ]
    [ "$(cat "$GHE_DATA_DIR/current/mssql/mssql.log")" = "fake mssql tran data" ]
  fi

  # verify that ghe-backup wrote its version information to the host
  [ -f "$GHE_REMOTE_DATA_USER_DIR/common/backup-utils-version" ]

  # tests that differ for cluster and single node backups
  if [ -f "$GHE_REMOTE_DATA_USER_DIR/common/cluster.conf" ]; then
    grep -q "fake cluster config" "$GHE_DATA_DIR/current/cluster.conf"
    # verify strategy used
    [ "$(cat "$GHE_DATA_DIR/current/strategy")" = "cluster" ]
  else
    # verify strategy used
    [ "$(cat "$GHE_DATA_DIR/current/strategy")" = "rsync" ]

    # verify all ES data was transferred from live directory - not for cluster backups
    diff -ru "$GHE_REMOTE_DATA_USER_DIR/elasticsearch" "$GHE_DATA_DIR/current/elasticsearch"
  fi

  # verify common data
  verify_common_data
}

# A unified method to check everything restored when performing a full restore
# during testing.
verify_all_restored_data() {
  set -e

  # verify all import scripts were run
  if ! $SKIP_MYSQL; then
    grep -q "fake ghe-export-mysql data" "$TRASHDIR/restore-out"
  fi
  grep -q "fake ghe-export-redis data" "$TRASHDIR/restore-out"
  grep -q "fake ghe-export-authorized-keys data" "$TRASHDIR/restore-out"

  # tests that differ for cluster and single node backups
  if [ "$(cat $GHE_DATA_DIR/current/strategy)" = "rsync" ]; then
    grep -q "fake ghe-export-ssh-host-keys data" "$TRASHDIR/restore-out"
    # verify all ES data was transferred from live directory to the temporary restore directory
    diff -ru --exclude="*.gz" "$GHE_DATA_DIR/current/elasticsearch" "$GHE_REMOTE_DATA_USER_DIR/elasticsearch-restore"
  else
    grep -q "fake audit log last yr last mth" "$TRASHDIR/restore-out"
    grep -q "fake audit log this yr this mth" "$TRASHDIR/restore-out"
  fi

  # verify settings import was *not* run due to instance already being
  # configured.
  ! grep -q "fake ghe-export-settings data" "$TRASHDIR/restore-out"

  # verify management console password was *not* restored
  ! grep -q "fake password hash data" "$GHE_REMOTE_DATA_USER_DIR/common/secrets.conf"

  # verify common data
  verify_common_data
}

subtract_minute() {
  # Expect date string in the format of yyyymmddTHHMMSS
  # Here parse date differently depending on GNU Linux vs BSD MacOS
  if date -v -1d > /dev/null 2>&1; then
    date -v -"$2"M -ujf'%Y%m%dT%H%M%S' "$1" +%Y%m%dT%H%M%S
  else
    dt=$1
    date '+%Y%m%dT%H%M%S' -d "${dt:0:8} ${dt:9:2}:${dt:11:2}:${dt:13:2} $2 minutes ago"
  fi
}

setup_mssql_backup_file() {
  rm -rf "$GHE_DATA_DIR/current/mssql"
  mkdir -p "$GHE_DATA_DIR/current/mssql"

  add_mssql_backup_file "$@"

  # Simulate ghe-export-mssql behavior
  if [ "$3" = "bak" ] || [ "$3" = "diff" ]; then
    touch "$GHE_DATA_DIR/current/mssql/$1@$fake_last_utc.log"
  fi
}

add_mssql_backup_file() {
  # $1 name: <name>@...
  # $2 minutes ago
  # $3 extension: bak, diff, log
  current_utc=$(date -u +%Y%m%dT%H%M%S)
  fake_last_utc=$(subtract_minute "$current_utc" "$2")

  touch "$GHE_DATA_DIR/current/mssql/$1@$fake_last_utc.$3"
}

enable_actions() {
  ghe-ssh "$GHE_HOSTNAME" -- 'ghe-config app.actions.enabled true'
}

is_actions_enabled() {
  ghe-ssh "$GHE_HOSTNAME" -- 'ghe-config --true app.actions.enabled'
}

enable_minio() {
  ghe-ssh "$GHE_HOSTNAME" -- 'ghe-config app.minio.enabled true'
}

is_minio_enabled() {
  ghe-ssh "$GHE_HOSTNAME" -- 'ghe-config --true app.minio.enabled'
}

setup_moreutils_parallel() {
  # CI servers may have moreutils parallel and GNU parallel installed.
  # We need moreutils parallel
  local x
  for x in \
      /usr/bin/parallel.moreutils \
      /usr/bin/parallel_moreutils \
      /usr/bin/moreutils.parallel \
      /usr/bin/moreutils_parallel \
      ; do
        if [ -x "${x}" ]; then
            ln -sf "${x}" "$ROOTDIR/test/bin/parallel"
            break
        fi
  done
}

cleanup_moreutils_parallel() {
  if [ -h "$ROOTDIR/test/bin/parallel" ]; then
    unlink "$ROOTDIR/test/bin/parallel"
  fi
}
