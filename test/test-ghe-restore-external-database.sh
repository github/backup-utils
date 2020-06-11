#!/usr/bin/env bash
# ghe-restore command tests - external database

# Bring in testlib
# shellcheck source=test/testlib.sh
. "$(dirname "$0")/testlib.sh"

setup_test_data "$GHE_DATA_DIR/1"

# Make the current symlink
ln -s 1 "$GHE_DATA_DIR/current"

begin_test "ghe-restore prevents restore of external DB snapshot to non-external DB appliance"
(
  set -e 
  rm -rf "$GHE_REMOTE_ROOT_DIR"
  setup_remote_metadata

  # set as configured, enable maintenance mode and create required directories
  setup_maintenance_mode "configured"

  # set restore host environ var
  GHE_RESTORE_HOST=127.0.0.1
  export GHE_RESTORE_HOST

  # Enable external database in snapshot
  rm -rf "$GHE_DATA_DIR/current/settings.json"
  git config -f "$GHE_DATA_DIR/current/settings.json" mysql.external.enabled true

  # Disable external database on remote host
  git config -f "$GHE_REMOTE_DATA_USER_DIR/common/github.conf" mysql.external.enabled false

  # run ghe-restore and write output to file for asserting against
  if ! GHE_DEBUG=1 ghe-restore -v -f > "$TRASHDIR/restore-out" 2>&1; then
    # Verify that the restore failed due to snapshot compatability.
    grep -q "Snapshot from GitHub Enterprise with a External Database configured cannot be restored 
    to an appliance without external database configured." "$TRASHDIR/restore-out"
    
    exit 0
  else
    # for debugging
    cat "$TRASHDIR/restore-out"

    exit 1
  fi
)
end_test

begin_test "ghe-restore prevents restore of non DB snapshot to external DB appliance"
(
  set -e 
  rm -rf "$GHE_REMOTE_ROOT_DIR"
  setup_remote_metadata

  # set as configured, enable maintenance mode and create required directories
  setup_maintenance_mode "configured"

  # set restore host environ var
  GHE_RESTORE_HOST=127.0.0.1
  export GHE_RESTORE_HOST

  # Enable external database in snapshot
  rm -rf "$GHE_DATA_DIR/current/settings.json"
  git config -f "$GHE_DATA_DIR/current/settings.json" mysql.external.enabled false

  # Disable external database on remote host
  git config -f "$GHE_REMOTE_DATA_USER_DIR/common/github.conf" mysql.external.enabled true

  # run ghe-restore and write output to file for asserting against
  if ! GHE_DEBUG=1 bash -x ghe-restore -v -f > "$TRASHDIR/restore-out" 2>&1; then
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
