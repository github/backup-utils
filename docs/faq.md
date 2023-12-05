# Frequently Asked Questions

## How does Backup Utilities differ from a High Availability replica?
It is recommended that both Backup Utilities and an [High Availability replica][1]
are used as part of a GitHub Enterprise Server deployment but they serve different roles.

### The purpose of the High Availability replica
The High Availability replica is a fully redundant secondary GitHub Enterprise Server
instance, kept in sync with the primary instance via replication of all major
datastores. This active/passive cluster configuration is designed to minimize
service disruption in the event of hardware failure or major network outage
affecting the primary instance. Because some forms of data corruption or loss may
be replicated immediately from primary to replica, it is not a replacement for
Backup Utilities as part of your disaster recovery plan.

### The purpose of Backup Utilities
Backup Utilities are a disaster recovery tool. This tool takes date-stamped
snapshots of all major datastores. These snapshots are used to restore an instance
to a prior state or set up a new instance without having another always-on GitHub
Enterprise instance (like the High Availability replica).

### Does taking or restoring a backup impact the GitHub Enterprise Server's performance or operation?

Git background maintenance and garbage collection jobs become paused during the repositories stage of a backup and restore, and the storage stage of a backup. This may result in a backlog of queued maintenance or storage jobs observable in the GitHub Enterprise Server metrics for the duration of those steps. We suggest allowing any backlog to process and drain to 0 before starting another backup run. Repositories that are frequently pushed to may experience performance degradation over time if queued maintenance jobs are not processed.

Backup processes triggered by `backup-utils` running on the GitHub Enterprise Server instance run at a low CPU and IO priority to reduce any user facing impact. You may observe elevated levels of CPU usage, disk IO, and network IO for the duration of a backup run.


[1]: https://help.github.com/enterprise/admin/guides/installation/high-availability-cluster-configuration/
