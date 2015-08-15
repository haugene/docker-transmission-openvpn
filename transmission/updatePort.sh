#! /bin/sh

# Source our persisted env variables from container startup
. /etc/transmission/environment-variables.sh

# Settings
PIA_PASSWD_FILE=/config/openvpn-credentials.txt
TRANSMISSION_PASSWD_FILE=/config/transmission-credentials.txt

pia_username=$(head -1 $PIA_PASSWD_FILE)
pia_passwd=$(tail -1 $PIA_PASSWD_FILE)
transmission_username=$(head -1 $TRANSMISSION_PASSWD_FILE)
transmission_passwd=$(tail -1 $TRANSMISSION_PASSWD_FILE)
local_vpn_ip=$(ip addr show tun0 | grep inet | awk '{ print $2 }')
pia_client_id_file=/etc/transmission/pia_client_id
transmission_settings_file=${TRANSMISSION_HOME}/settings.json
port_assignment_url=https://www.privateinternetaccess.com/vpninfo/port_forward_assignment

#
# First get a port from PIA
#

new_client_id() {
    head -n 100 /dev/urandom | md5sum | tr -d " -" | tee $pia_client_id_file
}

pia_client_id="$(cat $pia_client_id_file 2>/dev/null)"
if [ -z ${pia_client_id} ]; then
     echo "Generating new client id for PIA"
     pia_client_id=$(new_client_id)
fi

# Get the port
pia_response=$(curl -d "user=$pia_username&pass=$pia_passwd&client_id=$pia_client_id&local_ip=$local_vpn_ip" $port_assignment_url)

new_port=$(echo $pia_response | grep -oE "[0-9]+")
echo "Got new port $new_port from pia"

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
transmission_peer_port=$(transmission-remote $myauth -si | grep Listenport | grep -oE '[0-9]+')
if [ "$new_port" != "$transmission_peer_port" ]
  then
    transmission-remote $myauth -p "$new_port"
    echo "Checking port..."
    sleep 10 && transmission-remote $myauth -pt
  else
    echo "No action needed, port hasn't changed"
fi

