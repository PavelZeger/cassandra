#!/bin/bash

# Description : The backup script will complete the backup in 2 phases -

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
_BACKUP_INCREMENTAL_DIR="$_BACKUP_DIR/$_TODAY_DATE/INCREMENTAL"
_LOG_DIR=/root/scripts/logs/
_LOGFILE="${_LOG_DIR}backup_${_TODAY_DATE}.log"

remove_help_files() {
	rm -rf /root/scripts/logs/inc_files_list
	rm -rf /root/scripts/logs/incremental_dir_list
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

log "Incremental backup process started..."

### Create / check backup directory ####
create_incremental_backup_dir() {
	log "Creating incremental backup directories..."
	if [ -d  "$_BACKUP_INCREMENTAL_DIR" ] 
		then echo "$_BACKUP_INCREMENTAL_DIR already exist"
	else mkdir -p "$_BACKUP_INCREMENTAL_DIR"
	fi
	log "Created incremental backup directories."
}

##################### SECTION 2 : INCREMENTAL BACKUP ############################################

### Get incremental backups' directory path
get_incremental_dir_path() {
	_INCREMENTAL_DIR=`find $_DATA_DIR -type d -name backups | awk '{print}' > /root/scripts/logs/incremental_dir_list`; RETVAL=$?
	if [ "${RETVAL}." == "0." ]
		then
			log "Got incremental backups directories path succefully" 0
		else
			log "Failed to get incremental backups directories path" 1
	fi
}

## Create directory inside backup directory. As per keyspace name.
create_subdir_incremental_backups() {
	for i in `cat /root/scripts/logs/incremental_dir_list`
	do
		_INC_PATH_TRIM=`echo $i | awk '{gsub("'$_DATA_DIR'", "");print}'`
		if [ -d $_BACKUP_INCREMENTAL_DIR$_INC_PATH_TRIM ]
			then echo "$i directory exist"
		else
			mkdir -p $_BACKUP_INCREMENTAL_DIR$_INC_PATH_TRIM; RETVAL=$?
			if [ "${RETVAL}." == "0." ]
				then
					log "Created incremental subdirectories succefully" 0
				else
					log "Failed to create incremental subdirectories" 1
			fi
		fi
	done
}

### Copy backups' files to backup dir
copy_incremental_files_to_nfs() {
	for DIR in `cat /root/scripts/logs/incremental_dir_list`;
	do
		find $DIR -type f >> /root/scripts/logs/inc_files_list; RETVAL=$?
		if [ "${RETVAL}." == "0." ]
			then
				log "Wrote incremental files names to a log file succefully" 0
			else
				log "Failed to write incremental files names to a log file" 1
		fi
	done

	for FILE in `cat /root/scripts/logs/inc_files_list`;
	do
		_INC_PATH_TRIM=`echo $FILE | awk '{gsub("'$_DATA_DIR'", "");print}'`
		rsync -prvaz "$FILE" "$_BACKUP_INCREMENTAL_DIR$_INC_PATH_TRIM"; RETVAL=$?
		if [ "${RETVAL}." == "0." ]
			then
				log "Copied an incremental file $FILE to backup directory succefully" 0
			else
				log "Failed to copy an incremental file $FILE to backup directory" 1
		fi
	done
}

### Remove incremental files older than a week
remove_old_incremental_backups() {
	for DIR in `cat /root/scripts/logs/incremental_dir_list`;
	do
		find $DIR -type f -mtime +7 -exec rm -rf {} \;; RETVAL=$?
		if [ "${RETVAL}." == "0." ]
			then
				log "" 0
			else
				log "" 1
		fi
	done
}

# Run functions in this order
remove_help_files
create_incremental_backup_dir
get_incremental_dir_path
create_subdir_incremental_backups
copy_incremental_files_to_nfs
remove_old_incremental_backups

log "Incremental backup process ended."