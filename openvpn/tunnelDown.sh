#!/bin/bash
#tunnel is down, restore resolv.conf to previous version
# Source our persisted env variables from container startup
. /etc/transmission/environment-variables.sh
source /etc/openvpn/utils.sh

if ls /etc/resolv.conf-*.sv 1> /dev/null 2>&1; then
    cp /etc/resolv.conf-*.sv /etc/resolv.conf
    echo "resolv.conf was restored"
else
    echo "resolv.conf backup not found, could not restore"
fi

/etc/transmission/stop.sh
[[ -f /opt/privoxy/stop.sh ]] && /opt/privoxy/stop.sh
