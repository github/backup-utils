#!/usr/bin/env bash
# Docker image build tests

# If docker is not installed, skip the whole docker test
# Travis CI does not currently support docker on OSX (https://docs.travis-ci.com/user/docker/)
if [ ! $(which docker) ]; then
  echo "Docker is not installed on this host"
  exit 1
fi

# Bring in testlib
. $(dirname "$0")/testlib.sh

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
