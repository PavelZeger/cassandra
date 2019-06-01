# Template

archive_command=/bin/ln %path /backup/%name
restore_command=cp -f %from %to
restore_directories = /var/backup/cassandra/commitlogs/13...

# Example 1
ln /raid0/casandra/commitlogs/ /var/backup/cassandra/commitlogs/13...
cp -f /var/backup/cassandra/commitlogs/13... /raid0/casandra/commitlogs/

# Example 2
archive_command=/bin/bash /home/cassandra/scripts/cassandra-archive.sh %path %name

#! /bin/bash
bzip2 --best -k $1
rsync $1.bz2 $HOME/commitlog_restore/$2.bz2
