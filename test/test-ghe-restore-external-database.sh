#!/usr/bin/env bash
# ghe-restore command tests - external database

# Bring in testlib
# shellcheck source=test/testlib.sh
. "$(dirname "$0")/testlib.sh"

setup_test_data "$GHE_DATA_DIR/1"

# Make the current symlink
ln -s 1 "$GHE_DATA_DIR/current"

function setup(){
  rm -rf "$GHE_REMOTE_ROOT_DIR"
  setup_remote_metadata

  # set as configured, enable maintenance mode and create required directories
  setup_maintenance_mode "configured"

  # set restore host environ var
  GHE_RESTORE_HOST=127.0.0.1
  export GHE_RESTORE_HOST

  # Remove settings file with invalid data.
  rm -rf "$GHE_DATA_DIR/current/settings.json"
}

begin_test "ghe-restore allows restore of external DB snapshot to external DB instance."
(
  set -e 
  setup

  git config -f "$GHE_DATA_DIR/current/settings.json" mysql.external.enabled true

  # Enable external database on remote host
  git config -f "$GHE_REMOTE_DATA_USER_DIR/common/github.conf" mysql.external.enabled true

  export EXTERNAL_DATABASE_RESTORE_SCRIPT="echo 'fake ghe-export-mysql data'"

  # run ghe-restore and write output to file for asserting against
  if ! GHE_DEBUG=1  ghe-restore -v -f > "$TRASHDIR/restore-out" 2>&1; then
    # for debugging
    cat "$TRASHDIR/restore-out"
    : ghe-restore should have exited successfully
    false
  fi

  # verify connect to right host
  grep -q "Connect 127.0.0.1:22 OK" "$TRASHDIR/restore-out"

  # verify stale servers were cleared
  grep -q "ghe-cluster-cleanup-node OK" "$TRASHDIR/restore-out"

  verify_all_restored_data
)
end_test

begin_test "ghe-restore prevents restore of external DB snapshot to non-external DB appliance"
(
  set -e 
  setup

  git config -f "$GHE_DATA_DIR/current/settings.json" mysql.external.enabled true

  # Disable external database on remote host
  git config -f "$GHE_REMOTE_DATA_USER_DIR/common/github.conf" mysql.external.enabled false

  if ! GHE_DEBUG=1 ghe-restore -v -f 2> "$TRASHDIR/restore-out"; then
    # Verify that the restore failed due to snapshot compatability.
    grep -q "Snapshot from GitHub Enterprise with an external database configured cannot be restored to an appliance without external database configured" "$TRASHDIR/restore-out"
    
    exit 0
  else
    # for debugging
    cat "$TRASHDIR/restore-out"

    exit 1
  fi
)
end_test

begin_test "ghe-restore prevents restore of non external DB snapshot to external DB appliance"
(
  set -e 
  setup

  git config -f "$GHE_DATA_DIR/current/settings.json" mysql.external.enabled false

  # Disable external database on remote host
  git config -f "$GHE_REMOTE_DATA_USER_DIR/common/github.conf" mysql.external.enabled true

  # run ghe-restore and write output to file for asserting against
  if ! GHE_DEBUG=1  ghe-restore -v -f > "$TRASHDIR/restore-out" 2>&1; then
    # Verify that the restore failed due to snapshot compatability.
    grep -q "Snapshot from GitHub Enterprise with internal database cannot be restored 
    to an appliance with an external database configured." "$TRASHDIR/restore-out"
    
    exit 0
  else
    # for debugging
    cat "$TRASHDIR/restore-out"

    exit 1
  fi
)
end_test

begin_test "ghe-restore allows restore of external DB snapshot with --skip-mysql"
(
  set -e 
  setup

  git config -f "$GHE_DATA_DIR/current/settings.json" mysql.external.enabled true

  # Disable external database on remote host
  git config -f "$GHE_REMOTE_DATA_USER_DIR/common/github.conf" mysql.external.enabled false

  SKIP_MYSQL=true
  export SKIP_MYSQL

  # run ghe-restore and write output to file for asserting against
  if ! GHE_DEBUG=1  ghe-restore -v -f --skip-mysql > "$TRASHDIR/restore-out" 2>&1; then
    # for debugging
    cat "$TRASHDIR/restore-out"
    : ghe-restore should have exited successfully
    false
  fi

  grep -q "Skipping MySQL restore." "$TRASHDIR/restore-out"

  # verify connect to right host
  grep -q "Connect 127.0.0.1:22 OK" "$TRASHDIR/restore-out"

  # verify stale servers were cleared
  grep -q "ghe-cluster-cleanup-node OK" "$TRASHDIR/restore-out"

  verify_all_restored_data
)
end_test

begin_test "ghe-restore allows restore of non external DB snapshot with --skip-mysql"
(
  set -e 


  setup

  git config -f "$GHE_DATA_DIR/current/settings.json" mysql.external.enabled false

  # Disable external database on remote host
  git config -f "$GHE_REMOTE_DATA_USER_DIR/common/github.conf" mysql.external.enabled true

  SKIP_MYSQL=true
  export SKIP_MYSQL

  # run ghe-restore and write output to file for asserting against
  if ! GHE_DEBUG=1 ghe-restore -v -f --skip-mysql > "$TRASHDIR/restore-out" 2>&1; then
    # for debugging
    cat "$TRASHDIR/restore-out"
    : ghe-restore should have exited successfully
    false
  fi

  grep -q "Skipping MySQL restore." "$TRASHDIR/restore-out"

  # verify connect to right host
  grep -q "Connect 127.0.0.1:22 OK" "$TRASHDIR/restore-out"

  # verify stale servers were cleared
  grep -q "ghe-cluster-cleanup-node OK" "$TRASHDIR/restore-out"

  verify_all_restored_data
)
end_test

begin_test "ghe-restore allows restore of non external DB snapshot with -c"
(
  set -e 

  setup

  git config -f "$GHE_DATA_DIR/current/settings.json" mysql.external.enabled false

  # Disable external database on remote host
  git config -f "$GHE_REMOTE_DATA_USER_DIR/common/github.conf" mysql.external.enabled true

  # run ghe-restore and write output to file for asserting against
  if ! GHE_DEBUG=1  ghe-restore -v -f -c > "$TRASHDIR/restore-out" 2>&1; then
    # for debugging
    cat "$TRASHDIR/restore-out"
    : ghe-restore should have exited successfully
    false
  fi

  grep -q "Restoring MySQL database from logical backup snapshot on an appliance configured for logical backups ..." "$TRASHDIR/restore-out"

  # verify connect to right host
  grep -q "Connect 127.0.0.1:22 OK" "$TRASHDIR/restore-out"

  # verify stale servers were cleared
  grep -q "ghe-cluster-cleanup-node OK" "$TRASHDIR/restore-out"

  verify_all_restored_data
)
end_test

begin_test "ghe-restore allows restore of external DB snapshot with -c"
(
  set -e 
  setup

  git config -f "$GHE_DATA_DIR/current/settings.json" mysql.external.enabled true

  # Disable external database on remote host
  git config -f "$GHE_REMOTE_DATA_USER_DIR/common/github.conf" mysql.external.enabled false

  export EXTERNAL_DATABASE_RESTORE_SCRIPT="echo 'fake ghe-export-mysql data'"

  # run ghe-restore and write output to file for asserting against
  if ! GHE_DEBUG=1  ghe-restore -v -f -c > "$TRASHDIR/restore-out" 2>&1; then
    # for debugging
    cat "$TRASHDIR/restore-out"
    : ghe-restore should have exited successfully
    false
  fi

  grep -q "Restoring MySQL database from external backup snapshot on an appliance configured for external backups ..." "$TRASHDIR/restore-out"

  # verify connect to right host
  grep -q "Connect 127.0.0.1:22 OK" "$TRASHDIR/restore-out"

  # verify stale servers were cleared
  grep -q "ghe-cluster-cleanup-node OK" "$TRASHDIR/restore-out"

  verify_all_restored_data
)
end_test

begin_test "ghe-restore prevents restore of interal DB snapshot with -c to a cluster configured without mysql-server role"
(
  set -e 
  setup

  git config -f "$GHE_DATA_DIR/current/settings.json" mysql.external.enabled false

  # Disable external database on remote host
  git config -f "$GHE_REMOTE_DATA_USER_DIR/common/github.conf" mysql.external.enabled true

  echo "[cluster \"fake-uuid\"]
    hostname = fake-uuid
    git-server = true
    web-server = true
  " > $GHE_REMOTE_CLUSTER_CONF_FILE

  # run ghe-restore and write output to file for asserting against
  if ! GHE_DEBUG=1 ghe-restore -v -f -c > "$TRASHDIR/restore-out" 2>&1; then
    grep -q "Error: Target environment does not have a node with mysql-server role." "$TRASHDIR/restore-out"
    
    exit 0
  else
    # for debugging
    cat "$TRASHDIR/restore-out"
    : ghe-restore should have exited successfully
    false
  fi
)
end_test

begin_test "ghe-restore prevents restore of interal DB snapshot with -c to a cluster configured without mysql-master"
(
  set -e 
  setup

  git config -f "$GHE_DATA_DIR/current/settings.json" mysql.external.enabled false

  # Disable external database on remote host
  git config -f "$GHE_REMOTE_DATA_USER_DIR/common/github.conf" mysql.external.enabled true

  echo "[cluster \"fake-uuid\"]
    hostname = fake-uuid
    git-server = true
    web-server = true
    mysql-server = true
  " > $GHE_REMOTE_CLUSTER_CONF_FILE

  # run ghe-restore and write output to file for asserting against
  if ! GHE_DEBUG=1 ghe-restore -v -f -c > "$TRASHDIR/restore-out"; then
    grep -q "Error: Target environment does not have mysql-master configured. Aborting restore." "$TRASHDIR/restore-out"
    
    exit 0
  else
    # for debugging
    cat "$TRASHDIR/restore-out"
    : ghe-restore should not have exited successfully
    false
  fi
)
end_test

begin_test "ghe-restore allow restore of interal DB snapshot with -c to a cluster configured with mysql-server role"
(
  set -e 
  setup

  git config -f "$GHE_DATA_DIR/current/settings.json" mysql.external.enabled false

  # Disable external database on remote host
  git config -f "$GHE_REMOTE_DATA_USER_DIR/common/github.conf" mysql.external.enabled true

  echo "[cluster]
    mysql-master = fake-uuid
  [cluster \"fake-uuid\"]
    hostname = fake-uuid
    git-server = true
    web-server = true
    mysql-server = true
  " > $GHE_REMOTE_CLUSTER_CONF_FILE

  # run ghe-restore and write output to file for asserting against
  if ! GHE_DEBUG=1 ghe-restore -v -f -c > "$TRASHDIR/restore-out" 2>&1; then
    # for debugging
    cat "$TRASHDIR/restore-out"
    : ghe-restore should have exited successfully
    false
  fi

  # verify connect to right host
  grep -q "Connect 127.0.0.1:22 OK" "$TRASHDIR/restore-out"

  # verify stale servers were cleared
  grep -q "ghe-cluster-cleanup-node OK" "$TRASHDIR/restore-out"

  verify_all_restored_data
)
end_test

begin_test "ghe-restore restore of external DB snapshot with -c to a cluster configured with mysql-server role warns to remove mysql"
(
  set -e 
  setup

  git config -f "$GHE_DATA_DIR/current/settings.json" mysql.external.enabled true

  # Disable external database on remote host
  git config -f "$GHE_REMOTE_DATA_USER_DIR/common/github.conf" mysql.external.enabled false

  echo "[cluster \"fake-uuid\"]
    hostname = fake-uuid
    git-server = true
    web-server = true
    mysql-server = true
  " > $GHE_REMOTE_CLUSTER_CONF_FILE

  export EXTERNAL_DATABASE_RESTORE_SCRIPT="echo 'fake ghe-export-mysql data'"

  # run ghe-restore and write output to file for asserting against
  if ! GHE_DEBUG=1 ghe-restore -v -f -c > "$TRASHDIR/restore-out" 2>&1; then
    # for debugging
    cat "$TRASHDIR/restore-out"
    : ghe-restore should have exited successfully
    false
  fi

  grep -q "Target environment has mysql-server role. This should be removed after the restore has completed." "$TRASHDIR/restore-out"

  # verify connect to right host
  grep -q "Connect 127.0.0.1:22 OK" "$TRASHDIR/restore-out"

  # verify stale servers were cleared
  grep -q "ghe-cluster-cleanup-node OK" "$TRASHDIR/restore-out"

  verify_all_restored_data
)
end_test