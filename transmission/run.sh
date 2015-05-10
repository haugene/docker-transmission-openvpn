#!/bin/sh

if [ ! -z "${KEEP_TRANSMISSION_STATE}" ]
then
   echo "STARTING TRANSMISSION: Using transmission-data subdirectory to your /data mount point to store state."

   # Initialize settings from environment variables
   dockerize -template /etc/transmission-daemon/settings.tmpl:/data/transmission-data/settings.json \
  true

   exec /usr/bin/transmission-daemon -g /data/transmission-data/ &
else
   echo "STARTING TRANSMISSION: Storing state in container only."

   # Initialize settings from environment variables
   dockerize -template /etc/transmission-daemon/settings.tmpl:/etc/transmission-daemon/settings.json \
  true

   exec /usr/bin/transmission-daemon -g /etc/transmission-daemon/ &
fi

exec /etc/transmission-daemon/startPortUpdates.sh &

echo "STARTED PORT UPDATER"
