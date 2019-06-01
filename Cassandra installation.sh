#############################
# SSH session configuration #
#############################

vim /etc/ssh/sshd_config

	ClientAliveInterval 100m
	ClientAliveCountMax 0

systemctl restart sshd

#########################
# Clock synchronization #
#########################

yum install -y ntp
vim /etc/ntp.conf

	server ntp_server_hostname_1 iburst

ntpq -p
systemctl enable ntpd
systemctl start ntpd
timdedatectl status
ntpstat

####################
# Install jemalloc #
####################

rpm -q jemalloc
rpm -iv https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum install -y jemalloc

##################################
# Disabling firewall and SELinux #
##################################

systemctl stop firewalld
systemctl disable firewalld
vim /etc/sysconfig/selinux

	SELINUX=disabled

reboot

################
# OS preparing #
################

yum install -y epel-release
yum install -y htop wget vim mlocate ncdu rsync mlocate

# Disabling Transparent Huge Pages (THP)
cat /sys/kernel/mm/transparent_hugepage/enabled
cat /sys/kernel/mm/transparent_hugepage/defrag

# Create init script
vim /etc/init.d/disable-thp

#!/bin/bash
### BEGIN INIT INFO
# Provides:          disable-thp
# Required-Start:    $local_fs
# Required-Stop:
# X-Start-Before:    cassandra-server
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Disable THP
# Description:       disables Transparent Huge Pages (THP) on boot
### END INIT INFO

case $1 in
start)
  if [ -d /sys/kernel/mm/transparent_hugepage ]; then
    #echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled
    echo 'never' > /sys/kernel/mm/transparent_hugepage/defrag
  elif [ -d /sys/kernel/mm/redhat_transparent_hugepage ]; then
    #echo 'never' > /sys/kernel/mm/redhat_transparent_hugepage/enabled
    echo 'never' > /sys/kernel/mm/redhat_transparent_hugepage/defrag
  else
    return 0
  fi
;;
esac

# Create a file with the above code:

chmod 755 /etc/init.d/disable-thp
service disable-thp start
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag:wq
# Make sure the Init script starts at boot
chkconfig disable-thp on
systemctl enable disable-thp
cat /sys/kernel/mm/transparent_hugepage/enabled
cat /sys/kernel/mm/transparent_hugepage/defrag

# Alternative way to disable THP
grep AnonHugePages /proc/meminfo 
egrep 'trans|thp' /proc/vmstat
grep -e AnonHugePages  /proc/*/smaps | awk  '{ if($2>4) print $0} ' |  awk -F "/"  '{print $0; system("ps -fp " $3)} '
vim /etc/default/grub

  GRUB_TIMEOUT=5
  GRUB_DEFAULT=saved
  GRUB_DISABLE_SUBMENU=true
  GRUB_TERMINAL_OUTPUT="console"
  GRUB_CMDLINE_LINUX="nomodeset crashkernel=auto rd.lvm.lv=vg_os/lv_root rd.lvm.lv=vg_os/lv_swap rhgb quiet transparent_hugepage=never numa=off elevator=noop"
  GRUB_DISABLE_RECOVERY="true"

grub2-mkconfig -o /boot/grub2/grub.cfg
shutdown -r now
cat /proc/cmdline

  BOOT_IMAGE=/vmlinuz-3.10.0-514.10.2.el7.x86_64 root=/dev/mapper/vg_os-lv_root ro nomodeset crashkernel=auto

grep -i HugePages_Total /proc/meminfo 
cat /proc/sys/vm/nr_hugepages 
sysctl vm.nr_hugepages

# Update swappiness
cat /proc/sys/vm/swappiness
sh -c 'echo 1 > /proc/sys/vm/swappiness'
cp -p /etc/sysctl.conf /etc/sysctl.conf.`date +%Y%m%d-%H:%M`
sh -c 'echo "" >> /etc/sysctl.conf'
sh -c 'echo "vm.swappiness = 0" >> /etc/sysctl.conf'

# Setting hard limits
echo 'cassandra soft nproc 4096' >> /etc/security/limits.d/91-cassandra.conf
echo 'cassandra hard nproc 16384' >> /etc/security/limits.d/91-cassandra.conf

####################################################################
# Java installation with Oracle JDK - no longer available as free  #
####################################################################

cd /opt/
wget --no-cookies --no-check-certificate --header \
"Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" \
"https://download.oracle.com/otn/java/jdk/8u211-b12/478a62b7d4e34b78b671c754eaaf38ab/jdk-8u211-linux-x64.tar.gz"
tar xzf jre-8u201-linux-x64.tar.gz
cd /opt/jre1.8.0_201/
alternatives --install /usr/bin/java java /opt/jre1.8.0_201/bin/java 2
alternatives --config java
alternatives --install /usr/bin/jar jar /opt/jre1.8.0_201/bin/jar 2
alternatives --install /usr/bin/javac javac /opt/jre1.8.0_201/bin/javac 2
alternatives --set jar /opt/jre1.8.0_201/bin/jar
alternatives --set javac /opt/jre1.8.0_201/bin/javac
java -version
export JAVA_HOME=/opt/jre1.8.0_201
export JRE_HOME=/opt/jre1.8.0_201/jre
export PATH=$PATH:/opt/jre1.8.0_201/bin:/opt/jre1.8.0_201/jre/bin


##############################
# Java Open JDK installation #
##############################

yum -y update
yum -y install java-1.8.0-openjdk
java -version
update-alternatives --config java
echo 'export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.212.b04-0.el7_6.x86_64/jre/bin/java' >> ~/.bash_profile
echo 'export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.212.b04-0.el7_6.x86_64/jre/bin/java' >> ~/.bashrc
source ~/.bash_profile
source ~/.bashrc
echo $JAVA_HOME

##########################
# Cassandra installation #
##########################

python --version
python -V 

touch /etc/yum.repos.d/cassandra.repo
echo "[cassandra]
name=Apache Cassandra
baseurl=https://www.apache.org/dist/cassandra/redhat/311x/
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://www.apache.org/dist/cassandra/KEYS" > /etc/yum.repos.d/cassandra.repo
cat /etc/yum.repos.d/cassandra.repo
yum install -y cassandra


#vim /etc/systemd/system/multi-target...

#LimitMEMLOCK=infinity
#LimitNOFILE=100000
#LimitNPROC=32768
#LimitAS=infinityd

#systemctl daemon-reload
systemctl enable cassandra
systemctl start cassandra
systemctl status cassandra
cassandra -v

chown -R cassandra:cassandra /cassandra
vim /etc/cassandra/conf/cassandra.yaml

cluster_name: 'Meta Trader Replication Dev'
num_tokens: 256
seed_provider:
    - class_name: org.apache.cassandra.locator.SimpleSeedProvider
      parameters:
          - seeds: "10.59.5.83,10.59.5.84,10.59.5.85"
listen_address: 10.59.5.83
storage_port: 7000
native_transport_port: 9042
data_file_directories:
    - /cassandra/data
commitlog_directory: /cassandra/commitlog
saved_caches_directory: /cassandra/saved_caches
hints_directory: /cassandra/hints
start_rpc: true
rpc_address: 10.59.5.83

cqlsh [IP] 9042 -C -u [username] -p [password]
cqlsh> SELECT 
	bootstrapped,
	broadcast_address,
	cluster_name,
	data_center,
	host_id,
	listen_address,
	rack,
	release_version
FROM system.local;

 bootstrapped | broadcast_address | cluster_name   | data_center | host_id                              | listen_address | rack  | release_version
--------------+-------------------+----------------+-------------+--------------------------------------+----------------+-------+-----------------
    COMPLETED |    172.20.100.113 | Leader Capital | datacenter1 | b69303d9-133b-40b7-a952-80b57d47f868 | 172.20.100.113 | rack1 |          3.11.3

cqlsh> QUIT;
cqlsh> EXIT;

#####################################
# Clean up Cassandra repair history #
#####################################

du -md 1 <cassandra_root>/data/data/ | sort -n

ALTER TABLE system_distributed.repair_history WITH default_time_to_live = 604800;
TRUNCATE system_distributed.repair_history;
ALTER TABLE system_distributed.parent_repair_history WITH default_time_to_live = 604800;
TRUNCATE system_distributed.parent_repair_history;

nodetool clearsnapshot system_distributed
