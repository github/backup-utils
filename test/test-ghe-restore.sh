#!/usr/bin/env bash
# ghe-restore command tests

# Bring in testlib
# shellcheck source=test/testlib.sh
. "$(dirname "$0")/testlib.sh"

# Add some fake pages data to the snapshot
mkdir -p "$GHE_DATA_DIR/1/pages"
cd "$GHE_DATA_DIR/1/pages"
pages1="4/c8/1e/72/2/legacy"
pages2="4/c1/6a/53/31/dd3a9a0faa88c714ef2dd638b67587f92f109f96"
mkdir -p "$pages1" "$pages2"
touch "$pages1/index.html" "$pages2/index.html"

# Add some fake elasticsearch data to the snapshot
mkdir -p "$GHE_DATA_DIR/1/elasticsearch"
cd "$GHE_DATA_DIR/1/elasticsearch"
mkdir -p gh-enterprise-es/node/0
touch gh-enterprise-es/node/0/stuff1
touch gh-enterprise-es/node/0/stuff2

# Set a temporary management console password
mkdir -p "$GHE_REMOTE_DATA_USER_DIR/common"
git config -f "$GHE_REMOTE_DATA_USER_DIR/common/secrets.conf" secrets.manage "foobar"

# Create some fake hookshot data in the remote data directory
mkdir -p "$GHE_DATA_DIR/1/hookshot"
cd "$GHE_DATA_DIR/1/hookshot"
mkdir -p repository-123 repository-456
touch repository-123/test.bpack repository-456/test.bpack

# Create some fake environments
mkdir -p "$GHE_DATA_DIR/1/git-hooks/environments/tarballs"
cd "$GHE_DATA_DIR/1/git-hooks/environments/tarballs"
mkdir -p 123 456
touch 123/script.sh 456/foo.sh
cd 123
tar -czf script.tar.gz script.sh
cd ../456
tar -czf foo.tar.gz foo.sh
cd ..
rm 123/script.sh 456/foo.sh
mkdir -p "$GHE_DATA_DIR/1/git-hooks/repos/1"
touch "$GHE_DATA_DIR/1/git-hooks/repos/1/bar.sh"

cd "$GHE_DATA_DIR/1/git-hooks/environments"
mkdir -p 123 456
touch 123/script.sh 456/foo.sh

# Create some fake alambic data in the remote data directory
mkdir -p "$GHE_DATA_DIR/1/alambic_assets/github-enterprise-assets/0000"
touch "$GHE_DATA_DIR/1/alambic_assets/github-enterprise-assets/0000/test.png"

mkdir -p "$GHE_DATA_DIR/1/alambic_assets/github-enterprise-releases/0001"
touch "$GHE_DATA_DIR/1/alambic_assets/github-enterprise-releases/0001/1ed78298-522b-11e3-9dc0-22eed1f8132d"

# Create a fake uuid
echo "fake uuid" > "$GHE_DATA_DIR/1/uuid"

# Add some fake repositories to the snapshot
mkdir -p "$GHE_DATA_DIR/1/repositories"
mkdir -p "$TRASHDIR/hooks"
cd "$GHE_DATA_DIR/1/repositories"
repo1="0/nw/01/aa/3f/1234/1234.git"
repo2="0/nw/01/aa/3f/1234/1235.git"
repo3="1/nw/23/bb/4c/2345/2345.git"
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

# Add some fake svn data to repo3
echo "fake svn history data" > "$repo3/svn.history.msgpack"
mkdir "$repo3/svn_data"
echo "fake property history data" > "$repo3/svn_data/property_history.msgpack"

# Make the current symlink
ln -s 1 "$GHE_DATA_DIR/current"

# create a fake backups for each datastore
echo "fake ghe-export-mysql data" | gzip > "$GHE_DATA_DIR/current/mysql.sql.gz"
echo "fake ghe-export-redis data" > "$GHE_DATA_DIR/current/redis.rdb"
echo "fake ghe-export-authorized-keys data" > "$GHE_DATA_DIR/current/authorized-keys.json"
echo "fake ghe-export-ssh-host-keys data" > "$GHE_DATA_DIR/current/ssh-host-keys.tar"
echo "fake ghe-export-settings data" > "$GHE_DATA_DIR/current/settings.json"
echo "fake ghe-export-ssl-ca-certificates data" > "$GHE_DATA_DIR/current/ssl-ca-certificates.tar"
echo "fake license data" > "$GHE_DATA_DIR/current/enterprise.ghl"
echo "fake password hash data" > "$GHE_DATA_DIR/current/manage-password"
echo "rsync" > "$GHE_DATA_DIR/current/strategy"
echo "$GHE_REMOTE_VERSION" >  "$GHE_DATA_DIR/current/version"
touch "$GHE_DATA_DIR/current/es-scan-complete"

begin_test "ghe-restore into configured vm"
(
    set -e
    rm -rf "$GHE_REMOTE_ROOT_DIR"
    setup_remote_metadata

    # create file used to determine if instance has been configured.
    touch "$GHE_REMOTE_ROOT_DIR/etc/github/configured"

    # create file used to determine if instance is in maintenance mode.
    mkdir -p "$GHE_REMOTE_DATA_DIR/github/current/public/system"
    touch "$GHE_REMOTE_DATA_DIR/github/current/public/system/maintenance.html"

    # Create fake remote repositories dir
    mkdir -p "$GHE_REMOTE_DATA_USER_DIR/repositories"

    # set restore host environ var
    GHE_RESTORE_HOST=127.0.0.1
    export GHE_RESTORE_HOST

    # run ghe-restore and write output to file for asserting against
    if ! ghe-restore -v -f > "$TRASHDIR/restore-out" 2>&1; then
        cat "$TRASHDIR/restore-out"
        : ghe-restore should have exited successfully
        false
    fi

    # for debugging
    cat "$TRASHDIR/restore-out"

    # verify connect to right host
    grep -q "Connect 127.0.0.1:22 OK" "$TRASHDIR/restore-out"

    # verify all import scripts were run
    grep -q "$pages1/index.html" "$TRASHDIR/restore-out"
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

    # verify management console password was *not* restored
    ! grep -q "fake password hash data" "$GHE_REMOTE_DATA_USER_DIR/common/secrets.conf"

    # verify all hookshot user data was transferred
    diff -ru "$GHE_DATA_DIR/current/hookshot" "$GHE_REMOTE_DATA_USER_DIR/hookshot"

    # verify all git hooks data was transferred
    diff -ru "$GHE_DATA_DIR/current/git-hooks/environments/tarballs" "$GHE_REMOTE_DATA_USER_DIR/git-hooks/environments/tarballs"
    ! diff -ru "$GHE_DATA_DIR/current/git-hooks/environments" "$GHE_REMOTE_DATA_USER_DIR/git-hooks/environments"
    diff -ru "$GHE_DATA_DIR/current/git-hooks/repos" "$GHE_REMOTE_DATA_USER_DIR/git-hooks/repos"

    # verify all alambic assets user data was transferred
    diff -ru "$GHE_DATA_DIR/current/alambic_assets" "$GHE_REMOTE_DATA_USER_DIR/alambic_assets"

    # verify the UUID was transferred
    diff -ru "$GHE_DATA_DIR/current/uuid" "$GHE_REMOTE_DATA_USER_DIR/common/uuid"

    # verify the audit log migration sentinel file has been created on 2.9 and above
    if [ "$GHE_VERSION_MAJOR" -eq 2 ] && [ "$GHE_VERSION_MINOR" -ge 9 ]; then
      [ -f "$GHE_REMOTE_DATA_USER_DIR/common/es-scan-complete" ]
    fi
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

    # create file used to determine if instance has been configured.
    touch "$GHE_REMOTE_ROOT_DIR/etc/github/configured"

    # create file used to determine if instance is in maintenance mode.
    mkdir -p "$GHE_REMOTE_DATA_DIR/github/current/public/system"
    touch "$GHE_REMOTE_DATA_DIR/github/current/public/system/maintenance.html"

    # Create fake remote repositories dir
    mkdir -p "$GHE_REMOTE_DATA_USER_DIR/repositories"

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

    # create file used to determine if instance has been configured.
    touch "$GHE_REMOTE_ROOT_DIR/etc/github/configured"

    # create file used to determine if instance is in maintenance mode.
    mkdir -p "$GHE_REMOTE_DATA_DIR/github/current/public/system"
    touch "$GHE_REMOTE_DATA_DIR/github/current/public/system/maintenance.html"

    # Create fake remote repositories dir
    mkdir -p "$GHE_REMOTE_DATA_USER_DIR/repositories"

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

    # create file used to determine if instance is in maintenance mode.
    mkdir -p "$GHE_REMOTE_DATA_DIR/github/current/public/system"
    touch "$GHE_REMOTE_DATA_DIR/github/current/public/system/maintenance.html"

    # Create fake remote repositories dir
    mkdir -p "$GHE_REMOTE_DATA_USER_DIR/repositories"

    # run ghe-restore and write output to file for asserting against
    if ! ghe-restore -v -f -c > "$TRASHDIR/restore-out" 2>&1; then
        cat "$TRASHDIR/restore-out"
        false
    fi

    # verify connect to right host
    grep -q "Connect 127.0.0.1:22 OK" "$TRASHDIR/restore-out"

    # verify all import scripts were run
    grep -q "$pages1/index.html" "$TRASHDIR/restore-out"
    grep -q "fake ghe-export-mysql data" "$TRASHDIR/restore-out"
    grep -q "fake ghe-export-redis data" "$TRASHDIR/restore-out"
    grep -q "fake ghe-export-authorized-keys data" "$TRASHDIR/restore-out"
    grep -q "fake ghe-export-ssh-host-keys data" "$TRASHDIR/restore-out"

    # verify settings were imported
    grep -q "fake ghe-export-settings data" "$TRASHDIR/restore-out"

    # verify all repository data was transferred to the restore location
    diff -ru "$GHE_DATA_DIR/current/repositories" "$GHE_REMOTE_DATA_USER_DIR/repositories"

    # verify all pages data was transferred to the restore location
    diff -ru "$GHE_DATA_DIR/current/pages" "$GHE_REMOTE_DATA_USER_DIR/pages"

    # verify management console password
    grep -q "fake password hash data" "$GHE_REMOTE_DATA_USER_DIR/common/secrets.conf"

    # verify all hookshot user data was transferred
    diff -ru "$GHE_DATA_DIR/current/hookshot" "$GHE_REMOTE_DATA_USER_DIR/hookshot"

    # verify all git hooks data was transferred
    diff -ru "$GHE_DATA_DIR/current/git-hooks/environments/tarballs" "$GHE_REMOTE_DATA_USER_DIR/git-hooks/environments/tarballs"
    ! diff -ru "$GHE_DATA_DIR/current/git-hooks/environments" "$GHE_REMOTE_DATA_USER_DIR/git-hooks/environments"
    diff -ru "$GHE_DATA_DIR/current/git-hooks/repos" "$GHE_REMOTE_DATA_USER_DIR/git-hooks/repos"

    # verify all alambic assets user data was transferred
    diff -ru "$GHE_DATA_DIR/current/alambic_assets" "$GHE_REMOTE_DATA_USER_DIR/alambic_assets"

    # verify the UUID was transferred
    diff -ru "$GHE_DATA_DIR/current/uuid" "$GHE_REMOTE_DATA_USER_DIR/common/uuid"

    # verify ghe-export-ssl-ca-certificates was run
    grep -q "fake ghe-export-ssl-ca-certificates data" "$TRASHDIR/restore-out"

    # verify the audit log migration sentinel file has been created on 2.9 and above
    if [ "$GHE_VERSION_MAJOR" -eq 2 ] && [ "$GHE_VERSION_MINOR" -ge 9 ]; then
      [ -f "$GHE_REMOTE_DATA_USER_DIR/common/es-scan-complete" ]
    fi
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

    # create file used to determine if instance is in maintenance mode.
    mkdir -p "$GHE_REMOTE_DATA_DIR/github/current/public/system"
    touch "$GHE_REMOTE_DATA_DIR/github/current/public/system/maintenance.html"

    # Create fake remote repositories dir
    mkdir -p "$GHE_REMOTE_DATA_USER_DIR/repositories"

    # ghe-restore into an unconfigured vm implies -c
    ghe-restore -v -f > "$TRASHDIR/restore-out" 2>&1
    cat "$TRASHDIR/restore-out"

    # verify connect to right host
    grep -q "Connect 127.0.0.1:22 OK" "$TRASHDIR/restore-out"

    # verify all import scripts were run
    grep -q "$pages1/index.html" "$TRASHDIR/restore-out"
    grep -q "fake ghe-export-mysql data" "$TRASHDIR/restore-out"
    grep -q "fake ghe-export-redis data" "$TRASHDIR/restore-out"
    grep -q "fake ghe-export-authorized-keys data" "$TRASHDIR/restore-out"
    grep -q "fake ghe-export-ssh-host-keys data" "$TRASHDIR/restore-out"

    # verify settings were imported
    grep -q "fake ghe-export-settings data" "$TRASHDIR/restore-out"

    # verify all repository data was transferred to the restore location
    diff -ru "$GHE_DATA_DIR/current/repositories" "$GHE_REMOTE_DATA_USER_DIR/repositories"

    # verify all pages data was transferred to the restore location
    diff -ru "$GHE_DATA_DIR/current/pages" "$GHE_REMOTE_DATA_USER_DIR/pages"

    # verify all hookshot user data was transferred
    diff -ru "$GHE_DATA_DIR/current/hookshot" "$GHE_REMOTE_DATA_USER_DIR/hookshot"

    # verify all git hooks data was transferred
    diff -ru "$GHE_DATA_DIR/current/git-hooks/environments/tarballs" "$GHE_REMOTE_DATA_USER_DIR/git-hooks/environments/tarballs"
    ! diff -ru "$GHE_DATA_DIR/current/git-hooks/environments" "$GHE_REMOTE_DATA_USER_DIR/git-hooks/environments"
    diff -ru "$GHE_DATA_DIR/current/git-hooks/repos" "$GHE_REMOTE_DATA_USER_DIR/git-hooks/repos"

    # verify all alambic assets user data was transferred
    diff -ru "$GHE_DATA_DIR/current/alambic_assets" "$GHE_REMOTE_DATA_USER_DIR/alambic_assets"

    # verify the UUID was transferred
    diff -ru "$GHE_DATA_DIR/current/uuid" "$GHE_REMOTE_DATA_USER_DIR/common/uuid"

    # verify ghe-export-ssl-ca-certificates was run
    grep -q "fake ghe-export-ssl-ca-certificates data" "$TRASHDIR/restore-out"

    # verify no config run after restore on unconfigured instance
    ! grep -q "ghe-config-apply OK" "$TRASHDIR/restore-out"

    # verify the audit log migration sentinel file has been created on 2.9 and above
    if [ "$GHE_VERSION_MAJOR" -eq 2 ] && [ "$GHE_VERSION_MINOR" -ge 9 ]; then
      [ -f "$GHE_REMOTE_DATA_USER_DIR/common/es-scan-complete" ]
    fi
)
end_test

begin_test "ghe-restore with host arg"
(
    set -e
    rm -rf "$GHE_REMOTE_ROOT_DIR"
    setup_remote_metadata

    # create file used to determine if instance has been configured.
    touch "$GHE_REMOTE_ROOT_DIR/etc/github/configured"

    # create file used to determine if instance is in maintenance mode.
    mkdir -p "$GHE_REMOTE_DATA_DIR/github/current/public/system"
    touch "$GHE_REMOTE_DATA_DIR/github/current/public/system/maintenance.html"

    # Create fake remote repositories dir
    mkdir -p "$GHE_REMOTE_DATA_USER_DIR/repositories"

    # set restore host environ var
    GHE_RESTORE_HOST=127.0.0.1
    export GHE_RESTORE_HOST

    # run it
    output="$(ghe-restore -f localhost)" || false

    # verify host arg overrides configured restore host
    echo "$output" | grep -q 'Connect localhost:22 OK'

    # verify repository data was transferred to the restore location
    diff -ru "$GHE_DATA_DIR/current/repositories" "$GHE_REMOTE_DATA_USER_DIR/repositories"

    # verify all pages data was transferred to the restore location
    diff -ru "$GHE_DATA_DIR/current/pages" "$GHE_REMOTE_DATA_USER_DIR/pages"

    # verify all hookshot user data was transferred
    diff -ru "$GHE_DATA_DIR/current/hookshot" "$GHE_REMOTE_DATA_USER_DIR/hookshot"

    diff -ru "$GHE_DATA_DIR/current/git-hooks/environments/tarballs" "$GHE_REMOTE_DATA_USER_DIR/git-hooks/environments/tarballs"
    ! diff -ru "$GHE_DATA_DIR/current/git-hooks/environments" "$GHE_REMOTE_DATA_USER_DIR/git-hooks/environments"
    diff -ru "$GHE_DATA_DIR/current/git-hooks/repos" "$GHE_REMOTE_DATA_USER_DIR/git-hooks/repos"

    # verify all alambic assets user data was transferred
    diff -ru "$GHE_DATA_DIR/current/alambic_assets" "$GHE_REMOTE_DATA_USER_DIR/alambic_assets"

    # verify the UUID was transferred
    diff -ru "$GHE_DATA_DIR/current/uuid" "$GHE_REMOTE_DATA_USER_DIR/common/uuid"

    # verify the audit log migration sentinel file has been created on 2.9 and above
    if [ "$GHE_VERSION_MAJOR" -eq 2 ] && [ "$GHE_VERSION_MINOR" -ge 9 ]; then
      [ -f "$GHE_REMOTE_DATA_USER_DIR/common/es-scan-complete" ]
    fi
)
end_test

begin_test "ghe-restore no host arg or configured restore host"
(
    set -e
    rm -rf "$GHE_REMOTE_ROOT_DIR"
    setup_remote_metadata

    # create file used to determine if instance has been configured.
    touch "$GHE_REMOTE_ROOT_DIR/etc/github/configured"

    # create file used to determine if instance is in maintenance mode.
    mkdir -p "$GHE_REMOTE_DATA_DIR/github/current/public/system"
    touch "$GHE_REMOTE_DATA_DIR/github/current/public/system/maintenance.html"

    # Create fake remote repositories dir
    mkdir -p "$GHE_REMOTE_DATA_USER_DIR/repositories"

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

    # create file used to determine if instance has been configured.
    touch "$GHE_REMOTE_ROOT_DIR/etc/github/configured"

    # create file used to determine if instance is in maintenance mode.
    mkdir -p "$GHE_REMOTE_DATA_DIR/github/current/public/system"
    touch "$GHE_REMOTE_DATA_DIR/github/current/public/system/maintenance.html"

    # Create fake remote repositories dir
    mkdir -p "$GHE_REMOTE_DATA_USER_DIR/repositories"

    # remove pages data
    rm -rf "$GHE_DATA_DIR/1/pages"

    # run it
    ghe-restore -v -f localhost
)
end_test

begin_test "ghe-restore with empty uuid file"
(
  set -e

  # Remove the UUID from the remote instance
  rm -f "$GHE_REMOTE_DATA_USER_DIR/common/uuid"

  # Zero-length the UUID file
  cat /dev/null > "$GHE_DATA_DIR/current/uuid"

  # Run a restore
  ghe-restore -v -f localhost

  # Verify no uuid is restored
  [ ! -f "$GHE_REMOTE_DATA_USER_DIR/common/uuid" ]

)
end_test

begin_test "ghe-restore with no uuid file"
(  set -e

  # Remove the UUID from the remote instance
  rm -f "$GHE_REMOTE_DATA_USER_DIR/common/uuid"

  # Remove the UUID file
  rm -f "$GHE_DATA_DIR/current/uuid"

  # Run a restore
  ghe-restore -v -f localhost

  # Verify no uuid is restored
  [ ! -f "$GHE_REMOTE_DATA_USER_DIR/common/uuid" ]

)
end_test

begin_test "ghe-restore cluster backup to non-cluster appliance"
(
    set -e
    rm -rf "$GHE_REMOTE_ROOT_DIR"
    setup_remote_metadata

    # create file used to determine if instance has been configured.
    touch "$GHE_REMOTE_ROOT_DIR/etc/github/configured"

    # create file used to determine if instance is in maintenance mode.
    mkdir -p "$GHE_REMOTE_DATA_DIR/github/current/public/system"
    touch "$GHE_REMOTE_DATA_DIR/github/current/public/system/maintenance.html"

    # Create fake remote repositories dir
    mkdir -p "$GHE_REMOTE_DATA_USER_DIR/repositories"

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

  SHARED_UTILS_PATH=$(dirname "$(which ghe-detect-leaked-ssh-keys)")
  # Inject the fingerprint into the blacklist
  echo 98:d8:99:d3:be:c0:55:05:db:b0:53:2f:1f:ad:b3:60 >> "$SHARED_UTILS_PATH/ghe-ssh-leaked-host-keys-list.txt"

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
  if [ "$GHE_VERSION_MAJOR" -ne 2 ] && [ "$GHE_VERSION_MINOR" -ne 11 ]; then
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
  if [ "$GHE_VERSION_MAJOR" -ne 2 ] && [ "$GHE_VERSION_MINOR" -ne 11 ]; then
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
