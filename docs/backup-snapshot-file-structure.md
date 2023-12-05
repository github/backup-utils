# Backup snapshot file structure

Backup snapshots are stored in rotating increment directories named after the
date and time the snapshot was taken. Each snapshot directory contains a full
backup snapshot of all relevant data stores. Repository, Search, and Pages data
is stored efficiently via hard links.

*Please note* Symlinks must be maintained when archiving backup snapshots.
Dereferencing or excluding symlinks, or storing the snapshot contents on a
filesystem which does not support symlinks will result in operational
problems when the data is restored.

The following example shows a snapshot file hierarchy for hourly frequency.
There are five snapshot directories, with the `current` symlink pointing to the
most recent successful snapshot:

    ./data
       |- 20180124T010000
       |- 20180125T010000
       |- 20180126T010000
       |- 20180127T010000
       |- 20180128T010000
          |- audit-log
          |- benchmarks
          |- elasticsearch
          |- git-hooks
          |- hookshot
          |- pages
          |- repositories
          |- storage
          |- authorized-keys.json
          |- enterprise.ghl
          |- es-scan-complete
          |- manage-password
          |- mssql
          |- mysql.sql.gz
          |- redis.rdb
          |- settings.json
          |- ssh-host-keys.tar
          |- ssl-ca-certificates.tar
          |- strategy
          |- uuid
          |- version
       |- current -> 20180128T010000

Note: the `GHE_DATA_DIR` variable set in `backup.config` can be used to change
the disk location where snapshots are written.

## MS SQL Server backup structure
Actions service uses MS SQL Server as backend data store. Each snapshot includes a suite of backup files for MS SQL Server database(s).

To save time in backup, a three-level backup strategy is implemented. Based on the `GHE_MSSQL_BACKUP_CADENCE` setting, at each snapshot, either a (**F**)ull backup, a (**D**)ifferential or a (**T**)ransaction log backup is taken.

As a result, a suite always contains following for each database: a full backup, possibly a differential backup and at least one transaction log backup. Their relationship with timeline is demonstrated below:

```text
M---8:00--16:00---T---8:00--16:00---W... (timeline)

F-----------------F-----------------F... (full backup)
#-----D-----D-----#-----D-----D-----#... (differential backup)
T--T--T--T--T--T--T--T--T--T--T--T--T... (transaction log backup)
```

To save disk space, at each snapshot, hard links are created to point to previous backup files. Only newly-created backup files are transferred from appliance to backup host. When a new full/differential backup is created, they become the new source for hard links and new base line for transaction log backups, for subsequent snapshots.

During restore, a suite of backup files are restored in the sequence of full -> differential -> chronological transaction log.

## Benchmark data

Benchmark data for each snapshot is stored as a log file within the `benchmarks` directory within a snapshot directory. The benchmark log can be used to determine the duration of each backup step. For example:

```text
ghe-backup-store-version took 0s
ghe-backup-settings took 2s
ghe-export-authorized-keys took 0s
ghe-export-ssh-host-keys took 0s
ghe-backup-mysql-binary took 9s
ghe-backup-mysql took 9s
ghe-backup-minio took 0s
ghe-backup-redis took 1s
ghe-backup-es-audit-log took 1s
ghe-backup-repositories - Generating routes took 3s
ghe-backup-repositories - Fetching routes took 0s
ghe-backup-repositories - Processing routes took 0s
ghe-backup-pages - hostname took 1s
ghe-backup-pages took 1s
ghe-backup-storage - Generating routes took 2s
ghe-backup-storage - Fetching routes took 0s
ghe-backup-storage - Processing routes took 0s
ghe-backup-git-hooks took 0s
ghe-backup-es-rsync took 2s
```
