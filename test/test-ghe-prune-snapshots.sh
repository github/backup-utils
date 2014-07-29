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
  rm -rf "$GHE_DATA_DIR/*"
  prune_file_num=${1:-10}
  for i in $(seq 1 $prune_file_num); do
    mkdir -p "$GHE_DATA_DIR/$i"
  done
  ln -sf "$prune_file_num" "$GHE_DATA_DIR/current"
}

file_count_no_current() {
  ls -1d "$GHE_DATA_DIR"/[0-9]* | wc -l
}

generate_prune_files 3

begin_test "ghe-prune-snapshots uses default when GHE_NUM_BACKUPS not set"
(
    set -e
    generate_prune_files 12
    ghe-prune-snapshots
    [ $(ls -1d "$GHE_DATA_DIR"/[0-9]* | wc -l) -eq 2 ]
)
end_test

begin_test "ghe-prune-snapshots fails if GHE_NUM_SNAPSHOTS isn't a number"
(
  set -e
  GHE_NUM_SNAPSHOTS=toast ghe-prune-snapshots
)
end_test


begin_test "ghe-prune-snapshots doesn't prune if threshold isn't reached"
(
  set -e

  generate_prune_files 5

  pre_num_files=$(file_count_no_current)

  GHE_NUM_SNAPSHOTS=5 ghe-prune-snapshots

  post_num_files=$(file_count_no_current)

  [ "$pre_num_files" = "$post_num_files" ]
)
end_test

begin_test "ghe-prune-snapshots prunes if threshold is reached"
(
  set -e

  generate_prune_files 4

  pre_num_files=$(file_count_no_current)

  GHE_NUM_SNAPSHOTS=2 ghe-prune-snapshots

  post_num_files=$(file_count_no_current)

  # make sure we have different number of files and right file is deleted
  [ $post_num_files -eq 3 -a ! -f "$GHE_DATA_DIR/1" -a ! -f "$GHE_DATA_DIR/2" ]
)
end_test


begin_test "ghe-prune-snapshots prunes incomplete snapshots"
(
    set -e

    generate_prune_files 5

    touch "$GHE_DATA_DIR/4/incomplete"

    GHE_NUM_SNAPSHOTS=5 ghe-prune-snapshots

    [ $(file_count_no_current) -eq 4 ]
    [ ! -d "$GHE_DATA_DIR/4" ]
)
end_test
