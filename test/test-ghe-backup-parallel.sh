#!/usr/bin/env bash
# ghe-backup command tests run in parallel
set -e

export GHE_PARALLEL_ENABLED=yes

TESTS_DIR="$PWD/$(dirname "$0")"
# shellcheck source=test/test-ghe-backup.sh
. "$TESTS_DIR/test-ghe-backup.sh"
