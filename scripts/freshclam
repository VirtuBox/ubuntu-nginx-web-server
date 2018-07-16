#!/bin/sh
# make sure the process is stopped
/etc/init.d/clamav-freshclam stop

# check if database is outdated 
/usr/bin/freshclam -v >> /var/log/result_freshclam.log 2>&1

# update virus database
/etc/init.d/clamav-freshclam start >> /dev/null 2>&1
