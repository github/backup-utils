## Extras

Potentially useful extra files for backup-utils

### Mac OS X launchd launcher

If you're using a Mac OS X system for your backup host, you can use the
[com.github.backup-utils.launcher.plist](./com.github.backup-utils.launcher.plist)
file to use
[launchd](https://developer.apple.com/library/mac/documentation/macosx/conceptual/bpsystemstartup/chapters/CreatingLaunchdJobs.html)
as the system to schedule backups.

The provided file will need tweaking in a couple of places:

* Add the correct full path to the `ghe-backup` command  within the
`ProgramArguments` `<string>`, e.g.:

```xml
<key>ProgramArguments</key>
<array>
  <string>/opt/backup-utils/bin/ghe-backup</string>
</array>
```

* The file is currently configured to run a backup every 4 hours (14400
  seconds), if you want to change that, edit the `StartInterval` integer value

If you would prefer to change the frequency this runs to a specific time each
day, you would need to use a `StartCalendarInterval` instead. The example below
runs the backup each weekday at 11:00AM and 6:00PM

```xml
<key>StartCalendarInterval</key>
<array>
  <dict>
    <key>Weekday</key>
    <integer>1</integer>
    <key>Hour</key>
    <integer>11</integer>
    <key>Minute</key>
    <integer>0</integer>
  </dict>
  <dict>
    <key>Weekday</key>
    <integer>1</integer>
    <key>Hour</key>
    <integer>18</integer>
    <key>Minute</key>
    <integer>0</integer>
  </dict>
  <dict>
    <key>Weekday</key>
    <integer>2</integer>
    <key>Hour</key>
    <integer>11</integer>
    <key>Minute</key>
    <integer>0</integer>
  </dict>
  <dict>
    <key>Weekday</key>
    <integer>2</integer>
    <key>Hour</key>
    <integer>18</integer>
    <key>Minute</key>
    <integer>0</integer>
  </dict>
  <!-- and so on up to… -->
  <dict>
    <key>Weekday</key>
    <integer>5</integer>
    <key>Hour</key>
    <integer>18</integer>
    <key>Minute</key>
    <integer>0</integer>
  </dict>
</array>
```


Once you've modified the `.plist` file for your needs, drop it into
`/Library/LaunchAgents`:

    sudo cp com.github.backup-utils.launcher.plist /Library/LaunchAgents/

Then load this into `launchd`:

    sudo launchctl load /Library/LaunchAgents/com.github.backup-utils.launcher.plist
