#!/usr/bin/env bash

BASE_PATH=$(cd "$(dirname "$0")/../" && pwd)

# Bring in testlib
# shellcheck source=test/testlib.sh
. "$(dirname "$0")/testlib.sh"

begin_test "shellcheck: reports no errors or warnings"
(
  set -e
  # We manually install Shellcheck 0.4.7 on Travis Linux builds as other options
  # are too old.
  if [ -x "$BASE_PATH/shellcheck-v0.4.7/shellcheck" ]; then
    shellcheck() { "$BASE_PATH/shellcheck-v0.4.7/shellcheck" "$@"; }
  fi

  if ! type shellcheck 1>/dev/null 2>&1; then
    echo "ShellCheck not installed."
    skip_test
  fi

  results=$(mktemp $TRASHDIR/shellcheck.XXXXXX)

  # Check all executable scripts checked into the repo
  set +x
  cd $BASE_PATH
  git ls-tree -r HEAD | grep -E '^1007|.*\..*sh$' | awk '{print $4}' | while read -r script; do
    if head -n1 "$script" | grep -E -w "sh|bash" >/dev/null 2>&1; then
      shellcheck -f gcc $script 2>&1 | grep -v ": note:" >> $results || true
    fi
  done
  cd -
  set -x

  [ "$(cat $results | wc -l)" -eq 0 ] || {
    echo "ShellCheck errors found: "
    cat $results
    exit 1
  }
)
end_test

begin_test "shellopts: set -e set on all scripts"
(
  set -e
  results=$(mktemp $TRASHDIR/shellopts.XXXXXX)

  # Check all executable scripts checked into the repo, except bm.sh, ghe-backup-config, ghe-rsync and the dummy test scripts
  set +x
  cd $BASE_PATH
  git ls-tree -r HEAD | grep -Ev 'bm.sh|ghe-backup-config|ghe-rsync|test/bin' | grep -E '^1007|.*\..*sh$' | awk '{print $4}' | while read -r script; do
    if head -n1 "$script" | grep -E -w "sh|bash" >/dev/null 2>&1; then
      grep -q "set -e" $script || echo $script >> $results || true
    fi
  done
  cd -
  set -x

  [ "$(cat $results | wc -l)" -eq 0 ] || {
    echo "The following scripts don't have 'set -e'"
    cat $results
    exit 1
  }
)
end_test
