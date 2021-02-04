# Scheduling backups

Regular backups should be scheduled using `cron(8)` or similar command
scheduling service on the backup host. The backup frequency will dictate the
worst case [recovery point objective (RPO)][1] in your backup plan. We recommend
hourly backups at the least.

## Example scheduling usage

The following examples assume the Backup Utilities are installed under
`/opt/backup-utils`. The crontab entry should be made under the same user that
manual backup/recovery commands will be issued under and must have write access
to the configured `GHE_DATA_DIR` directory.

Note that the `GHE_NUM_SNAPSHOTS` option in `backup.config` should be tuned
based on the frequency of backups. The ten most recent snapshots are retained by
default. The number should be adjusted based on backup frequency and available
storage.

To schedule hourly backup snapshots with verbose informational output written to
a log file and errors generating an email:

    MAILTO=admin@example.com

    0 * * * * /opt/backup-utils/bin/ghe-backup -v 1>>/opt/backup-utils/backup.log 2>&1

To schedule nightly backup snapshots instead, use:

    MAILTO=admin@example.com

    0 0 * * * /opt/backup-utils/bin/ghe-backup -v 1>>/opt/backup-utils/backup.log 2>&1


[1]: https://en.wikipedia.org/wiki/Recovery_point_objective
