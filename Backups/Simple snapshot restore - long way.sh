cqlsh 172.20.100.113 9042

cqlsh> TRUNCATE TABLE market_streamer.market_streamer;
cqlsh> SELECT COUNT(*) AS Count FROM market_streamer.market_streamer;
cqlsh> DESCRIBE market_streamer;
cqlsh> QUIT;

ll /var/lib/cassandra/data/market_streamer/market_streamer-aa0639a05e9a11e9b83ffd47b2aa4eba/
ll /cassandra_backups/cassandra01/2019-05-15/SNAPSHOTS/market_streamer/market_streamer-aa0639a05e9a11e9b83ffd47b2aa4eba/snapshots/snapshot-15052019_0100/snapshot-15052019_0100/

rsync \
	-pavz \
	/cassandra_backups/cassandra01/2019-05-15/SNAPSHOTS/market_streamer/market_streamer-aa0639a05e9a11e9b83ffd47b2aa4eba/snapshots/snapshot-26052019_0100/* \
	/var/lib/cassandra/data/market_streamer/market_streamer-aa0639a05e9a11e9b83ffd47b2aa4eba/snapshots/

rsync \
	-pavz \
	/var/lib/cassandra/data/market_streamer/market_streamer-aa0639a05e9a11e9b83ffd47b2aa4eba/snapshots/snapshot-26052019_0100/* \
	/var/lib/cassandra/data/market_slltreamer/market_streamer-aa0639a05e9a11e9b83ffd47b2aa4eba/

chown -R cassandra:cassandra /var/lib/cassandra/
nodetool repair
