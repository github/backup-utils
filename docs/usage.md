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
