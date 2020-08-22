#! /bin/bash

# Source our persisted env variables from container startup
. /etc/transmission/environment-variables.sh

# Settings
TRANSMISSION_PASSWD_FILE=/config/transmission-credentials.txt

transmission_username=$(head -1 $TRANSMISSION_PASSWD_FILE)
transmission_passwd=$(tail -1 $TRANSMISSION_PASSWD_FILE)
transmission_settings_file=${TRANSMISSION_HOME}/settings.json

# Calculate the port

IPADDRESS=$TRANSMISSION_BIND_ADDRESS_IPV4
echo "ipAddress to calculate port from $IPADDRESS"
oct3=$(echo ${IPADDRESS} | tr "." " " | awk '{ print $3 }')
oct4=$(echo ${IPADDRESS} | tr "." " " | awk '{ print $4 }')
oct3binary=$(bc <<<"obase=2;$oct3" | awk '{ len = (8 - length % 8) % 8; printf "%.*s%s\n", len, "00000000", $0}')
oct4binary=$(bc <<<"obase=2;$oct4" | awk '{ len = (8 - length % 8) % 8; printf "%.*s%s\n", len, "00000000", $0}')

sum=${oct3binary}${oct4binary}
portPartBinary=${sum:4}
portPartDecimal=$((2#$portPartBinary))
if [ ${#portPartDecimal} -ge 4 ]
	then
	new_port="1"${portPartDecimal}
else
	new_port="10"${portPartDecimal}
fi
echo "calculated port $new_port"

#
# Now, set port in Transmission
#

# Check if transmission remote is set up with authentication
auth_enabled=$(grep 'rpc-authentication-required\"' $transmission_settings_file | grep -oE 'true|false')
if [ "true" = "$auth_enabled" ]
  then
  echo "transmission auth required"
  myauth="--auth $transmission_username:$transmission_passwd"
else
    echo "transmission auth not required"
    myauth=""
fi

# get current listening port
sleep 3
transmission_peer_port=$(transmission-remote $myauth -si | grep Listenport | grep -oE '[0-9]+')
if [ "$new_port" != "$transmission_peer_port" ]; then
  if [ "true" = "$ENABLE_UFW" ]; then
    echo "Update UFW rules before changing port in Transmission"

    echo "denying access to $transmission_peer_port"
    ufw deny ${transmission_peer_port}

    echo "allowing $new_port through the firewall"
    ufw allow ${new_port}
  fi

  transmission-remote ${myauth} -p "$new_port"

  echo "Checking port..."
  sleep 10
  transmission-remote ${myauth} -pt
else
    echo "No action needed, port hasn't changed"
fi
