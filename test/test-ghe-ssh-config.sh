#!/usr/bin/env bash
# ghe-ssh command tests

# Bring in testlib
# shellcheck source=test/testlib.sh
. "$(dirname "$0")/testlib.sh"

begin_test "ghe-ssh-config returns config for multiple nodes"
(
  set -e

  output=$(ghe-ssh-config host1 git-server1 git-server2)
  # Confirm we don't have a host1 entry as this is the proxy host
  echo "$output" | grep -Evq "^Host host1"
  # Confirm we have a host2 and host3 entry
  echo "$output" | grep -Eq "^Host git-server[12]"
  [ "$(echo "$output" | grep -E "^Host git-server[12]" | wc -l)" -eq 2 ]
  # Confirm the host2 and host3 entries proxy though host1
  echo "$output" | grep -q "admin@host1 nc.openbsd"
  # Confirm multiplexing enabled
  echo "$output" | grep -q "ControlMaster=auto"
  # Confirm ControlPath returns correct hash for admin@host1:122
  echo "$output" | grep -q ".ghe-sshmux-84f6bdcf"
)
end_test

begin_test "ghe-ssh-config multiplexing disabled"
(
  set -e

  output=$(GHE_DISABLE_SSH_MUX=1 ghe-ssh-config host1 git-server1)
  echo "$output" | grep -vq "ControlMaster=auto"

  output=$(GHE_DISABLE_SSH_MUX=1 ghe-ssh-config host1 git-server1 git-server2)
  echo "$output" | grep -vq "ControlMaster=auto"
)
end_test

begin_test "ghe-ssh-config with extra SSH opts"
(
  set -e

  output=$(GHE_EXTRA_SSH_OPTS="-o foo=bar" ghe-ssh-config host1 git-server1)
  echo "$output" | grep -q "foo=bar"

  output=$(GHE_EXTRA_SSH_OPTS="-o foo=bar" ghe-ssh-config host1 git-server1 git-server2)
  echo "$output" | grep -q "foo=bar"
)
end_test
