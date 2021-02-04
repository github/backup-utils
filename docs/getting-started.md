# Getting started

 1. [Download the latest release version][1] and extract the repository using `tar`:

    `tar -xzvf /path/to/github-backup-utils-vMAJOR.MINOR.PATCH.tar.gz`

    *or* clone the repository using Git:

    `git clone -b stable https://github.com/github/backup-utils.git`

    **Note**: you will need to use [Backup Utilities v2.11.x][2] or the `legacy` branch to
    backup and restore GitHub Enterprise Server 2.10 and earlier.

 2. Copy the [`backup.config-example`][3] file to `backup.config` and modify as
    necessary. The `GHE_HOSTNAME` value must be set to the primary GitHub Enterprise Server
    host name. Additional options are available and documented in the
    configuration file but none are required for basic backup functionality.

    As the data on a High Availability replica may be in a transient state at the time of backup,
    Backup Utilities should not be used to backup data from a High Availability replica.

    * Backup Utilities will attempt to load the backup configuration from the following
      locations, in this order:

      ```
      $GHE_BACKUP_CONFIG (User configurable environment variable)
      $GHE_BACKUP_ROOT/backup.config (Root directory of backup-utils install)
      $HOME/.github-backup-utils/backup.config
      /etc/github-backup-utils/backup.config
      ```
    * In a clustering environment, the `GHE_EXTRA_SSH_OPTS` key must be configured
      with the `-i <abs path to private key>` SSH option.

 3. Add the backup host's SSH key to the GitHub appliance as an *Authorized SSH
    key*. See [Adding an SSH key for shell access][4] for instructions.

 4. Run `bin/ghe-host-check` to verify SSH connectivity with the GitHub
    appliance.

 5. Run `bin/ghe-backup` to perform an initial full backup.

[1]: https://github.com/github/backup-utils/releases
[2]: https://github.com/github/backup-utils/releases/tag/v2.11.4
[3]: https://github.com/github/enterprise-backup-site/blob/master/backup.config-example
[4]: https://enterprise.github.com/help/articles/adding-an-ssh-key-for-shell-access
