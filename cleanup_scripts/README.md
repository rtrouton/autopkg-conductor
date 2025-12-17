# AutoPkg Cleanup Scripts

To assist with preserving available disk space on your AutoPkg host Mac, the following scripts are available:

* `clean-autopkg-repo.sh`
* `remove.autopkg.wrapper.sh`

If scheduled runs are wanted, both scripts can be run by either a LaunchAgent or LaunchDaemon.

The `clean-autopkg-repo.sh` does the following task:

* Determine which files in the `~/Library/AutoPkg/Cache` directory are older than the number of days specified in the script (by default, 20 days)
* Delete all files in the `~/Library/AutoPkg/Cache` directory are older than the specified number of days

The `remove.autopkg.wrapper.sh` script is designed to do the following:

* Determine which log files, where the filename contains `autopkg-run-for`, in the `~/Library/Logs` directory are older than the number of days specified in the script (by default, 20 days)
* Delete all relevant logfiles in the `~/Library/Logs` directory which are older than the specified number of days
