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
