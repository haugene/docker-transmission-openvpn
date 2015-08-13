#!/bin/sh

# Source our persisted env variables from container startup
. /etc/transmission-daemon/environment-variables.sh

tun0ip=$(ifconfig tun0 | sed -n '2 p' | awk '{print $2}' | cut -d: -f2)
echo "Updating TRANSMISSION_BIND_ADDRESS_IPV4 to tun0 ip: ${tun0ip}"
export TRANSMISSION_BIND_ADDRESS_IPV4=${tun0ip}

echo "Generating transmission settings.json from env variables"
# Ensure TRANSMISSION_HOME is created
mkdir -p ${TRANSMISSION_HOME}
dockerize -template /etc/transmission-daemon/settings.tmpl:${TRANSMISSION_HOME}/settings.json /bin/true

echo "STARTING TRANSMISSION"
exec /usr/bin/transmission-daemon -g ${TRANSMISSION_HOME} &

echo "STARTING PORT UPDATER"
exec /etc/transmission-daemon/periodicUpdates.sh &

echo "Transmission startup script complete."
