#!/usr/bin/env bash
# Usage: . testlib.sh
# Simple shell command language test library.
#
# Tests must follow the basic form:
#
#   begin_test "the thing"
#   (
#        set -e
#        echo "hello"
#        false
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
: ${GHE_TEST_REMOTE_VERSION:=2.11.0}
export GHE_TEST_REMOTE_VERSION

# Source in the backup config and set GHE_REMOTE_XXX variables based on the
# remote version established above or in the environment.
. $( dirname "${BASH_SOURCE[0]}" )/../share/github-backup-utils/ghe-backup-config
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

    # cleanup injected test key
    shared_path=$(dirname $(which ghe-detect-leaked-ssh-keys))
    sed -i.bak '/98:d8:99:d3:be:c0:55:05:db:b0:53:2f:1f:ad:b3:60/d' "$shared_path/ghe-ssh-leaked-host-keys-list.txt"
    rm -f "$shared_path/ghe-ssh-leaked-host-keys-list.txt.bak"

    [ -z "$KEEPTRASH" ] && rm -rf "$TRASHDIR"
    if [ $failures -gt 0 ]
    then exit 1
    elif [ $res -ne 0 ]
    then exit $res
    else exit 0
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
}

report_failure () {
  msg=$1
  desc=$2
  failures=$(( failures + 1 ))
  printf "test: %-73s $msg\\n" "$desc ..."
  (
      sed 's/^/    /' <"$TRASHDIR/out" |
      grep -a -v -e '^\+ end_test' -e '^+ set +x' <"$TRASHDIR/out" |
          sed 's/[+] test_status=/test failed. last command exited with /' |
          sed 's/^/    /'
  ) 1>&2
}

# Mark the end of a test.
end_test () {
    test_status="${1:-$?}"
    set +x -e
    exec 1>&3 2>&4

    if [ "$test_status" -eq 0 ]; then
      printf "test: %-60s OK\\n" "$test_description ..."
    elif [ "$test_status" -eq 254 ]; then
      printf "test: %-60s SKIPPED\\n" "$test_description ..."
    else
      report_failure "FAILED" "$test_description ..."
    fi

    unset test_description
}

skip_test() {
  exit 254
}

# Create dummy data used for testing
# This same method can be used to generate the data used for testing backups
# and restores by passing in the appropriate location.
#
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

  # Create some test repositories in the remote repositories dir
  mkdir "$loc/repositories"
  mkdir -p "$TRASHDIR/hooks"
  cd "$loc/repositories"
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
    echo "fake ghe-export-mysql data" | gzip > "$loc/mysql.sql.gz"
    echo "fake ghe-export-redis data" > "$loc/redis.rdb"
    echo "fake ghe-export-authorized-keys data" > "$loc/authorized-keys.json"
    echo "fake ghe-export-ssh-host-keys data" > "$loc/ssh-host-keys.tar"
    echo "fake ghe-export-settings data" > "$loc/settings.json"
    echo "fake ghe-export-ssl-ca-certificates data" > "$loc/ssl-ca-certificates.tar"
    echo "fake license data" > "$loc/enterprise.ghl"
    echo "fake password hash data" > "$loc/manage-password"
    echo "rsync" > "$loc/strategy"
    echo "$GHE_REMOTE_VERSION" >  "$loc/version"
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
  [ "$(cat "$GHE_DATA_DIR/current/strategy")" = "rsync" ]

  # check that settings were backed up
  [ "$(cat "$GHE_DATA_DIR/current/settings.json")" = "fake ghe-export-settings data" ]

  # check that license was backed up
  [ "$(cat "$GHE_DATA_DIR/current/enterprise.ghl")" = "fake license data" ]

  # check that repositories directory was created
  [ -d "$GHE_DATA_DIR/current/repositories" ]

  # check that pages data was backed up
  [ -f "$GHE_DATA_DIR/current/pages/4/c8/1e/72/2/legacy/index.html" ]
  [ -f "$GHE_DATA_DIR/current/pages/4/c1/6a/53/31/dd3a9a0faa88c714ef2dd638b67587f92f109f96/index.html" ]

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
  [ "$(cat "$GHE_DATA_DIR/current/manage-password")" = "fake password hash data" ]

  # verify all git hooks tarballs were transferred
  diff -ru "$GHE_REMOTE_DATA_USER_DIR/git-hooks/environments/tarballs" "$GHE_DATA_DIR/current/git-hooks/environments/tarballs"

  # verify the extracted environments were not transferred
  ! diff -ru "$GHE_REMOTE_DATA_USER_DIR/git-hooks/environments" "$GHE_DATA_DIR/current/git-hooks/environments"

  # verify the extracted repositories were transferred
  diff -ru "$GHE_REMOTE_DATA_USER_DIR/git-hooks/repos" "$GHE_DATA_DIR/current/git-hooks/repos"

  # verify the UUID was transferred
  diff -ru "$GHE_REMOTE_DATA_USER_DIR/common/uuid" "$GHE_DATA_DIR/current/uuid"

  # check that ca certificates were backed up
  [ "$(cat "$GHE_DATA_DIR/current/ssl-ca-certificates.tar")" = "fake ghe-export-ssl-ca-certificates data" ]

  # verify the audit log migration sentinel file has been created
  [ -f "$GHE_DATA_DIR/current/es-scan-complete" ]

  # verify that ghe-backup wrote its version information to the host
  [ -f "$GHE_REMOTE_DATA_USER_DIR/common/backup-utils-version" ]
}

# A unified method to check everything restored when performing a full restore
# during testing.
verify_all_restored_data() {
  set -e

  # verify all import scripts were run
  grep -q "4/c8/1e/72/2/legacy/index.html" "$TRASHDIR/restore-out"
  grep -q "4/c1/6a/53/31/dd3a9a0faa88c714ef2dd638b67587f92f109f96/index.html" "$TRASHDIR/restore-out"
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

  # verify all ES data was transferred from live directory to the temporary restore directory
  diff -ru "$GHE_DATA_DIR/current/elasticsearch" "$GHE_REMOTE_DATA_USER_DIR/elasticsearch-restore"

  # verify management console password was *not* restored
  ! grep -q "fake password hash data" "$GHE_REMOTE_DATA_USER_DIR/common/secrets.conf"

  # verify all git hooks data was transferred
  diff -ru "$GHE_DATA_DIR/current/git-hooks/environments/tarballs" "$GHE_REMOTE_DATA_USER_DIR/git-hooks/environments/tarballs"
  ! diff -ru "$GHE_DATA_DIR/current/git-hooks/environments" "$GHE_REMOTE_DATA_USER_DIR/git-hooks/environments"
  diff -ru "$GHE_DATA_DIR/current/git-hooks/repos" "$GHE_REMOTE_DATA_USER_DIR/git-hooks/repos"

  # verify the UUID was transferred
  diff -ru "$GHE_DATA_DIR/current/uuid" "$GHE_REMOTE_DATA_USER_DIR/common/uuid"

  # verify the audit log migration sentinel file has been created on 2.9 and above
  if [ "$GHE_VERSION_MAJOR" -eq 2 ] && [ "$GHE_VERSION_MINOR" -ge 9 ]; then
    [ -f "$GHE_REMOTE_DATA_USER_DIR/common/es-scan-complete" ]
  fi
}
