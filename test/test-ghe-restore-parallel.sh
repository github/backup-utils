#!/usr/bin/env bash
# ghe-restore command tests run in parallel
set -e

# Currently disabled on macOS due to rsync issues
if [[ "$OSTYPE" == "darwin"* ]]; then
  echo "Skipping $(basename "$0") tests as they are temporarily disabled on macOS: https://github.com/github/backup-utils/issues/841"
  exit 0
fi

# Overwrite default test suite name to distinguish it from test-ghe-restore
export GHE_TEST_SUITE_NAME="test-ghe-restore-parallel"

export GHE_PARALLEL_ENABLED=yes

# use temp dir to fix rsync file issues in parallel execution:
# we are imitating remote server by local files, and running rsync in parallel may cause
# race conditions when two processes writing to same folder
parallel_rsync_tempdir=$(mktemp -d -t backup-utils-restore-temp-XXXXXX)
export GHE_EXTRA_RSYNC_OPTS="--copy-dirlinks --temp-dir=$parallel_rsync_tempdir"

TESTS_DIR="$PWD/$(dirname "$0")"
# shellcheck source=test/test-ghe-restore.sh
. "$TESTS_DIR/test-ghe-restore.sh"
