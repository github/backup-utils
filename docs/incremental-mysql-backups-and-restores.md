# Incremental MySQL Backups and Restores

Customers who have large MySQL databases who wish to save storage space can use the `--incremental` flag with `ghe-backup` and `ghe-restore`.
Using this flag performs backups for other parts of GHES as normal, but only performs a MySQL backup of the changes to the database from the previous snapshot. 
For larger databases this can conserve a lot of storage space for backups.

## Configuring number of backups

In your backup.config file you will need to set the variable `GHE_INCREMENTAL_MAX_BACKUPS`.
This variable determines how many cycles of full and incremental backups will be performed before the next full backup is created.
For example, if `GHE_INCREMENTAL_MAX_BACKUPS` is set to 14, backup-utils will run 1 full backup and then 13 incremental backups before performing another full backup on the next cycle.

Incremental backups require the previous snapshot backups before them to work.
This means they do not follow the pruning strategy based on `GHE_NUM_SNAPSHOTS`.

## Performing incremental backups

To perform incremental backups:

`bin/ghe-backup --incremental`

the program will detect whether it needs to performa full or incremental snapshot based on what is currently in `GHE_DATA_DIR`. 

To see what snapshots are part of your full and incremental backups, you can reference `GHE_DATA_DIR/inc_full_backup` and `GHE_DATA_DIR/inc_snapshot_data`, respectively.

## Performing incremental restores

To perform incremental restores:

`bin/ghe-restore --incremental -s <snapshot-id>`

The program will use the MySQL folders from each previous incremental backup and the full backup to restore the database.

:warning: Incremental restores require the other snapshots in the cycle to complete a restore. Erasing snapshot directories that are part of a cycle corrupts the restore and makes it impossible to restore for the MySQL database.

### Previous cycles

To ensure there is a rolling window of mySQL backups, incremental MySQL backups from the cycle before the current one are kept.  Those snapshots are pre-pended with `inc_previous`. To perform a restore from there, just use the full directory name for the snapshot id.
