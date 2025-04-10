# GitHub Enterprise Server Backup Utilities!

This repository includes backup and recovery utilities for
[GitHub Enterprise Server][1].

**Note**: The parallel backup and restore feature will require [GNU awk](https://www.gnu.org/software/gawk) and [moreutils](https://joeyh.name/code/moreutils) to be installed. Note that on some distributions/platforms, the `moreutils-parallel` package is separate from `moreutils` and must be installed on its own.

**Note**: the [GitHub Enterprise Server version requirements][2] have
changed starting with Backup Utilities v2.13.0, released on 27 March 2018.

## Features

Backup Utilities implement a number of advanced capabilities for backup
hosts, built on top of the backup and restore features already included in
GitHub Enterprise Server.

- Complete GitHub Enterprise Server backup and recovery system via two simple
   utilities:<br>`ghe-backup` and `ghe-restore`.
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

## Documentation

- **[Requirements](docs/requirements.md)**
  - **[Backup host requirements](docs/requirements.md#backup-host-requirements)**
  - **[Storage requirements](docs/requirements.md#storage-requirements)**
  - **[GitHub Enterprise Server version requirements](docs/requirements.md#github-enterprise-version-requirements)**
- **[Getting started](docs/getting-started.md)**
- **[Using the backup and restore commands](docs/usage.md)**
- **[Scheduling backups](docs/scheduling-backups.md)**
- **[Backup snapshot file structure](docs/backup-snapshot-file-structure.md)**
- **[How does Backup Utilities differ from a High Availability replica?](docs/faq.md)**
- **[Docker](docs/docker.md)**
- **[Releases](https://github.com/github/enterprise-releases/blob/master/docs/release-backup-utils.md)**

## Support

If you have a question related to your specific GitHub Enterprise Server setup, would like assistance with
backup site setup or recovery, or would like to report a bug or a feature request, please contact our [Enterprise support team][3].


## Repository updates - November 2023

In October 2023 we announced a number of changes to this repository.
These changes will improve our (GitHub’s) ability to ship enhancements and new features to backup-utils,
as well as simplify how GitHub Enterprise Server customers interact with backup-utils.

Our process for shipping new versions of backup-utils prior to November 2023 involved a 2-way sync between this repository and an internal repository.
This 2-way sync became significantly more problematic once we started regularly shipping patches in alignment with GitHub Enterprise Server.

As of 2023-11-30 we have stopped this 2-way sync so that our internal repository becomes the source of truth for the backup-utils source code.
With the the 2-way sync stopped, this public repository will be used to host documentation about backup-utils and to publish new versions of backup-utils.
You will be able to access a specific version of backup-utils (which includes the full source code) from the [release page](https://github.com/github/backup-utils/releases) of this repository.

This change has not affected the functionality of the backup-utils tool or a customer’s ability to backup or restore their GitHub Enterprise Server instance.

### Details

There are three specific areas that have been affected by us stop the 2-way sync between our internal repository and this public repository on 2023-11-30:

1. **Pull requests**: Customers should no longer open pull requests in this repository.
These pull requests will not be reviewed or merged.
This is necessary because we will no longer be syncing changes between this repository and our internal repository.
2. **Issues**: Customers cannot open issues in this repository.
Instead, customers will need to follow the standard support process and open a support ticket for any questions/concerns/problems with backup-utils.
This will ensure all customer requests are handled consistently.
3. **Installing/upgrading backup-utils**: Customers will not be able to use a clone of the repository to install and upgrade backup-utils.
Customers will need to download a specific version of backup-utils from the [release page](https://github.com/github/backup-utils/releases)
(either as a Debian package or as an archive file - see below for details on how to incorporate this change).

### Timeline

Below is the two phase timeline we will follow to roll out the changes described above:

* **Phase 1 (rolled out on 2023-11-30):** We have closed all open pull requests and issues (after reviewing each one and porting them to our internal repository if merited),
and updated the repository settings so that new issues cannot be opened. Also, we have stopped syncing code from our internal repository to this repository.
  * As of 2023-11-30, you can still get a working copy of backup-utils by cloning the repository.
      But the code will not be updated in the repository; you can access updated versions of backup-utils via the [release page](https://github.com/github/backup-utils/releases).
* **Phase 2 (rolling out 2024-02-20):** The backup-utils code will be removed and the repository will be used to host documentation for backup-utils.
After this date, you will no longer be able to clone a working copy of backup-utils from the repository.
Instead, you will need to download a specific version of backup-utils from the [release page](https://github.com/github/backup-utils/releases).

### Updating your backup-utils upgrade process

#### Clone of repository

If your current process for upgrading backup-utils involves a clone of the repository, you will need to modify your process to download a new version of backup-utils and set it up.

For example, you could download the v3.10.0 (github-backup-utils-v3.10.0.tar.gz) artifact from the [releases page](https://github.com/github/backup-utils/releases/tag/v3.10.0) with:

```shell
\$ wget https://github.com/github/backup-utils/releases/download/v3.10.0/github-backup-utils-v3.10.0.tar.gz
```
And then extract it:

```shell
\$ tar xzvf github-backup-utils-v3.10.0.tar.gz
```

This will give you a new folder, `github-backup-utils-v3.10.0`, which contains the code for version 3.10.0 of backup-utils. Once you copy over your backup.config file from a previous installation of backup-utils your new version of backup-utils will be ready to use.

#### Docker

For customers that currently use Docker to create a backup-utils image, their existing process may need updating as a result of this change. Previously customers could execute this command to build a Docker image of backup-utils:

```shell
\$ docker build github.com/github/backup-utils
```

This will not work after phase 2 roles out. You will need to update your process to first download an archive from the [release page](https://github.com/github/backup-utils/releases), extract it, and then build the Dockerfile inside the extracted directory.


[1]: https://github.com/enterprise
[2]: docs/requirements.md#github-enterprise-version-requirements
[3]: https://support.github.com/

