#!/bin/bash

# Remove AutoPkg-downloaded files older than a specified number of days

# Add username of the account used to run AutoPkg

autopkg_username="autopkg"

# Age of files to retain. For example, setting the following number
# will delete anything older than 20 days
#
# autopkg_cache_age="20"

autopkg_cache_age="20"

/usr/bin/find "/Users/$autopkg_username/Library/AutoPkg/Cache" -mindepth 1 -mtime +"$autopkg_cache_age" -delete