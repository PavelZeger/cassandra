#!/bin/bash

_MAIL_LIST="pavelz@naya-tech.co.il"
_CASSANDRA_USER="cassandra"
_CASSANDRA_PASS="cassandra"

_HOST=$(hostname -I | awk '{print $1}')
_HOSTNAME=$(hostname -f)
_PORT=9042
_BACKUP_DIR=/cassandra_backups/$_HOSTNAME
_COMMITLOG_DIR=/var/lib/cassandra/commitlog

_TODAY_DATE=$(date +%F)
_BACKUP_COMMITLOG_DIR="$_BACKUP_DIR/$_TODAY_DATE/COMMITLOG"
_LOG_DIR=/root/scripts/logs/
_LOGFILE="${_LOG_DIR}backup_${_TODAY_DATE}.log"

remove_help_files() {
	rm -rf /root/scripts/logs/commitlog_path_list
#	rm -rf /root/scripts/logs/incremental_dir_list
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

log "Commit log backup process started..."

### Create / check backup directory ####
create_commit_log_backup_dir() {
	log "Creating commit log backup directories..."
	if [ -d  "$_BACKUP_COMMITLOG_DIR" ] 
		then echo "$_BACKUP_COMMITLOG_DIR already exist"
	else mkdir -p "$_BACKUP_COMMITLOG_DIR"
	fi
	log "Created commit log backup directories."
}

### Get commit log backups' directory path
get_commit_log_dir_path() {
	find $_COMMITLOG_DIR -type f -name *.log | awk '{print}' > /root/scripts/logs/commitlog_path_list; RETVAL=$?
	if [ "${RETVAL}." == "0." ]
		then
			log "Got commit log backups directories path succefully" 0
		else
			log "Failed to get commit log backups directories path" 1
	fi
}

### Copy backups' files to backup dir
copy_commit_log_files_to_nfs() {
	for FILE in `cat /root/scripts/logs/commitlog_path_list`;
	do
		_INC_PATH_TRIM=`echo $FILE | awk '{gsub("'$_COMMITLOG_DIR'", "");print}'`
		rsync -prvaz "$FILE" "$_BACKUP_COMMITLOG_DIR"; RETVAL=$?
		if [ "${RETVAL}." == "0." ]
			then
				log "Copied an commit log file $FILE to backup directory succefully" 0
			else
				log "Failed to copy an commit log file $FILE to backup directory" 1
		fi
	done
}

### Remove commit log files older than a week
remove_old_commit_log_backups() {
	for FILE in `find $_BACKUP_COMMITLOG_DIR -type f -name *.log`;
	do
		find $FILE -type f -mtime +7 -exec rm -rf {} \;; RETVAL=$?
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
create_commit_log_backup_dir
get_commit_log_dir_path
copy_commit_log_files_to_nfs
remove_old_commit_log_backups

log "Commit log backup process ended."