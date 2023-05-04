#!/usr/bin/env bash
#/ Usage: ghe-rsync-feature-checker <rsync-command>
#/ returns true if the passed rsync command is supported by the current version of rsync
#/ returns false if the passed rsync command is not supported by the current version of rsync
#/

set -o pipefail

# set the variable from the first argument and remove any leading dashes
rsync_command=$(echo "$1" | sed -E 's/^-+//')

echo "rsync_command: $rsync_command"

# check if the passed rsync command is supported by the current version of rsync
if rsync -h | grep -E "\B-+($rsync_command)\b" >/dev/null 2>&1; then
  echo "true"
else
  echo "false"
fi