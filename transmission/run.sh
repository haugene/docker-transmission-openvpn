#!/bin/sh

if [ -f /data/transmission-data/settings.json ]
then
   echo "STARTING TRANSMISSION: Using transmission-data subdirectory to your /data mount point to store state."
   exec /usr/bin/transmission-daemon -g /data/transmission-data/ &
else
   echo "STARTING TRANSMISSION: Storing state in container only."
   exec /usr/bin/transmission-daemon -g /etc/transmission-daemon/ &
fi

exec /etc/transmission-daemon/startPortUpdates.sh &

echo "STARTED PORT UPDATER"
