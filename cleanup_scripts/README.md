# AutoPkg Cleanup Scripts

To assist with preserving available disk space on your AutoPkg host Mac, the following scripts are available:

* `801.clean-autopkg-repo`
* `802.remove.autopkg.wrapper.logs`

Both scripts are designed to be installed into the following location:

`/etc/periodic/daily`

Installing them in that location will enable them to be run daily on your AutoPkg host Mac.

The `801.clean-autopkg-repo` does the following task:

* Determine which files in your `~/Library/AutoPkg/Cache` are older than the number of days specified in the script (by default, 20 days)
* Delete all files in `~/Library/AutoPkg/Cache` are older than the specified number of days

The `802.remove.autopkg.wrapper.logs` script is designed to do the following:

* Determine which log files, where the filename contains `autopkg-run-for`, in the `~/Library/Logs/Cache` directory are older than the number of days specified in the script (by default, 20 days)
* Delete all relevant logfiles in the `~/Library/Logs` directory which are older than the specified number of days