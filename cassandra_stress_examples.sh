mkdir cassandra_stress_logs
cd cassandra_stress_logs
cassandra-stress --help
cassandra-stress write --help
cassandra-stress write n=100000000 cl=QUORUM truncate=always -schema keyspace=keyspace -rate threads=200 -log file=write_$NOW.log
cassandra-stress write n=100000 cl=LOCAL_QUORUM -mode native cql3 -schema keyspace="keyspace1" -log file=load_1M_rows.log -node 172.20.100.113,172.20.100.114,172.20.100.115,172.20.100.116,172.20.100.117

cassandra-stress mixed \
    duration=30m \
    ratio\(write=100000,read=5000\) \
    no-warmup \
    cl=LOCAL_QUORUM \
    -mode native cql3 \
    -schema keyspace="keyspace1" \
    -log file=/root/cassandra_stress_logs/cassandra_stress_1M_30min.log \
    -node 172.20.100.113,172.20.100.114,172.20.100.115,172.20.100.116,172.20.100.117

cassandra-stress mixed \
    n=1000000 \
    ratio\(write=100000,read=5000\) \
    no-warmup \
    cl=LOCAL_QUORUM \
    -mode native cql3 \
    -schema keyspace="keyspace1" \
    -log file=/root/cassandra_stress_logs/cassandra_stress_1M_30min.log \
    -node 172.20.100.113,172.20.100.114,172.20.100.115,172.20.100.116,172.20.100.117

################################
# Cassandts stress test file

CASSANDRA_STRESS='/usr/bin/cassandra-stress write'
NOW=$(date +%d%m%Y_%H%M%S)
PARENT_DIR='/root/cassandra_stress_logs'
LOG_FILE=$PARENT_DIR/cassandra_stress_$NOW.log
N='n=1000000'
CL='cl=all'
MODE='-mode native cql3'
LOG='-log file=$LOG_FILE'
#HOSTS=$(hostname  -I | cut -f1 -d' ')
HOSTS="-node 172.20.100.113,172.20.100.114,172.20.100.115,172.20.100.116,172.20.100.117"

touch $LOG_FILE
$CASSANDRA_STRESS $N $CL $MODE -schema keyspace="keyspace1" $LOG $HOSTS

#################################

cassandra-stress user profile=./stress.yaml n=1000000 ops\(insert=20,read1=1\) no-warmup truncate=never cl=LOCAL_QUORUM duration=2m  

### YAML configuration file ###

# Keyspace name and create CQL
keyspace: mt4_replication_stress
keyspace_definition: |
  CREATE KEYSPACE mt4_replication WITH replication = {'class': 'NetworkTopologyStrategy', 'datacenter1' : 5, 'datacenter2' : 5} AND durable_writes = true;

# Table name and create CQL
table: mt4_replication_stress
table_definition: |
  CREATE TABLE mt4_replication (
    id text PRIMARY KEY,
    accountid bigint,
    actiontype text,
    closeprice decimal,
    closequoterecord map<text, decimal>,
    closetime timestamp,
    command int,
    comment text,
    commission decimal,
    openprice decimal,
    openquoterecord map<text, decimal>,
    opentime timestamp,
    partialto bigint,
    profit decimal,
    serverid text,
    stoploss decimal,
    storage decimal,
    symbol text,
    takeprofit decimal,
    tradeid bigint,
    volume int
) WITH bloom_filter_fp_chance = 0.01
    AND caching = {'keys': 'ALL', 'rows_per_partition': 'NONE'}
    AND comment = 'A test table for Avi (mt4_replication)'
    AND compaction = {'class': 'org.apache.cassandra.db.compaction.SizeTieredCompactionStrategy', 'max_threshold': '32', 'min_threshold': '4'}
    AND compression = {'chunk_length_in_kb': '64', 'class': 'org.apache.cassandra.io.compress.LZ4Compressor'}
    AND crc_check_chance = 1.0
    AND dclocal_read_repair_chance = 0.1
    AND default_time_to_live = 0
    AND gc_grace_seconds = 864000
    AND max_index_interval = 2048
    AND memtable_flush_period_in_ms = 0
    AND min_index_interval = 128
    AND read_repair_chance = 0.0
    AND speculative_retry = '99PERCENTILE';
 
# Specs for insert queries
insert:
  partitions: fixed(1)      # 1 partition per batch
  batchtype: UNLOGGED       # use unlogged batches
  select: fixed(10)/10      # no chance of skipping a row when generating inserts
