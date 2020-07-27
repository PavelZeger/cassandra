find /var/lib/cassandra/data/ -type f | grep -v -- -ib- | grep -v "/snapshots"

iostat -xdm 2

mtr -nr www.google.com
iftop -nNtP -i lo

yum install gcc-c++ patch readline readline-devel zlib zlib-devel \
   libyaml-devel libffi-devel openssl-devel make \
   bzip2 autoconf automake libtool bison iconv-devel sqlite-devel

nodetool info
nodetool status
nodetool gcstats
nodetool tpstats
nodetool describecluster
nodetool describering
nodetool ring
nodetool rangekeysample
nodetool compactionstats 
nodetool compactionhistory 
nodetool statusgossip 
nodetool gossipinfo 
nodetool statushandoff 
nodetool proxyhistograms 
nodetool toppartitions 

nodetool getlogginglevels
nodetool setlogginglevel org.apache.cassandra.service.StorageProxy DEBUG

# Get cluster's peers
SELECT * FROM system.peers;

# Query the defined keyspaces using the SELECT statement.
cqlsh> SELECT * FROM system.schema_keyspaces;

# Get the schema information for tables in the cycling keyspace.
cqlsh> SELECT * FROM system_schema.tables WHERE keyspace_name = 'cycling';

# Get details about a table's columns from system_schema.columns.
cqlsh> SELECT * FROM system_schema.columns WHERE keyspace_name = 'cycling' AND table_name = 'cyclist_name';

###########################################
# Parallel ssh installation for snapshots #
###########################################
yum install -y pssh

vim ~/.pssh_hosts

	#root@8f8m4y26o3
	root@172.20.100.113
	root@172.20.100.114
	root@172.20.100.115
	root@172.20.100.116
	root@172.20.100.117	

cat ~/.pssh_hosts

ssh root@172.20.100.113
ssh root@172.20.100.112
ssh root@172.20.100.115
ssh root@172.20.100.116
ssh root@172.20.100.117
cat .ssh/known_hosts

pssh -iAP -p 5 -t 0 -h ~/.pssh_hosts date

# You can now automate common sysadmin tasks such as patching all servers:
pssh -iAP -p 5 -t 0 -h ~/.pssh_hosts_files -- sudo yum -y update
pscp -iAP -p 5 -t 0 -h ~/.pssh_hosts_files [source path] [destination path]

# To copy $HOME/demo.txt to /tmp/ on all servers, enter:
pscp -iAP -p 5 -t 0 -h ~/.pssh_hosts $HOME/demo.txt /tmp/

prsync -iAP -p 5 -t 0 -h ~/.pssh_hosts /etc/passwd /tmp/
prsync -iAP -p 5 -t 0 -h ~/.pssh_hosts *.html /var/www/html/

# Use the pnuke command for killing processes in parallel on a number of hosts
pnuke -iAP -p 5 -t 0 -h .pssh_hosts [process name]
# kill nginx and firefox on hosts:
pnuke -iAP -p 5 -t 0 -h ~/.pssh_hosts firefox
pnuke -iAP -p 5 -t 0 -h ~/.pssh_hosts nginx

# See pssh/pscp command man pages for more information.
