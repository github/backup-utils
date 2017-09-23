GitHub Enterprise Backup Utilities
==================================

This repository includes backup and recovery utilities for [GitHub Enterprise][1].

- **[Features](#features)**
- **[Requirements](#requirements)**
  - **[Backup host requirements](#backup-host-requirements)**
  - **[Storage requirements](#storage-requirements)**
  - **[GitHub Enterprise version requirements](#github-enterprise-version-requirements)**
- **[Getting started](#getting-started)**
- **[Migrating from GitHub Enterprise v11.10.34x to v2.0](#migrating-from-github-enterprise-v111034x-to-v20-or-v21)**
- **[Using the backup and restore commands](#using-the-backup-and-restore-commands)**
- **[Scheduling backups](#scheduling-backups)**
- **[Backup snapshot file structure](#backup-snapshot-file-structure)**
- **[How does backup utilities differ from a High Availability replica?](#how-does-backup-utilities-differ-from-a-high-availability-replica)**
- **[Support](#support)**

### Features

The backup utilities implement a number of advanced capabilities for backup
hosts, built on top of the backup and restore features already included in
GitHub Enterprise.

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

##### Backup host requirements

Backup host software requirements are modest: Linux or other modern Unix
operating system with [bash][13], [git][14], [OpenSSH][15], and [rsync][4] v2.6.4 or newer.

The backup host must be able to establish network connections outbound to the
GitHub appliance over SSH. TCP port 122 is used to backup GitHub Enterprise 2.0
or newer instances, and TCP port 22 is used for older versions (11.10.34X).

##### Storage requirements

Storage requirements vary based on current Git repository disk usage and growth
patterns of the GitHub appliance. We recommend allocating at least 5x the amount
of storage allocated to the primary GitHub appliance for historical snapshots
and growth over time.

The backup utilities use [hard links][12] to store data efficiently, so the backup
snapshots must be written to a filesystem with support for hard links.

##### GitHub Enterprise version requirements

The backup utilities are fully supported under GitHub Enterprise 2.0 or
greater.

The previous release series (11.10.34x) is also supported but must meet minimum
version requirements. For online and incremental backup support, the GitHub
Enterprise instance must be running version 11.10.342 or above.

Earlier versions are supported, but online and incremental backups are not
supported. We strongly recommend upgrading to the latest release if you're
running a version prior to 11.10.342. Visit [enterprise.github.com][5] to
download the most recent GitHub Enterprise version.

Note: You can restore a snapshot that's at most two feature releases behind the restore target's version of GitHub Enterprise. For example, to restore a snapshot of GitHub Enterprise 2.4, the target GitHub Enterprise appliance must be running GitHub Enterprise 2.5.x or 2.6.x. You can't restore a snapshot from 2.4 to 2.7, because that's three releases ahead.


### Getting started

 1. [Download the latest release version][release] and extract *or* clone the
    repository using Git:

    `git clone -b stable https://github.com/github/backup-utils.git`

 2. Copy the [`backup.config-example`][2] file to `backup.config` and modify as
    necessary. The `GHE_HOSTNAME` value must be set to the GitHub Enterprise
    host name. Additional options are available and documented in the
    configuration file but none are required for basic backup functionality.

    * backup-utils will attempt to load the backup configuration from the following locations, in this order:

      ```
      $GHE_BACKUP_CONFIG (User configurable environment variable)
      $GHE_BACKUP_ROOT/backup.config (Root directory of backup-utils install)
      $HOME/.github-backup-utils/backup.config
      /etc/github-backup-utils/backup.config
      ```
    * In a clustering environment, the `GHE_EXTRA_SSH_OPTS` key must be configured with the `-i <abs path to private key>` SSH option.

 3. Add the backup host's SSH key to the GitHub appliance as an *Authorized SSH
    key*. See [Adding an SSH key for shell access][3] for instructions.

 4. Run `bin/ghe-host-check` to verify SSH connectivity with the GitHub
    appliance.

 5. Run `bin/ghe-backup` to perform an initial full backup.

[release]: https://github.com/github/backup-utils/releases

### Migrating from GitHub Enterprise v11.10.34x to v2.0, or v2.1

If you are migrating from GitHub Enterprise version 11.10.34x to 2.0 or 2.1
(note, migrations to versions greater than 2.1 are not officially supported),
please see the [Migrating from GitHub Enterprise v11.10.34x][10] documentation
in the [GitHub Enterprise System Administrator's Guide][11]. It includes
important information on using the backup utilities to migrate data from your
v11.10.34x instance to v2.0 or v2.1.

### Using the backup and restore commands

After the initial backup, use the following commands:

 - The `ghe-backup` command creates incremental snapshots of repository data,
   along with full snapshots of all other pertinent data stores.
 - The `ghe-restore` command restores snapshots to the same or separate GitHub
   Enterprise appliance. You must add the backup host's SSH key to the target
   GitHub Enterprise appliance before using this command.

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

A different backup snapshot may be selected by passing the `-s` argument and the
datestamp-named directory from the backup location.

The `ghe-backup` and `ghe-restore` commands also have a verbose output mode
(`-v`) that lists files as they're being transferred. It's often useful to
enable when output is logged to a file.

When restoring to an already configured GHE instance, settings, certificate, and license data
are *not* restored to prevent overwriting manual configuration on the restore
host. This behavior can be overridden by passing the `-c` argument to `ghe-restore`,
forcing settings, certificate, and license data to be overwritten with the backup copy's data.

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

    0 * * * * /opt/backup-utils/bin/ghe-backup -v 1>>/opt/backup-utils/backup.log 2>&1

To schedule nightly backup snapshots instead, use:

    MAILTO=admin@example.com

    0 0 * * * /opt/backup-utils/bin/ghe-backup -v 1>>/opt/backup-utils/backup.log 2>&1

### Backup snapshot file structure

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
       |- 20140724T010000
       |- 20140725T010000
       |- 20140726T010000
       |- 20140727T010000
       |- 20140728T010000
          |- authorized-keys.json
          |- elasticsearch/
          |- enterprise.ghl
          |- mysql.sql.gz
          |- pages/
          |- redis.rdb
          |- repositories/
          |- settings.json
          |- ssh-host-keys.tar
          |- strategy
          |- version
       |- current -> 20140728T010000

Note: the `GHE_DATA_DIR` variable set in `backup.config` can be used to change
the disk location where snapshots are written.

### How does backup utilities differ from a High Availability replica?
It is recommended that both backup utilities and an [High Availability replica](https://help.github.com/enterprise/admin/guides/installation/high-availability-cluster-configuration/) are used as part of a GitHub Enterprise deployment but they serve different roles.

##### The purpose of the High Availability replica
The High Availability replica is a fully redundant secondary GitHub Enterprise instance, kept in sync with the primary instance via replication of all major datastores. This active/passive cluster configuration is designed to minimize service disruption in the event of hardware failure or major network outage affecting the primary instance. Because some forms of data corruption or loss may be replicated immediately from primary to replica, it is not a replacement for the backup utilities as part of your disaster recovery plan.

##### The purpose of the backup utilities
Backup utilities are a disaster recovery tool. This tool takes date-stamped snapshots of all major datastores. These snapshots are used to restore an instance to a prior state or set up a new instance without having another always-on GitHub Enterprise instance (like the High Availability replica).


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
[10]: https://help.github.com/enterprise/2.0/admin-guide/migrating-to-a-different-platform-or-from-github-enterprise-11-10-34x/
[11]: https://help.github.com/enterprise/2.0/admin-guide/
[12]: https://en.wikipedia.org/wiki/Hard_link
[13]: https://www.gnu.org/software/bash/
[14]: https://git-scm.com/
[15]: https://www.openssh.com/
