#!/bin/bash

# Description : The backup script will complete the backup in 2 phases -
#  1. First Phase: Taking backup of Keyspace SCHEMA
#  2. Seconf Phase: Taking snapshot of keyspaces

_MAIL_LIST="pavelz@naya-tech.co.il"
_CASSANDRA_USER="cassandra"
_CASSANDRA_PASS="cassandra"

_HOST=$(hostname -I | awk '{print $1}')
_HOSTNAME=$(hostname -f)
_PORT=9042
_BACKUP_DIR=/cassandra_backups/$_HOSTNAME
_DATA_DIR=/var/lib/cassandra/data
_NODETOOL=$(which nodetool)
_CQLSH=$(which cqlsh)

_TODAY_DATE=$(date +%F)
_BACKUP_SNAPSHOT_DIR="$_BACKUP_DIR/$_TODAY_DATE/SNAPSHOTS"
_BACKUP_SCHEMA_DIR="$_BACKUP_DIR/$_TODAY_DATE/SCHEMA"
_SNAPSHOT_DIR=$(find $_DATA_DIR -type d -name snapshots)
_SNAPSHOT_NAME=snapshot-$(date +%d%m%Y_%H%M)
_DATE_SCHEMA=$(date +%d%m%Y_%H%M)
_LOG_DIR=/root/scripts/logs/
_LOGFILE="${_LOG_DIR}backup_${_TODAY_DATE}.log"

remove_help_files() {
	rm -rf /root/scripts/logs/keyspace_name_schema.cql
	rm -rf /root/scripts/logs/snapshot_dir_list
	rm -rf /root/scripts/logs/snp_dir_list
}

log() {
	touch $_LOGFILE
	if [ "$2." == "0." ]; 
		then echo -ne "[`date '+%d%m%Y %T'`] $1 \t[\e[40;32mOK\e[40;37m]\n" | expand -t 70 | tee -a ${_LOGFILE}
	elif [ "$2." == "1." ]; 
		then echo -ne "[`date '+%d%m%Y %T'`] $1 \t[\e[40;31mERROR\e[40;37m]\n" | expand -t 70 | tee -a ${_LOGFILE}
		exit 1
	else echo -ne "[`date '+%d%m%Y %T'`] $1 \n" | expand -t 70 | tee -a ${_LOGFILE}
	fi
}

log "Backup process started..."

###### Create / check backup directory ####
create_backup_dir() {
	log "Creating backup directories..."
	if [ -d  "$_BACKUP_SCHEMA_DIR" ] 
		then echo "$_BACKUP_SCHEMA_DIR already exist"
	else mkdir -p "$_BACKUP_SCHEMA_DIR"
	fi

	if [ -d  "$_BACKUP_SNAPSHOT_DIR" ] 
		then echo "$_BACKUP_SNAPSHOT_DIR already exist"
	else mkdir -p "$_BACKUP_SNAPSHOT_DIR"
	fi
	log "Created backup directories."
}

# Clean up keyspaces and partition keys no longer belonging to a node
keyspaces_cleanup() {
	$_NODETOOL cleanup -j 0; RETVAL=$?
	if [ "${RETVAL}." == "0." ]
		then
			log "Cleanup node succefully" 0
		else
			log "Failed to cleanup node" 1
	fi
}

# Clear old snapshots from data directory
clear_old_snapshots() {
	$_NODETOOL clearsnapshot; RETVAL=$?
	if [ "${RETVAL}." == "0." ]
		then
			log "Cleanup snapshots succefully" 0
		else
			log "Failed to cleanup snapshots" 1
	fi
}

##################### SECTION 1 : SCHEMA BACKUP ############################################ 

## List All Keyspaces
list_keyspaces() {
	$_CQLSH $_HOST $_PORT -e "DESCRIBE KEYSPACES" > /root/scripts/logs/keyspace_name_schema.cql; RETVAL=$?
	if [ "${RETVAL}." == "0." ]
	   then
	    	log "Listed keyspaces succefully" 0
	   else
	    	log "Failed to list keyspaces" 1
	fi
}

#_KEYSPACE_NAME=$(cat keyspace_name_schema.cql)

## Create directory inside backup SCHEMA directory. As per keyspace name
create_subdir_schema() {
	for i in $(cat /root/scripts/logs/keyspace_name_schema.cql)
	do
		if [ -d $i ]
			then echo "$i directory exist"
		else mkdir -p $_BACKUP_SCHEMA_DIR/$i; RETVAL=$?
			if [ "${RETVAL}." == "0." ]
		   	then 
			   	log "Created subdirectories for schemas succefully" 0
		   	else 
		   		log "Failed to create subdirectories for schemas " 1
			fi
		fi
	done
}

## Take SCHEMA Backup - All Keyspace and All tables
schema_backup() {
	for VAR_KEYSPACE in $(cat /root/scripts/logs/keyspace_name_schema.cql)
	do
		$_CQLSH $_HOST $_PORT -e "DESCRIBE KEYSPACE $VAR_KEYSPACE" > "$_BACKUP_SCHEMA_DIR/$VAR_KEYSPACE/$VAR_KEYSPACE"_schema-"$_DATE_SCHEMA".cql; RETVAL=$?
		if [ "${RETVAL}." == "0." ]
		   then
		    	log "Backuped schema $VAR_KEYSPACE succefully" 0
		   else
		    	log "Failed to backup schema $VAR_KEYSPACE" 1
		fi
	done
}
##################### SECTION 2 : SNAPSHOT BACKUP ############################################

###### Create snapshots for all keyspaces
take_snapshot() {
	$_NODETOOL snapshot -t $_SNAPSHOT_NAME
}

###### Get Snapshot directory path
get_snapshot_dir_path() {
	_SNAPSHOT_DIR_LIST=`find $_DATA_DIR -type d -name snapshots| awk '{gsub("'$_DATA_DIR'", "");print}' > /root/scripts/logs/snapshot_dir_list`; RETVAL=$?
	if [ "${RETVAL}." == "0." ]
		then
			log "Got snapshot directories path succefully" 0
		else
			log "Failed to get snapshot directories path" 1
	fi
}

#echo $_SNAPSHOT_DIR_LIST > /root/scripts/logs/snapshot_dir_list

## Create directory inside backup directory. As per keyspace name.
create_subdir_snapshots() {
	for i in `cat /root/scripts/logs/snapshot_dir_list`
	do
		if [ -d $_BACKUP_SNAPSHOT_DIR/$i ]
			then echo "$i directory exist"
		else
			mkdir -p $_BACKUP_SNAPSHOT_DIR/$i; RETVAL=$?
			if [ "${RETVAL}." == "0." ]
				then
					log "Created snapshot subdirectories succefully" 0
				else
					log "Failed to create snapshot subdirectories" 1
			fi
		fi
	done
}

### Copy default Snapshot dir to backup dir
copy_snapshots_to_backup() {
	find $_DATA_DIR -type d -name $_SNAPSHOT_NAME > /root/scripts/logs/snp_dir_list; RETVAL=$?
	if [ "${RETVAL}." == "0." ]
		then
			log "Wrote snapshot names to a log file succefully" 0
		else
			log "Failed to write snapshot names to a log file" 1
	fi

	for SNP_VAR in `cat /root/scripts/logs/snp_dir_list`;
	do
		_SNP_PATH_TRIM=`echo $SNP_VAR|awk '{gsub("'$_DATA_DIR'", "");print}'`
		rsync -prvaz "$SNP_VAR"/* "$_BACKUP_SNAPSHOT_DIR$_SNP_PATH_TRIM"; RETVAL=$?
		if [ "${RETVAL}." == "0." ]
			then
				log "Copied a snapshot $SNP_VAR to backup directory succefully" 0
			else
				log "Failed to copy a snapshot $SNP_VAR to backup directory" 1
		fi
	done
}

# Remove logs older than a week
remove_backup_logs() {
	find $_LOG_DIR -type f -name backup*.log -mtime +7 -exec rm -rf {} \;; RETVAL=$?
	if [ "${RETVAL}." == "0." ]
		then
			log "Removed logs older than a week succefully" 0
		else
			log "Failed to remove logs older than a week" 1
	fi
}

# Remove snapshots older than a week
remove_old_snapshots() {
	find $_BACKUP_DIR -type d -name 20* -mtime +7 -exec rm -rf {} \;; RETVAL=$?
	if [ "${RETVAL}." == "0." ]
		then
			log "Removed snapshots' directories older than a week succefully" 0
		else
			log "Failed to remove snapshots' directories older than a week" 1
	fi

	for i in `cat /root/scripts/logs/snapshot_dir_list`
	do
		find ${_DATA_DIR}${i} -type d -name snapshot-* -mtime +7 -exec rm -rf {} \;; RETVAL=$?
		if [ "${RETVAL}." == "0." ]
			then
				log "Removed snapshots' directories older than a week succefully" 0
			else
				log "Failed to remove snapshots' directories older than a week" 1
		fi
	done
}

# Run functions in this order
remove_help_files
create_backup_dir
keyspaces_cleanup
clear_old_snapshots
list_keyspaces
create_subdir_schema
schema_backup
take_snapshot
get_snapshot_dir_path
create_subdir_snapshots
copy_snapshots_to_backup
remove_backup_logs
remove_old_snapshots

log "Backup process ended."