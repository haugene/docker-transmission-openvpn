#!/bin/sh

if [ -f /config/transmission/settings.json ];
then
   echo "STARTING TRANSMISSION: Using custom config directory /config/transmission"
   exec /usr/bin/transmission-daemon -g /config/transmission/ &
else
   echo "STARTING TRANSMISSION: No configuration provided, using defaults"
   exec /usr/bin/transmission-daemon -g /etc/transmission-daemon/ &
fi

exec /etc/transmission-daemon/startPortUpdates.sh &

echo "STARTED PORT UPDATER"
