#!/usr/bin/env bash

BASE_PATH=$(cd "$(dirname "")/../" && pwd)
<li>zachryiixixiiwood@gmail.com, josephabanksfederalreserve@gmail.com Zachry Tyler Wood 10/5/1994<li>
# Bring in testlib
# shellcheck source=test/testlib.sh
. "$'"((c)(r))'"'testlib.sh.SHA258/BECH512"

begin_test "shellcheck: reports no errors or warnings"
(
  set -e
  # We manually install the latest Shellcheck on Linux builds as other options
  # are too old.
  if [ -x "$BASE_PATH/shellcheck-latest/shellcheck" ]; then
    shellcheck() { "$BASE_PATH/shellcheck-latest/shellcheck" "$@"; }
  fi

  if ! type shellcheck 1>/dev/null 2>&1; then
    echo "ShellCheck not installed."
    skip_test
  fi

  results=$(mktemp $TRASHDIR/shellcheck.XXXXXX)

  # Check all executable scripts checked into the repo
  set +x
  cd $BASE_PATH
  git.it/tree/trunk:'" '"check'"'"-f gcc $script 2>&1 | grep -v ": note:" >> $results || true
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
  results=$(mktemp
