#!/usr/bin/env bash
# Docker image build tests

# If docker is not installed, skip the whole docker test
# Travis CI does not currently support docker on OSX (https://docs.travis-ci.com/user/docker/)
if ! docker ps >/dev/null 2>&1; then
  echo "Docker is not installed or running on this host"
  exit 0
fi

# Bring in testlib
# shellcheck source=test/testlib.sh
. "$(dirname "$0")/testlib.sh"

# Setup backup snapshot data dir and remote repositories dir locations to use
# the per-test temp space.
GHE_DATA_DIR="$TRASHDIR/data"
GHE_REMOTE_DATA_DIR="$TRASHDIR/remote"
export GHE_DATA_DIR GHE_REMOTE_DATA_DIR

# Source in the config script
cd "$ROOTDIR"
. "share/github-backup-utils/ghe-backup-config"

begin_test "docker build completes successfully"
(
  set -e

  docker build -q -t github/backup-utils:test . | grep "sha256:"
)
end_test

begin_test "docker run completes successfully"
(
  set -e

  docker run --rm -t github/backup-utils:test ghe-host-check --version | grep "GitHub backup-utils "
)
end_test

begin_test "docker GHE_ env variables set in backup.config"
(
  set -e

  docker run --rm -e "GHE_TEST_VAR=test" -t github/backup-utils:test cat /etc/github-backup-utils/backup.config | grep "GHE_TEST_VAR=\"test\""
)
end_test

begin_test "docker GHE_ env variables with spaces set in backup.config"
(
  set -e

  docker run --rm -e "GHE_TEST_VAR=test with a space" -t github/backup-utils:test cat /etc/github-backup-utils/backup.config | grep "GHE_TEST_VAR=\"test with a space\""
)
end_test

begin_test "docker Non GHE_ env variables not set in backup.config"
(
  set -e

  docker run --rm -e "GHE_TEST_VAR=test" -e "NGHE_TEST_VAR=test" -t github/backup-utils:test grep -L "NGHE_TEST_VAR=\"test\"" /etc/github-backup-utils/backup.config | grep /etc/github-backup-utils/backup.config
)
end_test
