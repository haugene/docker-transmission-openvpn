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
IFS='.' read -ra ADDR <<< "$IPADDRESS"
function d2b() {
    printf "%08d" $(echo "obase=2;$1"|bc)
}
port_bin="$(d2b ${ADDR[2]})$(d2b ${ADDR[3]})"
port_dec=$(printf "%04d" $(echo "ibase=2;${port_bin:4}"|bc))
new_port=3$port_dec
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
