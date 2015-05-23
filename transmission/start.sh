#!/bin/sh

if [ -f /data/transmission-data/settings.json ]
then
   echo "STARTING TRANSMISSION: Using transmission-data subdirectory to your /data mount point to store state."
   exec /usr/bin/transmission-daemon -g /data/transmission-data/ &
else
   echo "STARTING TRANSMISSION: Storing state in container only."
   exec /usr/bin/transmission-daemon -g /etc/transmission-daemon/ &
fi

# determine IP of tun0, and bind to it
export TRANSMISSION_BIND_ADDRESS_IPV4=$(ifconfig tun0 | sed -n '2 p' | awk '{print $2}' | cut -d: -f2)
echo "BINDING TRANSMISSION to $TRANSMISSION_BIND_ADDRESS_IPV4"
perl -p -i -e 's/!!BINDIPV4!!/$ENV{"TRANSMISSION_BIND_ADDRESS_IPV4"}/' /etc/transmission-daemon/settings.json

exec /etc/transmission-daemon/startPortUpdates.sh &

echo "STARTED PORT UPDATER"
