GitHub Enterprise Backup Utilities
==================================

This repository includes backup and recovery utilities for [GitHub Enterprise][1].

### Features

 - Online and incremental backups of Git repository data from primary GitHub
   Enterprise instance.
 - Cold or warm standby recovery options.
 - Backup and recovery across data centers.
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

Backup site requirements are modest: Linux or other modern Unix operating system
with [rsync][4] v2.6.4 or greater.

For online and incremental backup support, the GitHub Enterprise appliance must
be running version 11.10.342 or above. Earlier versions may use the "tarball"
backup strategy (see `backup.config` for more information) but online and
incremental backups are not supported. We strongly recommend upgrading to
11.10.342 or later. Visit enterprise.github.com to [download the most recent
version][5].

### Backup

Backup runs look like this:

    $ ghe-backup
    Starting backup of github.example.com in snapshot 20140727T224148
    Connect github.example.com OK
    Backing up GitHub settings ...
    Backing up SSH public keys ...
    Backing up SSH host keys ...
    Backing up Git repositories ...
    Backing up GitHub Pages ...
    Backing up MySQL database ...
    Backing up Redis database ...
    Backing up Elasticsearch indices ...
    Completed backup of github.example.com in snapshot 20140727T224148 at 23:01:58

TODO:

 - Backup frequency and scheduling
 - Snapshot retention policy
 - Storage requirements

### Recovery

Restoring from the latest snapshot to a standby host:

    $ ghe-restore github-standby.example.com
    Starting restore of github-standby.example.com from snapshot 20140727T224148
    Connect github-standby.example.com OK
    Restoring Git repositories ...
    Restoring GitHub Pages ...
    Restoring MySQL database ...
    Restoring Redis database ...
    Restoring Elasticsearch indices ...
    Restoring SSH public keys ...
    Restoring SSH host keys ...
    Completed restore of github-standby.example.com from snapshot 20140727T224148

TODO:

 - Cold: restore from backup snapshot into an existing or newly provisioned
   VM at time of recovery.
 - Warm: continuously restore each snapshot into a warm standby VM (possibly in
   another datacenter).
 - Talk about RPO and RTO and trade-offs between recovery options.

### Backup file structure

Backups are stored in rotating increment directories named after the time the
snapshot was taken. Each increment directory contains a full backup snapshot of
all relevant datastores.

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

In the example above, five snapshot directories exist with the most recent
successful snapshot being pointed to by the `current` symlink.

Note: the `GHE_DATA_DIR` variable set in `backup.config` can be used to change
the location where snapshot directories are written.

### See Also

The utilities included in this repository are based on the documentation
provided by the GitHub Enterprise knowledge base. See the following articles for
more information:

 - [Backing up GitHub Enterprise data](https://enterprise.github.com/help/articles/backing-up-enterprise-data)
 - [Restoring GitHub Enterprise data](https://enterprise.github.com/help/articles/restoring-enterprise-data)

### Support

If you have any questions about how to backup your data from the GitHub
Enterprise appliance please get in touch with [GitHub Enterprise
Support](https://enterprise.github.com/support/)!


[1]: https://enterprise.github.com
[2]: https://github.com/github/enterprise-backup-site/blob/master/backup.config-example
[3]: https://enterprise.github.com/help/articles/adding-an-ssh-key-for-shell-access
[4]: http://rsync.samba.org/
[5]: https://enterprise.github.com/download
[6]: https://enterprise.github.com/help/articles/upgrading-to-a-newer-release
