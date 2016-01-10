#! /bin/bash

#
# Script: run.PROCESS_PLESK_MAIL_LOGS.sh
# Purpose: Process Plesk Mail Logs
# Author: Laurence Hubbard, 10th January 2016
#

# Need to source bashrc for using the script with CRON.
source /root/.bashrc

# Defining Local Variables
UNIX=/root/volleymaster_heart/MONITORING
BIN=$UNIX/bin
MAIL_LOGS=/usr/local/psa/var/log/maillog*
LOGS=/var/log/volleymaster/MONITORING
LOG_FILE=$LOGS/$(basename $0)"."$(date +%F)".log"
TMP=/tmp/volleymaster/MONITORING
PYTHON=$UNIX/python

# Defining Rules for Dynamic Variables
MONTH=$(date -d"yesterday" | awk '{print $2}')
DAY=$(date -d"yesterday" | awk '{print $3}')

# Defining Local Functions

function get_senders_from_log(){
	INPUT_FILE=$1
	
	grep from=\< $TMP/$INPUT_FILE > $TMP/$INPUT_FILE.from
	python $PYTHON/pull_sender.py < $TMP/$INPUT_FILE.from > $TMP/$INPUT_FILE.from.emails
	cat $TMP/$INPUT_FILE.from.emails
}

function get_recipients_from_log(){
	INPUT_FILE=$1

	grep to=\< $TMP/$INPUT_FILE > $TMP/$INPUT_FILE.to
	python $PYTHON/pull_recipient.py < $TMP/$INPUT_FILE.to > $TMP/$INPUT_FILE.to.emails
	cat $TMP/$INPUT_FILE.to.emails
}

#
# MAIN SCRIPT EXECUTION
#

# Cleaning the processing directory
rm -rf $TMP $TMP
mkdir -p $TMP $TMP

# Get latest copy of mail logs
cp $MAIL_LOGS $TMP/
gunzip $TMP/* &>> $LOG_FILE

# Get list of files to process
ls $TMP > $TMP/LOGS_TO_PROCESS.temp

# Run extraction functions to get senders and recipients (makes use of python scripts)
while read MAIL_LOG
do
	get_senders_from_log $MAIL_LOG >> $TMP/SENDERS.info
	get_recipients_from_log $MAIL_LOG >> $TMP/RECIPIENTS.info
done < $TMP/LOGS_TO_PROCESS.temp

# Sort the outputs
cat $TMP/SENDERS.info | sort | uniq > $TMP/sorting.temp
cat $TMP/sorting.temp > $TMP/SENDERS.info

cat $TMP/RECIPIENTS.info | sort | uniq > $TMP/sorting.temp
cat $TMP/sorting.temp > $TMP/RECIPIENTS.info

# Get some statistics
NUMBER_OF_RECIPIENTS=$(cat $TMP/RECIPIENTS.info | wc -l)
NUMBER_OF_SENDERS=$(cat $TMP/SENDERS.info | wc -l)

echo "
OVERVIEW OF $MAIL_LOGS

NUMBER_OF_RECIPIENTS $NUMBER_OF_RECIPIENTS for $MONTH $DAY
NUMBER_OF_SENDERS $NUMBER_OF_SENDERS for $MONTH $DAY
" &>> $LOG_FILE

echo "
OVERVIEW OF $MAIL_LOGS

NUMBER_OF_RECIPIENTS $NUMBER_OF_RECIPIENTS for $MONTH $DAY
NUMBER_OF_SENDERS $NUMBER_OF_SENDERS for $MONTH $DAY
"
