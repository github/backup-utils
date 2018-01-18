#!/usr/bin/env bash
# ghe-detect-leaked-ssh-keys command tests

# Bring in testlib
# shellcheck source=test/testlib.sh
. "$(dirname "$0")/testlib.sh"

# Add some fake repositories to the snapshot
mkdir -p "$GHE_DATA_DIR/1"

# Make the current symlink
ln -s 1 "$GHE_DATA_DIR/current"

# Make another backup snapshot based on 1
cp -r "$GHE_DATA_DIR/1" "$GHE_DATA_DIR/2"

# Add a custom ssh key that will be used as part of the backup and fingerprint injection for the tests
cat <<EOF > "$GHE_DATA_DIR/ssh_host_dsa_key.pub"
ssh-dss AAAAB3NzaC1kc3MAAACBAMv7O3YNWyAOj6Oa6QhG2qL67FSDoR96cYILilsQpn1j+f21uXOYBRdqauP+8XS2sPYZy6p/T3gJhCeC6ppQWY8n8Wjs/oS8j+nl5KX7JbIqzvSIb0tAKnMI67pqCHTHWx+LGvslgRALJuGxOo7Bp551bNN02Y2gfm2TlHOv6DarAAAAFQChqAK2KkHI+WNkFj54GwGYdX+GCQAAAIEApmXYiT7OYXfmiHzhJ/jfT1ZErPAOwqLbhLTeKL34DkAH9J/DImLAC0tlSyDXjlMzwPbmECdu6LNYh4OZq7vAN/mcM2+Sue1cuJRmkt5B1NYox4fRs3o9RO+DGOcbogUUUQu7OIM/o95zF6dFEfxIWnSsmYvl+Ync4fEgN6ZLjtMAAACBAMRYjDs0g1a9rocKzUQ7fazaXnSNHxZADQW6SIodt7ic1fq4OoO0yUoBf/DSOF8MC/XTSLn33awI9SrbQ5Kk0oGxmV1waoFkqW/MDlypC8sHG0/gxzeJICkwjh/1OVwF6+e0C/6bxtUwV/I+BeMtZ6U2tKy15FKp5Mod7bLBgiee test@backup-utils
EOF

begin_test "ghe-detect-leaked-ssh-keys check -h displays help message"
(
  set -e

  ghe-detect-leaked-ssh-keys -h | grep "\-\-help"
)
end_test

begin_test "ghe-detect-leaked-ssh-keys clean snapshot test, no messages"
(
  set -e

  # Test that there are no Leaked key messages
  ! ghe-detect-leaked-ssh-keys | grep -q "Leaked key"
)
end_test

begin_test "ghe-detect-leaked-ssh-keys leaked keys in current backup"
(
  set -e

  # Add custom key to tar file
  tar -cf "$GHE_DATA_DIR/1/ssh-host-keys.tar" --directory="$GHE_DATA_DIR" ssh_host_dsa_key.pub

  FINGERPRINT_BLACKLIST="98:d8:99:d3:be:c0:55:05:db:b0:53:2f:1f:ad:b3:60" ghe-detect-leaked-ssh-keys -s "$GHE_DATA_DIR/1" | grep "Leaked key found in current backup snapshot"
)
end_test

begin_test "ghe-detect-leaked-ssh-keys leaked keys in old snapshot"
(
  set -e

  # Add custom key to tar file in the older snapshot directory
  tar -cf "$GHE_DATA_DIR/2/ssh-host-keys.tar" --directory="$GHE_DATA_DIR" ssh_host_dsa_key.pub

  output=$(FINGERPRINT_BLACKLIST="98:d8:99:d3:be:c0:55:05:db:b0:53:2f:1f:ad:b3:60" ghe-detect-leaked-ssh-keys -s "$GHE_DATA_DIR/2")
  ! echo $output | grep -q "Leaked key in current backup"
  echo $output | grep -q "One or more older backup snapshots"
)
end_test
