#!/usr/bin/env bash
# bm.sh: benchmarking Bash code blocks
#
# Example:
#   bm_start "wget request"
#   wget --quiet https://www.google.com
#   bm_end "wget request"
#
# Sample output:
#   $ bash test.sh
#   wget request took 2s

bm_desc_to_varname(){
 echo "__bm$(echo $@ | tr -cd '[[:alnum:]]')"
}

bm_start()
{
  eval "$(bm_desc_to_varname $@)_start=$(date +%s)"

  bm_init > /dev/null
}

bm_init() {
  if [ -n "$BM_FILE_PATH" ]; then
    echo $BM_FILE_PATH
    return
  fi

  local logfile="benchmark.${BM_TIMESTAMP:-$(date +"%Y%m%dT%H%M%S")}.log"
  if [ -n "$GHE_RESTORE_SNAPSHOT_PATH" ]; then
    export BM_FILE_PATH=$GHE_RESTORE_SNAPSHOT_PATH/benchmarks/$logfile
  else
    export BM_FILE_PATH=$GHE_SNAPSHOT_DIR/benchmarks/$logfile
  fi

  mkdir -p $(dirname $BM_FILE_PATH)
  echo $BM_FILE_PATH
}

bm_end() {
  if [ -z "$BM_FILE_PATH" ]; then
    echo "Call bm_start first" >&2
    exit 1
  fi

  local tend=$(date +%s)
  local tstart=$(eval "echo \$$(bm_desc_to_varname $@)_start")

  echo "$1 took $(($tend - $tstart))s" >> $BM_FILE_PATH
}
