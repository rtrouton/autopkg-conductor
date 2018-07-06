To schedule runs of the `autopkg-conductor` script, I recommend the following:

1. Set up a user account named `autopkg` to run AutoPkg in.
2. Copy the `autopkg-conductor` script to `/usr/local/bin/autopkg-conductor.sh` and set the `autopkg-conductor.sh` script to be executable.
3. Set up a LaunchDaemon to run `/usr/local/bin/autopkg-conductor.sh` at a pre-determined time or interval.

The two LaunchDaemons in this directory follow this recommended setup:

* `com.github.autopkg-conductor-hourly-run.plist` - Runs `/usr/local/bin/autopkg-conductor.sh` every hour as the **autopkg** user.
* `com.github.autopkg-conductor-nightly-run.plist` - Runs `/usr/local/bin/autopkg-conductor.sh` every day at 2:00 AM as the **autopkg** user..