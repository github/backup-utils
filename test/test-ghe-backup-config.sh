#!/usr/bin/env bash
# ghe-backup-config lib tests

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

begin_test "ghe-backup-config GHE_DATA_DIR defined"
(
  set +e
  GHE_DATA_DIR=
  error=$(. share/github-backup-utils/ghe-backup-config 2>&1)
  # should exit 2
  if [ $? != 2 ]; then
    exit 1
  fi
  set -e
  echo $error | grep -q "Error: GHE_DATA_DIR not set in config file."
)
end_test

begin_test "ghe-backup-config GHE_CREATE_DATA_DIR disabled"
(
  set -e

  export GHE_DATA_DIR="$TRASHDIR/create-enabled-data"
  export GHE_VERBOSE=1
  . share/github-backup-utils/ghe-backup-config |
    grep -q "Creating the backup data directory ..."
  test -d $GHE_DATA_DIR
  rm -rf $GHE_DATA_DIR

  export GHE_DATA_DIR="$TRASHDIR/create-disabled-data"
  export GHE_CREATE_DATA_DIR=no
  set +e
  error=$(. share/github-backup-utils/ghe-backup-config 2>&1)
  # should exit 8
  if [ $? != 8 ]; then
    exit 1
  fi
  set -e
  echo $error | grep -q "Error: GHE_DATA_DIR .* does not exist"

  rm -rf $GHE_DATA_DIR
)
end_test

begin_test "ghe-backup-config run on GHE appliance"
(
  set -e

  export GHE_RELEASE_FILE="$TRASHDIR/enterprise-release"
  touch "$GHE_RELEASE_FILE"
  set +e
  error=$(. share/github-backup-utils/ghe-backup-config 2>&1)
  # should exit 1
  if [ $? != 1 ]; then
    exit 1
  fi
  set -e
  echo "$error" | grep -q "Error: Backup Utils cannot be run on the GitHub Enterprise host."

  test -f "$GHE_RELEASE_FILE"
  rm -rf "$GHE_RELEASE_FILE"
)
end_test

begin_test "ghe-backup-config ssh_host_part"
(
  set -e
  [ "$(ssh_host_part 'github.example.com')" = "github.example.com" ]
  [ "$(ssh_host_part 'github.example.com:22')" = "github.example.com" ]
  [ "$(ssh_host_part 'github.example.com:5000')" = "github.example.com" ]
  [ "$(ssh_host_part 'git@github.example.com:5000')" = "git@github.example.com" ]
)
end_test

begin_test "ghe-backup-config ssh_port_part"
(
  set -e
  [ "$(ssh_port_part 'github.example.com')" = "122" ]
  [ ! "$(ssh_port_part 'github.example.com:22' 2>/dev/null)" ]
  [ ! "$(ssh_port_part 'github.example.com:5000' 2>/dev/null)" ]
  [ "$(ssh_port_part 'git@github.example.com:122')" = "122" ]
)
end_test

begin_test "ghe-backup-config ghe_parse_remote_version v2.x series"
(
  set -e

  ghe_parse_remote_version "v2.0.0"
  [ "$GHE_VERSION_MAJOR" = "2" ]
  [ "$GHE_VERSION_MINOR" = "0" ]
  [ "$GHE_VERSION_PATCH" = "0" ]

  ghe_parse_remote_version "2.0.0"
  [ "$GHE_VERSION_MAJOR" = "2" ]
  [ "$GHE_VERSION_MINOR" = "0" ]
  [ "$GHE_VERSION_PATCH" = "0" ]

  ghe_parse_remote_version "v2.1.5"
  [ "$GHE_VERSION_MAJOR" = "2" ]
  [ "$GHE_VERSION_MINOR" = "1" ]
  [ "$GHE_VERSION_PATCH" = "5" ]

  ghe_parse_remote_version "v2.1.5.ldapfix1"
  [ "$GHE_VERSION_MAJOR" = "2" ]
  [ "$GHE_VERSION_MINOR" = "1" ]
  [ "$GHE_VERSION_PATCH" = "5" ]

  ghe_parse_remote_version "v2.1.5pre"
  [ "$GHE_VERSION_MAJOR" = "2" ]
  [ "$GHE_VERSION_MINOR" = "1" ]
  [ "$GHE_VERSION_PATCH" = "5" ]
)
end_test

begin_test "ghe-backup-config verbose log redirects to file"
(
  set -e

  export GHE_VERBOSE=1
  export GHE_VERBOSE_LOG="$TRASHDIR/verbose.log"
  . "share/github-backup-utils/ghe-backup-config"
  ghe_verbose "Hello world"
  [ "$(wc -l <"$GHE_VERBOSE_LOG")" -gt 0 ]
  unset GHE_VERBOSE
  unset GHE_VERBOSE_LOG
)

begin_test "ghe-backup-config verbose log redirects to file under parallel"
(
  set -e

  export GHE_PARALLEL_ENABLED=yes
  export GHE_VERBOSE=1
  export GHE_VERBOSE_LOG="$TRASHDIR/verbose.log"
  . "share/github-backup-utils/ghe-backup-config"
  ghe_verbose "Hello world"
  for i in {1..5}
  do
    if [ "$(wc -l <"$GHE_VERBOSE_LOG")" -gt 0 ]; then
      unset GHE_VERBOSE
      unset GHE_VERBOSE_LOG
      exit 0
    fi
    echo "Waiting for log file to be written $i"
    sleep 1
  done

  exit 1
)
end_test

begin_test "ghe-backup-config ghe_debug accepts stdin as well as argument"
(
  set -e

  export GHE_DEBUG=1
  export GHE_VERBOSE=1
  export GHE_VERBOSE_LOG="$TRASHDIR/verbose.log"
  . "share/github-backup-utils/ghe-backup-config"

  ghe_debug "debug arg"
  grep -q "debug arg" ${GHE_VERBOSE_LOG}

  echo "debug stdin" | ghe_debug
  grep -q "debug stdin" ${GHE_VERBOSE_LOG}

  unset GHE_DEBUG
  unset GHE_VERBOSE
  unset GHE_VERBOSE_LOG
)
end_test

begin_test "ghe-backup-config is_service_external enabled external mysql"
(
  set -e

  tmpfile=$(mktemp /tmp/abc-script.XXXXXX)
  echo "
[mysql \"external\"]
  enabled = true
" > $tmpfile
  is_service_external 'mysql' $tmpfile
)
end_test

begin_test "ghe-backup-config is_service_external disabled external mysql"
(
  set -e

  tmpfile=$(mktemp /tmp/abc-script.XXXXXX)
  echo "
[mysql \"external\"]
  enabled = false
" > $tmpfile

  ! is_service_external 'mysql' $tmpfile
)
end_test

begin_test "ghe-backup-config is_service_external unknown service"
(
  set -e

  tmpfile=$(mktemp /tmp/abc-script.XXXXXX)
  echo "
[mysql \"external\"]
  enabled = false
" > $tmpfile

  ! is_service_external 'hubot' $tmpfile
)
end_test
