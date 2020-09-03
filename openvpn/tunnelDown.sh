#!/bin/bash

/etc/transmission/stop.sh
[[ ! -f /opt/tinyproxy/stop.sh ]] || /opt/tinyproxy/stop.sh


# Attempt to restart TUN

INTERFACE=$(ls /sys/class/net | grep tun)
ISINTERFACE=$?

if [[ ${ISINTERFACE} -ne 0 ]]
then
        echo "TUN Interface not found"
        exit 1
fi

ip link set ${INTERFACE} down
sleep 1
ip link set ${INTERFACE} up

exit 0
