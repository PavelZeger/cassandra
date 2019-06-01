# 1. Backup a full schema
cqlsh 172.20.100.113 9042 -e "DESCRIBE FULL SCHEMA;" > /root/backup_test/cassandra_full_schema_$(date +%d%m%Y_%H%M%S).cql
pssh -ivAP -h ~/.pssh_hosts cqlsh $(hostname  -I | cut -f1 -d' ') -e "DESCRIBE FULL SCHEMA;" > /root/backup_test/cassandra_full_schema_$(date +%d%m%Y_%H%M%S).cql

# 2. Run nodetool cleanup to ensure that invalid replicas are removed
nodetool cleanup
pssh -ivAP -h ~/.pssh_hosts nodetool cleanup

# 3. Run the nodetool clearsnapshot command to delete all snapshots for a node, 
nodetool -h localhost -p 7199 clearsnapshot
pssh -ivAP -h ~/.pssh_hosts nodetool -h $(hostname  -I | cut -f1 -d' ') -p 7199 clearsnapshot


nodetool clearsnapshot -t <snapshot_name>


# 2. Run the nodetool snapshot command, specifying the hostname, JMX port, and keyspace
pssh
nodetool --host localhost --port 7199 snapshot --tag [snapshot name]
#data_directory/keyspace_name/table_name-UUID/snapshots/snapshot_name

When incremental backups are enabled (disabled by default), Cassandra hard-links each memtable-flushed SSTable to a backups directory under the keyspace data directory. This allows storing backups offsite without transferring entire snapshots. Also, incremental backups combined with snapshots to provide a dependable, up-to-date backup mechanism. Compacted SSTables will not create hard links in /backups because these SSTables do not contain any data that has not already been linked.A snapshot at a point in time, plus all incremental backups and commit logs since that time form a compete backup.

As with snapshots, Cassandra does not automatically clear incremental backup files. DataStax recommends setting up a process to clear incremental backup hard-links each time a new snapshot is created.




# Procedure for enabling incremental backups
vim /etc/cassandra/conf/cassandra.yaml
	
	incremental_backups: true

# or
sed -i 's/incremental_backups: false/incremental_backups: true/g' /etc/cassandra/conf/cassandra.yaml
pssh -ivAP -h ~/.pssh_hosts sed -i 's/incremental_backups: false/incremental_backups: true/g' /etc/cassandra/conf/cassandra.yaml
