#!/bin/sh
# Script for torrent completion in Transmission.
#
# 1. Copy downloaded torrents to a "staging" directory (where auto-renamers look)
# 2. Move finished (done seeding) torrents to a "complete" directory
# 3. Remove staging files after 7 days of inactivity
# 4. Remove complete files after 30 days of completion

# Enter your completed and staging torrent directories here
COMPLETEDIR=/media/downloads/.complete
STAGINGDIR=/media/downloads/.staging

# Log file
LOG=/var/log/torrent.log

# Log the time and name of the completed torrent that triggered the script
echo "$TR_TIME_LOCALTIME    Torrent $TR_TORRENT_ID \"$TR_TORRENT_NAME\" completed." >> $LOG

# First copy the completed torrent to the staging folder (where auto-renamers look).
# Also touch the file to update the last modified date
FILES=`transmission-remote --torrent $TR_TORRENT_ID --files | sed -e '1d;2d;s/^ &//' | tr -s ' ' | cut -d' ' -f8- | sed -e 's/ /\\ /g'`
echo "$FILES" | while read -r FILE; do
	cp "/media/downloads/$FILE" "$STAGINGDIR"
	echo "$TR_TIME_LOCALTIME    File \"$FILE\" copied to staging." >> $LOG
	touch "$STAGINGDIR/$FILE"
done 

# Iterate through all torrents to move finished torrents (done seeding)
# to the COMPLETEDIR. Remove from transmission after moved.
TORRENTLIST=`transmission-remote --list | sed -e '1d;$d;s/^ *//' | cut -f1 -d' '`
for TORRENTID in $TORRENTLIST
do
	TORRENTID=`echo "$TORRENTID" | sed 's:*::'`
	INFO=`transmission-remote --torrent $TORRENTID --info`
	NAME=`echo "$INFO" | grep "Name: *" | sed -n -e 's/  Name: \(.*\)/\1/p'`
	DL_COMPLETED=`echo "$INFO" | grep "Percent Done: 100%"`		# will match if done downloading
	STATE_STOPPED=`echo "$INFO" | grep "State: Stopped\|Finished"`	# will match if done seeding

	if [ "$DL_COMPLETED" != "" ] && [ "$STATE_STOPPED" != "" ]; then
		transmission-remote --torrent $TORRENTID --move $COMPLETEDIR
		transmission-remote --torrent $TORRENTID --remove
		echo "$TR_TIME_LOCALTIME    \"$NAME\" moved to $COMPLETEDIR" >> $LOG
	fi
done

# Set full full access on COMPLETEDIR and STAGINGDIR
# Note this is a BAD IDEA from a security standpoint. Set appropriate permissions
# instead of wide-open access if at all possible. I'm being lazy here.
chmod -R 777 $COMPLETEDIR/*
chmod -R 777 $STAGINGDIR/*

# Remove files/dirs from STAGINGDIR that are older than 7 days
find $STAGINGDIR -mtime +7 -exec rm {} \;
find $STAGINDDIR -mtime +7 -exec rmdir {} \;

# Remove files/dirs from COMPLETEDIR that are older than 30 days
find $COMPLETEDIR -mtime +30 -exec rm {} \;
find $COMPLETEDIR -mtime +30 -exec rmdir {} \;

# Add a blank line to the log file
echo " " >> $LOG
