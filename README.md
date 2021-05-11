# GitHub Enterprise Server Backup Utilities

This repository includes backup and recovery utilities for
[GitHub Enterprise Server][1].

**UPDATE**: The new parallel backup and restore beta feature will require [GNU awk](https://www.gnu.org/software/gawk) and [moreutils](https://joeyh.name/code/moreutils) to be installed. Note that on some distributions/platforms, the `moreutils-parallel` package is separate from `moreutils` and must be installed on its own.

**Note**: the [GitHub Enterprise Server version requirements][2] have
changed starting with Backup Utilities v2.13.0, released on 27 March 2018.

### Features

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

### Documentation

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

### Support

If you find a bug or would like to request a feature in Backup Utilities, please
open an issue or pull request on this repository. If you have a question related
to your specific GitHub Enterprise Server setup or would like assistance with
backup site setup or recovery, please contact our [Enterprise support team][3]
instead.

[1]: https://enterprise.github.com
[2]: docs/requirements.md#github-enterprise-version-requirements
[3]: https://enterprise.github.com/support/
