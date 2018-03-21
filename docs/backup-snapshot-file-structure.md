### Backup snapshot file structure

Backup snapshots are stored in rotating increment directories named after the
date and time the snapshot was taken. Each snapshot directory contains a full
backup snapshot of all relevant data stores. Repository, Search, and Pages data
is stored efficiently via hard links.

*Please note* Symlinks must be maintained when archiving backup snapshots.
Dereferencing or excluding symlinks, or storing the snapshot contents on a
filesystem which does not support symlinks will result in operational
problems when the data is restored.

The following example shows a snapshot file hierarchy for hourly frequency.
There are five snapshot directories, with the `current` symlink pointing to the
most recent successful snapshot:

    ./data
       |- 20140724T010000
       |- 20140725T010000
       |- 20140726T010000
       |- 20140727T010000
       |- 20140728T010000
          |- authorized-keys.json
          |- elasticsearch/
          |- enterprise.ghl
          |- mysql.sql.gz
          |- pages/
          |- redis.rdb
          |- repositories/
          |- settings.json
          |- ssh-host-keys.tar
          |- strategy
          |- version
       |- current -> 20140728T010000

Note: the `GHE_DATA_DIR` variable set in `backup.config` can be used to change
the disk location where snapshots are written.
