GitHub Enterprise Backup Utilities
==================================

This repository includes backup and recovery utilities for [GitHub Enterprise][1].

- **[Features](#features)**
- **[Requirements](#requirements)**
  - **[Backup host](#backup-host)**
  - **[Storage](#storage)**
  - **[GitHub Enterprise version](#github-enterprise-version)**
- **[Getting started](#getting-started)**
- **[Using the backup and restore commands](#using-the-backup-and-restore-commands)**
- **[Scheduling backups](#scheduling-backups)**
- **[Backup snapshot file structure](#backup-snapshot-file-structure)**
- **[Support](#support)**

### Features

The backup utilities implement a number of advanced capabilities for backup
hosts, built on top of the backup and restore features already included in
GitHub Enterprise.

These advanced features include:

 - Complete GitHub Enterprise backup and recovery system via two simple utilities:<br>
   `ghe-backup` and `ghe-restore`.
 - Online backups. The GitHub appliance need not be put in maintenance mode for
   the duration of the backup run.
 - Incremental backup of Git repository data. Only changes since the last
   snapshot are transferred, leading to faster backup runs and lower network
   bandwidth and machine utilization.
 - Efficient snapshot storage. Only data added since the previous snapshot
   consumes new space on the backup host.
 - Multiple backup snapshots with configurable retention periods.
 - Backup commands run under the lowest CPU/IO priority on the GitHub appliance,
   reducing performance impact while backups are in progress.
 - Runs under most Linux/Unix environments.
 - MIT licensed, open source software maintained by GitHub, Inc.

### Requirements

The backup utilities should be run on a host dedicated to long-term permanent
storage and must have network connectivity with the GitHub Enterprise appliance.

##### Backup host

Backup host software requirements are modest: Linux or other modern Unix
operating system with [rsync][4] v2.6.4 or newer.

The backup host must be able to establish network connections outbound to the
GitHub appliance over SSH (port 22).

##### Storage

Storage requirements vary based on current Git repository disk usage and growth
patterns of the GitHub appliance. We recommend allocating at least 5x the amount
of storage allocated to the primary GitHub appliance for historical snapshots
and growth over time.

##### GitHub Enterprise version

For online and incremental backup support, the GitHub Enterprise instance must
be running version 11.10.342 or above.

Earlier versions are supported by the backup utilities, but online and
incremental backups are not supported. We strongly recommend upgrading to the
latest release if you're running a version prior to 11.10.342. Visit
https://enterprise.github.com to [download the most recent GitHub Enterprise
version][5].

### Getting started

 1. [Download the latest release version][release] and extract *or* clone the
    repository using Git:

    `git clone -b stable https://github.com/github/backup-utils.git`

 2. Copy the [`backup.config-example`][2] file to `backup.config` and modify as
    necessary. The `GHE_HOSTNAME` value must be set to the GitHub Enterprise
    host name. Additional options are available and documented in the
    configuration file but none are required for basic backup functionality.

 3. Add the backup host's SSH key to the GitHub appliance as an *Authorized SSH
    key*. See [Adding an SSH key for shell access][3] for instructions.

 4. Run `bin/ghe-host-check` to verify SSH connectivity with the GitHub
    appliance.

 5. Run `bin/ghe-backup` to perform an initial full backup.

[release]: https://github.com/github/backup-utils/releases

### Using the backup and restore commands

After the initial backup, use the following commands:

 - The `ghe-backup` command creates incremental snapshots of repository data,
   along with full snapshots of all other pertinent data stores.
 - The `ghe-restore` command restores snapshots to the same or separate GitHub
   appliance.

##### Example backup and restore usage

The following assumes that `GHE_HOSTNAME` is set to "github.example.com" in
`backup.config`.

Creating a backup snapshot:

    $ ghe-backup
    Starting backup of github.example.com in snapshot 20140727T224148
    Connect github.example.com OK (v11.10.343)
    Backing up GitHub settings ...
    Backing up SSH authorized keys ...
    Backing up SSH host keys ...
    Backing up MySQL database ...
    Backing up Redis database ...
    Backing up Git repositories ...
    Backing up GitHub Pages ...
    Backing up Elasticsearch indices ...
    Completed backup of github.example.com in snapshot 20140727T224148 at 23:01:58

Restoring from last successful snapshot to a newly provisioned GitHub Enterprise
appliance at IP "5.5.5.5":

    $ ghe-restore 5.5.5.5
    Starting rsync restore of 5.5.5.5 from snapshot 20140727T224148
    Connect 5.5.5.5 OK (v11.10.343)
    Enabling maintenance mode on 5.5.5.5 ...
    Restoring Git repositories ...
    Restoring GitHub Pages ...
    Restoring MySQL database ...
    Restoring Redis database ...
    Restoring SSH authorized keys ...
    Restoring Elasticsearch indices ...
    Restoring SSH host keys ...
    Completed restore of 5.5.5.5 from snapshot 20140817T174152
    Visit https://5.5.5.5/setup/settings to configure the recovered appliance.

The `ghe-backup` and `ghe-restore` commands also have a verbose output mode
(`-v`) that lists files as they're being transferred. It's often useful to
enable when output is logged to a file.

### Scheduling backups

Regular backups should be scheduled using `cron(8)` or similar command
scheduling service on the backup host. The backup frequency will dictate the
worst case recovery point objective (RPO) in your backup plan. We recommend the
following:

 - **Hourly backups** for GitHub Enterprise versions 11.10.342 or greater (due to
   improved online and incremental backup support)
 - **Daily backups** for versions prior to 11.10.342.

Note: the time required to do full offline backups of large datasets under
GitHub Enterprise versions prior to 11.10.342 may prohibit the use of daily
backups. We strongly recommend upgrading to 11.10.342 or greater in that case.

##### Example scheduling usage

The following examples assume the backup utilities are installed under
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

    0 * * * * /opt/backup-utils/bin/ghe-backup -v 1>>/opt/backup-utils/backup.log

To schedule nightly backup snapshots instead, use:

    MAILTO=admin@example.com

    0 0 * * * /opt/backup-utils/bin/ghe-backup -v 1>>/opt/backup-utils/backup.log

### Backup snapshot file structure

Backup snapshots are stored in rotating increment directories named after the
date and time the snapshot was taken. Each snapshot directory contains a full
backup snapshot of all relevant data stores.

The following example shows a snapshot file hierarchy for hourly frequency.
There are five snapshot directories, with the `current` symlink pointing to the
most recent successful snapshot:

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

Note: the `GHE_DATA_DIR` variable set in `backup.config` can be used to change
the disk location where snapshots are written.

### Support

If you find a bug or would like to request a feature in backup-utils, please
open an issue or pull request on this repository. If you have a question related
to your specific GitHub Enterprise setup or would like assistance with backup
site setup or recovery, please contact our [Enterprise support team][7] instead.

[1]: https://enterprise.github.com
[2]: https://github.com/github/enterprise-backup-site/blob/master/backup.config-example
[3]: https://enterprise.github.com/help/articles/adding-an-ssh-key-for-shell-access
[4]: http://rsync.samba.org/
[5]: https://enterprise.github.com/download
[6]: https://enterprise.github.com/help/articles/upgrading-to-a-newer-release
[7]: https://enterprise.github.com/support/
[8]: https://enterprise.github.com/help/articles/backing-up-enterprise-data
[9]: https://enterprise.github.com/help/articles/restoring-enterprise-data
