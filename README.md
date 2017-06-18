# TransmissionCompletionScript
Torrent completion script for Transmission daemon.

I wrote this script for a Transmission daemon running in a jail on a Freenas 9.10.2. This Transmission daemon serves as a torrent client in an auto-downloading setup using CouchPotato and SickRage, and as such I wanted it to require little manual maintenance to keep it tidy. The script is run automatically by Transmission when a torrent is finished downloading, see the Transmission documentation for more info: https://trac.transmissionbt.com/wiki/Scripts

This script was written to perform the following:

1. Copy fully downloaded torrents to a "staging" directory where they will be picked up by the auto-renamers of CouchPotato and SickRage.
2. Move completed (finished seeding) torrents to a "complete" directory to get them out of the active torrent directory.
3. Remove leftover files from "staging" after 7 days of inactivity.
4. Remove completed torrents from "complete" after 30 days of completion.
5. Log activity to file for record keeping.
