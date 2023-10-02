# Requirements

Backup Utilities should be run on a host dedicated to long-term permanent
storage and must have network connectivity with the GitHub Enterprise Server appliance.

## Backup host requirements

Backup host software requirements are modest: Linux or other modern Unix operating system (Ubuntu is highly recommended) with [bash][1], [git][2], [OpenSSH][3] 5.6 or newer, [rsync][4] v2.6.4 or newer* (see [below](#april-2023-update-of-rsync-requirements) for exceptions), [jq][11] v1.5 or newer, and [bc][12] v1.07 or newer.

Ubuntu is the operating system we use to test `backup-utils` and it’s what we recommend you use too. You are welcome to use a different operating system, and we'll do our best to help you if you run into issues. But we can't guarantee that we'll be able to resolve issues that are specific to that operating system.

Additionally, we encourage the use of [Docker](docker.md), as it ensures compatible versions of the aforementioned software are available to backup-utils.

The parallel backup and restore feature will require [GNU awk][10] and [moreutils][9] to be installed.

The backup host must be able to establish outbound network connections to the GitHub appliance over SSH. TCP port 122 is used to backup GitHub Enterprise Server.

CPU and memory requirements are dependent on the size of the GitHub Enterprise Server appliance. We recommend a minimum of 4 cores and 8GB of RAM for the host running [GitHub Enterprise Backup Utilities](https://github.com/github/backup-utils). We recommend monitoring the backup host's CPU and memory usage to ensure it is sufficient for your environment.

### April 2023 Update of Rsync Requirements

The [fix in rsync `3.2.5`](https://github.com/WayneD/rsync/blob/master/NEWS.md#news-for-rsync-325-14-aug-2022) for [CVE-2022-29154](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-29154) can cause severe performance degradation to `backup-utils`.

If you encounter this degradation you can mitigate it by using the `--trust-sender` flag, which is available in rsync >= v3.2.5.

If your backup host is running rsync < v3.2.5 you may or may not need to make changes to your rsync package, depending on whether your rsync package has backported the fix for CVE-2022-29154 without also backporting the `--trust-sender` flag.

If your rsync package has backported the CVE fix _and_ the `--trust-sender` flag then you don't need to change anything.

However, if your rsync package has backported the CVE fix without backporting the `--trust-sender` flag then you have three options:

1. Downgrade (using the package manager on your host) the rsync package to a version before the CVE fix was backported
2. Upgrade (using the package manager on your host) the rsync package to v3.2.5 or newer
3. Manually download rsync v3.2.5 or newer and build the rsync binary

Option #3 is required if your operating system's package manager does not have access to rsync v3.2.5 or later (e.g. Ubuntu Focal).

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

Performance of backup and restore operations are also dependent on the backup host's storage. We recommend using a high performance storage system with low latency and high IOPS.

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

Due to how some components of Backup Utilities (e.g. MSSQL) take incremental backups, running another instance of Backup Utilities may result in unrestorable snapshots as data may be split across backup hosts. If you still wish to have multiple instances of Backup Utilities for redundancy purposes or to run at different frequencies, ensure that they share the same `GHE_DATA_DIR` backup directory.

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
[11]: https://stedolan.github.io/jq/
[12]: https://www.gnu.org/software/bc/
