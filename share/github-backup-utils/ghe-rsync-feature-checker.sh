#!/usr/bin/env bash
#/ Usage: ghe-rsync-feature-checker <rsync-command>
#/ returns true if the passed rsync command is supported by the current version of rsync
#/ returns false if the passed rsync command is not supported by the current version of rsync
#/

set -o pipefail

# set the variable from the first argument
rsync_command="$1"

# strip -- from the passed rsync command
rsync_command="${rsync_command/--/}"

# check if the passed rsync command is supported by the current version of rsync
if rsync -h | grep "$rsync_command" >/dev/null 2>&1; then
  echo "true"
else
  echo "false"
fi