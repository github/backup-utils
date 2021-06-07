#!/usr/bin/env bash
# ghe-host-check command tests

# Bring in testlib
# shellcheck source=test/testlib.sh
. "$(dirname "$0")/testlib.sh"

begin_test "ghe-host-check"
(
  set -e
  ghe-host-check

  ghe-host-check | grep OK
  ghe-host-check | grep localhost
)
end_test


begin_test "ghe-host-check with host arg"
(
  set -e
  ghe-host-check example.com

  ghe-host-check example.com | grep OK
  ghe-host-check example.com | grep example.com
)
end_test

begin_test "ghe-host-check honours --version flag"
(
  set -e

  # Make sure a partial version string is returned
  ghe-host-check --version | grep "GitHub backup-utils v"

)
end_test

begin_test "ghe-host-check honours --help and -h flags"
(
  set -e

  arg_help=$(ghe-host-check --help | grep -o 'Usage: ghe-host-check')
  arg_h=$(ghe-host-check -h | grep -o 'Usage: ghe-host-check')

  # Make sure a Usage: string is returned and that it's the same for -h and --help
  [ "$arg_help" = "$arg_h" ] && echo $arg_help | grep -q "Usage: ghe-host-check"

)
end_test

begin_test "ghe-host-check detects unsupported GitHub Enterprise Server versions"
(
  set -e
  # shellcheck disable=SC2046 # Word splitting is required to populate the variables
  read -r bu_version_major bu_version_minor _ <<<$(ghe_parse_version $BACKUP_UTILS_VERSION)

  ! GHE_TEST_REMOTE_VERSION=11.340.36 ghe-host-check
  # hardcode until https://github.com/github/backup-utils/issues/675 is resolved
  ! GHE_TEST_REMOTE_VERSION=2.20.0 ghe-host-check
  ! GHE_TEST_REMOTE_VERSION=2.21.0 ghe-host-check
  GHE_TEST_REMOTE_VERSION=2.22.0 ghe-host-check
  GHE_TEST_REMOTE_VERSION=3.0.0 ghe-host-check
  GHE_TEST_REMOTE_VERSION=$BACKUP_UTILS_VERSION ghe-host-check
  GHE_TEST_REMOTE_VERSION=$BACKUP_UTILS_VERSION ghe-host-check
  GHE_TEST_REMOTE_VERSION=$bu_version_major.$bu_version_minor.999 ghe-host-check
  GHE_TEST_REMOTE_VERSION=$bu_version_major.$bu_version_minor.999gm1 ghe-host-check
  ! GHE_TEST_REMOTE_VERSION=3.9999.1521793591.performancetest ghe-host-check
  GHE_TEST_REMOTE_VERSION=$((bu_version_major+1)).0.0 ghe-host-check
)
end_test

begin_test "ghe-host-check detects high availability replica"
(
  set -e
  echo "primary" > "$GHE_REMOTE_ROOT_DIR/etc/github/repl-state"
  ghe-host-check

  echo "replica" > "$GHE_REMOTE_ROOT_DIR/etc/github/repl-state"
  ! ghe-host-check
  GHE_ALLOW_REPLICA_BACKUP=yes ghe-host-check
)
end_test

begin_test "ghe-host-check blocks restore to old release"
(
  set -e
  
  mkdir -p "$GHE_DATA_DIR/current/"
  echo "$GHE_TEST_REMOTE_VERSION" > "$GHE_DATA_DIR/current/version"

  # shellcheck disable=SC2046 # Word splitting is required to populate the variables
  read -r bu_version_major bu_version_minor bu_version_patch <<<$(ghe_parse_version $GHE_TEST_REMOTE_VERSION)
  ! GHE_TEST_REMOTE_VERSION=$bu_version_major.$((bu_version_minor-1)).$bu_version_patch ghe-restore -v
)
end_test
