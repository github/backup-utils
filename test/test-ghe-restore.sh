#!/usr/bin/env bash
# ghe-restore command tests

# Bring in testlib
# shellcheck source=test/testlib.sh
. "$(dirname "$0")/testlib.sh"

setup_test_data "$GHE_DATA_DIR/1"

# Make the current symlink
ln -s 1 "$GHE_DATA_DIR/current"

begin_test "ghe-restore-snapshot-path reports an error when current symlink doesn't exist"
(
  set -e
  rm "$GHE_DATA_DIR/current"

  ghe-restore-snapshot-path > "$TRASHDIR/restore-out" 2>&1 || true
  ln -s 1 "$GHE_DATA_DIR/current"
  grep -q "Error: Snapshot 'current' doesn't exist." "$TRASHDIR/restore-out"
)
end_test

begin_test "ghe-restore-snapshot-path reports an error when specified snapshot doesn't exist"
(
  set -e
  rm "$GHE_DATA_DIR/current"

  ghe-restore-snapshot-path foo > "$TRASHDIR/restore-out" 2>&1 || true
  ln -s 1 "$GHE_DATA_DIR/current"
  grep -q "Error: Snapshot 'foo' doesn't exist." "$TRASHDIR/restore-out"
)
end_test

begin_test "ghe-restore into configured vm"
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
  if ! GHE_DEBUG=1 ghe-restore -v -f > "$TRASHDIR/restore-out" 2>&1; then
      cat "$TRASHDIR/restore-out"
      : ghe-restore should have exited successfully
      false
  fi

  # for debugging
  cat "$TRASHDIR/restore-out"

  # verify connect to right host
  grep -q "Connect 127.0.0.1:22 OK" "$TRASHDIR/restore-out"

  # verify stale servers were cleared
  grep -q "ghe-cluster-cleanup-node OK" "$TRASHDIR/restore-out"

  # Verify all the data we've restored is as expected
  verify_all_restored_data
)
end_test

begin_test "ghe-restore logs the benchmark"
(
  set -e

  export BM_TIMESTAMP=foo
  export GHE_RESTORE_HOST=127.0.0.1
  ghe-restore -v -f
  [ "$(grep took $GHE_DATA_DIR/current/benchmarks/benchmark.foo.log | wc -l)" -gt 1 ]
)
end_test

begin_test "ghe-restore aborts without user verification"
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
  if echo "no" | ghe-restore -v > "$TRASHDIR/restore-out" 2>&1; then
    cat "$TRASHDIR/restore-out"
    false # ghe-restore should have exited non-zero
  fi

  grep -q "Restore aborted" "$TRASHDIR/restore-out"
)
end_test

begin_test "ghe-restore accepts user verification"
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
  if ! echo "yes" | ghe-restore -v > "$TRASHDIR/restore-out" 2>&1; then
    cat "$TRASHDIR/restore-out"
    false # ghe-restore should have accepted the input
  fi
)
end_test

begin_test "ghe-restore -c into unconfigured vm"
(
  set -e
  rm -rf "$GHE_REMOTE_ROOT_DIR"
  setup_remote_metadata

  # set restore host environ var
  GHE_RESTORE_HOST=127.0.0.1
  export GHE_RESTORE_HOST

  # leave unconfigured, enable maintenance mode and create required directories
  setup_maintenance_mode

  # run ghe-restore and write output to file for asserting against
  if ! ghe-restore -v -f -c > "$TRASHDIR/restore-out" 2>&1; then
    cat "$TRASHDIR/restore-out"
    false
  fi

  # verify connect to right host
  grep -q "Connect 127.0.0.1:22 OK" "$TRASHDIR/restore-out"

  # verify attempt to clear stale servers was not made
  grep -q "ghe-cluster-cleanup-node OK" "$TRASHDIR/restore-out" && {
    echo "ghe-cluster-cleanup-node should not run on unconfigured nodes."
    exit 1
  }

  # Verify all the data we've restored is as expected
  verify_all_restored_data
)
end_test

begin_test "ghe-restore into unconfigured vm"
(
  set -e
  rm -rf "$GHE_REMOTE_ROOT_DIR"
  setup_remote_metadata

  # set restore host environ var
  GHE_RESTORE_HOST=127.0.0.1
  export GHE_RESTORE_HOST

  # leave unconfigured, enable maintenance mode and create required directories
  setup_maintenance_mode

  # ghe-restore into an unconfigured vm implies -c
  ghe-restore -v -f > "$TRASHDIR/restore-out" 2>&1
  cat "$TRASHDIR/restore-out"

  # verify no config run after restore on unconfigured instance
  ! grep -q "ghe-config-apply OK" "$TRASHDIR/restore-out"

  # verify connect to right host
  grep -q "Connect 127.0.0.1:22 OK" "$TRASHDIR/restore-out"

  # verify attempt to clear stale servers was not made
  grep -q "ghe-cluster-cleanup-node OK" "$TRASHDIR/restore-out" && {
    echo "ghe-cluster-cleanup-node should not run on unconfigured nodes."
    exit 1
  }

  # Verify all the data we've restored is as expected
  verify_all_restored_data
)
end_test

begin_test "ghe-restore with host arg"
(
  set -e
  rm -rf "$GHE_REMOTE_ROOT_DIR"
  setup_remote_metadata

  # set as configured, enable maintenance mode and create required directories
  setup_maintenance_mode "configured"

  # set restore host environ var
  GHE_RESTORE_HOST=127.0.0.1
  export GHE_RESTORE_HOST

  # run it
  output="$(ghe-restore -f localhost)" || false

  # verify host arg overrides configured restore host
  echo "$output" | grep -q 'Connect localhost:22 OK'

  # Verify all the data we've restored is as expected
  verify_all_restored_data
)
end_test

begin_test "ghe-restore no host arg or configured restore host"
(
  set -e
  rm -rf "$GHE_REMOTE_ROOT_DIR"
  setup_remote_metadata

  # set as configured, enable maintenance mode and create required directories
  setup_maintenance_mode "configured"

  # unset configured restore host
  unset GHE_RESTORE_HOST

  # verify running ghe-restore fails
  ! ghe-restore -f
)
end_test

begin_test "ghe-restore with no pages backup"
(
  set -e
  rm -rf "$GHE_REMOTE_ROOT_DIR"
  setup_remote_metadata

  # set as configured, enable maintenance mode and create required directories
  setup_maintenance_mode "configured"

  # remove pages data
  rm -rf "$GHE_DATA_DIR/1/pages"

  # run it
  ghe-restore -v -f localhost
)
end_test

begin_test "ghe-restore cluster backup to non-cluster appliance"
(
  set -e
  rm -rf "$GHE_REMOTE_ROOT_DIR"
  setup_remote_metadata

  # set as configured, enable maintenance mode and create required directories
  setup_maintenance_mode "configured"

  echo "cluster" > "$GHE_DATA_DIR/current/strategy"
  ! output=$(ghe-restore -v -f localhost 2>&1)

  echo $output | grep -q "Snapshot from a GitHub Enterprise cluster cannot be restored"
)
end_test

begin_test "ghe-restore no leaked ssh host keys detected"
(
  set -e

  # No leaked key message test
  ! ghe-restore -v -f localhost | grep -q "Leaked key"
)
end_test

begin_test "ghe-restore with current backup leaked key detection"
(
  set -e

  # Add a custom ssh key that will be used as part of the backup and fingerprint injection for the tests
  cat <<EOF > "$GHE_DATA_DIR/ssh_host_dsa_key.pub"
ssh-dss AAAAB3NzaC1kc3MAAACBAMv7O3YNWyAOj6Oa6QhG2qL67FSDoR96cYILilsQpn1j+f21uXOYBRdqauP+8XS2sPYZy6p/T3gJhCeC6ppQWY8n8Wjs/oS8j+nl5KX7JbIqzvSIb0tAKnMI67pqCHTHWx+LGvslgRALJuGxOo7Bp551bNN02Y2gfm2TlHOv6DarAAAAFQChqAK2KkHI+WNkFj54GwGYdX+GCQAAAIEApmXYiT7OYXfmiHzhJ/jfT1ZErPAOwqLbhLTeKL34DkAH9J/DImLAC0tlSyDXjlMzwPbmECdu6LNYh4OZq7vAN/mcM2+Sue1cuJRmkt5B1NYox4fRs3o9RO+DGOcbogUUUQu7OIM/o95zF6dFEfxIWnSsmYvl+Ync4fEgN6ZLjtMAAACBAMRYjDs0g1a9rocKzUQ7fazaXnSNHxZADQW6SIodt7ic1fq4OoO0yUoBf/DSOF8MC/XTSLn33awI9SrbQ5Kk0oGxmV1waoFkqW/MDlypC8sHG0/gxzeJICkwjh/1OVwF6+e0C/6bxtUwV/I+BeMtZ6U2tKy15FKp5Mod7bLBgiee test@backup-utils
EOF

  # Add custom key to tar file
  tar -cf "$GHE_DATA_DIR/current/ssh-host-keys.tar" --directory="$GHE_DATA_DIR" ssh_host_dsa_key.pub

  # Inject the fingerprint into the blacklist
  export FINGERPRINT_BLACKLIST="98:d8:99:d3:be:c0:55:05:db:b0:53:2f:1f:ad:b3:60"

  # Running it and ignoring the actual script status but testing that the ssh host detection still happens
  output=$(ghe-restore -v -f localhost) || true

  # Clean up, putting it back to its initial state
  echo "fake ghe-export-ssh-host-keys data" > "$GHE_DATA_DIR/current/ssh-host-keys.tar"

  # Test for leaked key messages
  echo $output | grep -q "Leaked key found in current backup snapshot"
  echo $output | grep -q "The snapshot that is being restored contains a leaked SSH host key."
)
end_test

begin_test "ghe-restore fails when restore to an active HA pair"
(
  set -e

  rm -rf "$GHE_REMOTE_ROOT_DIR"
  setup_remote_metadata

  echo "rsync" > "$GHE_DATA_DIR/current/strategy"
  touch "$GHE_REMOTE_ROOT_DIR/etc/github/repl-state"

  ! output=$(ghe-restore -v -f localhost 2>&1)

  echo $output | grep -q "Error: Restoring to an appliance with replication enabled is not supported."
)
end_test

begin_test "ghe-restore honours --version flag"
(
  set -e

  # Make sure a partial version string is returned
  ghe-restore --version | grep "GitHub backup-utils v"

)
end_test

begin_test "ghe-restore honours --help and -h flags"
(
  set -e

  arg_help=$(ghe-restore --help | grep -o 'Usage: ghe-restore')
  arg_h=$(ghe-restore -h | grep -o 'Usage: ghe-restore')

  # Make sure a Usage: string is returned and that it's the same for -h and --help
  [ "$arg_help" = "$arg_h" ] && echo $arg_help | grep -q "Usage: ghe-restore"
)
end_test

begin_test "ghe-restore fails when restore 2.9/2.10 snapshot without audit log migration sentinel file to 2.11"
(
  set -e

  # noop if not testing against 2.11
  if [ "$(version $GHE_REMOTE_VERSION)" -ne "$(version 2.11.0)" ]; then
    skip_test
  fi

  rm -rf "$GHE_REMOTE_ROOT_DIR"
  setup_remote_metadata

  echo "rsync" > "$GHE_DATA_DIR/current/strategy"
  echo "v2.9.10" > "$GHE_DATA_DIR/current/version"
  rm "$GHE_DATA_DIR/current/es-scan-complete"

  ! output=$(ghe-restore -v localhost 2>&1)

  echo $output | grep -q "Error: Snapshot must be from GitHub Enterprise v2.9 or v2.10 after running the"

  echo "v2.10.5" > "$GHE_DATA_DIR/current/version"
  ! output=$(ghe-restore -v localhost 2>&1)

  echo $output | grep -q "Error: Snapshot must be from GitHub Enterprise v2.9 or v2.10 after running the"
)
end_test

begin_test "ghe-restore force restore of 2.9/2.10 snapshot without audit log migration sentinel file to 2.11"
(
  set -e

  # noop if not testing against 2.11
  if [ "$(version $GHE_REMOTE_VERSION)" -ne "$(version 2.11.0)" ]; then
    skip_test
  fi

  rm -rf "$GHE_REMOTE_ROOT_DIR"
  setup_remote_metadata

  echo "rsync" > "$GHE_DATA_DIR/current/strategy"
  echo "v2.9.10" > "$GHE_DATA_DIR/current/version"

  # Create fake remote repositories dir
  mkdir -p "$GHE_REMOTE_DATA_USER_DIR/repositories"

  ghe-restore -v -f localhost

  echo "v2.10.5" > "$GHE_DATA_DIR/current/version"
  ghe-restore -v -f localhost
)
end_test

begin_test "ghe-restore exits early on unsupported version"
(
  set -e
  GHE_RESTORE_HOST=127.0.0.1
  export GHE_RESTORE_HOST

  ! GHE_TEST_REMOTE_VERSION=2.10.0 ghe-restore -v
)
end_test

# Reset data for sub-subsequent tests
rm -rf "$GHE_DATA_DIR/1"
setup_test_data "$GHE_DATA_DIR/1"

# Make the current symlink
ln -s 1 "$GHE_DATA_DIR/current"

begin_test "ghe-restore cluster"
(
  set -e
  rm -rf "$GHE_REMOTE_ROOT_DIR"
  setup_remote_metadata
  setup_remote_cluster
  echo "cluster" > "$GHE_DATA_DIR/current/strategy"

  # set as configured, enable maintenance mode and create required directories
  setup_maintenance_mode "configured"

  # set restore host environ var
  GHE_RESTORE_HOST=127.0.0.1
  export GHE_RESTORE_HOST

  # CI servers may have moreutils parallel and GNU parallel installed. We need moreutils parallel.
  if [ -x "/usr/bin/parallel.moreutils" ]; then
    ln -sf /usr/bin/parallel.moreutils "$ROOTDIR/test/bin/parallel"
  fi

  # run ghe-restore and write output to file for asserting against
  if ! ghe-restore -v -f > "$TRASHDIR/restore-out" 2>&1; then
      cat "$TRASHDIR/restore-out"
      : ghe-restore should have exited successfully
      false
  fi

  if [ -h "$ROOTDIR/test/bin/parallel" ]; then
    unlink "$ROOTDIR/test/bin/parallel"
  fi

  # for debugging
  cat "$TRASHDIR/restore-out"

  # verify data was copied from multiple nodes
  # repositories
  grep -q "networks to git-server-fake-uuid" "$TRASHDIR/restore-out"
  grep -q "networks to git-server-fake-uuid1" "$TRASHDIR/restore-out"
  grep -q "networks to git-server-fake-uuid2" "$TRASHDIR/restore-out"
  grep -q "dgit-cluster-restore-finalize OK" "$TRASHDIR/restore-out"

  # gists
  grep -q "gists to git-server-fake-uuid" "$TRASHDIR/restore-out"
  grep -q "gists to git-server-fake-uuid1" "$TRASHDIR/restore-out"
  grep -q "gists to git-server-fake-uuid2" "$TRASHDIR/restore-out"
  grep -q "gist-cluster-restore-finalize OK" "$TRASHDIR/restore-out"


  # storage
  grep -q "data to git-server-fake-uuid" "$TRASHDIR/restore-out"
  grep -q "data to git-server-fake-uuid1" "$TRASHDIR/restore-out"
  grep -q "data to git-server-fake-uuid2" "$TRASHDIR/restore-out"
  grep -q "storage-cluster-restore-finalize OK" "$TRASHDIR/restore-out"


  # pages
  grep -q "Pages to git-server-fake-uuid" "$TRASHDIR/restore-out"
  grep -q "Pages to git-server-fake-uuid1" "$TRASHDIR/restore-out"
  grep -q "Pages to git-server-fake-uuid2" "$TRASHDIR/restore-out"
  grep -q "dpages-cluster-restore-finalize OK" "$TRASHDIR/restore-out"

  # verify no warnings printed
  ! grep -q "Warning" "$TRASHDIR/restore-out"

  # Verify all the data we've restored is as expected
  verify_all_restored_data
)
end_test

begin_test "ghe-restore missing directories or files from source snapshot displays warning"
(
    # Tests the scenario where something exists in the database, but not on disk.
    set -e
    rm -rf "$GHE_REMOTE_ROOT_DIR"
    setup_remote_metadata
    setup_remote_cluster
    echo "cluster" > "$GHE_DATA_DIR/current/strategy"

    # set as configured, enable maintenance mode and create required directories
    setup_maintenance_mode "configured"

    # set restore host environ var
    GHE_RESTORE_HOST=127.0.0.1
    export GHE_RESTORE_HOST

    # CI servers may have moreutils parallel and GNU parallel installed. We need moreutils parallel.
    if [ -x "/usr/bin/parallel.moreutils" ]; then
      ln -sf /usr/bin/parallel.moreutils "$ROOTDIR/test/bin/parallel"
    fi

    # Tell dgit-cluster-restore-finalize and gist-cluster-restore-finalize to return warnings
    export GHE_DGIT_CLUSTER_RESTORE_FINALIZE_WARNING=1
    export GHE_GIST_CLUSTER_RESTORE_FINALIZE_WARNING=1

    # run ghe-restore and write output to file for asserting against
    if ! ghe-restore -v -f > "$TRASHDIR/restore-out" 2>&1; then
        cat "$TRASHDIR/restore-out"
        : ghe-restore should have exited successfully
        false
    fi

    if [ -h "$ROOTDIR/test/bin/parallel" ]; then
      unlink "$ROOTDIR/test/bin/parallel"
    fi

    # for debugging
    cat "$TRASHDIR/restore-out"

    grep -q "Warning: One or more repository networks failed to restore successfully." "$TRASHDIR/restore-out"
    grep -q "Warning: One or more Gists failed to restore successfully." "$TRASHDIR/restore-out"

    # Verify all the data we've restored is as expected
    verify_all_restored_data
)
end_test
