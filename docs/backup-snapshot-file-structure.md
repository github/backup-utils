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
```
M---8:00--16:00---T---8:00--16:00---W... (timeline)

F-----------------F-----------------F... (full backup)
#-----D-----D-----#-----D-----D-----#... (differential backup)
T--T--T--T--T--T--T--T--T--T--T--T--T... (transaction log backup)
```
To save disk space, at each snapshot, hard links are created to point to previous backup files. Only newly-created backup files are transferred from appliance to backup host. When a new full/differential backup is created, they become the new source for hard links and new base line for transaction log backups, for subsequent snapshots.

During restore, a suite of backup files are restored in the sequence of full -> differential -> chronological transaction log.