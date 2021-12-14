#!/usr/bin/env bash
# ghe-ssh command tests

# Bring in testlib
# shellcheck source=test/testlib.sh
. "$(dirname "$0")/testlib.sh"

export CLUSTER_CONF="$ROOTDIR/test/cluster.conf"

begin_test "ghe-ssh-config returns config for git-server nodes"
(
  set -e

  output=$(GIT_CONFIG=$CLUSTER_CONF ghe-ssh-config host1 git-server-1451687c-4be0-11ec-8684-02c387bd966b git-server-16089d52-4be0-11ec-b892-026c4c5e5bb1)
  # Confirm we don't have a host1 entry as this is the proxy host
  [ "$(echo "$output" | grep -c "^Host host1")" -eq 0 ]
  # Confirm we have git-server-<uuid> entries
  echo "$output" | grep -Eq "^Host git-server-[A-Za-z0-9]{8}-[A-Za-z0-9]{4}-[A-Za-z0-9]{4}-[A-Za-z0-9]{4}-[A-Za-z0-9]{12}"
  echo "$output" | grep -Eq "pages-server-[A-Za-z0-9]{8}-[A-Za-z0-9]{4}-[A-Za-z0-9]{4}-[A-Za-z0-9]{4}-[A-Za-z0-9]{12}"
  echo "$output" | grep -Eq "storage-server-[A-Za-z0-9]{8}-[A-Za-z0-9]{4}-[A-Za-z0-9]{4}-[A-Za-z0-9]{4}-[A-Za-z0-9]{12}"
  [ "$(echo "$output" | grep -Ec "^Host git-server-[A-Za-z0-9]{8}-[A-Za-z0-9]{4}-[A-Za-z0-9]{4}-[A-Za-z0-9]{4}-[A-Za-z0-9]{12}")" -eq 2 ]
  # Confirm the git-server entries has right IP
  echo "$output" | grep -q "HostName 172.31.22.90"
  echo "$output" | grep -q "HostName 172.31.26.173"
  # Confirm No proxy enabled
  [ "$(echo "$output" | grep -c "ProxyCommand")" -eq 0 ]
)
end_test

begin_test "ghe-ssh-config returns config for git-server nodes with GHE_SSH_PROXY=1"
(
  set -e

  output=$(GIT_CONFIG=$CLUSTER_CONF GHE_SSH_PROXY=1 ghe-ssh-config host1 git-server-1451687c-4be0-11ec-8684-02c387bd966b git-server-16089d52-4be0-11ec-b892-026c4c5e5bb1)
  # Confirm we don't have a host1 entry as this is the proxy host
  [ "$(echo "$output" | grep -c "^Host host1")" -eq 0 ]
  # Confirm we have git-server-<uuid> entries
  echo "$output" | grep -Eq "^Host git-server-[A-Za-z0-9]{8}-[A-Za-z0-9]{4}-[A-Za-z0-9]{4}-[A-Za-z0-9]{4}-[A-Za-z0-9]{12}"
  echo "$output" | grep -Eq "pages-server-[A-Za-z0-9]{8}-[A-Za-z0-9]{4}-[A-Za-z0-9]{4}-[A-Za-z0-9]{4}-[A-Za-z0-9]{12}"
  echo "$output" | grep -Eq "storage-server-[A-Za-z0-9]{8}-[A-Za-z0-9]{4}-[A-Za-z0-9]{4}-[A-Za-z0-9]{4}-[A-Za-z0-9]{12}"
  [ "$(echo "$output" | grep -Ec "^Host git-server-[A-Za-z0-9]{8}-[A-Za-z0-9]{4}-[A-Za-z0-9]{4}-[A-Za-z0-9]{4}-[A-Za-z0-9]{12}")" -eq 2 ]
  # Confirm the git-server entries has right IP
  echo "$output" | grep -q "HostName 172.31.22.90"
  echo "$output" | grep -q "HostName 172.31.26.173"
  # Confirm proxy enabled
  [ "$(echo "$output" | grep -c "ProxyCommand")" -eq 2 ]

  # Confirm ControlPath returns correct hash for admin@host1:122
  echo "$output" | grep -q "admin@host1 nc.openbsd"
  # Confirm multiplexing enabled
  echo "$output" | grep -q "ControlMaster=auto"
  # Confirm ControlPath returns correct hash for admin@host1:122
  echo "$output" | grep -q ".ghe-sshmux-7cb77002"
)
end_test


begin_test "ghe-ssh-config returns config for non-server-uuid nodes"
(
  set -e

  output=$(GIT_CONFIG=$CLUSTER_CONF ghe-ssh-config host1 mysql-node1 mysql-node2)
  # Confirm we don't have a host1 entry as this is the proxy host
  echo "$output" | grep -Evq "^Host host1"
  # Confirm we have a host2 and host3 entry
  echo "$output" | grep -Eq "^Host mysql-node[12]"
  [ "$(echo "$output" | grep -c "^Host mysql-node[12]")" -eq 2 ]
  # Confirm the host2 and host3 entries proxy though host1
  echo "$output" | grep -q "admin@host1 nc.openbsd"
  # Confirm multiplexing enabled
  echo "$output" | grep -q "ControlMaster=auto"
  # Confirm ControlPath returns correct hash for admin@host1:122
  echo "$output" | grep -q ".ghe-sshmux-7cb77002"
)
end_test

begin_test "ghe-ssh-config multiplexing disabled"
(
  set -e

  output=$(GIT_CONFIG=$CLUSTER_CONF GHE_DISABLE_SSH_MUX=1 ghe-ssh-config host1 git-server1)
  echo "$output" | grep -vq "ControlMaster=auto"

  output=$(GIT_CONFIG=$CLUSTER_CONF GHE_DISABLE_SSH_MUX=1 ghe-ssh-config host1 git-server1 git-server2)
  echo "$output" | grep -vq "ControlMaster=auto"

  # Confirm multiplexing disabled
  [ "$(echo "$output" | grep -c "ControlMaster=auto")" -eq 0 ]
  [ "$(echo "$output" | grep -c ".ghe-sshmux-7cb77002")" -eq 0 ]
)
end_test

begin_test "ghe-ssh-config with extra SSH opts"
(
  set -e

  output=$(GIT_CONFIG=$CLUSTER_CONF GHE_EXTRA_SSH_OPTS="-o foo=bar" ghe-ssh-config host1 git-server1)
  echo "$output" | grep -q "foo=bar"

  output=$(GIT_CONFIG=$CLUSTER_CONF GHE_EXTRA_SSH_OPTS="-o foo=bar" ghe-ssh-config host1 git-server1 git-server2)
  echo "$output" | grep -q "foo=bar"
)
end_test
