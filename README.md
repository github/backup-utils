GitHub Enterprise Backup Utilities
==================================

This repository includes backup and recovery utilities for [GitHub Enterprise][1].

### Features

 - Online and incremental backups of Git repository data from primary GitHub
   Enterprise instance.
 - Cold or warm standby recovery options.
 - Backup and recovery across datacenters.
 - Configurable backup snapshot frequency and retention periods.

### Getting started

 1. Clone the repository to the backup host:

    `git clone https://github.com/github/enterprise-backup-site.git ghe-backup`

 2. Copy the [`backup.config-example`][2] file to `backup.config` and modify as
    necessary. The `GHE_HOSTNAME` value must be set to the GitHub Enterprise
    host name. Additional options are available and documented in the
    configuration file but none are required for basic backup functionality.

 3. Add the backup host's SSH key to the GitHub Enterprise instance as an
    *Authorized SSH key*. See [Adding an SSH key for shell access][3] for
    instructions.

 4. Run `scripts/ghe-host-check` to verify SSH connectivity with the GitHub
    Enterprise instance.

 5. Run `scripts/ghe-backup` to perform an initial full backup.

Subsequent invocations of the `ghe-backup` command create incremental snapshots
of repository data along with full snapshots of all other pertinent data.
Snapshots may be restored to the same or separate GitHub Enterprise instance via
the `ghe-restore` command. See the sections on *Backup* and *Recovery* below for
detailed information on setting up a disaster recovery plan.

### Requirements

Backup site requirements are modest: a bash interperter and rsync v2.6.4 or greater. Any modern Linux with rsync should be fine.

In order to be able to start performing online backups via `ghe-rsync-backup` the GitHub Enterprise appliance needs to be running 11.10.342 or above. Offline backups via `ghe-backup` and `ghe-s3-backup` may work with older versions of GitHub Enterprise, though this is neither recommended nor supported.

GitHub Enterprise's running version can be seen on http(s)://[hostname]/setup/upgrade. If you're not running on the latest release we recommend to upgrade the appliance. Please download the most recent GHP from the [GitHub Enterprise website](https://enterprise.github.com/download) and see [our guide](https://enterprise.github.com/help/articles/upgrading-to-a-newer-release) for more information on how to perform upgrades.

### Backup file structure

Backups are stored in rotating increment directories named after the time the snapshot was taken. Each increment directory contains a full backup snapshot of all relevant datastores.

    ./data
       |- 20140724T010000
       |- 20140725T010000
       |- 20140726T010000
       |- 20140727T010000
       |- 20140728T010000
          |- pages.tar
          |- mysql.sql.gz
          |- redis.rdb
          |- authorized-keys.json
          |- ssh-host-keys.tar
          |- es-indices.tar
          |- repositories/
       |- current -> 20140727T010000

In the example above, five snapshot directories exist with the most recent successful snapshot being pointed to by the `current` symlink.

Note: the `GHE_DATA_DIR` variable set in `backup.config` can be used to change the location where snapshot directories are written.

### See Also

The scripts in this repository are based on the documentation provided by the
GitHub Enterprise knowledge base. See the following articles for more information:

 - [Backing up GitHub Enterprise data](https://enterprise.github.com/help/articles/backing-up-enterprise-data)
 - [Restoring GitHub Enterprise data](https://enterprise.github.com/help/articles/restoring-enterprise-data)

### Support

If you have any questions about how to backup your data from the GitHub Enterprise appliance please get in touch with [GitHub Enterprise Support](https://enterprise.github.com/support/)!


[1]: https://enterprise.github.com
