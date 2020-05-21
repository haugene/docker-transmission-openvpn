#! /bin/bash

# Source our persisted env variables from container startup
. /etc/transmission/environment-variables.sh

# Settings
TRANSMISSION_PASSWD_FILE=/config/transmission-credentials.txt

transmission_username=$(head -1 $TRANSMISSION_PASSWD_FILE)
transmission_passwd=$(tail -1 $TRANSMISSION_PASSWD_FILE)
transmission_settings_file=${TRANSMISSION_HOME}/settings.json

#
# Fetch forwarded port from PrivateVPN API
#

# Get the port
tun_ip=$(ip address show dev tun0 | grep 'inet\b' | awk '{print $2}' | cut -d/ -f1)
pvpn_get_port_url="https://xu515.pvdatanet.com/v3/mac/port?ip%5B%5D=$tun_ip"
pvpn_response=$(curl -s -f "$pvpn_get_port_url")
pvpn_curl_exit_code=$?

if [[ -z "$pvpn_response" ]]; then
    echo "PrivateVPN port forward API returned a bad response"
fi

# Check for curl error (curl will fail on HTTP errors with -f flag)
if [[ ${pvpn_curl_exit_code} -ne 0 ]]; then
    echo "curl encountered an error looking up forwarded port: $pvpn_curl_exit_code"
    exit
fi

# Check for errors in curl response
error=$(echo "$pvpn_response" | grep -o "\"Not supported\"")
if [[ ! -z "$error" ]]; then
    echo "PrivateVPN API returned an error: $error - not all PrivateVPN servers support port forwarding. Try 'SE Stockholm'."
    exit
fi

# Get new port, check if empty
new_port=$(echo "$pvpn_response" | grep -oe 'Port [0-9]*' | awk '{print $2}' | cut -d/ -f1)
if [[ -z "$new_port" ]]; then
    echo "Could not find new port from PrivateVPN API"
    exit
fi
echo "Got new port $new_port from PrivateVPN API"

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
