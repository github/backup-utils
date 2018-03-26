# Using the backup and restore commands

After the initial backup, use the following commands:

 - The `ghe-backup` command creates incremental snapshots of repository data,
   along with full snapshots of all other pertinent data stores.
 - The `ghe-restore` command restores snapshots to the same or separate GitHub
   Enterprise appliance. You must add the backup host's SSH key to the target
   GitHub Enterprise appliance before using this command.

### Example backup and restore usage

The following assumes that `GHE_HOSTNAME` is set to "github.example.com" in
`backup.config`.

Creating a backup snapshot:

    $ ghe-backup
    Starting backup of github.example.com in snapshot 20180326T020444
    Connect github.example.com:122 OK (v2.13.0)
    Backing up GitHub settings ...
    Backing up SSH authorized keys ...
    Backing up SSH host keys ...
    Backing up MySQL database ...
    Backing up Redis database ...
    Backing up audit log ...
    Backing up hookshot logs ...
    Backing up Git repositories ...
    Backing up GitHub Pages ...
    Backing up storage data ...
    Backing up custom Git hooks ...
    Backing up Elasticsearch indices ...
    Completed backup of github.example.com:122 in snapshot 20180326T020444 at 02:05:12
    Checking for leaked ssh keys ...
    * No leaked keys found

Restoring from last successful snapshot to a newly provisioned GitHub Enterprise
appliance at IP "5.5.5.5":

    $ ghe-restore 5.5.5.5
    Checking for leaked keys in the backup snapshot that is being restored ...
    * No leaked keys found
    Connect 5.5.5.5:122 OK (v2.13.0)
    Starting restore of 5.5.5.5:122 from snapshot 20180326T020444
    Stopping cron and github-timerd ...
    Restoring settings ...
    Restoring license ...
    Restoring management console password ...
    Restoring CA certificates ...
     --> Importing custom CA certificates...
    Restoring UUID ...
    Restoring MySQL database ...
     --> Importing MySQL data...
    Restoring Redis database ...
    Restoring Git repositories and Gists ...
    Restoring GitHub Pages ...
    Restoring SSH authorized keys ...
    Restoring storage data ...
    Restoring custom Git hooks ...
    Restoring Elasticsearch indices ...
    Starting cron ...
    Restoring SSH host keys ...
    Completed restore of 5.5.5.5:122 from snapshot 20180326T020444
    Visit https://5.5.5.5/setup/settings to review appliance configuration.

A different backup snapshot may be selected by passing the `-s` argument and the
datestamp-named directory from the backup location.

The `ghe-backup` and `ghe-restore` commands also have a verbose output mode
(`-v`) that lists files as they're being transferred. It's often useful to
enable when output is logged to a file.

When restoring to a new GitHub Enterprise instance, settings, certificate, and license data
*are* restored. These settings must be reviewed and saved before using the GitHub Enterprise to ensure all migrations take place and all required services are started.

When restoring to an already configured GitHub Enterprise instance, settings, certificate, and license data
are *not* restored to prevent overwriting manual configuration on the restore
host. This behavior can be overridden by passing the `-c` argument to `ghe-restore`,
forcing settings, certificate, and license data to be overwritten with the backup copy's data.