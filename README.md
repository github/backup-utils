GitHub Enterprise Backup Utilities
==================================

This repository includes backup and recovery utilities for [GitHub Enterprise][1].

### Features

The backup utilities are based on the server-side [backup][8] and [restore][9]
capabilities built in to GitHub Enterprise but implement a number of advanced
features for backup hosts.

 - Complete GitHub Enterprise backup and restore system via two simple utilities:
   `ghe-backup` and `ghe-restore`.
 - Online backups. The GitHub appliance need not be put in maintenance
   mode for the duration of the backup run.
 - Incremental backup of Git repository data. Only changes since the last
   snapshot are transferred, leading to faster backup runs and lower network
   bandwidth and machine utilization.
 - Multiple backup snapshots with configurable retention periods.
 - Efficient snapshot storage. Only data added since the previous snapshot
   consumes new space on the backup host.
 - Backup commands run under the lowest CPU/IO priority on the GitHub appliance,
   reducing performance impact while backups are in progress.
 - Runs under most Linux/Unix environments.
 - MIT licensed, open source software maintained by GitHub, Inc.

### Getting started

The backup utilities should be run on a host dedicated to long-term permanent
storage and must have network connectivity with the GitHub Enterprise appliance.
See the section below on *Backup host and storage requirements* for more
information.

 1. [Download the latest release](need this url) and extract:

    `curl <release-url> | gzip -dc | tar xvf -`

    Tip: You can also use Git to obtain the utilities instead, which may make
    upgrading to future backup-utils releases easier:

    `git clone https://github.com/github/backup-utils.git backup-utils`

 2. Copy the [`backup.config-example`][2] file to `backup.config` and modify as
    necessary. The `GHE_HOSTNAME` value must be set to the GitHub Enterprise
    host name. Additional options are available and documented in the
    configuration file but none are required for basic backup functionality.

 3. Add the backup host's SSH key to the GitHub appliance as an *Authorized SSH
    key*. See [Adding an SSH key for shell access][3] for instructions.

 4. Run `bin/ghe-host-check` to verify SSH connectivity with the GitHub
    appliance.

 5. Run `bin/ghe-backup` to perform an initial full backup.

Subsequent invocations of the `ghe-backup` command will create incremental
snapshots of repository data along with full snapshots of all other pertinent
data stores. Snapshots may be restored to the same or separate GitHub appliance
via the `ghe-restore` command. See the *Example usage* section below for more
detailed information.

### Requirements

##### Backup host and storage requirements

Backup host software requirements are modest: Linux or other modern Unix
operating system with [rsync][4] v2.6.4 or newer.

The backup host must be able to establish network connections outbound to the
GitHub appliance over SSH (port 22).

Storage requirements vary based on current Git repository disk usage and growth
patterns of the GitHub appliance. Allocating at least 5x the amount of storage
allocated to the primary GitHub appliance for historical snapshots and growth
over time is recommended.

##### GitHub Enterprise version requirements

For online and incremental backup support, the GitHub Enterprise instance must
be running version 11.10.342 or above. Earlier versions may use the "tarball"
backup strategy (see `backup.config` for more information) but online and
incremental backups are not supported. We strongly recommend upgrading to
version 11.10.342 or later. Visit enterprise.github.com to [download the most
recent GitHub Enterprise version][5].

### Example usage


The following assumes that`GHE_HOSTNAME` is set to "github.example.com" in
`backup.config`.

Creating a backup snapshot:

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

Restoring from last successful snapshot to a newly provisioned VM at IP
"5.5.5.5":

    $ ghe-restore 5.5.5.5
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

The `ghe-backup` and `ghe-restore` commands also have a verbose output mode
(`-v`) that lists files as they're being transferred. It's often useful to
enable when output is logged to a file.

### Scheduling

Regular backups should be scheduled using `cron(8)` or similar command
scheduling service on the backup host. We recommend a backup frequency of hourly
for the (default) rsync backup strategy, or daily for the more intense tarball
backup strategy. The backup frequency will dictate the worst case recovery
point objective (RPO) in your backup plan.

The following examples assume the backup utilities are installed under
`/opt/backup-utils`. The crontab entry should be made under the same user that
manual backup/recovery commands will be issued under and must have write access
to the configured `GHE_DATA_DIR` directory.

To schedule hourly backup snapshots with verbose informational output written to
a log file and errors generating an email:

    MAILTO=admin@example.com

    0 * * * * /opt/backup-utils/bin/ghe-backup -v 1>>/opt/backup-utils/backup.log

To schedule nightly backup snapshots instead, use:

    MAILTO=admin@example.com

    0 0 * * * /opt/backup-utils/bin/ghe-backup -v 1>>/opt/backup-utils/backup.log

Note that the `GHE_NUM_SNAPSHOTS` option in `backup.config` should be tuned
based on the frequency of backups. The ten most recent snapshots are retained by
default. The number should be adjusted based on backup frequency and available
storage.

### Backup snapshot file structure

Backup snapshots are stored in rotating increment directories named after the
date and time the snapshot was taken. Each snapshot directory contains a full
backup snapshot of all relevant data stores. The following example shows a
snapshot file hierarchy for hourly

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
the disk location where snapshots are written.

### See Also

The GitHub Enterprise knowledge base includes additional information on backup
and recovery. See the following for more:

 - [Backing up GitHub Enterprise data][8]
 - [Restoring GitHub Enterprise data][9]

### Support

If you have any questions about how to backup your data from the GitHub
Enterprise appliance please get in touch with [GitHub Support][7]!

[1]: https://enterprise.github.com
[2]: https://github.com/github/enterprise-backup-site/blob/master/backup.config-example
[3]: https://enterprise.github.com/help/articles/adding-an-ssh-key-for-shell-access
[4]: http://rsync.samba.org/
[5]: https://enterprise.github.com/download
[6]: https://enterprise.github.com/help/articles/upgrading-to-a-newer-release
[7]: https://enterprise.github.com/support/
[8]: https://enterprise.github.com/help/articles/backing-up-enterprise-data
[9]: https://enterprise.github.com/help/articles/restoring-enterprise-data
