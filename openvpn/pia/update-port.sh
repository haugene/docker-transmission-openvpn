#!/bin/bash 
#export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/root/bin
# Source our persisted env variables from container startup
## this is an amalgamation of two scripts to keep my PIA working, credit to the main authors, the original scripts linked in the READ.ME
#v0.2

. /etc/transmission/environment-variables.sh

# Settings
TRANSMISSION_PASSWD_FILE=/config/transmission-credentials.txt

transmission_username=$(head -1 ${TRANSMISSION_PASSWD_FILE})
transmission_passwd=$(tail -1 ${TRANSMISSION_PASSWD_FILE})
pia_client_id_file=/etc/transmission/pia_client_id
transmission_settings_file=${TRANSMISSION_HOME}/settings.json

sleep 5

###### PIA Variables ######
curl_max_time=15
curl_retry=5
curl_retry_delay=15
user=$(sed -n 1p /config/openvpn-credentials.txt)
pass=$(sed -n 2p /config/openvpn-credentials.txt)
pf_host=$(ip route | grep tun | grep -v src | head -1 | awk '{ print $3 }')

###### Nextgen PIA port forwarding      ##################

get_auth_token () {
            tok=$(curl --insecure --silent --show-error --request POST --max-time $curl_max_time \
                 --header "Content-Type: application/json" \
                 --data "{\"username\":\"$user\",\"password\":\"$pass\"}" \
                "https://www.privateinternetaccess.com/api/client/v2/token" | jq -r '.token')
            [ $? -ne 0 ] && echo "Failed to acquire new auth token" && exit 1
            #echo "$tok"
    }


get_sig () {
  pf_getsig=$(curl --insecure --get --silent --show-error \
    --retry $curl_retry --retry-delay $curl_retry_delay --max-time $curl_max_time \
    --data-urlencode "token=$tok" \
    $verify \
    "https://$pf_host:19999/getSignature")
  if [ "$(echo $pf_getsig | jq -r .status)" != "OK" ]; then
    echo "$(date): getSignature error"
    echo $pf_getsig
    echo "the has been a fatal_error"
  fi
  pf_payload=$(echo $pf_getsig | jq -r .payload)
  pf_getsignature=$(echo $pf_getsig | jq -r .signature)
  pf_port=$(echo $pf_payload | base64 -d | jq -r .port)
  pf_token_expiry_raw=$(echo $pf_payload | base64 -d | jq -r .expires_at)
  if date --help 2>&1 /dev/null | grep -i 'busybox' > /dev/null; then
    pf_token_expiry=$(date -D %Y-%m-%dT%H:%M:%S --date="$pf_token_expiry_raw" +%s)
  else
    pf_token_expiry=$(date --date="$pf_token_expiry_raw" +%s)
  fi
}

bind_port () {
  pf_bind=$(curl --insecure --get --silent --show-error \
      --retry $curl_retry --retry-delay $curl_retry_delay --max-time $curl_max_time \
      --data-urlencode "payload=$pf_payload" \
      --data-urlencode "signature=$pf_getsignature" \
      $verify \
      "https://$pf_host:19999/bindPort")
  if [ "$(echo $pf_bind | jq -r .status)" = "OK" ]; then
    echo "Reserved Port: $pf_port  $(date)"		
  else  
    echo "$(date): bindPort error"
    echo $pf_bind
    echo "the has been a fatal_error"
  fi
}

bind_trans () {
new_port=$pf_port
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
until torrent_list="$(transmission-remote $TRANSMISSION_RPC_PORT $myauth -l)"; do sleep 10; done
echo "transmission became responsive"
output="$(echo "$torrent_list" | tail -n 2)"
echo "$output"

# get current listening port
transmission_peer_port=$(transmission-remote $TRANSMISSION_RPC_PORT $myauth -si | grep Listenport | grep -oE '[0-9]+')
if [[ "$new_port" != "$transmission_peer_port" ]]; then
  if [[ "true" = "$ENABLE_UFW" ]]; then
    echo "Update UFW rules before changing port in Transmission"

    echo "denying access to $transmission_peer_port"
    ufw deny "$transmission_peer_port"

    echo "allowing $new_port through the firewall"
    ufw allow "$new_port"
  fi

  echo "setting transmission port to $new_port"
  transmission-remote ${TRANSMISSION_RPC_PORT} ${myauth} -p "$new_port"

  echo "Checking port..."
  sleep 10
  transmission-remote ${TRANSMISSION_RPC_PORT} ${myauth} -pt
else
    echo "No action needed, port hasn't changed"
fi
}
echo "Running functions for token based port fowarding"
get_auth_token
get_sig
bind_port
bind_trans
format_expiry=$(date -d @$pf_token_expiry)
echo "#######################"
echo "        SUCCESS        "
echo "#######################"
echo "Port: $pf_port"
echo "Expiration $format_expiry"
echo "#######################"
echo "Entering infinite while loop"
echo "Every 15 minutes, check port status"
pf_minreuse=$(( 60 * 60 * 24 * 7 ))
pf_remaining=$((  $pf_token_expiry - $(date +%s) ))

while true; do
	pf_remaining=$((  $pf_token_expiry - $(date +%s) ))
	if [ $pf_remaining -lt $pf_minreuse ]; then
		echo "60 day port reservation reached"
		echo "Getting a new one"
		get_auth_token
		get_sig
		bind_port
		bind_trans
	fi
	sleep 900 &
	wait $!
	bind_port
done
