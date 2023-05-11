#!/bin/bash

source /etc/openvpn/utils.sh

# Handle SIGTERM
sigterm() {
    echo "Received SIGTERM, exiting..."
    trap - SIGTERM
    kill -- -$$
}
trap sigterm SIGTERM

#Network check
# Ping uses both exit codes 1 and 2. Exit code 2 cannot be used for docker health checks,
# therefore we use this script to catch error code 2
HOST=${HEALTH_CHECK_HOST}

if [[ -z "$HOST" ]]
then
    echo "Host  not set! Set env 'HEALTH_CHECK_HOST'. For now, using default google.com"
    HOST="google.com"
fi

# Check DNS resolution works
nslookup $HOST > /dev/null
STATUS=$?
if [[ ${STATUS} -ne 0 ]]
then
    echo "DNS resolution failed"
    exit 1
fi

ping -c 2 -w 10 $HOST # Get at least 2 responses and timeout after 10 seconds
STATUS=$?
if [[ ${STATUS} -ne 0 ]]
then
    echo "Network is down"
    exit 1
fi

echo "Network is up"

#Service check
#Expected output is 2 for both checks, 1 for process and 1 for grep
OPENVPN=$(pgrep openvpn | wc -l )
TRANSMISSION=$(pgrep transmission | wc -l)
PROXY=$(pgrep privoxy | wc -l)

if [[ ${OPENVPN} -ne 1 ]]; then
	echo "Openvpn process not running"
	exit 1
fi
if [[ ${TRANSMISSION} -ne 1 ]]; then
	echo "transmission-daemon process not running"
	exit 1
fi

if [[ ${WEBPROXY_ENABLED} =~ [yY][eE]?[Ss]?|[tT][Rr][Uu][eE] ]]; then
  if [[ ${PROXY} -eq 0 ]]; then
    echo "Privoxy warning: process was stopped, restarting."
  fi
    proxy_ip=$(grep -oP "(?<=^listen-address )[0-9\.]+" /etc/privoxy/config)
    cont_ip=$(ip -j a show dev eth0 | jq -r .[].addr_info[].local)
    if [[ ${proxy_ip} != ${cont_ip} ]]; then
      echo "Privoxy error: container ip (${cont_ip} has changed: privoxy listening to ${proxy_ip}, restarting privoxy."
      pkill privoxy || true
      /opt/privoxy/start.sh
    fi
fi
echo "Openvpn and transmission-daemon processes are running"
exit 0
