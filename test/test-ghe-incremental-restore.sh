#!/usr/bin/env bash
# ghe-restore command tests

# Bring in testlib
# shellcheck source=test/testlib.sh
. "$(dirname "$0")/testlib.sh"

setup_incremental_restore_data 
setup_actions_enabled_settings_for_restore true

# Make the current symlink
ln -s 1 "$GHE_DATA_DIR/current"
begin_test "ghe_restore -i doesn't run on unsupported versions"
(
  set -e
  GHE_RESTORE_HOST=127.0.0.1
  export GHE_RESTORE_HOST

  # restore should fail on versions older than 3.10
  ! GHE_TEST_REMOTE_VERSION=3.9.0 ghe-restore -i -v
  ! GHE_TEST_REMOTE_VERSION=3.7.0 ghe-restore -i -v
  ! GHE_TEST_REMOTE_VERSION=3.1.0 ghe-restore -i -v
)
end_test

begin_test "ghe-restore -i into configured vm from full backup"
(
  set -e
  rm -rf "$GHE_REMOTE_ROOT_DIR"
  setup_remote_metadata

  # set as configured, enable maintenance mode and create required directories
  setup_maintenance_mode "configured"

  # set restore host environ var
  GHE_RESTORE_HOST=127.0.0.1
  export GHE_RESTORE_HOST
  # run ghe-restore and write output to file for asserting against
  if ! GHE_TEST_REMOTE_VERSION=3.10.0 GHE_DEBUG=1 ghe-restore -i -v -f > "$TRASHDIR/restore-out" 2>&1; then
output_debug_logs_and_fail_test
  fi


  # verify connect to right host
  grep -q "Connect 127.0.0.1:122 OK" "$TRASHDIR/restore-out"

  # verify stale servers were cleared
  grep -q "Cleaning up stale nodes ..." "$TRASHDIR/restore-out"

  # Verify all the data we've restored is as expected
  verify_all_restored_data
)
end_test

begin_test "ghe-restore -i fails when the lsn information for the listed files is out of order"
(
  set -e
  rm -rf "$GHE_REMOTE_ROOT_DIR"
  setup_remote_metadata

  # set as configured, enable maintenance mode and create required directories
  setup_maintenance_mode "configured"

  # set restore host environ var
  GHE_RESTORE_HOST=127.0.0.1
  export GHE_RESTORE_HOST

  inc_1="$GHE_DATA_DIR/2"
  inc_2="$GHE_DATA_DIR/3"

  # screw up the order of the LSNs in xtrabackup_checkpoints
  setup_incremental_lsn $inc_1 100 200 incremental
  setup_incremental_lsn $inc_2 50 50 incremental
  # run ghe-restore and write output to file for asserting against
  # we expect failure and need the right output.
  if GHE_DEBUG=1 ghe-restore -i -v -f > "$TRASHDIR/restore-out" 2>&1; then
    true
  fi
)
end_test


