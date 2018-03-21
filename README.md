# GitHub Enterprise Backup Utilities

This repository includes backup and recovery utilities for [GitHub Enterprise][1].

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

### Documentation


### Support

If you find a bug or would like to request a feature in backup-utils, please
open an issue or pull request on this repository. If you have a question related
to your specific GitHub Enterprise setup or would like assistance with backup
site setup or recovery, please contact our [Enterprise support team][2] instead.

[1]: https://enterprise.github.com
[2]: https://enterprise.github.com/support/








[6]: https://enterprise.github.com/help/articles/upgrading-to-a-newer-release
[8]: https://enterprise.github.com/help/articles/backing-up-enterprise-data
[9]: https://enterprise.github.com/help/articles/restoring-enterprise-data
[10]: https://help.github.com/enterprise/2.0/admin-guide/migrating-to-a-different-platform-or-from-github-enterprise-11-10-34x/
[11]: https://help.github.com/enterprise/2.0/admin-guide/
