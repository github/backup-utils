#!/usr/bin/env bash
# get-rsync-size.sh Get the total size of dir-files to be transfered using rsync --link-dest
#
# Example:
#   transfer_size repositories /dest_dir
#
# Sample output:
#   Total transferred file size: 80 bytes

# Bring in the backup configuration
# shellcheck source=share/github-backup-utils/ghe-backup-config
. "$(dirname "${BASH_SOURCE[0]}")/ghe-backup-config"

# Location of last good backup for rsync --link-dest
backup_current="$GHE_DATA_DIR/current/"

# If we have a previous increment, avoid using those unchanged files using --link-dest support.
if [ -d "$backup_current" ]; then
  link_dest="--link-dest=${GHE_DATA_DIR}/current"
fi

transfer_size()
{
  local backup_data=$1
  local data_user_dir=/data/user/$1/
  local dest_dir=$2/

  # Define user for rsync-path
  case "$backup_data" in
  "repositories" | "pages")
    user="git"
    ;;
  "storage")
    user="alambic"
    ;;
  "elasticsearch")
    user="elasticsearch"
    ;;
  "mysql")
    user="mysql"
    ;;
  "mssql")
    user="mssql"
    ;;
  "minio")
    user="minio"
    ;;
  *)
    echo "Unknown user: $backup_data"
    exit 1
    ;;
  esac

  total_file_size=$(ghe-rsync -arn --stats \
      -e "ssh -q $GHE_EXTRA_SSH_OPTS -p 122 -l admin" \
      --rsync-path="sudo -u $user rsync" \
      $link_dest/$1 \
      --ignore-missing-args \
      "$GHE_HOSTNAME:$data_user_dir/" \
      "$dest_dir" | grep "Total transferred file size" | sed 's/.*size: //; s/,//g')
  echo "$total_file_size" 
}
