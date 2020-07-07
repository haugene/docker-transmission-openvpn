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
    exit 1
fi

echo "Network is up"

#Service check
#Expected output is 2 for both checks, 1 for process and 1 for grep
OPENVPN=$(ps -ef | grep 'openvpn --script-security' |wc| awk '{print $1}')
TRANSMISSION=$(ps -ef | grep 'transmission-daemon' |wc| awk '{print $1}')

if [[ ${OPENVPN} -ne 2 ]]
then
	echo "Openvpn process not running"
	exit 1
fi
if [[ ${TRANSMISSION} -ne 2 ]]
then
	echo "transmission-daemon process not running"
	exit 1
fi

echo "Openvpn and transmission-daemon processes are running"
exit 0
