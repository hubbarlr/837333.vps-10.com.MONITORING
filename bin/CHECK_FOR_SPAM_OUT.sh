#! /bin/bash

#
# Script: CHECK_FOR_SPAM_OUT.sh
# Purpose: Cross Reference Processed Plesk Mail Logs For Potential Outgoing SPAM
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

# White List Location
WHITE_LIST=$UNIX/info/SENDERS.WHITE_LIST.info
PROCESSED_SENDERS=$TMP/SENDERS.info
PROCESSED_RECIPIENTS=$TMP/RECIPIENTS.info

# Maintaining old variables
LOC=$BIN
SCRIPT=$(basename $0)

# Run "Process Plesk Mail Logs" script
sh $LOC/run.PROCESS_PLESK_MAIL_LOGS.sh

# Join the output of the "Process Plesk Mail Logs" script with the white list and then filter for associated domain names.
join -v 1 $PROCESSED_SENDERS $WHITE_LIST > $TMP/UNKNOWN_ADDRESSES.temp
#join -v 1 $PROCESSED_RECIPIENTS $WHITE_LIST >> $TMP/UNKNOWN_ADDRESSES.temp

rm -f $TMP/SUSPCIOUS_ADDRESSED.temp

for DOMAIN in $(ls /var/www/vhosts | grep \\.)
do
	cat $TMP/UNKNOWN_ADDRESSES.temp | grep "@"$DOMAIN >> $TMP/SUSPCIOUS_ADDRESSED.temp
done

SPAM_OUT_COUNT=$(cat $TMP/SUSPCIOUS_ADDRESSED.temp | wc -l)

if [ $SPAM_OUT_COUNT -ne 0 ]; then
	cat $TMP/SENDERS.info > $LOGS/SENDERS.info.$(date +%F)
	cat $TMP/RECIPIENTS.info > $LOGS/RECIPIENTS.info.$(date +%F)
	echo "$SCRIPT $(date +%F\ %T) -- Outgoing mail was sent from $SPAM_OUT_COUNT unknown addresses yesterday. See $TMP/SUSPCIOUS_ADDRESSED.temp" >> $LH_ALERT_STREAM
	echo "$SCRIPT $(date +%F\ %T) -- Outgoing mail was sent from $SPAM_OUT_COUNT unknown addresses yesterday. See $TMP/SUSPCIOUS_ADDRESSED.temp"
else
	echo "$SCRIPT $(date +%F\ %T) -- There was no outgoing mail sent from an owned domain not on the white list yesterday." >> $LH_ALERT_STREAM
	echo "$SCRIPT $(date +%F\ %T) -- There was no outgoing mail sent from an owned domain not on the white list yesterday."
fi
