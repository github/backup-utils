GitHub Enterprise Backup Utilities
==================================

This repository includes utilities for and documentation on running a
[GitHub Enterprise](https://enterprise.github.com) backup / DR site.

### Setup

Follow these instructions to configure a new backup site:

 1. `git clone https://github.com/github/enterprise-backup-site.git ghe-backup`
 1. Copy the `backup.config-example` file to `backup.config` and modify as needed.
 2. Add the local user's ssh key to the GitHub Enteprise instance's authorized keys.
    See [Adding an SSH key for shell access](https://enterprise.github.com/help/articles/adding-an-ssh-key-for-shell-access)
    for instructions.
 3. Run `scripts/ghe-host-check` to verify connectivity with the GitHub Enterprise instance.

### See Also

The scripts in this repository build on the documentation provided in the
GitHub Enterprise help site. See the following more information:

 - [Backing up GitHub Enterprise data](https://enterprise.github.com/help/articles/backing-up-enterprise-data)
 - [Restoring GitHub Enterprise data](https://enterprise.github.com/help/articles/restoring-enterprise-data)
