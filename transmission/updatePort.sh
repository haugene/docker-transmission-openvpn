#! /bin/bash

echo "Wait for tunnel to be fully initialized and PIA is ready to give us a port"
sleep 15

# Source our persisted env variables from container startup
. /etc/transmission/environment-variables.sh

# Settings
TRANSMISSION_PASSWD_FILE=/config/transmission-credentials.txt

transmission_username=$(head -1 ${TRANSMISSION_PASSWD_FILE})
transmission_passwd=$(tail -1 ${TRANSMISSION_PASSWD_FILE})
pia_client_id_file=/etc/transmission/pia_client_id
transmission_settings_file=${TRANSMISSION_HOME}/settings.json

#
# First get a port from PIA
#

new_client_id() {
    head -n 100 /dev/urandom | sha256sum | tr -d " -" | tee ${pia_client_id_file}
}

pia_client_id="$(cat ${pia_client_id_file} 2>/dev/null)"
if [[ -z "${pia_client_id}" ]]; then
   echo "Generating new client id for PIA"
   pia_client_id=$(new_client_id)
fi

# Get the port
port_assignment_url="http://209.222.18.222:2000/?client_id=$pia_client_id"
pia_response=$(curl -s -f "$port_assignment_url")
pia_curl_exit_code=$?

if [[ -z "$pia_response" ]]; then
    echo "Port forwarding is already activated on this connection, has expired, or you are not connected to a PIA region that supports port forwarding"
fi

# Check for curl error (curl will fail on HTTP errors with -f flag)
if [[ ${pia_curl_exit_code} -ne 0 ]]; then
   echo "curl encountered an error looking up new port: $pia_curl_exit_code"
   exit
fi

# Check for errors in PIA response
error=$(echo "$pia_response" | grep -oE "\"error\".*\"")
if [[ ! -z "$error" ]]; then
   echo "PIA returned an error: $error"
   exit
fi

# Get new port, check if empty
new_port=$(echo "$pia_response" | grep -oE "[0-9]+")
if [[ -z "$new_port" ]]; then
    echo "Could not find new port from PIA"
    exit
fi
echo "Got new port $new_port from PIA"

#
# Now, set port in Transmission
#

# Check if transmission remote is set up with authentication
auth_enabled=$(grep 'rpc-authentication-required\"' "$transmission_settings_file" \
                   | grep -oE 'true|false')
if [[ "true" = "$auth_enabled" ]]
  then
  echo "transmission auth required"
  myauth="--auth $transmission_username:$transmission_passwd"
else
    echo "transmission auth not required"
    myauth=""
fi

# make sure transmission is running and accepting requests
echo "waiting for transmission to become responsive"
until torrent_list="$(transmission-remote $myauth -l)"; do sleep 10; done
echo "transmission became responsive"
output="$(echo "$torrent_list" | tail -n 2)"
echo "$output"

# get current listening port
transmission_peer_port=$(transmission-remote $myauth -si | grep Listenport | grep -oE '[0-9]+')
if [[ "$new_port" != "$transmission_peer_port" ]]; then
  if [[ "true" = "$ENABLE_UFW" ]]; then
    echo "Update UFW rules before changing port in Transmission"

    echo "denying access to $transmission_peer_port"
    ufw deny "$transmission_peer_port"

    echo "allowing $new_port through the firewall"
    ufw allow "$new_port"
  fi

  echo "setting transmission port to $new_port"
  transmission-remote ${myauth} -p "$new_port"

  echo "Checking port..."
  sleep 10
  transmission-remote ${myauth} -pt
else
    echo "No action needed, port hasn't changed"
fi
