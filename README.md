GitHub Enterprise Backup Utilities
==================================

This repository includes utilities for and documentation on running a
[GitHub Enterprise](https://enterprise.github.com) backup / DR site.

### Setup for server based backups

Follow these instructions to configure a new backup site:

 1. `git clone https://github.com/github/enterprise-backup-site.git ghe-backup`
 2. Copy the `backup.config-example` file to `backup.config` and modify as needed.
 3. Add the local user's SSH key to the GitHub Enterprise instance's `authorized keys` file.
    See [Adding an SSH key for shell access](https://enterprise.github.com/help/articles/adding-an-ssh-key-for-shell-access)
    for instructions.
 4. Run `scripts/ghe-host-check` to verify connectivity with the GitHub Enterprise instance.

### Setup for S3 based backups

Follow these instructions to configure S3 backups:

 1. Perform the above steps to setup a backup site.
 2. Install s3cmd
   * OSX: `brew install s3cmd`
   * Ubuntu: `apt-get install s3cmd`
 4. Run `scripts/ghe-s3-backup-all`

### Requirements

Backup site requirements are modest: a bash interperter and rsync v2.6.4 or greater. Any modern Linux with rsync should be fine.

In order to be able to start performing online backups via `ghe-rsync-backup` the GitHub Enterprise appliance needs to be running 11.10.342 or above. Offline backups via `ghe-backup` and `ghe-s3-backup` may work with older versions of GitHub Enterprise, though this is neither recommended nor supported.

GitHub Enterprise's running version can be seen on http(s)://[hostname]/setup/upgrade. If you're not running on the latest release we recommend to upgrade the appliance. Please download the most recent GHP from the [GitHub Enterprise website](https://enterprise.github.com/download) and see [our guide](https://enterprise.github.com/help/articles/upgrading-to-a-newer-release) for more information on how to perform upgrades.

### Backup file structure

The `GHE_DATA_DIR` variable set in `backup.config` controls where backup data is written. It has the following file hierarchy:

    $GHE_DATA_DIR
    |- ghe-pages-backup.tar
    |- ghe-mysql-backup.sql.gz
    |- ghe-redis-backup.rdb
    |- ghe-authorized-keys-backup.json
    |- ghe-ssh-host-keys-backup.tar
    |- ghe-es-indices-backup.tar
    |- ghe-repositories/
       |- 20140724T010000
       |- 20140725T010000
       |- 20140726T010000
       |- 20140727T010000
       |- 20140728T010000
       |- current -> 20140727T010000

The `ghe-repositories` directory stores all git repositories under timestamped increment directories. The `current` symlink points to the most recent full increment.

### See Also

The scripts in this repository are based on the documentation provided by the
GitHub Enterprise knowledge base. See the following articles for more information:

 - [Backing up GitHub Enterprise data](https://enterprise.github.com/help/articles/backing-up-enterprise-data)
 - [Restoring GitHub Enterprise data](https://enterprise.github.com/help/articles/restoring-enterprise-data)

### Support

If you have any questions about how to backup your data from the GitHub Enterprise appliance please get in touch with [GitHub Enterprise Support](https://enterprise.github.com/support/)!
