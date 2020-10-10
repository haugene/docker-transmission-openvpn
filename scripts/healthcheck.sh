#!/bin/bash

#Network check
# Ping uses both exit codes 1 and 2. Exit code 2 cannot be used for docker health checks,
# therefore we use this script to catch error code 2
HOST=${HEALTH_CHECK_HOST}

if [[ -z "$HOST" ]]
then
    echo "Host  not set! Set env 'HEALTH_CHECK_HOST'. For now, using default google.com"
    HOST="google.com"
fi

ping -c 1 $HOST
STATUS=$?
if [[ ${STATUS} -ne 0 ]]
then
    echo "Network is down"
    INTERFACE=$(ls /sys/class/net | grep tun)
    ISINTERFACE=$?

    if [[ ${ISINTERFACE} -ne 0 ]]
    then
        echo "TUN Interface not found"
        exit 1
    fi

    echo "Resetting TUN"
    ip link set ${INTERFACE} down
    sleep 1
    ip link set ${INTERFACE} up
    echo "Sent kill SIGUSR1 to openvpn"
    pkill -SIGUSR1 openvpn
    sleep 20
fi

ping -c 1 $HOST
STATUS=$?
if [[ ${STATUS} -ne 0 ]]
then
    echo "Network is still down"
    exit 1
fi

echo "Network is up"

#Service check
#Expected output is 2 for both checks, 1 for process and 1 for grep
OPENVPN=$(pgrep openvpn | wc -l )
TRANSMISSION=$(pgrep transmission | wc -l)

if [[ ${OPENVPN} -ne 1 ]]
then
	echo "Openvpn process not running"
	exit 1
fi
if [[ ${TRANSMISSION} -ne 1 ]]
then
	echo "transmission-daemon process not running"
	exit 1
fi

echo "Openvpn and transmission-daemon processes are running"
exit 0
