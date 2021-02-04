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

[1]: https://help.github.com/enterprise/admin/guides/installation/high-availability-cluster-configuration/
