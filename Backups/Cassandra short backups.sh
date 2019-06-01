https://blog.pythian.com/backup-strategies-cassandra/

# Nodetool snapshot operates at the node level, meaning that you will need to run it at the same time on multiple nodes.
NTP SERVICE !!!


nodetool listsnapshots
nodetool statusbackup

# nodetool enablebackup
# nodetool disablebackup

nodetool snapshot -t keyspace1_date +”%s” keyspace1

nodetool clearsnapshot with the -t flag and the snapshot name
nodetool clearsnapshot -t 1528233451291 — keyspace1 # Don't do it without - and without -t



# Restoring from incrementals is similar to restoring from a snapshot — copying the files and running nodetool refresh — but incrementals require a snapshot.




