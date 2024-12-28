#!/bin/bash

# Remove autopkg-conductor logfiles older than a specified number of days

# Add username of the account used to run AutoPkg

autopkg_username="autopkg"

# Age of logfiles to retain. For example, setting the following number
# will delete anything older than 20 days
#
# autopkg_log_age="20"

autopkg_log_age="20"

/usr/bin/find "/Users/$autopkg_username/Library/Logs" -name "autopkg-run-for*" -mindepth 1 -mtime +"$autopkg_log_age" -delete