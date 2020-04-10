#!/usr/bin/env bash
# ghe-restore command tests run in parallel
set -e

export GHE_PARALLEL_ENABLED=yes

TESTS_DIR="$PWD/$(dirname "$0")"
# shellcheck source=test/test-ghe-restore.sh
. "$TESTS_DIR/test-ghe-restore.sh"
