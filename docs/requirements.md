# Requirements

Backup Utilities should be run on a host dedicated to long-term permanent
storage and must have network connectivity with the GitHub Enterprise Server appliance.

## Backup host requirements

Backup host software requirements are modest: Linux or other modern Unix operating
system with [bash][1], [git][2], [OpenSSH][3] 5.6 or newer, and [rsync][4] v2.6.4 or newer.

The new parallel backup and restore beta feature will require [GNU awk][10] and [moreutils][9] to be installed.

We encourage the use of [Docker](docker.md) if your backup host doesn't meet these
requirements, or if Docker is your preferred platform.

The backup host must be able to establish outbound network connections to the
GitHub appliance over SSH. TCP port 122 is used to backup GitHub Enterprise Server.

## Storage requirements

Storage requirements vary based on current Git repository disk usage and growth
patterns of the GitHub appliance. We recommend allocating at least 5x the amount
of storage allocated to the primary GitHub appliance for historical snapshots
and growth over time.

Backup Utilities use [hard links][5] to store data efficiently, and the
repositories on GitHub Enterprise Server use [symbolic links][6] so the backup snapshots
must be written to a filesystem with support for symbolic and hard links.

To check if your filesystem supports creating hardlinks of symbolic links, you can run the following within your backup destination directory:

```bash
touch file
ln -s file symlink
ln symlink hardlink
ls -la
```

Using a [case sensitive][7] file system is also required to avoid conflicts.

## GitHub Enterprise Server version requirements

Starting with Backup Utilities v2.13.0, version support is inline with that of the
[GitHub Enterprise Server upgrade requirements][8] and as such, support is limited to
three versions of GitHub Enterprise Server: the version that corresponds with the version
of Backup Utilities, and the two releases prior to it.

For example, Backup Utilities v2.13.0 can be used to backup and restore all patch
releases from 2.11.0 to the latest patch release of GitHub Enterprise Server 2.13.
Backup Utilities v2.14.0 will be released when GitHub Enterprise Server 2.14.0 is released
and will then be used to backup all releases of GitHub Enterprise Server from 2.12.0
to the latest patch release of GitHub Enterprise Server 2.14.

Backup Utilities v2.11.4 and earlier offer support for GitHub Enterprise Server 2.10
and earlier releases up to GitHub Enterprise Server 2.2.0. Backup Utilities v2.11.0 and earlier
offer support for GitHub Enterprise Server 2.1.0 and earlier.

**Note**: You can restore a snapshot that's at most two feature releases behind
the restore target's version of GitHub Enterprise Server. For example, to restore a
snapshot of GitHub Enterprise Server 2.11, the target GitHub Enterprise Server appliance must
be running GitHub Enterprise Server 2.12.x or 2.13.x. You can't restore a snapshot from
2.10 to 2.13, because that's three releases ahead.

**Note**: You _cannot_ restore a backup created from a newer version of GitHub Enterprise Server to an older version. For example, an attempt to restore a snapshot of GitHub Enterprise Server 2.21 to a GitHub Enterprise Server 2.20 environment will fail with an error of `Error: Snapshot can not be restored to an older release of GitHub Enterprise Server.`.

## Multiple backup hosts

Using multiple backup hosts or backup configurations is not currently recommended.

Due to how some components of Backup Utiltiies (e.g. MSSQL) take incremental backups, running another instance of Backup Utilities may result in unrestorable snapshots as data may be split across backup hosts. If you still wish to have multiple instances of Backup Utilties for redundancy purposes or to run at different frequencies, ensure that they share the same `GHE_DATA_DIR` backup directory.

[1]: https://www.gnu.org/software/bash/
[2]: https://git-scm.com/
[3]: https://www.openssh.com/
[4]: http://rsync.samba.org/
[5]: https://en.wikipedia.org/wiki/Hard_link
[6]: https://en.wikipedia.org/wiki/Symbolic_link
[7]: https://en.wikipedia.org/wiki/Case_sensitivity
[8]: https://help.github.com/enterprise/admin/guides/installation/upgrade-requirements/
[9]: https://joeyh.name/code/moreutils
[10]: https://www.gnu.org/software/gawk
