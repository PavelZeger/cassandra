# Replace node

# On all node
nodetool cleanup

# On anothe node
nodetool status

	Datacenter: datacenter1
	=======================
	Status=Up/Down
	|/ State=Normal/Leaving/Joining/Moving
	--  Address         Load       Tokens       Owns    Host ID                               Rack
	UN  172.20.100.116  364.03 MiB  256          ?       7e93e897-cb57-43b3-8bd7-118f7c86bce4  rack1
	UN  172.20.100.117  423.16 MiB  256          ?       83830392-9250-416a-9abd-bc170b628a15  rack1
	UN  172.20.100.113  482.83 MiB  256          ?       b69303d9-133b-40b7-a952-80b57d47f868  rack1
	UN  172.20.100.114  375.35 MiB  256          ?       a10845ac-9c75-4086-9d2f-f6ebd8c0fc40  rack1
	DN  172.20.100.115  310.02 MiB  256          ?       9158d735-db95-4d01-ade1-e6bdb314f48d  rack1


nodetool remove <node id>
# nodetool remove 9158d735-db95-4d01-ade1-e6bdb314f48d

# On a failed node
rm -rf /var/lib/cassandra/*
chown -R cassandra:cassandra /var/lib/cassandra
systemctl start cassandra
systemctl status cassandra