#!/bin/sh
# ghe-prune-snapshots command tests

# Bring in testlib
. $(dirname "$0")/testlib.sh

# Setup backup snapshot data dir to use the per-test temp space.
GHE_DATA_DIR="$TRASHDIR/data"

# Create the backup data dir
mkdir -p "$GHE_DATA_DIR"

# helper for generating dirs to clean up
generate_prune_files() {
  prune_file_num=${1:-10}
  for i in $(seq 1 $prune_file_num); do
    mkdir -p "$GHE_DATA_DIR/prune_file_$i"
    # space creates apart because we only get seconds resolution
    sleep 1
  done
  ln -sf "$GHE_DATA_DIR/prune_file_$prune_file_num" "$GHE_DATA_DIR/current"
}

file_count_no_current() {
  ls -1d $GHE_DATA_DIR | grep -v current | wc -l | awk '{ print $1; }'
}

generate_prune_files 3

begin_test "ghe-prune-snapshots fails to run if isn't GHE_NUM_BACKUPS set"
(
  ghe-prune-snapshots
  res=$?
  if [ $res != 0 ]; then
    true
  else
    false
  fi
)
end_test

begin_test "ghe-prune-snapshots fails to run if GHE_NUM_BACKUPS isn't a number"
(
  GHE_NUM_BACKUPS=toast ghe-prune-snapshots
  res=$?
  if [ $res != 0 ]; then
    true
  else
    false
  fi
)
end_test


begin_test "ghe-prune-snapshots doesn't prune if threshold isn't reached"
(
  set -e

  pre_num_files=$(file_count_no_current)

  GHE_NUM_SNAPSHOTS=5 ghe-prune-snapshots

  post_num_files=$(file_count_no_current)

  if [ "$pre_num_files" = "$post_num_files" ]; then
    true
  else
    false
  fi
)
end_test

begin_test "ghe-prune-snapshots prunes if threshold is reached"
(
  set -e

  pre_num_files=$(file_count_no_current)

  GHE_NUM_SNAPSHOTS=2 ghe-prune-snapshots

  post_num_files=$(file_count_no_current)

  # make sure we have different number of files and right file is deleted
  if [ $pre_num_files -gt $post_num_files -a
       ! -f "$GHE_DATA_DIR/prune_file_1" ]; then
    true
  else
    false
  fi
)
end_test
