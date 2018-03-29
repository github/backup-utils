#!/usr/bin/env bash

BASE_PATH=$(cd "$(dirname "$0")/../" && pwd)

# Bring in testlib
# shellcheck source=test/testlib.sh
. "$(dirname "$0")/testlib.sh"

begin_test "shellcheck: reports no errors or warnings"
(
  set -e
  if ! type shellcheck 1>/dev/null 2>&1; then
    echo "ShellCheck not installed."
    skip_test
  fi

  results=$(mktemp $TRASHDIR/shellcheck.XXXXXX)

  # Check all executable scripts checked into the repo
  cd $BASE_PATH
  git ls-tree -r HEAD | grep -E '^1007|.*\..*sh$' | awk '{print $4}' | while read -r script; do
    if head -n1 "$script" | grep -E -w "sh|bash" >/dev/null 2>&1; then
      shellcheck -a -f gcc $script 2>&1 | grep -v ": note:" >> $results || true
    fi
  done
  cd -

  [ "$(cat $results | wc -l)" -eq 0 ] || {
    echo "ShellCheck errors found: "
    cat $results
    exit 1
  }
)
end_test
