#!/bin/sh

if [ -f /config/transmission/settings.json ];
then
   echo "STARTING TRANSMISSION: Using custom config directory /config/transmission"
   exec /usr/bin/transmission-daemon -f -g /config/transmission/
else
   echo "STARTING TRANSMISSION: No configuration provided, using defaults"
   exec /usr/bin/transmission-daemon -f -g /etc/transmission-daemon/
fi
