#!/bin/sh
# script to check for completed torrents and stop and move them

# enter your completed torrent directory here
COMPLETEDIR=/media/downloads/.complete
STAGINGDIR=/media/downloads/.staging
LOG=/var/log/torrent.log

echo "$TR_TIME_LOCALTIME    Torrent $TR_TORRENT_ID \"$TR_TORRENT_NAME\" completed." >> $LOG
#echo "$TR_TIME_LOCALTIME    Torrent \"$TR_TORRENT_NAME\" completed." >> /test/output

# first copy the completed torrent to the staging folder (where auto-renamers look)
# also touch the file to update the last modified date
FILES=`transmission-remote --torrent $TR_TORRENT_ID --files | sed -e '1d;2d;s/^ &//' | tr -s ' ' | cut -d' ' -f8- | sed -e 's/ /\\ /g'`

echo "$FILES" | while read -r FILE; do
	cp "/media/downloads/$FILE" "$STAGINGDIR"
	echo "$TR_TIME_LOCALTIME    File \"$FILE\" copied to staging." >> $LOG
	touch "$STAGINGDIR/$FILE"
done 

TORRENTLIST=`transmission-remote --list | sed -e '1d;$d;s/^ *//' | cut -f1 -d' '`
for TORRENTID in $TORRENTLIST
do
	TORRENTID=`echo "$TORRENTID" | sed 's:*::'`
	INFO=`transmission-remote --torrent $TORRENTID --info`
	NAME=`echo "$INFO" | grep "Name: *" | sed -n -e 's/  Name: \(.*\)/\1/p'`
	DL_COMPLETED=`echo "$INFO" | grep "Percent Done: 100%"`
	STATE_SEEDING=`echo "$INFO" | grep "State: Seeding\|Idle"`
	STATE_STOPPED=`echo "$INFO" | grep "State: Stopped\|Finished"`	

	if [ "$DL_COMPLETED" != "" ] && [ "$STATE_STOPPED" != "" ]; then
		transmission-remote --torrent $TORRENTID --move $COMPLETEDIR
		transmission-remote --torrent $TORRENTID --remove
		echo "$TR_TIME_LOCALTIME    \"$NAME\" moved to $COMPLETEDIR" >> $LOG
	fi
done

# set full full access on COMPLETEDIR and STAGINGDIR
chmod -R 777 $COMPLETEDIR/*
chmod -R 777 $STAGINGDIR/*

# remove files/dirs from STAGINGDIR that are older than 7 days
find $STAGINGDIR -mtime +7 -exec rm {} \;
find $STAGINDDIR -mtime +7 -exec rm {} \;

# remove files/dirs from COMPLETEDIR that are older than 30 days
find $COMPLETEDIR -mtime +30 -exec rm {} \;
find $COMPLETEDIR -mtime +30 -exec rmdir {} \;

echo " " >> $LOG
