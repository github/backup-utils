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

# Helper function to set BYODB state of backup snapshot
function set_external_database_enabled_state_of_backup_snapshot(){
  git config -f "$GHE_DATA_DIR/current/settings.json" mysql.external.enabled "$1"
}

# Helper function to set BYODB state of remote host
function set_external_database_enabled_state_of_appliance(){
  git config -f "$GHE_REMOTE_DATA_USER_DIR/common/github.conf" mysql.external.enabled "$1"
}

function output_debug_logs_and_fail_test() {
  cat "$TRASHDIR/restore-out"
  exit 1
}

function check_restore_output_for() {
  grep -q "$1" "$TRASHDIR/restore-out"
}

begin_test "ghe-restore allows restore of external DB snapshot to external DB instance"
(
  set -e
  setup

  set_external_database_enabled_state_of_backup_snapshot true
  set_external_database_enabled_state_of_appliance true

  export EXTERNAL_DATABASE_RESTORE_SCRIPT="echo 'fake ghe-export-mysql data'"

  # run ghe-restore and write output to file for asserting against
  if ! GHE_DEBUG=1  ghe-restore -v -f > "$TRASHDIR/restore-out" 2>&1; then
    output_debug_logs_and_fail_test
  fi

  # verify connect to right host
  check_restore_output_for "Connect 127.0.0.1:122 OK"

  # verify stale servers were cleared
  check_restore_output_for "Cleaning up stale nodes ..."

  verify_all_restored_data
)
end_test

begin_test "ghe-restore -c from external DB snapshot to non-external DB appliance is not allowed"
(
  set -e
  setup

  set_external_database_enabled_state_of_backup_snapshot true
  set_external_database_enabled_state_of_appliance false

  if ! GHE_DEBUG=1 ghe-restore -v -f -c > "$TRASHDIR/restore-out" 2>&1; then
    # Verify that the restore failed due to snapshot incompatibility.
    check_restore_output_for "Restoring the settings of a snapshot from an appliance using an externally-managed MySQL service to an appliance using the bundled MySQL service is not supported."
    check_restore_output_for "Please reconfigure the appliance first, then run ghe-restore again."
  else
    output_debug_logs_and_fail_test
  fi
)
end_test

begin_test "ghe-restore -c from non external DB snapshot to external DB appliance is not allowed"
(
  set -e
  setup

  set_external_database_enabled_state_of_backup_snapshot false
  set_external_database_enabled_state_of_appliance true

  # run ghe-restore and write output to file for asserting against
  if ! GHE_DEBUG=1  ghe-restore -v -f -c > "$TRASHDIR/restore-out" 2>&1; then
    # Verify that the restore failed due to snapshot incompatibility.
    check_restore_output_for "Restoring the settings of a snapshot from an appliance using the bundled MySQL service to an appliance using an externally-managed MySQL service is not supported."
    check_restore_output_for "Please reconfigure the appliance first, then run ghe-restore again."
  else
    output_debug_logs_and_fail_test
  fi
)
end_test

begin_test "ghe-restore from external DB snapshot to non external DB appliance without --skip-mysql is not allowed"
  set -e
  setup

  set_external_database_enabled_state_of_backup_snapshot true
  set_external_database_enabled_state_of_appliance false

  # run ghe-restore and write output to file for asserting against
  if ! GHE_DEBUG=1  ghe-restore -v -f > "$TRASHDIR/restore-out" 2>&1; then
    check_restore_output_for "Restoring a snapshot from an appliance using an externally-managed MySQL service to an appliance using the bundled MySQL service is not supported."
    check_restore_output_for "Please migrate the MySQL data beforehand, then run ghe-restore again, passing in the --skip-mysql flag."
  else
    output_debug_logs_and_fail_test
  fi

end_test

begin_test "ghe-restore from non external DB snapshot to external DB appliance without --skip-mysql is not allowed"
  set -e
  setup

  set_external_database_enabled_state_of_backup_snapshot false
  set_external_database_enabled_state_of_appliance true

  # run ghe-restore and write output to file for asserting against
  if ! GHE_DEBUG=1  ghe-restore -v -f > "$TRASHDIR/restore-out" 2>&1; then
    check_restore_output_for "Restoring a snapshot from an appliance using the bundled MySQL service to an appliance using an externally-managed MySQL service is not supported."
    check_restore_output_for "Please migrate the MySQL data beforehand, then run ghe-restore again, passing in the --skip-mysql flag."
  else
    output_debug_logs_and_fail_test
  fi

end_test

begin_test "ghe-restore allows restore of external DB snapshot to non-external DB appliance with --skip-mysql"
(
  set -e
  setup

  set_external_database_enabled_state_of_backup_snapshot true
  set_external_database_enabled_state_of_appliance false

  # run ghe-restore and write output to file for asserting against
  if ! GHE_DEBUG=1  ghe-restore -v -f --skip-mysql > "$TRASHDIR/restore-out" 2>&1; then
    output_debug_logs_and_fail_test
  fi

  check_restore_output_for "Skipping MySQL restore."

  # verify connect to right host
  check_restore_output_for "Connect 127.0.0.1:122 OK"

  # verify stale servers were cleared
  check_restore_output_for "Cleaning up stale nodes ..."

  # ghe-restore sets this when --skip-mysql is passed, but that won't propagate back to this shell and it affects what we validate
  SKIP_MYSQL=true verify_all_restored_data
)
end_test

begin_test "ghe-restore allows restore of non external DB snapshot to external DB appliance with --skip-mysql"
(
  set -e
  setup

  set_external_database_enabled_state_of_backup_snapshot false
  set_external_database_enabled_state_of_appliance true

  # run ghe-restore and write output to file for asserting against
  if ! GHE_DEBUG=1 ghe-restore -v -f --skip-mysql > "$TRASHDIR/restore-out" 2>&1; then
    output_debug_logs_and_fail_test
  fi

  check_restore_output_for "Skipping MySQL restore."

  # verify connect to right host
  check_restore_output_for "Connect 127.0.0.1:122 OK"

  # verify stale servers were cleared
  check_restore_output_for "Cleaning up stale nodes ..."

  # ghe-restore sets SKIP_MYSQL=true when --skip-mysql is passed, but that won't propagate back to this shell and it affects what we validate
  SKIP_MYSQL=true verify_all_restored_data
)
end_test
