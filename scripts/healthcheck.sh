#!/bin/bash
# redirect stdout/stderr to a file
#exec &>>logfile.txt

#Network check
# Ping uses both exit codes 1 and 2. Exit code 2 cannot be used for docker health checks,
# therefore we use this script to catch error code 2
HOST=${HEALTH_CHECK_HOST}

#Print Date
NOW=$(date +"%Y-%m-%d %T")
echo "${NOW}: Starting Health check script "

#Check if we have an tun interface
INTERFACE=$(ls /sys/class/net | grep tun)
ISINTERFACE=$?
if [[ ${ISINTERFACE} -ne 0 ]]; then
  echo "TUN Interface not found"
  exit 1

else
  NINTERFACE=$(echo "${INTERFACE}" | wc -l)
  if [[ ${NINTERFACE} -ne 1 ]]; then
    echo "Warning: Multiple tun dev found! May not be using the correct interface"
  fi
fi

#Ping the host 5 time
ping -c 5 $HOST
STATUS=$?
if [[ ${STATUS} -ne 0 ]]; then
  echo "Network is down"

  echo "Resetting TUN"
  ip link set "${INTERFACE}" down
  sleep 1
  ip link set "${INTERFACE}" up
  echo "Sent kill SIGUSR1 to openvpn"
  pkill -SIGUSR1 openvpn
  sleep 20

  #Ping again to see if vpn recover
  ping -c 5 $HOST
  STATUS=$?
  if [[ ${STATUS} -ne 0 ]]; then
    echo "Network is still down, try again with hard restart"
    ip link set "${INTERFACE}" down
    sleep 1
    ip link set "${INTERFACE}" up
    echo "Sent kill HUP to openvpn"
    pkill -HUP openvpn
    sleep 20
  fi

fi

echo "Ping success, checking if using tun"
IP=$(getent ahostsv4 ${HOST} | awk '{print $1}' | head -1)
ip r get "${IP}" | grep "${INTERFACE}"
STATUS=$?
if [[ ${STATUS} -ne 0 ]]; then
  echo "Not using ${INTERFACE}!"
  ip link set "${INTERFACE}" down
  sleep 1
  ip link set "${INTERFACE}" up
  echo "Sent kill HUP to openvpn"
  pkill -HUP openvpn
  sleep 20
else
  echo "Using ${INTERFACE}, OK!"
fi

ping -c 5 $HOST
STATUS=$?
if [[ ${STATUS} -ne 0 ]]; then
  echo "Network is still down, health check failed."
  exit 1
fi

echo "Network is up"

#Service check
#Expected output is 2 for both checks, 1 for process and 1 for grep
OPENVPN=$(pgrep openvpn | wc -l)
TRANSMISSION=$(pgrep transmission | wc -l)

if [[ ${OPENVPN} -ne 1 ]]; then
  echo "Openvpn process not running"
  exit 1
fi
if [[ ${TRANSMISSION} -ne 1 ]]; then
  echo "transmission-daemon process not running"
  exit 1
fi

echo "Openvpn and transmission-daemon processes are running"
exit 0
